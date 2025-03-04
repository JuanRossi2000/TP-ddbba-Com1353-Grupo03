/*
Parte cumplida: Stored Procedures de Importación
fecha de entrega: 04/03/25
Comisión: 1353
Número de grupo: 3
Materia: Bases de datos Aplicadas
Nombres y DNI: 
-Bautista Rios Di Gaeta, 46431397
-Samuel Gallardo, 45926613
-Juan Ignacio Rossi, 42115962
-Joel Fabián Stivala Patiño, 42825990
*/
USE Com1353G03;

GO

CREATE OR ALTER PROCEDURE ImportarInfoComplementaria
    @ubicacionArchivo NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    -- Habilitar opciones necesarias
    EXEC sp_configure 'Show Advanced Options', 1;
    RECONFIGURE;
    EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
    RECONFIGURE;

    DECLARE @cadena NVARCHAR(MAX);

    
    -- Importar hoja "sucursal"
    
    SET @cadena = N'
    INSERT INTO rrhh.sucursal(ciudad, ubicacion, direccion, horario, telefono)
    SELECT DISTINCT
         src.[Ciudad],
         src.[Reemplazar por],
         src.[direccion],
         src.[Horario],
         src.[Telefono]
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
         ''SELECT Ciudad, [Reemplazar por], direccion, Horario, Telefono FROM [sucursal$]''
    ) AS src
    WHERE NOT EXISTS (
         SELECT 1 
         FROM rrhh.sucursal r
         WHERE r.ubicacion = src.[Reemplazar por]
           AND r.ciudad = src.[Ciudad]
    );';
    EXEC sp_executesql @cadena;

    
    -- Importar hoja "medios de pago"
    
    CREATE TABLE #medioPago(
         español VARCHAR(30),
         ingles VARCHAR(30)
    );

    SET @cadena = N'
    INSERT INTO #medioPago (ingles, español)
    SELECT DISTINCT
         [F2] AS ingles,
         [F3] AS español
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''Excel 12.0 Xml;HDR=NO;Database=' + @ubicacionArchivo + ''',
         ''SELECT * FROM [medios de pago$A3:C100]''
    );';
    EXEC sp_executesql @cadena;

    -- Insertar en la tabla definitiva sin duplicados
    INSERT INTO ventas.MedioPago(descripcionIng, descripcionEsp)
    SELECT DISTINCT mp.ingles, mp.español
    FROM #medioPago mp
    WHERE NOT EXISTS (
         SELECT 1 FROM ventas.MedioPago v
         WHERE v.descripcionIng = mp.ingles
           AND v.descripcionEsp = mp.español
    );

    
    -- Importar hoja "Clasificacion productos" 
    
    IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'utilidades' AND TABLE_NAME = 'lineaTemp')
    BEGIN
       CREATE TABLE utilidades.lineaTemp
        (
             producto VARCHAR(50) PRIMARY KEY,
             linea VARCHAR(10)
        );
    END;

    SET @cadena = N'
    INSERT INTO utilidades.LineaTemp(linea, producto)
    SELECT src.[Línea de producto], src.[Producto]
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''Excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
         ''SELECT [Línea de producto], [Producto] FROM [Clasificacion productos$]''
    ) AS src
    WHERE NOT EXISTS (
         SELECT 1 FROM utilidades.LineaTemp ut
         WHERE ut.producto = src.[Producto]
    );';
    EXEC sp_executesql @cadena;

    -- Insertar las líneas de producto (sin duplicados) en la tabla definitiva
    INSERT INTO productos.LineaProducto(nombre)
    SELECT DISTINCT lt.linea
    FROM utilidades.lineaTemp lt
    WHERE NOT EXISTS (
         SELECT 1 FROM productos.LineaProducto lp
         WHERE lp.nombre = lt.linea
    );

    
    -- Importar hoja "Empleados"
    
    CREATE TABLE #EmpleadoTemp (
         legajo INT,
         nombre VARCHAR(50),
         apellido VARCHAR(50),
         dni INT,
         direccion VARCHAR(255),
         emailPersonal VARCHAR(255),
         emailEmpresa VARCHAR(255),
         cuil char(11),
         cargo VARCHAR(30),
         sucursal VARCHAR(20),
         turno VARCHAR(17)
    );

    SET @cadena = N'
    INSERT INTO #EmpleadoTemp(legajo, nombre, apellido, dni, direccion, emailPersonal, emailEmpresa, cuil, cargo, sucursal, turno)
    SELECT DISTINCT
         [Legajo/ID], 
         Nombre, 
         Apellido, 
         DNI, 
         Direccion, 
         [email personal], 
         [email empresa], 
         CUIL, 
         Cargo, 
         Sucursal, 
         Turno
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
         ''SELECT [Legajo/ID], Nombre, Apellido, DNI, Direccion, [email personal], [email empresa], CUIL, cargo, sucursal, turno FROM [Empleados$]''
    );';
    EXEC sp_executesql @cadena;
	
    -- Insertar los empleados en la tabla definitiva, relacionando la sucursal mediante JOIN y evitando duplicados por legajo
    INSERT INTO rrhh.Empleado(legajo, nombre, apellido, dni, direccion, emailPersonal, emailEmpresa, cuil, cargo, sucursalId, turno)
    SELECT e.legajo,
           e.nombre,
           e.apellido,
           e.dni,
           e.direccion,
           e.emailPersonal,
           e.emailEmpresa,
           utilidades.GenerarCuil(e.dni),
           e.cargo,
           s.id,
           e.turno
    FROM #EmpleadoTemp e
    JOIN rrhh.Sucursal s ON s.ubicacion = e.sucursal
    WHERE NOT EXISTS (
         SELECT 1 FROM rrhh.Empleado emp
         WHERE emp.legajo = e.legajo
    );

    DROP TABLE #EmpleadoTemp;
    DROP TABLE #medioPago;
