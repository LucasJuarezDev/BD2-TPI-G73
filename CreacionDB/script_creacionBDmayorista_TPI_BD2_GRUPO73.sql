-- =============================================
-- BASE DE DATOS: DB_Mayorista_TPI_G73
-- GRUPO: G73
-- =============================================
CREATE DATABASE DB_Mayorista_TPI_G73;
GO

USE DB_Mayorista_TPI_G73;
GO

-- =============================================
-- TABLA: Persona (datos unificados)
-- =============================================
CREATE TABLE Persona (
    IdPersona INT IDENTITY(1,1) PRIMARY KEY,
    Apellido VARCHAR(100) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Documento VARCHAR(20) NOT NULL,
    Direccion VARCHAR(200) NULL,
    Email VARCHAR(150) NULL,
    Telefono VARCHAR(20) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL
);
GO

-- =============================================
-- TABLA: Tipo_Cliente
-- =============================================
CREATE TABLE Tipo_Cliente (
    IdTipoCliente INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipoCliente VARCHAR(100) NOT NULL UNIQUE
);
GO

-- Datos iniciales
INSERT INTO Tipo_Cliente (NombreTipoCliente) VALUES 
('General'), ('Socio'), ('Mayorista');
GO

-- =============================================
-- TABLA: Cliente
-- =============================================
CREATE TABLE Cliente (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    IdPersona INT NOT NULL,
    IdTipoCliente INT NULL,
    FranjaHoraria VARCHAR(100) NULL,           -- Ej: "Mañana 8-12", "Tarde 14-18"
    DireccionEnvio VARCHAR(200) NULL,
    Observaciones VARCHAR(250) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    CONSTRAINT FK_Cliente_Persona FOREIGN KEY (IdPersona) REFERENCES Persona(IdPersona),
    CONSTRAINT FK_Cliente_TipoCliente FOREIGN KEY (IdTipoCliente) REFERENCES Tipo_Cliente(IdTipoCliente)
);
GO

