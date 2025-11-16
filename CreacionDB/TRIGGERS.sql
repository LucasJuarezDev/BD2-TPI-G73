USE DB_Mayorista_TPI_G73
GO


-- TRIGGER PARA VALIDAR SI EL CLIENTE QUE COMPRO FIGURA ACTIVO
CREATE TRIGGER tr_ClienteActivoEnCompraXCliente_AfterInsert
ON Compra_X_Cliente
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Cliente cl ON i.IdCliente = cl.IdCliente
        WHERE cl.Activo = 0
    )
    BEGIN
        RAISERROR('No se puede asociar un cliente inactivo a una compra.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
end


	-- TRIGGER PARA RESTAURAR STOCK EN CASO DE CANCELACION DE COMPRA-
	CREATE TRIGGER tr_restaurarStock
	ON Compra_X_Producto
	AFTER DELETE
	AS
	BEGIN
		UPDATE p
		SET p.Stock = p.Stock + d.Cantidad,
			p.FechaUltimaModificacion = GETDATE()
		FROM Productos p
		INNER JOIN deleted d ON p.IdProducto = d.IdProducto;
	END;