END;
GO


CREATE OR ALTER PROCEDURE ventas.importCatalogo
    @ubicacionArchivo VARCHAR(255)  
AS
BEGIN
    -- Crear tabla temporal para cargar el archivo CSV
    CREATE TABLE #catalogo
    (
        id INT,
        category VARCHAR(50),
        [name] VARCHAR(100),
        price DECIMAL(7,2),
        reference_price DECIMAL(7,2),
        reference VARCHAR(7),
        [date] SMALLDATETIME
    );

    -- Variable con lindo nombre para la cadena dinamica
    DECLARE @sql NVARCHAR(MAX);

    -- BULK INSERT DINAMICO
    SET @sql = N'
        BULK INSERT #catalogo
        FROM ''' +@ubicacionArchivo+ N'''
        WITH
        (
            FIELDTERMINATOR = '','', -- Especifica el delimitador de campo (coma en un archivo CSV)
            ROWTERMINATOR = ''0x0A'', -- Especifica el terminador de fila (salto de línea en un archivo CSV)
            CODEPAGE = ''65001'', -- Especifica la página de códigos del archivo
            FORMAT = ''CSV'',
            FIRSTROW = 2 -- Saltamos la primera fila de encabezados
        );'

    -- Ejecutar la consulta dinámica 
    EXEC (@sql);

    ;WITH CTE_catalogo AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY [name]
                ORDER BY price DESC -- Ordena por precio descendente (para sacar ganancias como buen capitalista)
            ) AS duplicado
        FROM #catalogo
    )
    -- Insertar los productos en la tabla productos.Producto
    INSERT INTO productos.Producto (descripcion, precio, unidadReferencia, lineaID)
    SELECT 
        utilidades.remplazar(c.[name]), 
        c.price, 
        c.reference, 
        lp.id
    FROM CTE_catalogo c
    INNER JOIN utilidades.lineaTemp l ON c.category = l.producto
    INNER JOIN productos.LineaProducto lp ON lp.nombre = l.linea
    WHERE c.duplicado = 1;

    PRINT 'Datos cargados exitosamente desde el archivo.';

	drop table #catalogo
	drop table utilidades.lineaTemp
END;

go

