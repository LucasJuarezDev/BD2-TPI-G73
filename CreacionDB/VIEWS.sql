	
	USE DB_Mayorista_TPI_G73
	GO


	-- 1. Compras con cliente (solo clientes que compraron)
	CREATE VIEW VW_Compras_Cliente AS
	SELECT 
		c.IdCompra as 'Nro Compra',
		p.Apellido + ', ' + p.Nombre AS Cliente,
		c.FechaCompra 'Fecha',
		c.Monto AS 'Monto Total',
		tp.NombreTipoPago 'Forma de pago' 
	FROM Compra c
	INNER JOIN Compra_X_Cliente cxc ON c.IdCompra = cxc.IdCompra
	INNER JOIN Cliente cl ON cxc.IdCliente = cl.IdCliente
	INNER JOIN Persona p ON cl.IdPersona = p.IdPersona
	INNER JOIN Tipo_Pago tp ON c.IdTipoPago = tp.IdTipoPago;
	GO


	-- 2. Stock bajo (solo productos activos)
	CREATE VIEW VW_Stock_Bajo AS
	SELECT 
		IdProducto AS 'Id',
		Nombre AS 'Producto',
		Stock,
		Precio
	FROM Productos
	WHERE Stock < 10 AND Estado = 1;
	GO


	-- 3. Empleados con puesto principal
	CREATE VIEW VW_Empleado_Activo AS
	SELECT 
		e.IdEmpleado 'Id',
		per.Apellido + ', ' + per.Nombre AS 'Empleado',
		p.NombrePuesto 'Puesto',
		e.CUIL,
		e.TurnoTrabajo 'Turno'
	FROM Empleado e
	INNER JOIN Persona per ON e.IdPersona = per.IdPersona
	INNER JOIN Empleados_X_Puesto empexp ON e.IdEmpleado = empexp.IdEmpleado 
		AND empexp.EsPrincipal = 1 AND empexp.FechaHasta IS NULL
	INNER JOIN Puestos p ON empexp.IdPuesto = p.IdPuesto
	WHERE e.Activo = 1;
	GO
