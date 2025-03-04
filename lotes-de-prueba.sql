/*
Parte cumplida: Lotes de pruebas para los Stored procedures de ABM de las tablas
fecha de entrega: 04/03/2025
Comisión: 1353
Número de grupo: 3
Materia: Bases de datos Aplicadas
Nombres y DNI: 
-Bautista Rios Di Gaeta, 46431397
-Samuel Gallardo, 45926613
-Juan Ignacio Rossi, 42115962
-Joel Fabián Stivala Patiño, 42825990
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------

USE Com1353G03
	 
/*--SP'S TABLA SUCURSAL--*/
--EVALUACION DE NULOS (campos ciudad y ubicación): 

EXEC rrhh.altaSucursal @ciudad = NULL, @ubicacion = NULL, @direccion = '', @horario = 'HORARIO DE PRUEBA', @telefono = '1144442222'
--> Debe devolver un error ya que los campos son NULL

EXEC rrhh.altaSucursal @ciudad = '', @ubicacion = '', @direccion = '', @horario = 'HORARIO DE PRUEBA', @telefono = '1144442222'
--> En el SP se contempla que los campos sean distintos de '' (cadena vacía)

EXEC rrhh.altaSucursal @ciudad = 'Beijing', @ubicacion = 'Villa Luzuriaga', @direccion = '', @horario = 'HORARIO DE PRUEBA', @telefono = '1144442222'
--> SELECT * FROM rrhh.Sucursal WHERE Sucursal.id = 1 --> Debe devolver los valores ingresados en el SP, la id es 1 ya que es un campo IDENTITY.

-- Actualizamos la sucursal que acabamos de crear. Primero probar cambiando los valores de ciudad y/o ubicación a ''
EXEC rrhh.actualizaSucursal @id = 1,	@ciudad = '', @ubicacion = ''
--> Mismo error, esto también se contempla en la sentencia UPDATE.

-- Cambiar datos
EXEC rrhh.actualizaSucursal @id = 1,	@ciudad = 'beijing', @ubicacion = 'La Tablada', @direccion = 'Monseñor Bufano 2222', @horario = '24hs', @telefono = '1199998888'
--> SELECT * FROM rrhh.Sucursal WHERE Sucursal.id = 1 --> Se visualizan adecuadamente los valores que utilizamos para probar el SP.

-- Baja de sucursal.
EXEC rrhh.bajaSucursal 1 
--> SELECT * FROM rrhh.Sucursal WHERE Sucursal.id = 1 --> El campo habilitado pasó a 0.

EXEC rrhh.actualizaSucursal @id = 1, @habilitado = 1
--> SELECT * FROM rrhh.Sucursal WHERE Sucursal.id = 1 --> Utilizando el SP de actualizacion, podremos habilitar registros, como vemos, habilitado volvió a pasar a 1.



/*--SP'S TABLA EMPLEADOS--*/
--APROVECHANDO El registro de la tabla Sucursal, vamos a cargar empleados que trabajen en ella
EXEC rrhh.altaEmpleado @nombre = NULL, @apellido = NULL, @dni = -20, @direccion = 'Calle Falsa 123', @emailPersonal = '', @emailEmpresa = 'email@empresa.com', @cuil = -12345, @cargo = NULL, @sucursal = 10, @turno = 'TT'
--> Se comprueba que la validacion de NULL o datos inválidos sea correcta.

EXEC rrhh.altaEmpleado @nombre = 'NATALIA', @apellido = 'NATALIA', @dni = 99999999, @direccion = 'Calle Falsa 123', @emailPersonal = '', @emailEmpresa = 'email@empresa.com', @cuil = 12345, @cargo = 'Gerente de sucursal', @sucursal = 10, @turno = 'TT'
--> Se verifica el conflicto por Foreing Key, ya que la sucursal con ID 10 no existe.

EXEC rrhh.altaEmpleado @nombre = 'NATALIA', @apellido = 'NATALIA', @dni = 99999999, @direccion = 'Calle Falsa 123', @emailPersonal = '', @emailEmpresa = 'email@empresa.com', @cuil = 12345, @cargo = 'Gerente de sucursal', @sucursal = 1, @turno = 'TT'
--> SELECT * FROM rrhh.Empleado --> Los datos cargados por el SP son correctos.