CREATE OR ALTER PROCEDURE ventas.importProductos
    @ubicacionArchivo NVARCHAR(255) 
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para almacenar los datos del archivo Excel
    CREATE TABLE #Import
    (
        IdProducto INT,
        NombreProducto VARCHAR(100),
        Proveedor VARCHAR(100),
        Categoria VARCHAR(100),
        CantidadPorUnidad VARCHAR(50),
        PrecioUnidad DECIMAL(10,2)
    );
	
    DECLARE @sql NVARCHAR(MAX);
    -- Construir la consulta OPENROWSET dinámicamente
    SET @sql = N'
        INSERT INTO #Import (IdProducto, NombreProducto, Proveedor, Categoria, CantidadPorUnidad, PrecioUnidad)
        SELECT 
            IdProducto, NombreProducto, Proveedor, Categoría, CantidadPorUnidad, PrecioUnidad
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
            ''SELECT IdProducto, NombreProducto, Proveedor, Categoría, CantidadPorUnidad, PrecioUnidad FROM [Listado de Productos$]''
        );';

    -- Ejecutar la consulta dinámica para cargar datos en #Import
    EXEC sp_executesql @sql;

    -- Insertar en productos.LineaProducto si no existe la línea 'Importado'
    IF NOT EXISTS (SELECT 1 FROM productos.LineaProducto WHERE nombre = 'Importado')
    BEGIN
        INSERT INTO productos.LineaProducto(nombre) VALUES('Importado');
    END

    -- Eliminar duplicados en #Import usando una CTE: se conserva sólo la primera aparición de cada NombreProducto
    ;WITH CTE_importado AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY NombreProducto 
                ORDER BY (SELECT NULL)
            ) AS duplicado
        FROM #Import
    )
    DELETE FROM CTE_importado
    WHERE duplicado > 1;

    -- Insertar los productos en la tabla productos.Producto, evitando insertar duplicados que ya existan
    INSERT INTO productos.Producto (descripcion, precio, lineaID)
    SELECT i.NombreProducto, i.PrecioUnidad, l.id 
    FROM #Import i
    INNER JOIN productos.LineaProducto l 
         ON l.nombre = 'Importado'
    WHERE NOT EXISTS (
         SELECT 1 
         FROM productos.Producto p 
         WHERE p.descripcion = i.NombreProducto
    );

    PRINT 'Datos cargados exitosamente desde el archivo.';

    -- eliminar temporal (hasta la vista, baby)
    DROP TABLE IF EXISTS #Import;
END;

go

CREATE OR ALTER PROCEDURE ventas.importElectronic
    @ubicacionArchivo NVARCHAR(255) -- Parámetro para la ubicación del archivo
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para almacenar los datos del archivo Excel
    CREATE TABLE #Electronic
    (
        producto VARCHAR(100),
        precio DECIMAL(10,2)
    );

    -- Variable para la consulta dinámica
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta OPENROWSET dinámicamente
    SET @sql = N'
        INSERT INTO #Electronic (producto, precio)
        SELECT 
            [Product], [Precio Unitario en dolares]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
            ''SELECT Product, [Precio Unitario en dolares] FROM [Sheet1$]''
        );';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- Eliminar duplicados usando una CTE
;WITH CTE_Electronic AS (
SELECT 
producto,
precio,
ROW_NUMBER() OVER (
PARTITION BY producto 
ORDER BY (SELECT NULL)  -- Opcional: Ordenar por alguna columna si se necesita prioridad
) AS duplicado
FROM #Electronic
)
DELETE FROM #Electronic
WHERE producto IN (
SELECT producto FROM CTE_Electronic WHERE duplicado > 1
);

-- Insertar en productos.LineaProducto si no existe
IF NOT EXISTS (SELECT 1 FROM productos.LineaProducto WHERE nombre = 'Electronicos')
BEGIN
INSERT INTO productos.LineaProducto(nombre) VALUES('Electronicos');
END

-- Insertar los productos en la tabla productos.Producto sin duplicados
INSERT INTO productos.Producto (descripcion, precio, lineaID)
SELECT e.producto, e.precio * utilidades.obtenerPrecioMoneda('USD'), l.id 
FROM #Electronic e
INNER JOIN productos.LineaProducto l ON l.nombre = 'Electronicos'
WHERE NOT EXISTS (
SELECT 1 
FROM productos.Producto p 
WHERE p.descripcion = e.producto
);


    PRINT 'Datos cargados exitosamente desde el archivo';

    -- Limpiar la tabla temporal
    DROP TABLE IF EXISTS #Electronic;
END;

go





