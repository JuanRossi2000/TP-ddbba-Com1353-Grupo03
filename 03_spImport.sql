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