EXEC rrhh.altaEmpleado @nombre = 'NATALIA', @apellido = 'NATALIA', @dni = 99999999, @direccion = 'Calle Falsa 123', @emailPersonal = '', @emailEmpresa = 'email@empresa.com', @cuil = 12345, @cargo = 'Gerente de sucursal', @sucursal = 1, @turno = 'TT'
--> No se permite agregar un empleado con el mismo dni.


EXEC rrhh.actualizaEmpleado @legajo = 1, @nombre = 'PEDRO', @apellido = 'PEREZ', @dni = 11111111, @direccion = 'AVENIDA Falsa 123', @emailPersonal = 'HOLA@MAIL.COM', @emailEmpresa = 'PEDRO@empresa.com', @cuil = 54321, @cargo = 'Cajero', @turno = 'TM' 
--> SELECT * FROM rrhh.Empleado --> Nuevamente probamos los datos cargados por el SP y como vemos, son correctos.

EXEC rrhh.bajaEmpleado 1
--> SELECT * FROM rrhh.Empleado --> El campo habilitado pasó a 0, lo cual indica una baja lógica.

EXEC rrhh.actualizaEmpleado @legajo = 1, @habilitado = 1
--> SELECT * FROM rrhh.Empleado --> Para volver a habilitarlo, utilizamos el SP actualizaEmpleado.



/*--SP'S TABLA CLIENTE--*/
EXEC ventas.altaCliente @ciudad = 'La matanza', @genero = 'O', @tipo = 'consumidor final'
--> Error por Genero incorrecto.

EXEC ventas.altaCliente @ciudad = 'La matanza', @genero = 'F', @tipo = 'CF'
--> SELECT * FROM ventas.Cliente --> Como vemos un solo registro con los datos que enviamos como parámetro.

EXEC ventas.actualizaCliente @id = 1, @ciudad = 'Nordelta', @genero = 'M', @tipo = 'RI'
--> SELECT * FROM ventas.Cliente --> El SP actualizó los campos correctamente.

EXEC ventas.bajaCliente @id = 1
--> SELECT * FROM ventas.Cliente --> El cliente con ID 1 fue dado de baja (baja lógica).

EXEC ventas.actualizaCliente @id = 1, @habilitado = 1
--> SELECT * FROM ventas.Cliente --> Lo volvemos a habilitar con el SP de actualización.



/*--SP'S TABLA MEDIOPAGO--*/
EXEC ventas.altaMedioPago @descripcionESP = '', @descripcionING = ''
--> Ninguna de ambas descripciones puede estar vacia

EXEC ventas.altaMedioPago @descripcionESP = 'Billetera Electronica', @descripcionING = 'Ewallet'
--> SELECT * FROM ventas.MedioPago --> Descripción son correctas

EXEC ventas.altaMedioPago @descripcionEsp = 'Billetera Electronica', @descripcionING = 'PRUEBA123'
--> No se pueden insertar 2 registros con la misma descripción

EXEC ventas.altaMedioPago @descripcionEsp = 'PRUEBA123', @descripcionING = 'Ewallet'
--> Lo mismo ocurre con el campo en ingles

EXEC ventas.actualizaMedioPago @id = 1, @descripcionIng = ''
--> Nuevamente, la descripción no puede ser vacía

EXEC ventas.actualizaMedioPago @id = 1, @descripcionEsp = ''
--> La descripción Espanol tampoco no puede ser vacía

EXEC ventas.actualizaMedioPago @id = 1, @descripcionEsp = 'PRUEBA'
--> SELECT * FROM ventas.MedioPago --> Se actualiza y la descripción ESPANOL es correcta

EXEC ventas.actualizaMedioPago @id = 1, @descripcionING = 'PRUEBA'
--> SELECT * FROM ventas.MedioPago --> Se actualiza y la descripción INGLES es correcta

EXEC ventas.bajaMedioPago 1
--> SELECT * FROM ventas.MedioPago --> Baja lógica al registro con id enviada como parametro.

