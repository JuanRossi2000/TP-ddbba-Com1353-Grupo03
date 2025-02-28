/*
Parte cumplida: Generacion de los reportes XML solicitados
fecha de entrega: 28/02/25
Comisión: 1353
Número de grupo: 3
Materia: Bases de datos Aplicadas
Nombres y DNI: 
-Bautista Rios Di Gaeta, 46431397
-Samuel Gallardo, 45926613
-Juan Ignacio Rossi, 42115962
-Joel Fabián Stivala Patiño, 42825990
*/

USE Com1353G03
GO
--1)

IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'reporteMensualPorDia' AND schema_id = SCHEMA_ID('reportes'))
BEGIN 
	EXEC('CREATE PROCEDURE reportes.reporteMensualPorDia
		@mes INT,
		@anio INT
	AS 
	BEGIN 
		SELECT DATENAME(WEEKDAY, F.fechaHora) AS dia
			, SUM(F.precioTotal) AS monto
		FROM ventas.Factura F
		WHERE DATEPART(MONTH, F.fechaHora) = @mes
			AND DATEPART(YEAR, F.fechaHora) = @anio
		GROUP BY DATEPART(WEEKDAY, F.fechaHora) 
			, DATENAME(WEEKDAY, F.fechaHora)
		ORDER BY DATEPART(WEEKDAY, F.fechaHora) ASC
		FOR XML PATH(''recaudacion''), ROOT(''recaudaciones-por-mes-y-dia''), TYPE
	END;')
END;
GO 

--2)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'reporteMensualPorTrimestreTurno' AND schema_id = SCHEMA_ID('reportes'))
BEGIN 
	EXEC('CREATE PROCEDURE reportes.reporteMensualPorTrimestreTurno
		@trimestre INT,
		@anio INT
	AS 
	BEGIN 
		SELECT DATENAME(MONTH, ventas.Factura.fechaHora) AS nombre
		, (
			SELECT rrhh.Empleado.turno turno
				, SUM(B.precioTotal) monto
			FROM ventas.Factura B 
			INNER JOIN rrhh.Empleado ON rrhh.Empleado.legajo = B.empleadoID
			WHERE DATEPART(MONTH, B.fechaHora) = DATEPART(MONTH, ventas.Factura.fechaHora)
			GROUP BY rrhh.Empleado.turno
			FOR XML PATH(''''), TYPE
		) as [turnos]
		FROM ventas.Factura
		WHERE utilidades.getTrimestre(DATEPART(MONTH, ventas.Factura.fechaHora)) = @trimestre
			AND DATEPART(YEAR, ventas.Factura.fechaHora) = @anio
		GROUP BY DATEPART(MONTH, ventas.Factura.fechaHora)
			, DATENAME(MONTH, ventas.Factura.fechaHora)
		ORDER BY DATEPART(MONTH, ventas.Factura.fechaHora) ASC
		FOR XML PATH(''mes''), ROOT(''recaudaciones'')
	END;')
END;
GO

--3)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'productosVendidosPorRango' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.productosVendidosPorRango
		@fechaMin SMALLDATETIME,
		@fechaMax SMALLDATETIME
	AS 
	BEGIN 
		SELECT productos.Producto.descripcion AS descripcion
			, SUM(ventas.DetalleFactura.cantidad) AS cantidad
		FROM ventas.Factura
		INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
		INNER JOIN productos.Producto ON ventas.DetalleFactura.productoID = productos.Producto.id
		WHERE ventas.Factura.fechaHora BETWEEN @fechaMin AND @fechaMax
		GROUP BY productos.Producto.descripcion 
		ORDER BY SUM(ventas.DetalleFactura.cantidad) DESC
		FOR XML PATH(''producto''), ROOT(''cantidades-por-producto''), TYPE
	END;')
END;
GO

--4)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'cantidadProductosPorSucursal' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.cantidadProductosPorSucursal
		@fechaMin SMALLDATETIME,
		@fechaMax SMALLDATETIME
	AS 
	BEGIN 
		SELECT rrhh.Sucursal.ubicacion 
			, SUM(ventas.DetalleFactura.cantidad) as quantity
		FROM ventas.Factura
		INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
		INNER JOIN productos.Producto ON ventas.DetalleFactura.productoID = productos.Producto.id
		INNER JOIN rrhh.Empleado ON ventas.Factura.empleadoID = rrhh.Empleado.legajo
		INNER JOIN rrhh.Sucursal ON rrhh.Empleado.sucursalId = rrhh.Sucursal.id
		WHERE ventas.Factura.fechaHora BETWEEN @fechaMin AND @fechaMax
		GROUP BY rrhh.Sucursal.ubicacion 
		ORDER BY SUM(ventas.DetalleFactura.cantidad) DESC
 		FOR XML PATH(''sucursal''), ROOT(''cantidad-por-sucursal''), TYPE
	END;')
END;
GO

--5)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'top5PorMesSemana' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.top5PorMesSemana 
		@mes INT,
		@anio INT
	AS
	BEGIN
		;WITH productosPorSemana AS (SELECT DATEPART(WEEK, ventas.Factura.fechaHora) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ventas.Factura.fechaHora), 0)) + 1 AS semana
			, ventas.DetalleFactura.productoID AS productoID
			, SUM(ventas.DetalleFactura.cantidad) cantidad
			, RANK() OVER (PARTITION BY DATEPART(WEEK, ventas.Factura.fechaHora) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ventas.Factura.fechaHora), 0)) + 1 ORDER BY SUM(ventas.DetalleFactura.cantidad) DESC) rango
		FROM ventas.Factura
		INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
		WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
			AND DATEPART(YEAR, ventas.Factura.fechaHora) = @anio
		GROUP BY DATEPART(WEEK, ventas.Factura.fechaHora) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ventas.Factura.fechaHora), 0)) + 1
			, ventas.DetalleFactura.productoID)
	
		SELECT semana numero
			, (
				SELECT P.descripcion descripcion
					, cantidad
				FROM productosPorSemana B
				INNER JOIN productos.Producto P ON B.productoID = P.id 
				WHERE B.semana = productosPorSemana.semana
					AND rango <= 5
				FOR XML PATH(''producto''), ROOT(''productos''), TYPE
			)
		FROM productosPorSemana
		GROUP BY productosPorSemana.semana
		ORDER BY semana ASC
		FOR XML PATH(''semana''), ROOT(''top-5-productos''), TYPE
	
	END;')
END;
GO

--6)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'top5PeoresPorMes' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.top5PeoresPorMes
		@mes INT,
		@anio INT 
	AS
	BEGIN
		;WITH productosPorMes AS (SELECT ventas.DetalleFactura.productoID AS productoID
			, SUM(ventas.DetalleFactura.cantidad) cantidad
			, RANK() OVER (ORDER BY SUM(ventas.DetalleFactura.cantidad) ASC) rango
		FROM ventas.Factura
		INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
		WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
			AND DATEPART(YEAR, ventas.Factura.fechaHora) = @anio
		GROUP BY ventas.DetalleFactura.productoID)

		SELECT productos.Producto.descripcion descripcion
			, cantidad
		FROM productosPorMes
		INNER JOIN productos.Producto ON productosPorMes.productoID = productos.Producto.id
		WHERE rango <= 5
		ORDER BY rango ASC
		FOR XML PATH(''producto''), ROOT(''top-5-peores-productos''), TYPE
	END;')
END;
GO

--7)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'ventasPorFechaYSucursal' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.ventasPorFechaYSucursal
		@fecha DATE,
		@sucursal INT
	AS
	BEGIN
		SELECT F.id
			, F.tipo
			, F.fechaHora
			, S.ubicacion sucursal
			, (
				SELECT E.legajo 
					, E.nombre + '' '' + E.apellido vendedor
					, E.cargo
					, E.turno
				FOR XML PATH(''''), TYPE
			) empleado
			, ( 
				SELECT F.genero
					, F.tipoCliente
				FOR XML PATH(''''), TYPE
			) cliente
			, (
				SELECT P.descripcion
					, DF.cantidad
					, DF.precio
					, DF.precio * DF.cantidad AS totalItem
				FROM ventas.DetalleFactura DF
				INNER JOIN productos.Producto P ON DF.productoID = P.id
				WHERE DF.facturaId = F.id
				FOR XML PATH(''producto''), TYPE
			) productos
		FROM ventas.Factura F
		INNER JOIN rrhh.Empleado E ON F.empleadoID = E.legajo
		INNER JOIN rrhh.Sucursal S ON E.sucursalId = S.id 
		WHERE CONVERT(DATE, F.fechaHora) = @fecha
			AND E.sucursalId = @sucursal
		FOR XML PATH(''venta''), ROOT(''ventas''), TYPE
	END;')
END;
GO

--8)
IF NOT EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE name = 'mayorVendedorPorSucursal' AND schema_id = SCHEMA_ID('reportes'))
BEGIN
	EXEC('CREATE PROCEDURE reportes.mayorVendedorPorSucursal
		@mes INT,
		@anio INT
	AS 
	BEGIN 
		;WITH monto_empleado_por_sucursal AS (
			SELECT rrhh.Sucursal.ubicacion as sucursal
			, rrhh.Empleado.legajo as legajo
			, (SELECT EmplAUX.nombre + '' '' + EmplAUX.apellido FROM rrhh.Empleado AS EmplAUX where EmplAUX.legajo = rrhh.Empleado.legajo) as nombre
			, SUM(ventas.DetalleFactura.precio * ventas.DetalleFactura.cantidad) as monto
			, ROW_NUMBER() OVER (PARTITION BY rrhh.Sucursal.ubicacion ORDER BY SUM(ventas.DetalleFactura.precio * ventas.DetalleFactura.cantidad) DESC) AS rn
			FROM ventas.Factura
			INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
			INNER JOIN rrhh.Empleado ON ventas.Factura.empleadoID = rrhh.Empleado.legajo
			INNER JOIN rrhh.Sucursal ON rrhh.Empleado.sucursalId = rrhh.Sucursal.id
			WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
				AND DATEPART(YEAR, ventas.Factura.fechaHora) = @anio
			GROUP BY rrhh.Sucursal.ubicacion, rrhh.Empleado.legajo
		)

		SELECT sucursal
			, legajo
			, nombre
			, monto
		FROM monto_empleado_por_sucursal
		WHERE rn = 1
		FOR XML PATH(''vendedor''), ROOT(''vendedores-por-sucursal''), TYPE
	END;')
END;
GO