-- =============================================
-- TABLA: Puestos
-- =============================================
CREATE TABLE Puestos (
    IdPuesto INT IDENTITY(1,1) PRIMARY KEY,
    NombrePuesto NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- Datos iniciales
INSERT INTO Puestos (NombrePuesto) VALUES 
('Repositor'), ('Cajero'), ('Limpiador'), ('Manager');
GO

-- =============================================
-- TABLA: Empleado
-- =============================================
CREATE TABLE Empleado (
    IdEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    IdPersona INT NOT NULL,
    CUIL NVARCHAR(20) NULL,
    FechaIngreso DATE NULL,
    SueldoBase DECIMAL(10,2) NULL CHECK (SueldoBase >= 0),
    TurnoTrabajo NVARCHAR(50) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    CONSTRAINT FK_Empleado_Persona FOREIGN KEY (IdPersona) REFERENCES Persona(IdPersona),
    CONSTRAINT UQ_Empleado_CUIL UNIQUE (CUIL)
);
GO

-- =============================================
-- TABLA: Empleados_X_Puesto
-- =============================================
CREATE TABLE Empleados_X_Puesto (
    IdEmpleado INT NOT NULL,
    IdPuesto INT NOT NULL,
    FechaDesde DATE NULL,
    FechaHasta DATE NULL,
    EsPrincipal BIT NOT NULL DEFAULT 0,
    PRIMARY KEY (IdEmpleado, IdPuesto),
    CONSTRAINT FK_EmXPu_Empleado FOREIGN KEY (IdEmpleado) REFERENCES Empleado(IdEmpleado),
    CONSTRAINT FK_EmXPu_Puesto FOREIGN KEY (IdPuesto) REFERENCES Puestos(IdPuesto),
    CONSTRAINT CHK_Fechas CHECK (FechaHasta IS NULL OR FechaHasta >= FechaDesde)
);
GO

-- =============================================
-- TABLA: Usuario (login)
-- =============================================
CREATE TABLE Usuario (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    IdPersona INT NOT NULL,
    UserName VARCHAR(100) NOT NULL UNIQUE,
    Contraseña VARCHAR(200) NOT NULL,  
    TipoUsuario VARCHAR(50) NOT NULL,  -- Ej: Gerente, Cajero, Repositor
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (IdPersona) REFERENCES Persona(IdPersona)
);
GO

-- =============================================
-- TABLA: Tipo_Pago
-- =============================================
CREATE TABLE Tipo_Pago (
    IdTipoPago INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipoPago NVARCHAR(50) NOT NULL UNIQUE
);
GO

INSERT INTO Tipo_Pago (NombreTipoPago) VALUES 
('Efectivo'), ('Tarjeta'), ('Transferencia'), ('Cheque');
GO

-- =============================================
-- TABLA: Compra
-- =============================================
CREATE TABLE Compra (
    IdCompra INT IDENTITY(1,1) PRIMARY KEY,
    IdTipoPago INT NOT NULL,
    Monto DECIMAL(12,2) NOT NULL CHECK (Monto >= 0),
    FechaCompra DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Compra_TipoPago FOREIGN KEY (IdTipoPago) REFERENCES Tipo_Pago(IdTipoPago)
);
GO

-- =============================================
-- TABLA: Compra_X_Cliente 
-- =============================================
CREATE TABLE Compra_X_Cliente (
    IdCompra INT NOT NULL,
    IdCliente INT NOT NULL,
    Rol NVARCHAR(50) NULL,  -- Ej: 'Comprador', 'Beneficiario', 'Autorizado'
    PRIMARY KEY (IdCompra, IdCliente),
    CONSTRAINT FK_CompraCliente_Compra FOREIGN KEY (IdCompra) REFERENCES Compra(IdCompra),
    CONSTRAINT FK_CompraCliente_Cliente FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);
GO

-- =============================================
-- TABLA: Caja
-- =============================================
CREATE TABLE Caja (
    IdCaja INT IDENTITY(1,1) PRIMARY KEY,
    IdCompra INT NOT NULL,
    MontoRecibido DECIMAL(12,2) NULL,
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    Observaciones NVARCHAR(250) NULL,
    CONSTRAINT FK_Caja_Compra FOREIGN KEY (IdCompra) REFERENCES Compra(IdCompra),
    CONSTRAINT UQ_Caja_Compra UNIQUE (IdCompra)
);
GO

-- =============================================
-- TABLA: Categoria
-- =============================================
CREATE TABLE Categoria (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria NVARCHAR(150) NOT NULL UNIQUE
);
GO

-- =============================================
-- TABLA: Productos
-- =============================================
CREATE TABLE Productos (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(150) NOT NULL,
    Stock INT NOT NULL CHECK (Stock >= 0),
    Precio DECIMAL(12,2) NOT NULL CHECK (Precio >= 0),
    Descripcion NVARCHAR(400) NULL,
    Estado BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL
);
GO


-- =============================================
-- TABLA: Productos_X_Categoria 
-- =============================================
CREATE TABLE Productos_X_Categoria (
    IdProducto INT NOT NULL,
    IdCategoria INT NOT NULL,
    PRIMARY KEY (IdProducto, IdCategoria),
    CONSTRAINT FK_ProductoCategoria_Producto FOREIGN KEY (IdProducto) REFERENCES Productos(IdProducto),
    CONSTRAINT FK_ProductoCategoria_Categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(IdCategoria)
);
GO

-- =============================================
-- TABLA: Proveedores
-- =============================================
CREATE TABLE Proveedores (
    IdProveedor INT IDENTITY(1,1) PRIMARY KEY,
    NombreProveedor NVARCHAR(200) NOT NULL,
    Descripcion NVARCHAR(400) NULL,
    Telefono NVARCHAR(50) NULL,
    Email NVARCHAR(150) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL
);
GO

-- =============================================
-- TABLA: Productos_X_Proveedores
-- =============================================
CREATE TABLE Productos_X_Proveedores (
    IdProducto INT NOT NULL,
    IdProveedor INT NOT NULL,
    CodigoProveedor NVARCHAR(100) NULL,
    PRIMARY KEY (IdProducto, IdProveedor),
    CONSTRAINT FK_ProductoProveedor_Producto FOREIGN KEY (IdProducto) REFERENCES Productos(IdProducto),
    CONSTRAINT FK_ProductoProveedor_Proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedores(IdProveedor)
);
GO

-- =============================================
-- TABLA: Compra_X_Producto (detalle)
-- =============================================
CREATE TABLE Compra_X_Producto (
    IdCompra INT NOT NULL,
    IdProducto INT NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL CHECK (PrecioUnitario >= 0),
    PRIMARY KEY (IdCompra, IdProducto),
    CONSTRAINT FK_CompraProducto_Compra FOREIGN KEY (IdCompra) REFERENCES Compra(IdCompra),
    CONSTRAINT FK_CompraProducto_Producto FOREIGN KEY (IdProducto) REFERENCES Productos(IdProducto)
);
GO

-- =============================================
-- TABLA: Productos_Compra_Temporal (para el sp de registrar compra)
-- =============================================

CREATE TABLE Productos_Compra_Temporal (
    IdProducto INT,
    Cantidad INT,
    PrecioUnitario DECIMAL(12,2)
);
GO