CREATE or ALTER PROCEDURE CargarVentas
    @ubicacionArchivo VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Crear tabla temporal para la carga de datos
    CREATE TABLE #ventas(
        ID varchar(50),
        tipoFactura char(1),
        ciudad varchar(50),
        tipoCliente varchar(50),
        genero varchar(20),
        producto nvarchar(200),
        precio_unitario decimal(10,2),
        cantidad int,
        fecha smalldatetime,
        hora time,
        medioPago varchar(30),
        empleado int,
        identificador varchar(200)
    );

	   CREATE TABLE #ventas2(
        ID varchar(50),
        tipoFactura char(1),
        ciudad varchar(50),
        tipoCliente varchar(50),
        genero varchar(20),
        producto nvarchar(200),
        precio_unitario decimal(10,2),
        cantidad int,
        fecha smalldatetime,
        hora time,
        medioPago varchar(30),
        empleado int,
        identificador varchar(200)
    );

    -- 2. Construir y ejecutar el BULK INSERT usando dynamic SQL
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'BULK INSERT #ventas FROM ''' + @ubicacionArchivo + N''' 
    WITH (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''65001'',
        FORMAT = ''CSV'',
        FIELDQUOTE  = ''"'',
        FIRSTROW = 2
    );';
    EXEC sp_executesql @sql;

    -- 3. Insertar registros en la tabla ventas, omitiendo duplicados (basado en ID)
    INSERT INTO #ventas2(ID, tipoFactura, ciudad, tipoCliente, genero, producto, precio_unitario, cantidad, fecha, hora, medioPago, empleado, identificador)
    SELECT v.ID,
           v.tipoFactura,
           v.ciudad,
           v.tipoCliente,
           v.genero,
           utilidades.remplazar(v.producto) AS producto,
           v.precio_unitario,
           v.cantidad,
           v.fecha,
           v.hora,
           v.medioPago,
           v.empleado,
           v.identificador
    FROM #ventas v
    WHERE NOT EXISTS (
         SELECT 1 FROM #ventas2 WHERE ID = v.ID
    );

    -- Eliminar la tabla temporal
    DROP TABLE #ventas;

    -- 4. Insertar estados si aÃºn no existen
    IF NOT EXISTS(SELECT 1 FROM ventas.Estado WHERE descripcion = 'Pendiente')
    BEGIN
         INSERT INTO ventas.Estado(descripcion) VALUES ('Pendiente');
    END
    IF NOT EXISTS(SELECT 1 FROM ventas.Estado WHERE descripcion = 'Pagado')
    BEGIN
         INSERT INTO ventas.Estado(descripcion) VALUES ('Pagado');
    END

    -- 5. Insertar registros en la tabla Factura (evitando duplicados basados en el campo nro)
    INSERT INTO ventas.Factura (nro, tipo, tipoCliente, genero, fechaHora, empleadoID, pagoID, estadoID, identificadorPago, sucursalId)
    SELECT v.ID,
           v.tipoFactura,
           CASE ABS(CHECKSUM(NEWID())) % 2
                WHEN 0 THEN 'Member'
                ELSE 'Normal'
           END AS tipoCliente,
           CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Male' ELSE 'Female' END AS genero,
           CAST(CAST(v.fecha AS DATE) AS VARCHAR) + ' ' + LEFT(CAST(v.hora AS VARCHAR), 8) AS fechaHora,
           v.empleado,
           m.id,
           CASE 
                WHEN m.descripcionIng = 'Credit card' THEN (ABS(CHECKSUM(NEWID())) % 2) + 1
                WHEN m.descripcionIng = 'Cash' THEN 2 
                ELSE 2
           END AS estadoID,
           v.identificador AS identificadorPago,
		   s.id
    FROM #ventas2 v
    inner JOIN ventas.mediopago m ON m.descripcionIng = v.medioPago
	inner JOIN rrhh.Sucursal s on v.ciudad = s.ciudad
    WHERE NOT EXISTS (
         SELECT 1 FROM ventas.Factura f WHERE f.nro = v.ID
    );

    -- 6. Insertar registros en la tabla DetalleFactura para cada factura nueva
    ;WITH cteDetalle AS
    (
       SELECT f.id AS facturaID,
              ROW_NUMBER() OVER(PARTITION BY f.id ORDER BY f.id) AS item,
              v.cantidad,
              v.precio_unitario,
              p.id AS productoID
       FROM ventas.Factura f
       INNER JOIN #ventas2 v ON v.ID = f.nro
       INNER JOIN productos.Producto p ON p.descripcion = v.producto
    )

    INSERT INTO ventas.DetalleFactura(facturaID, item, cantidad, precio, productoID)
    SELECT cte.facturaID,
           cte.item,
           cte.cantidad,
           cte.precio_unitario,
           cte.productoID
    FROM cteDetalle cte
    WHERE NOT EXISTS (
         SELECT 1 
         FROM ventas.DetalleFactura df
         WHERE df.facturaID = cte.facturaID AND df.item = cte.item
    );

    PRINT 'Proceso de carga de ventas completado exitosamente.';

	EXEC sp_configure 'Ad Hoc Distributed Queries', 0;
		RECONFIGURE;
	EXEC sp_configure 'Show Advanced Options', 0;
		RECONFIGURE;
END;
