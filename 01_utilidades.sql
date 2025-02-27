--FUNCION QUE UTILIZARA EL PROCEDURE reporteMensualPorTrimestreTurno

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('utilidades.getTrimestre') AND type = 'FN')
BEGIN
	EXEC('CREATE FUNCTION utilidades.getTrimestre
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
			END;');
END;
GO

--FUNCION PARA GENERAR CUIL DE EMPLEADOS
IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('utilidades.GenerarCuil') AND type = 'FN')
BEGIN
	EXEC('CREATE FUNCTION utilidades.GenerarCuil(@dni INT)
	RETURNS VARCHAR(11)
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
	END;');
END;
GO

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('utilidades.remplazar') AND type = 'FN')
BEGIN
	EXEC('CREATE FUNCTION utilidades.remplazar (@cadena VARCHAR(MAX))
	RETURNS VARCHAR(MAX)
	AS
	BEGIN
		RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@cadena, ''Ã±'', ''ñ''), ''Ã¡'', ''á''), ''Ã©'', ''é''), ''Ãº'', ''ú''), ''Ã³'', ''ó''), ''Ã­'', ''í''), ''Â'', '''')
	END');
END;
GO

IF NOT EXISTS(SELECT 1 FROM sys.triggers WHERE name = 'actualizaPrecioTotal' AND parent_class_desc = 'OBJECT_OR_COLUMN')
BEGIN
	EXEC('CREATE OR ALTER TRIGGER ventas.actualizaPrecioTotal ON ventas.DetalleFactura AFTER INSERT, UPDATE
	AS
	BEGIN
		UPDATE ventas.Factura
		SET precioTotal = (
			SELECT ISNULL(SUM(df.precio * df.cantidad), 0)
			FROM ventas.DetalleFactura df
			WHERE df.facturaID = Factura.id
		)
		WHERE Factura.id IN (SELECT DISTINCT facturaID FROM inserted);
	END');
END;
GO