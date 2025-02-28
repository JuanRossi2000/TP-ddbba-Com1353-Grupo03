/*--SP'S TABLA SUCURSAL--*/
Use Com1353G03

CREATE OR ALTER PROCEDURE rrhh.altaSucursal
		@ciudad VARCHAR(20),
		@ubicacion VARCHAR(20),
		@direccion VARCHAR (130),
		@horario VARCHAR(130),
		@telefono VARCHAR(12)
	AS
	BEGIN
		DECLARE @esValido BIT
		SET @esValido = 1

		IF ISNULL(@ciudad, '') = ''
		BEGIN
			RAISERROR('El campo Ciudad no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@ubicacion, '') = '' 
		BEGIN
			RAISERROR('El campo Ubicacion no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 

		IF @esValido = 1
		BEGIN
			INSERT INTO rrhh.Sucursal (ciudad, ubicacion, direccion, horario, telefono)
			VALUES (@ciudad, @ubicacion, @direccion, @horario, @telefono)
			PRINT 'La sucursal se creó correctamente.'
		END
	END;
GO

CREATE OR ALTER PROCEDURE rrhh.actualizaSucursal
		@id int,
		@ciudad varchar(20) = NULL,
		@ubicacion varchar(20) = NULL,
		@direccion varchar(255) = NULL,
		@horario varchar(255) = NULL,
		@telefono varchar(12) = NULL,
		@habilitado BIT = NULL
	AS
	BEGIN 
		DECLARE @esValido BIT
		SET @esValido = 1

		IF EXISTS(	SELECT 1 
					FROM rrhh.Sucursal
					WHERE id = @id)
		BEGIN
			IF @ciudad = '' 
			BEGIN
				RAISERROR('El campo Ciudad no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @ubicacion = ''
			BEGIN
				RAISERROR('El campo Ubicacion no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
		
			IF @esValido = 1 
			BEGIN
				UPDATE rrhh.Sucursal
				SET ciudad = COALESCE(@ciudad, ciudad) 
				, ubicacion = COALESCE(@ubicacion, ubicacion)
				, direccion = COALESCE(@direccion, direccion)
				, horario = COALESCE(@horario, horario)
				, telefono = COALESCE(@telefono, telefono)
				, habilitado = COALESCE(@habilitado, habilitado)
				WHERE id = @id
				PRINT 'La sucursal se actualizó correctamente.'
			END
		END
		ELSE
		BEGIN
			RAISERROR('La sucursal solicitada no existe.', 16, 1)
		END
	END;
GO

CREATE OR ALTER PROCEDURE rrhh.bajaSucursal
	@id INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM rrhh.Sucursal WHERE id = @id)
		BEGIN
			UPDATE rrhh.Sucursal
			SET habilitado = 0
			WHERE id = @id
			PRINT 'La sucursal se dio de baja correctamente'
		END
		ELSE
		BEGIN
			RAISERROR('La sucursal solicitada no existe.', 16, 1)
		END
	END;
GO

/*--SP'S TABLA EMPLEADO--*/
CREATE OR ALTER PROCEDURE rrhh.altaEmpleado
		@legajo int = NULL,
		@nombre VARCHAR(50),
		@apellido VARCHAR(50),
		@dni INT,
		@direccion VARCHAR(255),
		@emailPersonal VARCHAR(255),
		@emailEmpresa VARCHAR(255),
		@cuil BIGINT,
		@cargo VARCHAR(30),
		@sucursal INT,
		@turno VARCHAR(17)
	AS
	BEGIN
		DECLARE @esValido BIT
		DECLARE @newLegajo INT
		SET @esValido = 1
		
		IF ISNULL(@nombre, '') = ''
		BEGIN
			RAISERROR('El campo Nombre no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@apellido, '') = ''
		BEGIN
			RAISERROR('El campo Apellido no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@dni, 0) <= 0
		BEGIN
			RAISERROR('El campo DNI no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@emailEmpresa, '') = '' 
		BEGIN
			RAISERROR('El campo EmailEmpresa no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@cuil, 0) <= 0
		BEGIN
			RAISERROR('El campo CUIL no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@cargo, '') = ''
		BEGIN
			RAISERROR('El campo Cargo no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@sucursal, 0) <= 0
		BEGIN
			RAISERROR('El campo Sucursal no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 
		IF ISNULL(@turno, '') = ''
		BEGIN
			RAISERROR('El campo Turno no admite valores vacíos', 16, 1)
			SET @esValido = 0
		END 

		IF ISNULL(@legajo, 0) = 0
		BEGIN
			SET @newLegajo = (SELECT ISNULL(MAX(legajo), 0) FROM rrhh.Empleado) + 1
		END
		ELSE
		BEGIN
			SET @newLegajo = @legajo
		END


		IF EXISTS (SELECT 1 FROM rrhh.Empleado WHERE dni = @dni)
		BEGIN 
			RAISERROR('Error: El empleado ya esta dado de alta.', 16, 1)
			SET @esValido = 0
		END

		IF EXISTS (SELECT 1 FROM rrhh.Empleado WHERE legajo = @newLegajo)
		BEGIN 
			RAISERROR('El campo Legajo no admite valores duplicados', 16, 1)
			SET @esValido = 0
		END

		IF @esValido = 1 
		BEGIN
			INSERT INTO rrhh.Empleado (legajo, nombre, apellido, dni, direccion, emailPersonal, emailEmpresa, cuil, cargo, sucursalId, turno)
			VALUES (@newLegajo, @nombre, @apellido, @dni, @direccion, @emailPersonal, @emailEmpresa, @cuil, @cargo, @sucursal, @turno);
		END
	END;
GO

CREATE OR ALTER PROCEDURE rrhh.actualizaEmpleado
			@legajo int,	
			@nombre varchar(50) = NULL,	
			@apellido varchar(50) = NULL,
			@dni int = NULL,	
			@direccion varchar(255) = NULL,	
			@emailPersonal varchar(255) = NULL,	
			@emailEmpresa varchar(255) = NULL,	
			@cuil bigint = NULL,	
			@cargo varchar(30) = NULL,	
			@sucursalId int = NULL,	
			@turno varchar(17) = NULL,
			@habilitado BIT = NULL
		AS
		BEGIN
			DECLARE @esValido BIT
			SET @esValido = 1
		
			IF @nombre = ''
			BEGIN
				RAISERROR('El campo Nombre no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @apellido = ''
			BEGIN
				RAISERROR('El campo Apellido no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @dni <= 0
			BEGIN
				RAISERROR('El campo DNI no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @emailEmpresa = ''
			BEGIN
				RAISERROR('El campo EmailEmpresa no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @cuil <= 0
			BEGIN
				RAISERROR('El campo CUIL no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @cargo = '' 
			BEGIN
				RAISERROR('El campo Cargo no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @sucursalId <= 0 
			BEGIN
				RAISERROR('El campo Sucursal no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END 
			IF @turno = ''
			BEGIN
				RAISERROR('El campo Turno no admite valores vacíos', 16, 1)
				SET @esValido = 0
			END

			IF EXISTS(	SELECT 1
						FROM rrhh.Empleado
						WHERE legajo = @legajo)
			BEGIN
				UPDATE rrhh.Empleado
				SET nombre = COALESCE(@nombre, Nombre)
					, apellido = COALESCE(@apellido, Apellido)
					, dni = COALESCE(@dni, dni)
					, direccion = COALESCE(@direccion, direccion)
					, emailPersonal = COALESCE(@emailPersonal, emailPersonal)
					, emailEmpresa = COALESCE(@emailEmpresa, emailEmpresa)
					, cuil = COALESCE(@cuil, cuil)
					, cargo = COALESCE(@cargo, cargo)
					, sucursalId = COALESCE(@sucursalId, sucursalId)
					, turno = COALESCE(@turno, turno)
					, habilitado = COALESCE(@habilitado, habilitado)
				WHERE legajo = @legajo;
			END
			ELSE
			BEGIN
				RAISERROR('El empleado solicitado no existe.', 16, 1)
			END
	END;
GO

CREATE OR ALTER PROCEDURE rrhh.bajaEmpleado
	@legajo INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM rrhh.Empleado WHERE legajo = @legajo)
		BEGIN
			UPDATE rrhh.Empleado
			SET habilitado = 0
			WHERE legajo = @legajo
			PRINT 'El empleado se dio de baja correctamente'
		END
		ELSE
		BEGIN
			RAISERROR('El empleado no existe', 16, 1)
		END
	END;
GO

/*--SP'S TABLA CLIENTE--*/
CREATE OR ALTER PROCEDURE ventas.altaCliente
		@ciudad VARCHAR(20),
		@genero CHAR(1),
		@tipo VARCHAR(10)
	AS
	BEGIN
		IF (@genero NOT IN ('M', 'F'))
		BEGIN
			RAISERROR( 'Genero incorrecto.', 16, 1)
			RETURN
		END

		INSERT INTO ventas.Cliente (ciudad, genero, tipo)
		VALUES (@ciudad, UPPER(@genero), @tipo)
	END;
GO

CREATE OR ALTER PROCEDURE ventas.actualizaCliente 
		@id int,
		@ciudad varchar(20) = NULL,
		@genero char(1) = NULL,
		@tipo varchar(10) = NULL,
		@habilitado BIT = NULL
	AS
	BEGIN
		IF EXISTS(	SELECT 1 
					FROM ventas.Cliente
					WHERE id = @id)
		BEGIN
			UPDATE ventas.Cliente
			SET ciudad = COALESCE(@ciudad, ciudad)
			, genero = COALESCE(@genero, genero)
			, tipo = COALESCE(@tipo, tipo)
			, habilitado = COALESCE(@habilitado, habilitado)
			WHERE id = @id
		END
		ELSE
		BEGIN
			RAISERROR( 'El cliente solicitado no existe.', 16, 1)
		END
	END;
GO


CREATE OR ALTER PROCEDURE ventas.bajaCliente
	@id INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM ventas.Cliente WHERE id = @id)
			BEGIN
				UPDATE ventas.Cliente
				SET habilitado = 0
				WHERE id = @id
				RETURN
			END
		RAISERROR('El cliente no existe', 16, 1)
	END;
GO

/*--SP'S TABLA MEDIOPAGO--*/
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'altaMedioPago' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.altaMedioPago
	@descripcionEsp VARCHAR(21),
	@descripcionIng VARCHAR(21)
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM ventas.MedioPago WHERE descripcionEsp = @descripcionEsp or descripcionIng = @descripcionIng)
			BEGIN
				PRINT ''Error: El medio de pago ya existe.''
				RETURN
			END
		IF @descripcionEsp <> '''' AND @descripcionIng <> ''''
		BEGIN
			INSERT INTO ventas.MedioPago (descripcionEsp,descripcionIng)
			VALUES (@descripcionEsp,@descripcionIng)
			PRINT ''El medio de pago se dio de alta.''
		END
		ELSE
		BEGIN
			RAISERROR(''La descripcion no puede estar vacia'', 16, 1)
		END
	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'actualizaMedioPago' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.actualizaMedioPago
			@id int,
			@descripcionEsp varchar(21) = NULL,
			@descripcionIng varchar(21) = NULL,
			@habilitado BIT = NULL			
	AS 
	BEGIN
		IF EXISTS(	SELECT 1
					FROM ventas.MedioPago
					WHERE id = @id)
		BEGIN
			IF (@descripcionEsp <> '''' OR @descripcionIng <> '''')
			BEGIN
				UPDATE ventas.MedioPago
				SET descripcionEsp = COALESCE(@descripcionEsp, descripcionEsp),
				descripcionIng = COALESCE(@descripcionIng, descripcionIng),
				habilitado = COALESCE(@habilitado, habilitado)
				WHERE id = @id
			END
			ELSE
			BEGIN
				RAISERROR(''La descripcion no puede estar vacia'', 16, 1)
			END
		END
		ELSE
		BEGIN
			PRINT ''El medio de pago solicitado no existe.''
		END
	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'bajaMedioPago' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.bajaMedioPago
	@id INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM ventas.MedioPago WHERE id = @id)
			BEGIN
				UPDATE ventas.MedioPago
				SET habilitado = 0
				WHERE id = @id
				PRINT ''El medio de pago se dio de baja correctamente.''
				RETURN
			END
	
		PRINT ''El medio de pago no existe.''
	END;')
END;
GO

/*--SP'S TABLA LINEAPRODUCTO--*/
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'altaLineaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	EXEC('CREATE PROCEDURE productos.altaLineaProducto
	@nombre VARCHAR(20)
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM productos.LineaProducto WHERE nombre = @nombre)
			BEGIN
				PRINT ''La linea del producto ya existe.''
				RETURN
			END

		IF @nombre = ''''
		BEGIN
			RAISERROR(''El campo Nombre no puede estar vacio'', 16, 1)
			RETURN
		END

		INSERT INTO productos.LineaProducto (nombre)
		VALUES (@nombre)

		PRINT ''La linea del prodcuto se dio de alta.''

	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'actualizaLineaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	EXEC('CREATE PROCEDURE productos.actualizaLineaProducto
		@id int,
		@nombre varchar(20) = NULL,
		@habilitado BIT = NULL
	AS
	BEGIN
		IF EXISTS(	SELECT 1
					FROM productos.LineaProducto
					WHERE id = @id)
		BEGIN
			IF @nombre <> '''' OR @nombre IS NULL
			BEGIN
				UPDATE productos.LineaProducto 
				SET nombre = COALESCE(@nombre, nombre)
				, @habilitado = COALESCE(@habilitado, habilitado)
				WHERE id = @id
			END
			ELSE 
			BEGIN
				RAISERROR(''El campo nombre no puede ser vacio.'', 16, 1)
			END
		END
		ELSE
		BEGIN
			PRINT ''La línea de producto solicitada no existe''
		END
	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'bajaLineaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	EXEC('CREATE PROCEDURE productos.bajaLineaProducto
	@id INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM productos.LineaProducto WHERE id = @id)
			BEGIN
				UPDATE productos.LineaProducto
				SET habilitado = 0
				WHERE id = @id
				PRINT ''La linea del producto se dio de baja correctamente''
				RETURN
			END
		PRINT ''La linea del producto no existe''
	END;')
END;
GO

/*--SP'S TABLA PRODUCTO--*/
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'altaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	exec('CREATE PROCEDURE productos.altaProducto
	@descripcion VARCHAR(75),
	@precio DECIMAL(7,2),
	@unidadadReferencia VARCHAR(7) = ''UNIDAD'',
	@idLineaProd INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM productos.Producto WHERE descripcion = @descripcion)
			BEGIN
				PRINT ''Error: El producto ya esta dado de alta.''
				RETURN
			END

		IF NOT EXISTS (SELECT 1 FROM productos.LineaProducto WHERE id = @idLineaProd)
			BEGIN
				PRINT ''Error: La linea del producto es incorrecta.''
				RETURN
			END
		IF ISNULL(@descripcion, '''') = ''''
		BEGIN
			RAISERROR(''La descripcion no puede estar vacia.'', 16, 1)
			RETURN
		END
		INSERT INTO productos.Producto (descripcion, precio, unidadReferencia, lineaID)
		VALUES (@descripcion, @precio, @unidadadReferencia, @idLineaProd)

		PRINT ''El producto se dio de alta.''

	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'actualizaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	EXEC('CREATE PROCEDURE productos.actualizaProducto	
		@id int,
		@descripcion varchar(75) = NULL,
		@precio decimal(7,2) = NULL,
		@unidadReferencia varchar(7) = NULL,
		@idLineaProd int = NULL,
		@habilitado BIT = NULL
	AS
	BEGIN
		IF EXISTS(	SELECT 1
					FROM productos.Producto
					WHERE id = @id)
		BEGIN
			IF @descripcion <> '''' OR @descripcion IS NULL
			BEGIN
				UPDATE productos.Producto
				SET descripcion = COALESCE(@descripcion, descripcion) 
				, precio = COALESCE(@precio, precio)
				, unidadReferencia = COALESCE(@unidadReferencia, unidadReferencia)
				, lineaID = COALESCE(@idLineaProd, lineaID)
				, habilitado = COALESCE(@habilitado, habilitado)
				WHERE id = @id
			END
			ELSE
			BEGIN
				RAISERROR(''La descripcion no puede estar vacia.'', 16, 1)
			END
		END
		ELSE
		BEGIN 
			PRINT ''El producto solicitado no existe''
		END
	END;') 
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'bajaProducto' AND schema_id = SCHEMA_ID('productos'))
BEGIN
	EXEC('CREATE PROCEDURE productos.bajaProducto
	@id INT
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM productos.Producto WHERE id = @id)
			BEGIN
				UPDATE productos.Producto
				SET habilitado = 0
				WHERE id = @id
				PRINT ''El producto se dio de baja correctamente.''
				RETURN
			END

		PRINT ''El producto no existe.''

	END;')
END;
GO

/*--SP'S TABLA FACTURA--*/
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'actualizaFactura' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.actualizaFactura 
		@nro char(11),
		@tipo char(1) = NULL,
		@tipoCliente VARCHAR(20),
		@genero VARCHAR(20) = NULL,
		@fechaHora smalldatetime = NULL,
		@empleadoID int = NULL,
		@pagoID int = NULL,
		@estadoID int = NULL,
		@identificadorPago VARCHAR(25) = NULL		
	AS
	BEGIN
		IF EXISTS(	SELECT 1
					FROM ventas.Factura
					WHERE nro= @nro)
		BEGIN
			UPDATE ventas.Factura
			SET	tipo = COALESCE(@tipo, tipo)
			, tipoCliente = COALESCE(@tipoCliente, tipoCliente)
			, genero = COALESCE(@genero, genero)
			, fechaHora = COALESCE(@fechaHora, fechaHora)
			, empleadoID = COALESCE(@empleadoID, empleadoID)
			, pagoID = COALESCE(@pagoID, pagoID)
			, estadoID = COALESCE(@estadoID, estadoID)
			, identificadorPago = COALESCE(@identificadorPago, identificadorPago)
			WHERE nro = @nro
		END
		ELSE
		BEGIN 
			PRINT ''La factura solicitada no existe.''
		END
	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'altaFactura' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE or alter PROCEDURE ventas.altaFactura
		(
		@productosXML XML,
		@tipoFactura CHAR(1),
		@empleadoId INT,
		@tipoCliente VARCHAR(20),
		@generoCliente VARCHAR(20),
		@pagoId INT,
		@identPago VARCHAR(25)
		)
	AS
	BEGIN

		DECLARE @nroFacturaFormateada CHAR(11);
		DECLARE @nroFacturaSinFormatear INT;
		DECLARE @idFactura INT;
		DECLARE @descMedioPago VARCHAR(21);
		DECLARE @idEstado INT;

		IF @productosXML IS NULL OR @productosXML.exist(''/productos/producto'') = 0
		BEGIN
			RAISERROR(''El XML de productos no puede ser nulo o vacío.'', 16, 1);
			RETURN;
		END

		IF ISNULL(@tipoFactura, '''') = ''''
		BEGIN
			RAISERROR(''El tipo de factura no puede ser vacio.'', 16, 1);
			RETURN;
		END

		IF @empleadoId <= 0
		BEGIN
			RAISERROR(''El ID del empleado no puede ser menor o igual a cero.'', 16, 1);
			RETURN;
		END

		IF ISNULL(@tipoCliente, '''') = ''''
		BEGIN
			RAISERROR(''El tipo del cliente no puede ser vacio.'', 16, 1);
			RETURN;
		END

		IF ISNULL(@generoCliente, '''') = ''''
		BEGIN
			RAISERROR(''El genero del cliente no puede ser nulo.'', 16, 1);
			RETURN;
		END

		IF @pagoId <= 0
		BEGIN
			RAISERROR(''El ID del medio de pago no puede ser menor o igual a 0.'', 16, 1);
			RETURN;
		END

		IF ISNULL(@identPago, '''') = ''''
		BEGIN
			RAISERROR(''El identificador de pago no puede ser nulo o vacío.'', 16, 1);
			RETURN;
		END

	BEGIN TRANSACTION

	BEGIN TRY

		-- Generar un número aleatorio de 9 dígitos
		SET @nroFacturaSinFormatear = ABS(CHECKSUM(NEWID())) % 900000000 + 100000000; 

		-- Formatearlo como XXX-XX-XXXX
		SET @nroFacturaFormateada = STUFF(STUFF(CAST(@nroFacturaSinFormatear as char(9)), 4, 0, ''-''), 7, 0, ''-'');
	
	WHILE EXISTS (SELECT 1 FROM Factura WHERE nro = @nroFacturaFormateada)
		BEGIN
			-- Si el numero de factura ya existe dentro de la tabla genero uno nuevo
			SET @nroFacturaSinFormatear = ABS(CHECKSUM(NEWID())) % 900000000 + 100000000; 

			-- Formatearlo como XXX-XX-XXXX
			SET @nroFacturaFormateada = STUFF(STUFF(CAST(@nroFacturaSinFormatear as varchar(9)), 4, 0, ''-''), 7, 0, ''-'');
	END

		SET @descMedioPago = (SELECT descripcionEsp FROM ventas.MedioPago WHERE id = @pagoId AND habilitado = 1);

		SET @Idestado =
			CASE 
				WHEN @descMedioPago = ''Tarjeta Crédito'' THEN 
					(SELECT id FROM ventas.Estado WHERE descripcion = ''Pendiente'')
				WHEN @descMedioPago = ''Efectivo'' THEN 
					(SELECT id FROM ventas.Estado WHERE descripcion = ''Pagado'')
				WHEN @descMedioPago = ''Billetera Electronica'' THEN 
					(SELECT id FROM ventas.Estado WHERE descripcion = ''Pagado'')
				ELSE 
					NULL  -- En caso de que no coincida con ninguno de los valores
		END;


		INSERT INTO ventas.Factura (nro, tipo, fechaHora, empleadoID, tipoCliente, genero, pagoID, estadoId, identificadorPago)
		VALUES (@nroFacturaFormateada,@tipoFactura, CAST(getdate() AS smalldatetime), @empleadoId, @tipoCliente, @generoCliente, @pagoId, @idEstado, @identPago)

		SET @idFactura = (SELECT id FROM ventas.Factura WHERE nro = @nroFacturaFormateada AND habilitado = 1);

		INSERT INTO ventas.DetalleFactura (facturaID, item, cantidad, precio, productoID)
		SELECT 
			@idFactura, 
			x.p.value(''(id/text())[1]'', ''INT''),
			x.p.value(''(cantComprada/text())[1]'', ''INT''),
			p.precio,
			x.p.value(''(idProducto/text())[1]'', ''INT'')
		FROM @productosXML.nodes(''/productos/producto'') AS x(p)
		INNER JOIN productos.Producto p ON x.p.value(''(idProducto/text())[1]'', ''INT'') = p.id;


	COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR(''Error al insertar los datos. La transacción ha sido revertida.'', 16, 1)
	END CATCH

	END;')
END;
GO

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'bajaFactura' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.bajaFactura
		@id int
	AS
	BEGIN
		IF EXISTS (SELECT 1 FROM ventas.Factura WHERE id = @id)
		BEGIN
			UPDATE ventas.Factura
			SET habilitado = 0
			WHERE id = @id
			PRINT ''La factura se dio de baja correctamente'';
		END;
		ELSE
		BEGIN
			RAISERROR(''La factura solicitada no existe.'', 16, 1);
		END;
	END');
END;
GO

/*--SP'S TABLA DETALLEFACTURA--*/
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'actualizaDetalleFactura' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
	EXEC('CREATE PROCEDURE ventas.actualizaDetalleFactura
		@facturaID int,
		@cantidad int = NULL,
		@precio decimal(10,2) = NULL,
		@productoID int = NULL
	AS 
	BEGIN
		IF EXISTS(	SELECT 1
					FROM DetalleFactura
					WHERE facturaID = @facturaID)
		BEGIN
			UPDATE DetalleFactura
			SET cantidad = COALESCE(@cantidad, cantidad)
			, precio = COALESCE(@precio, precio)
			, productoID = COALESCE(@productoID, productoID)
			WHERE facturaID = @facturaID
		END 
		ELSE 
		BEGIN 
			PRINT ''La factura solicitada no existe.''
		END
	END;')
END;
GO
