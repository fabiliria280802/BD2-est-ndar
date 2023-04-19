/*
El siguiente script fue desarrollado por los estudiantes de la clase: ITIZ-2201 - BASE DE DATOS II – 3180 - 202302
El mismo será utilizado para diversos ejercicios planteados a lo largo de la materia

Fecha de creacion: 18-04-2023 21:00
Última versión: 19-04-2023 00:46

****************************************************************************************************
-- Verificacion de existencia de la base de datos y creacion de la misma
****************************************************************************************************
*/

-- Usar master para creacion de base.
USE Master
GO

-- Verificar si la base de datos LabX ya existe; si existe, eliminarla
IF EXISTS(SELECT name FROM sys.databases WHERE name = 'LabX')
BEGIN
    DROP DATABASE LabX;
END

CREATE DATABASE LabX;
GO

/*
****************************************************************************************************
-- Verificacion de existencia de reglas y tipos; creacion de las mismas
****************************************************************************************************
*/

-- Usar la base de datos LabX
USE LabX
GO

-- Validar si existe el tipo de dato correo y crear tipo de dato para correo electrónico
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'correo')
BEGIN
    DROP TYPE correo;
END

CREATE TYPE correo FROM varchar(320) NOT NULL 
GO

-- Validar si existe el tipo de dato cedulaIdentidad y crear tipo de dato para cedulaIdentidad
IF EXISTS(SELECT name FROM sys.systypes WHERE name = 'cedulaIdentidad')
BEGIN
    DROP TYPE cedulaIdentidad;
END

CREATE TYPE cedulaIdentidad FROM char(10) NOT NULL
GO

--  Validar si existe la regla "cedulaIdentidad_rule" y crear la regla
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'R' AND name = 'cedulaIdentidad_rule')
BEGIN
    DROP RULE cedulaIdentidad_rule;
END
GO

CREATE RULE cedulaIdentidad_rule AS @value LIKE '[2][0-4][0-5][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
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

-- Asociar tipo de dato "cedulaIdentidad" con regla "cedulaIdentidad_rule"
EXEC sp_bindrule 'cedulaIdentidad_rule', 'cedulaIdentidad';
GO

--  Validar si existe la regla "cedulaIdentidad_rule" y crear la regla
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'R' AND name = 'correo_rule')
BEGIN
    DROP RULE correo_rule;
END
GO

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

-- Asociar tipo de dato "correo" con regla "correo_rule"
EXEC sp_bindrule 'correo_rule', 'correo';
GO

/*
*******************************************************************************************************************************************************************
-- Creacion de tablas de la base de datos, no se eliminan las tablas una por una, ya que la validacion de su existencia esta realizada a nivel de la base de datos
*******************************************************************************************************************************************************************
*/

-- Creacion de tabla Paciente
CREATE TABLE Paciente (
    idUsuario SMALLINT IDENTITY(1,1) NOT NULL,

    cedula cedulaIdentidad NOT NULL UNIQUE,
    nombre NVARCHAR(55) NOT NULL,
    apellido NVARCHAR(55) NOT NULL,
    mail correo NOT NULL UNIQUE,
    telefono VARCHAR(15),
    fechaNacimiento DATE NOT NULL,
    tipoSangre VARCHAR(3) NOT NULL,
    usuarioRegistro NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Paciente PRIMARY KEY (idUsuario),
    CONSTRAINT CH_TipoSangre CHECK (tipoSangre IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    CONSTRAINT CH_Nombre CHECK (PATINDEX('%[0-9]%', nombre) = 0),
    CONSTRAINT CH_Apellido CHECK (PATINDEX('%[0-9]%', apellido) = 0),
    CONSTRAINT CH_Telefono CHECK (PATINDEX('%[^+0-9 ()-]%', telefono) = 0),
    CONSTRAINT CH_FechaNacimiento CHECK (fechaNacimiento <= GETDATE())
)
GO

-- Trigger que impide ingreso directo de un usuario del sistema
CREATE TRIGGER tr_UsuarioRegistro_Paciente
ON Paciente 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(usuarioRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar usuarios directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO

-- Trigger que impide ingreso directo de la fecha del registro de un paciente
CREATE TRIGGER tr_FechaRegistro_Paciente
ON Paciente 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(fechaRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar fechas de registro directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO


-- Creacion de tabla Examen
CREATE TABLE Examen (
    idExamen INT IDENTITY(1,1) NOT NULL,

    nombre VARCHAR(64) UNIQUE NOT NULL,
    minimoNormal DECIMAL(7, 3) NOT NULL,
    maximoNormal DECIMAL(7, 3) NOT NULL,
    ayuno BIT NOT NULL,
    diasResultado TINYINT NOT NULL,
    usuarioRegistro NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Examen PRIMARY KEY (idExamen),
    CONSTRAINT CH_DiasResultado CHECK (diasResultado IN (0,1,2,3)),
    CONSTRAINT CH_MinimoNormal CHECK (minimoNormal < maximoNormal)
)
GO

-- Trigger que impide ingreso directo de un usuario del sistema
CREATE TRIGGER tr_UsuarioRegistro_Examen
ON Examen 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(usuarioRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar usuarios directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO

-- Trigger que impide ingreso directo de la fecha del registro de un examen
CREATE TRIGGER tr_FechaRegistro_Examen
ON Examen 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(fechaRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar fechas de registro directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO

-- Creacion de tabla Resultado
CREATE TABLE Resultado (
    idResultado INT IDENTITY(1,1) NOT NULL, 

    idExamen INT NOT NULL,
    idUsuario SMALLINT NOT NULL,

    fechaPedido DATETIME NOT NULL,
    fechaExamen DATETIME NOT NULL,
    fechaEntrega DATETIME NOT NULL,

    resultado DECIMAL(7, 3) NOT NULL,
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    usuarioRegistro NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,

    CONSTRAINT PK_Resultado PRIMARY KEY (idResultado),
    CONSTRAINT FK_Examen FOREIGN KEY (idExamen) REFERENCES Examen(idExamen),
    CONSTRAINT FK_Paciente FOREIGN KEY (idUsuario) REFERENCES Paciente(idUsuario),

    CONSTRAINT CH_FechaEntrega CHECK (fechaEntrega >= fechaExamen),
    CONSTRAINT CH_fechaExamen CHECK(fechaExamen >= fechaPedido)
)
GO

-- Trigger que impide ingreso directo de un usuario del sistema
CREATE TRIGGER tr_UsuarioRegistro_Resultado
ON Resultado 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(usuarioRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar usuarios directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO

-- Trigger que impide ingreso directo de la fecha del registro de un Resultado
CREATE TRIGGER tr_FechaRegistro_Resultado
ON Resultado 
FOR INSERT, UPDATE
AS
BEGIN
  IF (SELECT COUNT(fechaRegistro) FROM inserted) <> 0 
  BEGIN
    RAISERROR ('No puede ingresar fechas de registro directamente', 16, 1)
    ROLLBACK TRANSACTION
  END
END
GO