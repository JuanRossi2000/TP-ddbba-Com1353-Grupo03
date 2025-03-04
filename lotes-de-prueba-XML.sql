/*
Parte cumplida: Lotes de pruebas para los reportes XML
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


-USE Com1353G03
--1)
EXEC reportes.reporteMensualPorDia 1, 2019 --> Devuelve el monto agrupado por dia de semana dentro de un mes
--2) 
EXEC reportes.reporteMensualPorTrimestreTurno 1, 2019 --> Devuelve el monto agrupado por turno, y mes, en base al trimestre solicitado
--3)
EXEC reportes.productosVendidosPorRango '20190110', '20190329' --> Dado un rango de fechas, devuelve la cantidad de productos vendidos en ese rango, ordenado de forma descendente
--4)
EXEC reportes.cantidadProductosPorSucursal '20190111', '20190112' --> Dado un rango de fechas, devuelve la cantidad de productos vendidos por sucursal
--5)
EXEC reportes.top5PorMesSemana 1, 2019 --> Muestra los 5 productos más vendidos agrupados por semana del mes.
--6)
EXEC reportes.top5PeoresPorMes 1, 2019 --> Muestra los 5 productos menos vendidos.
--7)
EXEC reportes.ventasPorFechaYSucursal '20190111', 3 --> Dada una fecha específica y una id de sucursal, muestra el detalle de las ventas de ese dia en esa sucursal
--8)
EXEC reportes.mayorVendedorPorSucursal 1, 2019 --> Dado un mes y un año, muestra el mejor vendedor por sucursal
