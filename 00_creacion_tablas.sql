IF NOT EXISTS(	SELECT 1 FROM SYS.DATABASES WHERE name = 'Aurora_SA')
BEGIN
	CREATE DATABASE Aurora_SA
END;
GO

USE Aurora_SA
GO

IF NOT EXISTS(	SELECT 1 FROM SYS.SCHEMAS WHERE name = 'rrhh')
BEGIN
	EXEC('CREATE SCHEMA rrhh')
END;
GO

IF NOT EXISTS(	SELECT 1 FROM SYS.SCHEMAS WHERE name = 'productos')
BEGIN
	EXEC('CREATE SCHEMA productos')
END;
GO

IF NOT EXISTS(	SELECT 1 FROM SYS.SCHEMAS WHERE name = 'ventas')
BEGIN
	EXEC('CREATE SCHEMA ventas')
END;
GO

IF NOT EXISTS(	SELECT 1 FROM SYS.SCHEMAS WHERE name = 'utilidades')
BEGIN
	EXEC('CREATE SCHEMA utilidades')
END;
GO

IF NOT EXISTS(	SELECT 1 FROM SYS.SCHEMAS WHERE name = 'reportes')
BEGIN
	EXEC('CREATE SCHEMA reportes')
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'rrhh' AND TABLE_NAME = 'Sucursal')
BEGIN
	CREATE TABLE rrhh.Sucursal (
		id int primary key identity(1,1),
		ciudad varchar(20) NOT NULL,
		ubicacion varchar(20) NOT NULL,
		direccion varchar(255),
		horario varchar(255),
		telefono varchar(12),
		habilitado bit DEFAULT 1
	);
END
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'rrhh' AND TABLE_NAME = 'Empleado')
BEGIN
	CREATE TABLE rrhh.Empleado (
		legajo INT Primary Key,
		nombre VARCHAR(50) NOT NULL,
		apellido VARCHAR(50) NOT NULL,
		dni INT NOT NULL,
		direccion VARCHAR(255),
		emailPersonal VARCHAR(255),
		emailEmpresa VARCHAR(255) NOT NULL,
		cuil bigint NOT NULL,
		cargo VARCHAR(30) NOT NULL,
		sucursalId int NOT NULL,
		turno VARCHAR(17) NOT NULL,
		habilitado bit DEFAULT 1,
		FOREIGN KEY (sucursalID) REFERENCES rrhh.sucursal(id)
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'Cliente')
BEGIN
	CREATE TABLE ventas.Cliente(
		id int identity (1, 1) PRIMARY KEY,
		ciudad varchar(20) NOT NULL,
		genero char(1),
		tipo varchar(10),
		CONSTRAINT CHK_genero CHECK (genero = 'M' OR genero = 'F'),
		habilitado bit DEFAULT 1
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'MedioPago')
BEGIN
	CREATE TABLE ventas.MedioPago(
		id int PRIMARY KEY identity(1,1),
		descripcionIng varchar(21) NOT NULL,
		descripcionEsp varchar(21) NOT NULL,
		habilitado bit DEFAULT 1
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'productos' AND TABLE_NAME = 'LineaProducto')
	BEGIN
	CREATE TABLE productos.LineaProducto(
		id int PRIMARY KEY identity(1,1),
		nombre varchar (20) NOT NULL,
		habilitado bit DEFAULT 1
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'productos' AND TABLE_NAME = 'Producto')
BEGIN
	CREATE TABLE productos.Producto(	
		id int PRIMARY KEY identity(1,1),
		descripcion varchar(100),
		precio decimal(7,2),
		unidadReferencia varchar(7) DEFAULT 'UNIDAD',
		lineaID int,
		habilitado bit DEFAULT 1
		FOREIGN KEY (lineaID) REFERENCES productos.LineaProducto(id)
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'Estado')
BEGIN
	CREATE TABLE ventas.Estado(
		id int primary key identity(1,1),
		descripcion varchar(12)
	)
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE ventas.Factura(
		id int PRIMARY KEY identity(1,1),
		nro char(11),
		tipo char(1) NOT NULL,
		tipoCliente VARCHAR(20),
		genero VARCHAR(20),
		fechaHora smalldatetime NOT NULL,
		empleadoID int NOT NULL,
		pagoID int NOT NULL,
		estadoId int NOT NULL,
		precioTotal decimal(11,2),
		identificadorPago varchar(25),
		habilitado BIT DEFAULT 1,
		FOREIGN KEY (estadoId) REFERENCES ventas.Estado(id),
		FOREIGN KEY (empleadoID) REFERENCES rrhh.Empleado(legajo),
		FOREIGN KEY (pagoID) REFERENCES ventas.MedioPago(id),
		CONSTRAINT CHK_genero_factura CHECK (genero = 'Male' OR genero = 'Female'),
		CONSTRAINT CHK_nro CHECK (nro LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'DetalleFactura')
BEGIN
	CREATE TABLE ventas.DetalleFactura (
		facturaID int,
		item int,
		cantidad int NOT NULL,
		precio decimal(10,2) NOT NULL,
		productoID int,
		PRIMARY KEY (facturaID, item),
		FOREIGN KEY (facturaID) REFERENCES ventas.Factura(id),
		FOREIGN KEY (productoID) REFERENCES productos.Producto(id),
		CONSTRAINT CHK_precio CHECK(precio > 0),
		CONSTRAINT CHK_cantidad CHECK(cantidad > 0)
	);
END;
GO

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = 'ventas' AND TABLE_NAME = 'NotaCredito')
BEGIN
	CREATE TABLE ventas.NotaCredito (
		id INT IDENTITY(1,1) PRIMARY KEY,
		facturaID INT NOT NULL,
		fecha DATETIME DEFAULT GETDATE(),
		monto DECIMAL(10,2) NOT NULL,
		tipoNota CHAR(1) NOT NULL,  -- 'D' para devolución, 'S' para sustitución
		FOREIGN KEY (facturaID) REFERENCES ventas.Factura(id)
	);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'nix_nroFactura' AND object_id = OBJECT_ID('ventas.Factura'))
BEGIN
    CREATE NONCLUSTERED INDEX nix_nroFactura 
    ON ventas.Factura(nro);
END
