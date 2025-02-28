USE Com1353G03

Create or alter PROCEDURE ImportarInfoComplementaria
    @ubicacionArchivo NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

EXEC sp_configure 'Show Advanced Options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

    
    -- Importar hoja "sucursal"
    
    DECLARE @cadena NVARCHAR(MAX);

    SET @cadena = N'
    INSERT INTO rrhh.sucursal(ciudad, ubicacion, direccion, horario, telefono)
    SELECT 
         [Ciudad],
         [Reemplazar por], 
         [direccion],
         [Horario],
         [Telefono]
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
         ''SELECT Ciudad, [Reemplazar por], direccion, Horario, Telefono FROM [sucursal$]''
    );';

    EXEC sp_executesql @cadena;

    
    -- Importar hoja "medios de pago"
    
    -- Se crea una tabla temporal para almacenar la información.
    CREATE TABLE #medioPago(
         español VARCHAR(30),
         ingles VARCHAR(30)
    );

    SET @cadena = N'
    INSERT INTO #medioPago (ingles, español)
    SELECT 
         [F2] AS ingles,
         [F3] AS español
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''Excel 12.0 Xml;HDR=NO;Database=' + @ubicacionArchivo + ''',
         ''SELECT * FROM [medios de pago$A3:C100]''
    );';

    EXEC sp_executesql @cadena;

	--Insertar en la tabla definitiva
     INSERT INTO ventas.MedioPago(descripcionIng, descripcionEsp)
     SELECT ingles, español 
	 FROM #medioPago;

 
    -- Importar hoja "Clasificacion productos" (Líneas de producto)
  
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
    SELECT [Línea de producto], [Producto]
    FROM OPENROWSET(
         ''Microsoft.ACE.OLEDB.12.0'',
         ''Excel 12.0 Xml;HDR=YES;Database=' + @ubicacionArchivo + ''',
         ''SELECT * FROM [Clasificacion productos$]''
    );';

    EXEC sp_executesql @cadena;

    -- Insertar las líneas de producto (sin duplicados) en la tabla definitiva
    INSERT INTO productos.LineaProducto(nombre)
    SELECT DISTINCT linea
    FROM utilidades.lineaTemp;


    -- Importar hoja "Empleados"
    
    CREATE TABLE #EmpleadoTemp (
         legajo INT,
         nombre VARCHAR(50),
         apellido VARCHAR(50),
         dni INT,
         direccion VARCHAR(255),
         emailPersonal VARCHAR(255),
         emailEmpresa VARCHAR(255),
         cuil BIGINT,
         cargo VARCHAR(30),
         sucursal VARCHAR(20),
         turno VARCHAR(17)
    );

    SET @cadena = N'
    INSERT INTO #EmpleadoTemp(legajo, nombre, apellido, dni, direccion, emailPersonal, emailEmpresa, cuil, cargo, sucursal, turno)
    SELECT 
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

    -- Insertar los empleados en la tabla definitiva, relacionando la sucursal mediante JOIN
    INSERT INTO rrhh.Empleado(legajo, nombre, apellido, dni, direccion, emailPersonal, emailEmpresa, cuil, cargo, sucursalId, turno)
    SELECT 
         e.legajo,
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
    JOIN rrhh.Sucursal s ON s.ubicacion = e.sucursal;

    DROP TABLE #EmpleadoTemp;

    -- Limpieza de la tabla temporal de medios de pago (te vere en el infierno)
    DROP TABLE #medioPago;

	EXEC sp_configure 'Ad Hoc Distributed Queries', 0;
	RECONFIGURE;

	EXEC sp_configure 'Show Advanced Options', 0;
	RECONFIGURE;
END;

go

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
GO
