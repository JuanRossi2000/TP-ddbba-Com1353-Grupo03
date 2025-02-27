
/*
Parte cumplida: Importaciones
fecha de entrega: 27/02/25
Comisión: 1353
Número de grupo: 3
Materia: Bases de datos Aplicadas
Nombres y DNI: 
	-Bautista Rios Di Gaeta, 46431397
	-Samuel Gallardo, 45926613
	-Juan Ignacio Rossi, 42115962
	-Joel Fabián Stivala Patiño, 42825990
*/
-----------------------------------------------------------------------------------------------------------------------------------------------
use Aurora_SA
go
EXEC sp_configure 'Show Advanced Options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
go


-----------------------------------------------------------------------------------------------------------------------------------------------
--SUCURSAL

INSERT INTO rrhh.sucursal(ciudad,ubicacion,direccion,horario,telefono)
SELECT 
	[Ciudad],
    [Reemplazar por], 
    [direccion], 
    [Horario], 
    [Telefono]
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'excel 12.0 Xml;HDR=YES;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Informacion_complementaria.xlsx',
   'SELECT Ciudad,[Reemplazar por], direccion, Horario, Telefono FROM [sucursal$]'
);

-----------------------------------------------------------------------------------------------------------------------------------------------
--EMPLEADO

CREATE TABLE #EmpleadoTemp (
	legajo int,
	nombre varchar(50),
	apellido varchar(50),
	dni int,
	direccion varchar(255),
	emailPersonal varchar(255),
	emailEmpresa varchar(255),
	cuil bigint,
	cargo varchar(30),
	sucursal varchar(20),
    turno varchar(17),
);

INSERT INTO #EmpleadoTemp(legajo, nombre, apellido, dni, direccion, emailPersonal,emailEmpresa,cuil,cargo,sucursal,turno)
SELECT 
    [Legajo/ID], Nombre, Apellido, DNI, Direccion, [email personal],[email empresa],CUIL,Cargo,Sucursal,Turno
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'excel 12.0 Xml;HDR=YES;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Informacion_complementaria.xlsx',
   'SELECT [Legajo/ID], Nombre, Apellido, DNI, Direccion,[email personal],[email empresa],CUIL,cargo,sucursal,turno FROM [Empleados$]'
);
go
INSERT INTO rrhh.Empleado(legajo, nombre, apellido, dni, direccion, emailPersonal,emailEmpresa,cuil,cargo,sucursalId,turno)
SELECT legajo, nombre, apellido, dni, e.direccion, emailPersonal, emailEmpresa, utilidades.GenerarCuil(dni), cargo, s.id, turno
FROM #EmpleadoTemp AS e
JOIN rrhh.Sucursal AS s ON s.ubicacion = e.sucursal
go
drop table #EmpleadoTemp
--------------------------------------------------------------------------------------------------------------------------------------------
--MEDIO DE PAGO

INSERT INTO ventas.MedioPago(descripcionEsp,descripcionIng)
SELECT 
    [F3] AS DescripcionEsp,
	[F2] AS descripcionIng
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'Excel 12.0 Xml;HDR=NO;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Informacion_complementaria.xlsx',
   'SELECT * FROM [medios de pago$A3:C100]'
)

-----------------------------------------------------------------------------------------------------------------------------------------------
--LINEA PRODUCTO

create table #lineaProd
(
	producto varchar(50) primary key,
	linea varchar(10)
);

go

INSERT INTO #lineaProd(linea, producto)
SELECT [Línea de producto], 
		[Producto]
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'Excel 12.0 Xml;HDR=YES;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Informacion_complementaria.xlsx',
   'SELECT * FROM [Clasificacion productos$]'
)

INSERT INTO productos.LineaProducto(nombre)
select distinct linea from #lineaProd
group by linea
-----------------------------------------------------------------------------------------------------------------------------------
--CATALOGO

create table #catalogo
(
id int,
category varchar(50),
[name] varchar(100),
price decimal(7,2),
reference_price decimal (7,2),
reference varchar(7),
[date] smalldatetime
)

bulk insert #catalogo
from 'C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Productos\catalogo.csv'
WITH
(
FIELDTERMINATOR = ',', -- Especifica el delimitador de campo (coma en un archivo CSV)
ROWTERMINATOR = '0x0A', -- Especifica el terminador de fila (salto de línea en un archivo CSV)
CODEPAGE = '65001', -- Especifica la página de códigos del archivo
FORMAT = 'CSV',
FIRSTROW = 2
);


WITH CTE_catalogo AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY [name]
            ORDER BY price DESC -- Ordena por precio descendente (elige el más alto)
        ) AS duplicado
    FROM #catalogo
)

insert into productos.Producto(descripcion,precio,unidadReferencia,lineaID)
select utilidades.remplazar(c.[name]), c.price, c.reference, lp.id
from CTE_catalogo c inner join #lineaProd l
on c.category = l.producto
inner join productos.LineaProducto lp
on lp.nombre = l.linea
where c.duplicado = 1

drop table #catalogo
drop table #lineaProd

-----------------------------------------------------------------------------------------------------------------------------------
--ELECTRONICOS
Create table #Electronic
(
	producto varchar(100),
	precio decimal(10,2)
)

