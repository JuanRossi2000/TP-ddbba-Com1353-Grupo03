--1)
CREATE PROCEDURE ventas.reporteMensualPorDia
	@mes INT,
	@anio INT
AS 
BEGIN 
	SELECT DATENAME(WEEKDAY, ventas.Factura.fechaHora) AS dia
		, SUM(ventas.DetalleFactura.precio * ventas.DetalleFactura.cantidad) AS monto
	FROM ventas.Factura
	INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
	WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
		AND DATEPART(YEAR, ventas.Factura.fechaHora) = @anio
	GROUP BY DATEPART(WEEKDAY, ventas.Factura.fechaHora) 
		, DATENAME(WEEKDAY, ventas.Factura.fechaHora)
	ORDER BY DATEPART(WEEKDAY, ventas.Factura.fechaHora) ASC
	FOR XML PATH('recaudacion'), ROOT('recaudaciones-por-mes-y-dia'), TYPE
END;
GO

--FUNCION QUE UTILIZARA EL PROCEDURE reporteMensualPorTrimestreTurno
CREATE FUNCTION ventas.getTrimestre
	(@mes INT)
RETURNS INT
AS
BEGIN
	DECLARE @trimestre INT

	SET @trimestre = CASE
		WHEN @mes BETWEEN 1 AND 3 THEN 1 
		WHEN @mes BETWEEN 4 AND 6 THEN 2 
		WHEN @mes BETWEEN 7 AND 9 THEN 3 
		WHEN @mes BETWEEN 10 AND 12 THEN 4 
		ELSE NULL
	END;

	RETURN @trimestre
END;
GO

--2)
CREATE PROCEDURE ventas.reporteMensualPorTrimestreTurno
	@trimestre INT
AS 
BEGIN 
	SELECT DATENAME(MONTH, ventas.Factura.fechaHora) AS nombre
	, (
		SELECT rrhh.Empleado.turno turno
			, SUM(ventas.DetalleFactura.precio * ventas.DetalleFactura.cantidad) monto
		FROM ventas.Factura B 
		INNER JOIN ventas.DetalleFactura ON ventas.DetalleFactura.facturaID = B.id
		INNER JOIN rrhh.Empleado ON rrhh.Empleado.legajo = B.empleadoID
		WHERE DATEPART(MONTH, B.fechaHora) = DATEPART(MONTH, ventas.Factura.fechaHora)
		GROUP BY rrhh.Empleado.turno
		FOR XML PATH(''), TYPE
	) as [turnos]
	FROM ventas.Factura
	WHERE ventas.getTrimestre(DATEPART(MONTH, ventas.Factura.fechaHora)) = @trimestre
	GROUP BY DATEPART(MONTH, ventas.Factura.fechaHora)
		, DATENAME(MONTH, ventas.Factura.fechaHora)
	ORDER BY DATEPART(MONTH, ventas.Factura.fechaHora) ASC
	FOR XML PATH('mes'), ROOT('recaudaciones')
END;
GO

--3)
CREATE PROCEDURE ventas.productosVendidosPorRango
	@fechaMin SMALLDATETIME,
	@fechaMax SMALLDATETIME
AS 
BEGIN 
	SELECT productos.Producto.descripcion AS description
		, SUM(ventas.DetalleFactura.cantidad) AS quantity
	FROM ventas.Factura
	INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
	INNER JOIN productos.Producto ON ventas.DetalleFactura.productoID = productos.Producto.id
	WHERE ventas.Factura.fechaHora BETWEEN @fechaMin AND @fechaMax
	GROUP BY productos.Producto.descripcion 
	ORDER BY SUM(ventas.DetalleFactura.cantidad) DESC
	FOR XML PATH('producto'), ROOT('cantidades-por-producto'), TYPE
END;
GO

--4)
CREATE PROCEDURE ventas.cantidadProductosPorSucursal
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
 	FOR XML PATH('sucursal'), ROOT('cantidad-por-sucursal'), TYPE
END;
GO

--5)
CREATE PROCEDURE ventas.top5PorMesSemana 
	@mes INT
