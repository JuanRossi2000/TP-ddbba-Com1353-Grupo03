/*
Parte cumplida: Ejecucion de SP de Importe
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

exec utilidades.altaMoneda 'USD', 1230 --SE AGREGA UN VALOR DE EJEMPLO PARA EL PRECIO DOLAR PARA LOS PRODUCTOS QUE LO UTILIZAN
  
exec ImportarInfoComplementaria 'RUTA DE ARCHIVO'

exec ventas.importCatalogo 'RUTA DE ARCHIVO'

exec ventas.importProductos 'RUTA DE ARCHIVO'

exec ventas.importElectronic 'RUTA DE ARCHIVO'

exec CargarVentas 'RUTA DE ARCHIVO'