INSERT INTO #Electronic(producto,precio)
SELECT 
    [Product],[Precio Unitario en dolares] 
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'excel 12.0 Xml;HDR=YES;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Productos\Electronic accessories.xlsx',
   'SELECT Product,[Precio Unitario en dolares] FROM [Sheet1$]'
);
GO

WITH CTE_Electronic AS (
    SELECT 
        producto,
        precio,
        ROW_NUMBER() OVER (
            PARTITION BY producto 
            ORDER BY (SELECT NULL)  -- Opcional: Ordenar por columna relevante si hay prioridad
        ) AS duplicado
    FROM #Electronic
)
DELETE FROM #Electronic
WHERE producto IN ( SELECT producto
                    FROM CTE_Electronic WHERE duplicado > 1)

insert into productos.LineaProducto(nombre)
values('Electronicos')

insert into productos.Producto(descripcion, precio, lineaID)
select e.producto, e.precio, l.id from #Electronic e
inner join productos.LineaProducto l 
on l.nombre = 'Electronicos'

drop table #Electronic

-----------------------------------------------------------------------------------------------------------------------------------
--PRODUCTOS IMPORTADOS

Create table #Import
(
	IdProducto int,
	NombreProducto varchar(100),
	Proveedor varchar(100),
	Categoria varchar(100),
	CantidadPorUnidad varchar(50),
	PrecioUnidad decimal(10,2)
)


INSERT INTO #Import(IdProducto,NombreProducto,Proveedor,Categoria,CantidadPorUnidad,PrecioUnidad)
SELECT 
    IdProducto,NombreProducto,Proveedor,Categoría,CantidadPorUnidad,PrecioUnidad
FROM OPENROWSET(
   'Microsoft.ACE.OLEDB.12.0',
   'excel 12.0 Xml;HDR=YES;Database=C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
   'SELECT IdProducto,NombreProducto,Proveedor,Categoría,CantidadPorUnidad,PrecioUnidad  FROM [Listado de Productos$]'
);
GO

insert into productos.LineaProducto(nombre)
values('Importado');

WITH CTE_importado AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NombreProducto 
            ORDER BY (SELECT NULL)  -- Opcional: Ordenar por columna relevante si hay prioridad
        ) AS duplicado
    FROM #Import
)
DELETE FROM #Import
WHERE NombreProducto IN ( SELECT NombreProducto
                    FROM CTE_importado WHERE duplicado > 1)



insert into productos.Producto(descripcion,precio,lineaID)
select i.NombreProducto, i.PrecioUnidad, l.id from #Import i
inner join productos.LineaProducto l 
on l.nombre = 'Importado'

drop table #Import;

-----------------------------------------------------------------------------------------------------------------------------------
--VENTAS

go

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
)
GO

BULK INSERT #ventas
FROM 'C:\Users\bauri\OneDrive\Escritorio\TP_integrador_Archivos\Ventas_registradas.csv'
WITH
(
FIELDTERMINATOR = ';', -- Especifica el delimitador de campo (coma en un archivo CSV)
ROWTERMINATOR = '0x0A', -- Especifica el terminador de fila (salto de línea en un archivo CSV)
CODEPAGE = '65001', -- Especifica la página de códigos del archivo
FORMAT = 'CSV',
FIELDQUOTE  = '"',
FIRSTROW = 2
)


CREATE TABLE ventas(
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
)

INSERT INTO ventas(ID,tipoFactura,ciudad,tipoCliente,genero,producto,precio_unitario,cantidad,fecha,hora,medioPago,empleado,identificador)
SELECT ID,tipoFactura,ciudad,tipoCliente,genero,utilidades.remplazar(producto) as producto,precio_unitario,cantidad,fecha,hora,medioPago,empleado,identificador
FROM #ventas

drop table #ventas

insert into ventas.Estado(descripcion)
values
	('Pendiente'),
	('Pagado');

INSERT INTO ventas.Factura (nro,tipo,tipoCliente,genero,fechaHora,empleadoID,pagoID,estadoID, precioTotal,identificadorPago)
SELECT v.ID,
v.tipoFactura,
CASE ABS(CHECKSUM(NEWID())) % 2
 WHEN 0 THEN 'Member'
 ELSE 'Normal'
    END AS tipoCliente,
CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Male' ELSE 'Female' END AS genero,
CAST(CAST(v.fecha AS DATE) AS VARCHAR) + ' ' + LEFT(CAST(v.hora AS VARCHAR), 8),
v.empleado,
m.id,
    CASE 
WHEN m.descripcionIng = 'Credit card' THEN 1
WHEN m.descripcionIng = 'Cash' THEN 2 
ELSE 2
END AS estadoID,
v.cantidad * v.precio_unitario,
v.identificador
FROM ventas as v
JOIN ventas.mediopago as m ON m.descripcionIng = v.medioPago

insert into ventas.DetalleFactura(facturaID,item,cantidad,precio, productoID)
select f.id, ROW_NUMBER() over(partition by f.id order by f.id) as item, v.cantidad, v.precio_unitario, p.id from ventas.Factura f
inner join ventas v on v.ID = f.nro
inner join productos.Producto p on p.descripcion = v.producto

drop table ventas
-----------------------------------------------------------------------------------------------------------------------------------
go
EXEC sp_configure 'Ad Hoc Distributed Queries', 0;
RECONFIGURE;
go
EXEC sp_configure 'Show Advanced Options', 0;
RECONFIGURE;
-----------------------------------------------------------------------------------------------------------------------------------