AS
BEGIN
	;WITH productosPorSemana AS (SELECT DATEPART(WEEK, ventas.Factura.fechaHora) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ventas.Factura.fechaHora), 0)) + 1 AS semana
		, ventas.DetalleFactura.productoID AS productoID
		, SUM(ventas.DetalleFactura.cantidad) cantidad
		, RANK() OVER (ORDER BY SUM(ventas.DetalleFactura.cantidad)) rango
	FROM ventas.Factura
	INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
	WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
	GROUP BY DATEPART(WEEK, ventas.Factura.fechaHora) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ventas.Factura.fechaHora), 0)) + 1
		, ventas.DetalleFactura.productoID)

	SELECT semana
		, productos.Producto.descripcion descripcion
		, cantidad
	FROM productosPorSemana
	INNER JOIN productos.Producto ON productosPorSemana.productoID = productos.Producto.id
	WHERE rango <= 5
	ORDER BY semana ASC
		, rango ASC
	FOR XML PATH('producto'), ROOT('top-5-productos'), TYPE
END

--6)
CREATE PROCEDURE ventas.top5PeoresPorMes
	@mes INT
AS
BEGIN
	;WITH productosPorSemana AS (SELECT ventas.DetalleFactura.productoID AS productoID
		, SUM(ventas.DetalleFactura.cantidad) cantidad
		, RANK() OVER (ORDER BY SUM(ventas.DetalleFactura.cantidad) DESC) rango
	FROM ventas.Factura
	INNER JOIN ventas.DetalleFactura ON ventas.Factura.id = ventas.DetalleFactura.facturaID
	WHERE DATEPART(MONTH, ventas.Factura.fechaHora) = @mes
	GROUP BY ventas.DetalleFactura.productoID)

	SELECT productos.Producto.descripcion descripcion
		, cantidad
	FROM productosPorSemana
	INNER JOIN productos.Producto ON productosPorSemana.productoID = productos.Producto.id
	WHERE rango <= 5
	ORDER BY rango ASC
	FOR XML PATH('producto'), ROOT('top-5-peores-productos'), TYPE
END

--7)
CREATE PROCEDURE ventas.ventasPorFechaYSucursal
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
				, E.nombre + ' ' + E.apellido vendedor
				, E.cargo
				, E.turno
			FOR XML PATH(''), TYPE
		) empleado
		, ( 
			SELECT C.ciudad
				, C.genero
				, C.tipo
			FROM ventas.Cliente C
			WHERE C.id = F.clienteID
			FOR XML PATH(''), TYPE
		) cliente
		, (
			SELECT P.descripcion
				, DF.cantidad
				, DF.precio
				, DF.precio * DF.cantidad AS totalItem
			FROM ventas.DetalleFactura DF
			INNER JOIN productos.Producto P ON DF.productoID = P.id
			WHERE DF.facturaId = F.id
			FOR XML PATH('producto'), TYPE
		) productos
	FROM ventas.Factura F
	INNER JOIN rrhh.Empleado E ON F.empleadoID = E.legajo
	INNER JOIN rrhh.Sucursal S ON E.sucursalId = S.id 
	WHERE CONVERT(DATE, F.fechaHora) = @fecha
		AND E.sucursalId = @sucursal
	FOR XML PATH('venta'), ROOT('ventas'), TYPE
END

--8)
CREATE PROCEDURE ventas.mayorVendedorPorSucursal
	@mes INT,
	@anio INT
AS 
BEGIN 
	;WITH monto_empleado_por_sucursal AS (
		SELECT rrhh.Sucursal.ubicacion as sucursal
		, rrhh.Empleado.legajo as legajo
		, (SELECT EmplAUX.nombre + ' ' + EmplAUX.apellido FROM rrhh.Empleado AS EmplAUX where EmplAUX.legajo = rrhh.Empleado.legajo) as nombre
		, SUM(ventas.DetalleFactura.precio * ventas.DetalleFactura.cantidad) as monto
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
		, MAX(monto) monto
	FROM monto_empleado_por_sucursal
	GROUP BY sucursal
		, legajo
		, nombre
	FOR XML PATH('mejor-vendedor'), ROOT('monto-por-sucursal'), TYPE
END;
GO



