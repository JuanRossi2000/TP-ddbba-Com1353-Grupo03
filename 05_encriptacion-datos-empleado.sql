USE Com1353G03

--1) SE AÑADEN LOS CAMPOS CIFRADOS EN FORMATO VARBINARY(256)
ALTER TABLE rrhh.Empleado
ADD apellido_Cifrado VARBINARY(256),
dni_Cifrado VARBINARY(256),
direccion_Cifrado VARBINARY(256),
email_Cifrado VARBINARY(256),
cuil_Cifrado VARBINARY(256);


--2) SE CREA UNA FRASE DE ENCRIPTACION Y SE PROCEDE A ENCRIPTAR LOS DATOS EN LOS CAMPOS CREADOS
DECLARE @Frase NVARCHAR(128);
SET @Frase = 'AL4GR4ND3L3PUS3CUC4';

--3) ENCRIPTACION DATOS EMPLEADO. SE UTILIZA LA FUNCION ENCRYPTBYPASSPHRASE.    
UPDATE rrhh.Empleado
SET apellido_Cifrado = EncryptByPassPhrase(@Frase, apellido),
dni_Cifrado = EncryptByPassPhrase(@Frase, CONVERT(VARCHAR(MAX), dni)),
direccion_Cifrado = EncryptByPassPhrase(@Frase, direccion),
email_Cifrado = EncryptByPassPhrase(@Frase, emailPersonal),
cuil_Cifrado = EncryptByPassPhrase(@Frase, CONVERT(VARCHAR(MAX), cuil));


--4) PARA VISUALIZAR LOS DATOS ENCRIPTADOS, SE UTILIZA LA FUNCION DECRYPTBYPASSPHRASE
SELECT CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE(@Frase, apellido_Cifrado))
	, CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE(@Frase, dni_cifrado))
	, CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE(@Frase, direccion_cifrado))
	, CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE(@Frase, email_cifrado))	
	, CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE(@Frase, cuil_cifrado))
FROM rrhh.Empleado

