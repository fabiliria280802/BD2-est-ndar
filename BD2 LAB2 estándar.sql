/*
****************************************************************************************************
-- Verificaciones de la base de datos y tipos
****************************************************************************************************
*/
-- Verificar si la base de datos EJERCICIODDL ya existe; si no existe, crearla
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name='LabX')
BEGIN
    CREATE DATABASE LabX
END
GO

/*
-- opcional???
--falta un if exists para verificar si la base de datos existe
SELECT *
FROM
    SYS.systypes --Desvincular una rule y tipo de dato
    sp_unbindrule 'cedula',
    'cedula_rule' DROP RULE cedula_rule
GO
*/

/*
****************************************************************************************************
-- Inicio del script de creacion
****************************************************************************************************
*/

-- Usar la base de datos EJERCICIODDL
USE LabX
GO

-- Crear tipo de dato para correo electrónico
CREATE TYPE correo FROM varchar(320) NOT NULL 
GO

-- Crear tipo de dato para cédula
CREATE TYPE cedula FROM char(10) NOT NULL
GO

--Script para crear la regla de la cedula
--Crear regla de para el tipo cedula
CREATE RULE cedula_rule AS @value LIKE '[2][0-4][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[1][0-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[0][1-9][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR @value LIKE '[3][0][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    AND SUBSTRING(@value, 3, 1) BETWEEN '0'
    AND '5'
    AND CAST(SUBSTRING(@value, 10, 1) AS INT) = (
        (
            2 * CAST(SUBSTRING(@value, 1, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 2, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 3, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 4, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 5, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 6, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 7, 1) AS INT) + 1 * CAST(SUBSTRING(@value, 8, 1) AS INT) + 2 * CAST(SUBSTRING(@value, 9, 1) AS INT)
        ) % 10
    )
GO
EXEC sp_bindrule 'cedula_rule', 'cedula';
GO

-- Script para crear la regla para el email
-- Crear regla de para el tipo mail
CREATE RULE correo_rule
AS
    @Correo LIKE '%@%' AND
    LEN(@Correo) <= 320 AND
    LEN(SUBSTRING(@Correo, 1, CHARINDEX('@', @Correo)-1)) BETWEEN 2 AND 64 AND --LA PARTE ANTES DEL '@' DEBE TENER ENTRE 2 Y 64 CARACTERES
    LEN(SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo))) BETWEEN 4 AND 255 AND --LA PARTE DESPUES DEL '@' DEBE TENER ENTRE 4 Y 255 CARACTERES
    SUBSTRING(@Correo, 1, 1) LIKE '[a-zA-Z0-9]' AND --VALIDA QUE EL PRIMER CARACTER SIEMPRE SEA UNA LETRA O NUMERO
    SUBSTRING(@Correo, LEN(@Correo), 1) NOT LIKE '[0-9]' AND --VALIDA QUE EL ULTIMO CARACTER NO SEA UN NUMERO
	SUBSTRING(@Correo, LEN(@Correo), 1) NOT LIKE '[-]' AND -- VALIDA QUE EL DOMINIO NO TERMINE CON '-'
	SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1,1) NOT LIKE '[-]' AND -- VALIDA QUE EL DOMINIO NO EMPIECE CON '-'
    NOT (@Correo LIKE '%..%') AND --VALIDA QUE NO HAYAN DOS PUNTOS SEGUIDOS
	NOT (@Correo LIKE '%@%@%') AND  -- VALIDA QUE NO HAYAN DOS ARROBAS
    SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo)) LIKE '%.[a-zA-Z][a-zA-Z][a-zA-Z]' OR -- VALIDA QUE LA EXTENSION DEL DOMINIO TENGA 4 CARACTERES
    SUBSTRING(@Correo, CHARINDEX('@', @Correo)+1, LEN(@Correo)-CHARINDEX('@', @Correo)) LIKE '%.[a-zA-Z][a-zA-Z]' -- VALIDA QUE LA EXTENSION DEL DOMINIO TENGA 3 CARACTERES 
GO
EXEC sp_bindrule 'correo_rule', 'correo';
GO

/*
****************************************************************************************************
--Script para la creacion de tablas
****************************************************************************************************
*/

--Script para la creacion de tabla Paciente
CREATE TABLE Paciente (
idPaciente SMALLINT IDENTITY(1,1) NOT NULL,
    cedula cedula NOT NULL UNIQUE,
    nombre varchar(55) NOT NULL,
    apellido varchar(55) NOT NULL,
    -- genero char(1) NOT NULL DEFAULT '-', --opcional?
    correo correo NOT NULL UNIQUE,
    telefono char(10),
    fechaNacimiento DATETIME NOT NULL,
    tipoSangre varchar(3) NOT NULL,
    usuarioRegistro nvarchar(128) NOT NULL DEFAULT SYSTEM_USER, -- HOST_NAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Paciente PRIMARY KEY (idPaciente),
    CONSTRAINT CH_TipoSangre CHECK (tipoSangre IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    -- CONSTRAINT CH_Genero CHECK (genero IN ('H', 'M', '-')), -- Definir restricción de género, opcional?
    CONSTRAINT CH_FechaNacimiento CHECK (fechaNacimiento < GETDATE())
)
GO

--Script para la creacion de tabla Examen
CREATE TABLE Examen (
    idExamen SMALLINT IDENTITY(1,1) NOT NULL, -- INT???

    nombre VARCHAR(50) UNIQUE NOT NULL,
    minimoNormal FLOAT NOT NULL,
    maximoNormal FLOAT NOT NULL,
    ayuno BIT NOT NULL,
    diasResultado TINYINT NOT NULL,
    usuarioRegistro nvarchar(128) NOT NULL DEFAULT SYSTEM_USER, -- HOST_NAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Examen PRIMARY KEY (idExamen),
    CONSTRAINT CH_DiasResultado CHECK (diasResultado IN (0,1,2,3))
)
GO

--Script para borrar tabla Examen
CREATE TABLE Resultado (
    idResultado SMALLINT IDENTITY(1,1), 

    idExamen SMALLINT NOT NULL,
    idPaciente SMALLINT NOT NULL,

    fechaPedido DATE NOT NULL DEFAULT GETDATE(),
    fechaExamen DATE NOT NULL,
    fechaEntrega DATE NOT NULL,
    resultado NUMERIC(10,2) NOT NULL,
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    usuarioRegistro nvarchar(128) NOT NULL DEFAULT SYSTEM_USER, -- HOST_NAME(),

    CONSTRAINT PK_Resultado PRIMARY KEY (idResultado),
    CONSTRAINT FK_Examen FOREIGN KEY (idExamen) REFERENCES Examen(idExamen),
    CONSTRAINT FK_Paciente FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
    CONSTRAINT CH_FechaEntrega CHECK (fechaEntrega >= fechaExamen),
    CONSTRAINT CH_fechaExamen CHECK(fechaExamen >= fechaPedido)
)
GO

/*
****************************************************************************************************
-- Validaciones de creacion de tablas y tipos
****************************************************************************************************
*/

/*
****************************************************************************************************
-- Validaciones de insercion de datos
****************************************************************************************************
*/

/*
****************************************************************************************************
-- Validaciones extras
****************************************************************************************************
*/
