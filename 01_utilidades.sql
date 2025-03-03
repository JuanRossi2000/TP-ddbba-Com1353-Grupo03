/*
Parte cumplida: Creacion utilidades como funciones y triggers
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
use Com1353G03

GO

--FUNCION QUE UTILIZARA EL PROCEDURE reporteMensualPorTrimestreTurno

	CREATE or ALTER FUNCTION utilidades.getTrimestre
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

--FUNCION PARA GENERAR CUIL DE EMPLEADOS

CREATE or ALTER FUNCTION utilidades.GenerarCuil(@dni INT)
	RETURNS CHAR(11)
	AS
	BEGIN
		-- Convertir el DNI a una cadena de 8 caracteres, completando con ceros a la izquierda si es necesario
		DECLARE @dniStr CHAR(8) = CAST(@dni AS VARCHAR(8));

		-- Seleccionar un prefijo de forma determinista usando el hash del DNI
		-- Se usan los prefijos 20, 23, 24 y 27
		DECLARE @mod INT = ABS(CHECKSUM(@dni)) % 4;
		DECLARE @prefijo INT = CASE @mod
								WHEN 0 THEN 20
								WHEN 1 THEN 23
								WHEN 2 THEN 24
								WHEN 3 THEN 27
							  END;

		-- Convertir el prefijo a una cadena de 2 caracteres
		DECLARE @prefijoStr CHAR(2) = CAST(@prefijo AS VARCHAR(2))

		-- Calcular el dígito verificador usando la fórmula del módulo 11
		DECLARE @suma INT =
			  CAST(SUBSTRING(@prefijoStr, 1, 1) AS INT) * 5 +
			  CAST(SUBSTRING(@prefijoStr, 2, 1) AS INT) * 4 +
			  CAST(SUBSTRING(@dniStr, 1, 1) AS INT)   * 3 +
			  CAST(SUBSTRING(@dniStr, 2, 1) AS INT)   * 2 +
			  CAST(SUBSTRING(@dniStr, 3, 1) AS INT)   * 7 +
			  CAST(SUBSTRING(@dniStr, 4, 1) AS INT)   * 6 +
			  CAST(SUBSTRING(@dniStr, 5, 1) AS INT)   * 5 +
			  CAST(SUBSTRING(@dniStr, 6, 1) AS INT)   * 4 +
			  CAST(SUBSTRING(@dniStr, 7, 1) AS INT)   * 3 +
			  CAST(SUBSTRING(@dniStr, 8, 1) AS INT)   * 2;

		DECLARE @r INT = @suma % 11;
		DECLARE @digito INT = 11 - @r;

		IF @digito = 11 SET @digito = 0;
		IF @digito = 10 SET @digito = 9;

		RETURN @prefijoStr + @dniStr + CAST(@digito AS CHAR(1));
	END;
	
GO
-----------------------------------------------------------------------------------------------------------------------
-- Esta funcion fue el resultado de sudor y sangre, no estamos orgullosos pero tampoco arrepentidos, gracias por leer
-----------------------------------------------------------------------------------------------------------------------
	CREATE or ALTER FUNCTION utilidades.remplazar (@cadena VARCHAR(MAX))
	RETURNS VARCHAR(MAX)
	AS
	BEGIN
		RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@cadena,'1Âº','1º'),'NÂº','Nº'),'Âº','ú'),'Â',''),'Ãƒ',''),'å˜','ñ'),'Ã‘','Ñ'),'Ã', 'Á'),'Ã±', 'ñ'),'Ã¡', 'á'), 'Ã©', 'é'), 'Ãº', 'ú'), 'Ã³', 'ó'), 'Ã­', 'í')
	END

GO
	
CREATE OR ALTER FUNCTION ventas.fn_CalculaPrecioTotal(@facturaID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @precioTotal DECIMAL(10,2);
    
    SELECT @precioTotal = ISNULL(SUM(precio * cantidad), 0)
    FROM ventas.DetalleFactura
    WHERE facturaID = @facturaID;
    
    RETURN @precioTotal;
END
GO

CREATE OR ALTER FUNCTION utilidades.obtenerPrecioMoneda
	(@codigo CHAR(3))
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @precioActual DECIMAL(10,2)
	
	SET @precioActual = (SELECT valor FROM utilidades.Moneda WHERE codigo = @codigo)

	RETURN @precioActual
END;
GO

