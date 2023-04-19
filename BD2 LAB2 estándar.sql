--Script para usar el master
USE MASTER
GO

--Script para crear una base de datos llamada Lab1
CREATE DATABASE LabX
SELECT * FROM SYS.sysdatabases
SELECT * FROM SYS.systypes

--Script para la creación de tipos de datos
CREATE TYPE mail 
FROM VARCHAR(320);
CREATE TYPE cedula
FROM VARCHAR(10);

------------------------------------------------------------------
--Script para crear la regla de la cédula
--Crear regla de para el tipo cedula
CREATE RULE cedula_rule AS
@value LIKE '[2][0-4][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR
@value LIKE '[1][0-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR
@value LIKE '[0][1-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR
@value LIKE '[3][0][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
AND SUBSTRING(@value, 3, 1) BETWEEN '0' AND '5'
AND CAST(SUBSTRING(@value, 10, 1) AS INT) = 
		((2 * CAST(SUBSTRING(@value, 1, 1) AS INT) +
          1 * CAST(SUBSTRING(@value, 2, 1) AS INT) +
          2 * CAST(SUBSTRING(@value, 3, 1) AS INT) +
          1 * CAST(SUBSTRING(@value, 4, 1) AS INT) +
          2 * CAST(SUBSTRING(@value, 5, 1) AS INT) +
          1 * CAST(SUBSTRING(@value, 6, 1) AS INT) +
          2 * CAST(SUBSTRING(@value, 7, 1) AS INT) +
          1 * CAST(SUBSTRING(@value, 8, 1) AS INT) +
          2 * CAST(SUBSTRING(@value, 9, 1) AS INT)) % 10);

--Verficar creación de la regla
SELECT * FROM SYS.sysobjects
WHERE xtype = 'R'

--Verificar como se definio la regla
sp_helptext cedula_rule

--Otra forma es revisar
SELECT* FROM SYS.syscomments

--Enlace del tipo de dato y regla
sp_bindrule cedula_rule, 'cedula'

--Verificar regla enlazada
SELECT * FROM SYS.systypes

--Desvincular una rule y tipo de dato
sp_unbindrule 'cedula','cedula_rule'
DROP RULE cedula_rule;
------------------------------------------------------------------

--Script para crear la regla para el email
--Crear regla de para el tipo mail
CREATE RULE mail_rule AS
@value LIKE '%_@_%.__%' AND @value NOT LIKE '%@%@%';

--Verficar creación de la regla
SELECT * FROM SYS.sysobjects
WHERE xtype = 'R'

--Verificar como se definio la regla
sp_helptext mail_rule

--Otra forma de verificar:
SELECT* FROM SYS.syscomments

--Enlace del tipo de dato y regla
sp_bindrule mail_rule, 'mail'

--Verificar regla enlazada
SELECT * FROM SYS.systypes
-------------------------------------------------------------------

--Script para la creación de tabla Paciente
CREATE TABLE Paciente (
    idUsuario SMALLINT IDENTITY NOT NULL,
    cedula cedula NOT NULL,
    nombre VARCHAR(20) NOT NULL,
    apellido VARCHAR(25) NOT NULL,
    mail mail NOT NULL,
    telefono CHAR(10),
    fechaNacimiento DATE NOT NULL,
    tipoSangre VARCHAR(3) NOT NULL,
    usuarioRegistro VARCHAR(50) DEFAULT USER NOT NULL,
    fechaRegistro DATE DEFAULT GETDATE() NOT NULL,
	CONSTRAINT PK_idUsuario PRIMARY KEY (idUsuario),
	CONSTRAINT CH_fechaNacimiento CHECK (fechaNacimiento < GETDATE()),
	CONSTRAINT CH_tipoSangre CHECK (tipoSangre IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'))
);

--Script para borrar tabla Paciente
DROP TABLE IF EXISTS Paciente

--Script para ver los insert de la tabla Paciente
SELECT * FROM  Paciente

--Script para la creación de tabla Examen
CREATE TABLE Examen (
    idExamen SMALLINT IDENTITY NOT NULL,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    minimoNormal NUMERIC(10, 2) NOT NULL,
    maximoNormal NUMERIC(10, 2) NOT NULL,
    ayuno BIT NOT NULL,
    diasResultado INT CHECK (diasResultado IN (0, 1, 2, 3)) NOT NULL,
    usuarioRegistro VARCHAR(50) DEFAULT USER NOT NULL,
    fechaRegistro DATE DEFAULT GETDATE() NOT NULL,
	CONSTRAINT PK_Examen PRIMARY KEY (idExamen)
);

--Script para borrar tabla Examen
DROP TABLE IF EXISTS Examen

--Script para ver los insert de la tabla Examen
SELECT * FROM  Examen

--Script para la creación de tabla Resultado
CREATE TABLE Resultado (
    idResultado SMALLINT IDENTITY NOT NULL,
    idUsuario SMALLINT NOT NULL,
    idExamen SMALLINT NOT NULL,
    fechaPedido DATE NOT NULL DEFAULT GETDATE(),
    fechaExamen DATE NOT NULL,
    resultado NUMERIC(10, 2) NOT NULL,
    fechaEntrega DATE NOT NULL,
    usuarioRegistro VARCHAR(50) DEFAULT USER NOT NULL,
    fechaRegistro DATE DEFAULT GETDATE(),
	CONSTRAINT PK_Resuldado PRIMARY KEY (idResultado),
    CONSTRAINT FK_Resultado_Usuario FOREIGN KEY (idUsuario) REFERENCES Paciente (idUsuario),
    CONSTRAINT FK_Resultado_Examen FOREIGN KEY (idExamen) REFERENCES Examen (idExamen),
	CONSTRAINT CH_fechaExamen CHECK(fechaExamen >= fechaPedido),
	CONSTRAINT CH_fechaEntrega CHECK(fechaEntrega >= fechaExamen)
);

--Script para borrar tabla Resultado
DROP TABLE IF EXISTS Resultado

--Script para ver los insert de la tabla Resultado
SELECT * FROM  Resultado


