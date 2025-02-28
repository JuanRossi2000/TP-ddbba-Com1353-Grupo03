--Crear la Master Key de la base de datos 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TuContraseñaMuySegura';
GO

--Crear el certificado para encriptación
CREATE CERTIFICATE CertificadoEmpleados
WITH SUBJECT = 'Certificado para encriptacion de datos de empleados';
GO

--Crear la clave simétrica utilizando el certificado
CREATE SYMMETRIC KEY ClaveSimetricaEmpleados
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoEmpleados;
GO

--Respaldar el certificado y su clave privada (ajusta la ruta y contraseña según tu entorno)
BACKUP CERTIFICATE CertificadoEmpleados
TO FILE = 'C:\Backups\CertificadoEmpleados.cer'
WITH PRIVATE KEY (
    FILE = 'C:\Backups\CertificadoEmpleados_PrivateKey.pvk',
    ENCRYPTION BY PASSWORD = 'OtraContraseñaMuySegura'
);
GO

--Agregar columnas para almacenar los datos encriptados
ALTER TABLE rrhh.Empleado 
  ADD dni_encriptado VARBINARY(256),
      direccion_encriptada VARBINARY(256),
      emailPersonal_encriptado VARBINARY(256),
      cuil_encriptado VARBINARY(256);
GO

--Abrir la llave simétrica para encriptar los datos
OPEN SYMMETRIC KEY ClaveSimetricaEmpleados
DECRYPTION BY CERTIFICATE CertificadoEmpleados;
GO
--AHORA ME VEN
--Encriptar y actualizar los datos en la tabla
UPDATE rrhh.Empleado
SET 
    dni_encriptado = ENCRYPTBYKEY(
                         KEY_GUID('ClaveSimetricaEmpleados'), 
                         CONVERT(VARBINARY(256), CAST(dni AS VARCHAR(50)))
                      ),
    direccion_encriptada = ENCRYPTBYKEY(
                              KEY_GUID('ClaveSimetricaEmpleados'), 
                              CONVERT(VARBINARY(256), direccion)
                           ),
    emailPersonal_encriptado = ENCRYPTBYKEY(
                                 KEY_GUID('ClaveSimetricaEmpleados'), 
                                 CONVERT(VARBINARY(256), emailPersonal)
                              ),
    cuil_encriptado = ENCRYPTBYKEY(
                         KEY_GUID('ClaveSimetricaEmpleados'), 
                         CONVERT(VARBINARY(256), CAST(cuil AS VARCHAR(50)))
                      );
GO

--Cerrar la llave simétrica
CLOSE SYMMETRIC KEY ClaveSimetricaEmpleados;
GO

--Eliminar las columnas originales (ya que ahora están encriptadas)
ALTER TABLE rrhh.Empleado DROP COLUMN dni, direccion, emailPersonal, cuil;
GO

--Renombrar las columnas encriptadas para que conserven los nombres originales
EXEC sp_rename 'rrhh.Empleado.dni_encriptado', 'dni', 'COLUMN';
EXEC sp_rename 'rrhh.Empleado.direccion_encriptada', 'direccion', 'COLUMN';
EXEC sp_rename 'rrhh.Empleado.emailPersonal_encriptado', 'emailPersonal', 'COLUMN';
EXEC sp_rename 'rrhh.Empleado.cuil_encriptado', 'cuil', 'COLUMN';
GO

SELECT * FROM rrhh.Empleado;
GO
--AHORA NO ME VEN


-- DESENCRIPTADO
--Abrir la llave simétrica para desencriptar los datos
OPEN SYMMETRIC KEY ClaveSimetricaEmpleados
DECRYPTION BY CERTIFICATE CertificadoEmpleados;
GO

--Consultar la tabla y desencriptar los datos
SELECT 
    CONVERT(VARCHAR(256), DECRYPTBYKEY(dni)) AS dni,
    CONVERT(VARCHAR(256), DECRYPTBYKEY(direccion)) AS direccion,
    CONVERT(VARCHAR(256), DECRYPTBYKEY(emailPersonal)) AS emailPersonal,
    CONVERT(VARCHAR(256), DECRYPTBYKEY(cuil)) AS cuil
FROM rrhh.Empleado;
GO

-- Cerrar la llave simétrica una vez terminada la operación
CLOSE SYMMETRIC KEY ClaveSimetricaEmpleados;
GO