EXEC ventas.actualizaMedioPago @id = 1, @habilitado = 1
--> SELECT * FROM ventas.MedioPago --> Lo volvemos a habilitar.



/*--SP'S TABLA LINEAPRODUCTO--*/
EXEC productos.altaLineaProducto @nombre = ''
--> Linea de producto no puede tener nombre vacio

EXEC productos.altaLineaProducto @nombre = 'BEBIDAS'
--> SELECT * FROM productos.LineaProducto --> Los datos se cargan de manera adecuada

EXEC productos.altaLineaProducto @nombre = 'BEBIDAS'
--> No se permiten campos repetidos

EXEC productos.actualizaLineaProducto @id = 1, @nombre = ''
--> Error al intentar actualizar el nombre a vacío

EXEC productos.actualizaLineaProducto @id = 2, @nombre = 'GOLOSINAS'
--> Error al intentar actualizar una linea que no existe

EXEC productos.actualizaLineaProducto @id = 1, @nombre = 'GOLOSINAS'
--> SELECT * FROM productos.LineaProducto --> Los campos se actualizan correctamente.

EXEC productos.bajaLineaProducto @id = 1
--> SELECT * FROM productos.LineaProducto --> Los campos se dan de baja lógica.

EXEC productos.actualizaLineaProducto @id = 1, @habilitado = 1
--> SELECT * FROM productos.LineaProducto --> Para habilitarlo nuevamente, se utiliza el SP de actualizaLineaProducto.



/*--SP'S TABLA PRODUCTO--*/
EXEC productos.altaProducto @descripcion = '', @precio = 17.1, @idLineaProd = 1
--> No se puede instalar un producto con descripción en vacia.

EXEC productos.altaProducto @descripcion = 'CARAMELOS DE MIEL', @precio = 17.1, @idLineaProd = 10
--> Validacion de linea de producto.

EXEC productos.altaProducto @descripcion = 'CARAMELOS DE MIEL', @precio = 17.1, @idLineaProd = 1
--> SELECT * FROM productos.Producto --> Se insertó correctamente.

EXEC productos.actualizaProducto @id = 1, @descripcion = '', @precio = 20, @unidadReferencia = 'KG', @idLineaProd = 1
--> Nuevamente el campo descripción no puede estar vacio

EXEC productos.actualizaProducto @id = 1, @descripcion = 'GOMITAS ACIDAS', @precio = 20, @unidadReferencia = 'KG', @idLineaProd = 1
--> SELECT * FROM productos.Producto --> Los datos se actualizaron tal cual fueron enviados en el SP.

EXEC productos.bajaProducto @id = 1
--> SELECT * FROM productos.Producto --> La baja logica se llevo a cabo correctamente.

EXEC productos.actualizaProducto @id = 1, @habilitado = 1
--> SELECT * FROM productos.Producto --> Los datos se actualizaron tal cual fueron enviados en el SP.

/*--SP'S TABLA FACTURA--*/

--Necesario para Alta de factura
--------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT 1 FROM ventas.Estado WHERE descripcion = 'Pendiente')
    BEGIN
         INSERT INTO ventas.Estado(descripcion) VALUES ('Pendiente');
    END
    IF NOT EXISTS(SELECT 1 FROM ventas.Estado WHERE descripcion = 'Pagado')
    BEGIN
         INSERT INTO ventas.Estado(descripcion) VALUES ('Pagado');
    END
--------------------------------------------------------------------------------

EXEC ventas.altaFactura @productosXML = '', @tipoFactura = 'A', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = 1, @identPago = '4660-1046-8238-6585'
-- No se puede insertar una factura con un XML vacio

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = '', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = 1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un tipo de factura vacio

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 0, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = 1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un id de empleado con valor 0

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 1, @tipoCliente = '', @generoCliente = 'Female', @pagoId = 1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un tipo de cliente vacio

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = '', @pagoId = 1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un genero de cliente vacio

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = 0, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un id de medio de pago igual a cero

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = -1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> No se puede insertar un id de medio de pago menor a cero

EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<idProducto>10</idProducto>
			<cantComprada>2</cantComprada>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @empleadoId = 1, @tipoCliente = 'Member', @generoCliente = 'Female', @pagoId = 1, @identPago = '', @sucursalID = 1
--> No se puede insertar un identificador de pago vacio


EXEC ventas.altaFactura 
	@productosXML =
	'<productos>
		<producto>
			<id>1</id>
			<cantComprada>2</cantComprada>
			<idProducto>1</idProducto>
		</producto>
	</productos>', 
		@tipoFactura = 'A', @tipoCliente = 'Member', @generoCliente = 'Female', @empleadoId = 1, @pagoId = 1, @identPago = '4660-1046-8238-6585', @sucursalID = 1
--> SELECT * FROM ventas.Factura ORDER BY nro --> Se dio de alta correctamente

EXEC ventas.bajaFactura @id = 1
--> SELECT * FROM ventas.Factura --> La baja logica se llevo a cabo correctamente.

/*--SP'S TABLA Nota de Credito--*/
EXEC ventas.altaNotaDeCredito @facturaId = 0, @tipoNota = 'D', @empleadoId = '1'
--> No se puede insertar una nota de credito para una factura con valor 0

EXEC ventas.altaNotaDeCredito @facturaId = -1000, @tipoNota = 'D', @empleadoId = '1'
--> No se puede insertar una nota de credito para una factura con valor Negativo

EXEC ventas.altaNotaDeCredito @facturaId = 1, @tipoNota = '', @empleadoId = '1'
--> No se puede insertar una nota de credito con un tipo vacio

EXEC ventas.altaNotaDeCredito @facturaId = 1, @tipoNota = 'D', @empleadoId = '0'
-->No se puede insertar una nota de credito con un id de empleado menor a 1

EXECUTE AS USER = 'UsuarioVentas';
exec ventas.altaNotaDeCredito @facturaId = 1, @tipoNota = 'D', @empleadoId = 1
revert;
--> No se puede insertar una nota de credito por permisos de usuario

EXECUTE AS USER = 'UsuarioSupervisor';
exec ventas.altaNotaDeCredito @facturaId = 1, @tipoNota = 'D', @empleadoId = 1
--> SELECT * FROM ventas.NotaCredito --> Se dio de alta correctamente

EXECUTE AS USER = 'UsuarioSupervisor';
exec ventas.altaNotaDeCredito @facturaId = 1, @tipoNota = 'D', @empleadoId = 1
--> No se permiten multiples NC para la misma factura

/*--SP'S TABLA Moneda--*/

--- Vamos a insertar a la tabla el valor del Yen Japones
EXEC utilidades.altaMoneda 'JPY', 7.13
--> SELECT * FROM utilidades.Moneda --> Podemos ver que se dio de alta la moneda.

EXEC utilidades.altaMoneda 'JPY', 7.13
--> Si tratamos de volver a insertarla nos da error ya que la misma ya existe

EXEC utilidades.altaMoneda '', 7.13
--> No se puede insertar un codigo de moneda vacio

EXEC utilidades.altaMoneda 'CHF', 0
--> No se puede insertar un valor de moneda en 0

EXEC utilidades.altaMoneda 'CHF', -7.13
--> No se puede insertar un valor de moneda negativo

EXEC utilidades.actualizaMoneda 'JPY', 10
--> SELECT * FROM utilidades.Moneda --> Podemos ver que se modifico el valor de la moneda.

EXEC utilidades.actualizaMoneda '', 10
--> No se puede actualziar un codigo de moneda vacio

EXEC utilidades.actualizaMoneda 'JPY', 0
--> No se puede actualizar el valor de la moneda por 0

EXEC utilidades.actualizaMoneda 'JPY', -10
--> No se puede actualziar el valor de la moneda por un numero negativo

EXEC utilidades.actualizaMoneda 'CHF', 10
--> No se puede actualizar una moneda inexistente

EXEC utilidades.bajaMoneda 'JPY'
--> SELECT * FROM utilidades.Moneda --> Podemos ver que se dio de baja la moneda.

EXEC utilidades.bajaMoneda 'CHF'
--> No podemos dar de baja una moneda inexistente
