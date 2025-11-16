
-----------------Procedimiento Almacenado 2------------------------------------------
--generar un reporte de ventas filtrado por rango de fechas, 
--incluyendo cliente, monto, tipo de pago y cantidad de productos.

USE DB_Mayorista_TPI_G73
GO

CREATE PROCEDURE SP_Reporte_Ventas_Por_Periodo
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SELECT 
        c.IdCompra,
        p.Apellido + ', ' + p.Nombre AS Cliente,
        c.FechaCompra,
        c.Monto,
        tp.NombreTipoPago,
        COUNT(cxp.IdProducto) AS CantidadProductos
    FROM Compra c
    JOIN Compra_X_Cliente cxc ON c.IdCompra = cxc.IdCompra
    JOIN Cliente cl ON cxc.IdCliente = cl.IdCliente
    JOIN Persona p ON cl.IdPersona = p.IdPersona
    JOIN Tipo_Pago tp ON c.IdTipoPago = tp.IdTipoPago
    LEFT JOIN Compra_X_Producto cxp ON c.IdCompra = cxp.IdCompra
    WHERE CAST(c.FechaCompra AS DATE) BETWEEN @FechaDesde AND @FechaHasta
    GROUP BY c.IdCompra, p.Apellido, p.Nombre, c.FechaCompra, c.Monto, tp.NombreTipoPago
    ORDER BY c.FechaCompra DESC;
END;
GO

--------------Procedimiento Almacenado 1--------------------------------------------------
----registrar una compra completa de forma automática

USE DB_Mayorista_TPI_G73;
GO

CREATE OR ALTER PROCEDURE SP_Registrar_Compra_Desde_Tabla
    @IdCliente INT,
    @IdTipoPago INT,
    @MontoRecibido DECIMAL(12,2),
    @ListaProductos VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdCompra INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE Productos_Compra_Temporal;

        DECLARE @Item NVARCHAR(200);
        DECLARE @pos INT;

        WHILE LEN(@ListaProductos) > 0
        BEGIN
            SET @pos = CHARINDEX(';', @ListaProductos);
            IF @pos = 0 BREAK;

            SET @Item = SUBSTRING(@ListaProductos, 1, @pos - 1);
            SET @ListaProductos = SUBSTRING(@ListaProductos, @pos + 1, LEN(@ListaProductos));

            DECLARE @IdP NVARCHAR(50), @Cant NVARCHAR(50), @Prec NVARCHAR(50);

            ;WITH CTE AS (
                SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N, value
                FROM STRING_SPLIT(@Item, ',')
            )
            SELECT 
                @IdP  = (SELECT value FROM CTE WHERE N = 1),
                @Cant = (SELECT value FROM CTE WHERE N = 2),
                @Prec = (SELECT value FROM CTE WHERE N = 3);

            INSERT INTO Productos_Compra_Temporal (IdProducto, Cantidad, PrecioUnitario)
            VALUES (CAST(@IdP AS INT), CAST(@Cant AS INT), CAST(@Prec AS DECIMAL(12,2)));
        END

        IF EXISTS (
            SELECT 1
            FROM Productos_Compra_Temporal t
            LEFT JOIN Productos p ON p.IdProducto = t.IdProducto
            WHERE p.IdProducto IS NULL
        )
        BEGIN
            RAISERROR('Se intento usar un producto que NO existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF EXISTS (
            SELECT 1
            FROM Productos p
            INNER JOIN Productos_Compra_Temporal t ON p.IdProducto = t.IdProducto
            WHERE p.Stock < t.Cantidad
        )
        BEGIN
            RAISERROR('No hay stock suficiente.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        INSERT INTO Compra (IdTipoPago, Monto, FechaCompra)
        VALUES (@IdTipoPago, 0, GETDATE());

        SET @IdCompra = SCOPE_IDENTITY();


        INSERT INTO Compra_X_Cliente (IdCompra, IdCliente, Rol)
        VALUES (@IdCompra, @IdCliente, 'Comprador');

        INSERT INTO Compra_X_Producto (IdCompra, IdProducto, Cantidad, PrecioUnitario)
        SELECT @IdCompra, IdProducto, Cantidad, PrecioUnitario
        FROM Productos_Compra_Temporal;

        DECLARE @MontoTotal DECIMAL(12,2) =
        (
            SELECT SUM(Cantidad * PrecioUnitario)
            FROM Productos_Compra_Temporal
        );

        UPDATE Compra 
        SET Monto = @MontoTotal 
        WHERE IdCompra = @IdCompra;

        UPDATE p
        SET 
            p.Stock = p.Stock - t.Cantidad,
            p.FechaUltimaModificacion = GETDATE()
        FROM Productos p
        INNER JOIN Productos_Compra_Temporal t 
            ON p.IdProducto = t.IdProducto;

        INSERT INTO Caja (IdCompra, MontoRecibido, Fecha)
        VALUES (@IdCompra, @MontoRecibido, GETDATE());

        TRUNCATE TABLE Productos_Compra_Temporal;

        COMMIT TRANSACTION;

        SELECT 'Compra registrada con éxito' AS Resultado, @IdCompra AS IdCompra;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();

        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO


