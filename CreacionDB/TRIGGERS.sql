USE DB_Mayorista_TPI_G73
GO


-- TRIGGER PARA VALIDAR SI EL CLIENTE QUE COMPRO FIGURA ACTIVO
CREATE TRIGGER tr_ClienteActivoEnCompra
ON Compra
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN CompraXCliente cxc ON i.IdCompra = cxc.IdCompra
        INNER JOIN Cliente cl ON cxc.IdCliente = cl.IdCliente
        WHERE cl.Activo = 0
    )
    BEGIN
        RAISERROR('No se puede registrar una compra para un cliente inactivo.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;


	-- TRIGGER PARA RESTAURAR STOCK EN CASO DE CANCELACION DE COMPRA
	CREATE TRIGGER tr_restaurarStock
	ON CompraXProducto
	AFTER DELETE
	AS
	BEGIN
		UPDATE p
		SET p.Stock = p.Stock + d.Cantidad,
			p.FechaUltimaModificacion = GETDATE()
		FROM Producto p
		INNER JOIN deleted d ON p.IdProducto = d.IdProducto;
	END;