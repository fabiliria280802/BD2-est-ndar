/*
El siguiente script fue desarrollado por los estudiantes de la clase: ITIZ-2201 - BASE DE DATOS II – 3180 - 202302
El mismo será utilizado para diversos ejercicios planteados a lo largo de la materia

Fecha de creacion: 18-04-2023 21:00
Última versión: 19-04-2023 15:38

**********************************
-- Verificacion de existencia de la base de datos y creacion de la misma
**********************************
*/

-- Usar master para creación de base.
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
**********************************
-- Verificacion de existencia de reglas y tipos; creacion de las mismas
**********************************
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

-- Creación de la regla que valide que el tipo de dato cedulaIdentidad siga los parámetros de una cédula de identidad Ecuatoriana
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

-- Creación de la regla que valide que el tipo de dato correo siga los parámetros requeridos por un email.
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
*******************************************************
-- Creacion de tablas de la base de datos, no se eliminan las tablas una por una, ya que la validacion de su existencia esta realizada a nivel de la base de datos
*******************************************************
*/

-- Creacion de tabla Paciente
CREATE TABLE Paciente (
    idUsuario SMALLINT IDENTITY(1,1) NOT NULL,

    cedula cedulaIdentidad NOT NULL UNIQUE,
    nombre NVARCHAR(55) NOT NULL,
    apellido NVARCHAR(55) NOT NULL,
    mail correo NOT NULL UNIQUE,
    telefono VARCHAR(16),
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

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_Paciente')
BEGIN
    DROP TRIGGER tr_Paciente
END
GO
-- Trigger que impide ingreso directo de un usuario del sistema
CREATE TRIGGER tr_Paciente
ON Paciente 
FOR INSERT, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM inserted) > 1
	BEGIN
		RAISERROR('No se puede ingresar multiples valores al mismo tiempo',16,10)
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) AND (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar usuarios y fecha directamente', 16, 1)
			ROLLBACK TRANSACTION
		END
		ELSE IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) OR (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar el registro', 16, 1)
			ROLLBACK TRANSACTION
		END
	END
END
GO

-- Creación de tabla Examen
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

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_Examen')
BEGIN
    DROP TRIGGER tr_Examen
END
GO
-- Trigger que impide ingreso directo de un usuario del sistema
CREATE TRIGGER tr_Examen
ON Examen
FOR INSERT, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM inserted) > 1
	BEGIN
		RAISERROR('No se puede ingresar multiples valores al mismo tiempo',16,10)
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) AND (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar usuarios y fecha directamente', 16, 1)
			ROLLBACK TRANSACTION
		END
		ELSE IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) OR (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar el registro', 16, 1)
			ROLLBACK TRANSACTION
		END
	END
END
GO

-- Creación de tabla Resultado
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

--Verificar si existe el Trigger
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'TR' AND name = 'tr_Resultado')
BEGIN
    DROP TRIGGER tr_Resultado
END
GO
-- Trigger que impide ingreso directo de un usuario o fecha del sistema 
CREATE TRIGGER tr_Resultado
ON Resultado 
FOR INSERT, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM inserted) > 1
	BEGIN
		RAISERROR('No se puede ingresar multiples valores al mismo tiempo',16,10)
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) AND (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar usuarios y fecha directamente', 16, 1)
			ROLLBACK TRANSACTION
		END
		ELSE IF ((SELECT usuarioRegistro FROM inserted) <> SYSTEM_USER) OR (DATEDIFF(second, (SELECT fechaRegistro FROM inserted), GETDATE()) >= 5)
		BEGIN
			RAISERROR ('No puede ingresar el registro', 16, 1)
			ROLLBACK TRANSACTION
		END
	END
END
GO
/*
**********************************
-- Procedimiento almacenado que controla el ingreso de tuplas en la tabla Resultado
**********************************
*/

--Verificar si existe el Procedimiento Almacenado
IF EXISTS(SELECT name FROM sys.objects WHERE type = 'P' AND name = 'ingresoResultado')
BEGIN
    DROP PROCEDURE ingresoResultado
END
GO
--Creación de un Procedimiento Almacenado que permita ingresar un registro a la tabla Resultado, 
--a través de la cédula del paciente, y el nombre del examen. 
CREATE PROCEDURE ingresoResultado
	--Se declaran los argumentos que recibe el procedimiento almacenado
	@nombreExamen VARCHAR(64),
    @ciPaciente cedulaIdentidad,
    @fechaPedido DATETIME,
    @fechaExamen DATETIME,
    @fechaEntrega DATETIME,
    @resultado DECIMAL(7, 3)
AS
	--Se verifica si existe el examen que se está intentando ingresar.
	IF (SELECT COUNT(*) FROM Examen WHERE nombre = @nombreExamen) = 0
	BEGIN
		RAISERROR('El nombre del examen no existe',16,10)
	END
	ELSE
	BEGIN
		--Se verifica si existe un paciente con esa cédula que se está intentando ingresar. 
		IF (SELECT COUNT(*) FROM Paciente WHERE cedula = @ciPaciente) = 0
		BEGIN
			RAISERROR('La cédula ingresada no existe',16,10)
		END
		ELSE
		BEGIN
			--Si el examen y la cédula existen, se obtiene el id del paciente y el id del examen. 
			DECLARE @idPaciente SMALLINT
			DECLARE @idExamen INT

			SET @idPaciente = (SELECT idUsuario FROM Paciente WHERE cedula = @ciPaciente);
			SET @idExamen = (SELECT idExamen FROM Examen WHERE nombre = @nombreExamen);
			
			--Se realiza la inserción de la tupla en la tabla Resultado.
			INSERT INTO Resultado(idExamen,idUsuario,fechaPedido,fechaExamen, fechaEntrega, resultado) 
			VALUES(@idExamen,@idPaciente,@fechaPedido,@fechaExamen,@fechaEntrega,@resultado)
		END
	END
GO
/*
**********************************
-- Inserción de datos en tablas de la base de datos
**********************************
*/
-- Ingreso de datos en la tabla Paciente
--Javier M
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1102508772', 'Juan', 'Pérez', 'juanperezelgrande@hotmail.com', '09912367228', '1980-05-25', 'O+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0912390649', 'María', 'González', 'mariag_gonzalez@gmail.com', '+593 0994586775', '1995-12-08', 'B-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0703521160', 'Pedro', 'Ramírez', 'ppramirez@udla.edu.ec', '02 2448337', '1974-02-14', 'AB+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0801567892', 'Ana', 'García', 'anagarcia1234@uide.edu.ec', '0995672889', '1988-08-01', 'A-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0502479531', 'Luis', 'Martínez', 'luismartinez18@epn.edu.ec', '+1 212-555-0123', '1965-11-03', 'B+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1204870963', 'Sara', 'López', 'saralopez@usfq.edu.ec', '+58 212-555-0123', '2000-07-20', 'A+')
--Adrian
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1104491862', 'Juan', 'Perez', 'jperez@gmail.com', '0991234567', '1995-02-14', 'O+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1758326503', 'Maria', 'Gonzalez', 'mgonzalez@hotmail.com', '0987654321', '1989-07-27', 'A-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0923081847', 'Luis', 'Martinez', 'lmartinez@yahoo.com', '0954321098', '1978-10-09', 'AB-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0911276548', 'Ana', 'Sanchez', 'asanchez@gmail.com', '0967890123', '2001-05-22', 'B+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1705682925', 'Pedro', 'Castro', 'pcastro@hotmail.com', '0976543210', '1990-12-03', 'O-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1301167859', 'Carla', 'Valencia', 'cvalencia@yahoo.com', '0987654321', '1985-03-18', 'A+')
--Xavi
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1721694285', 'Rodrigo', 'Sanchez', 'rodri@gmail.com', '0998716545', '08-15-1960', 'AB+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1705862756', 'Maria', 'Brown', 'mary@gmail.com', '0995599166', '04-16-1985', 'A+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, fechaNacimiento, tipoSangre) VALUES ('1741643297', 'Sofia', 'Perez', 'sfi19@gmail.com', '11-04-2003', 'O+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0400609954', 'Mariana', 'Rodriguez', 'marir@gmail.com', '0961523478', '01-19-1984', 'O+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0412864712', 'Cristian', 'Wilson', 'cwilson@gmail.com', '0956241873', '05-26-2002', 'A+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, fechaNacimiento, tipoSangre) VALUES ('1708071024', 'Jose', 'Davies', 'pepedav@gmail.com', '08-15-1960', 'O+')
--Sebas A
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0913876254', 'Carla', 'Sánchez', 'carlasanchez@hotmail.com', '0998765432', '1985-01-15', 'A-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1209567834', 'Julio', 'Herrera', 'julioherrera@gmail.com', '022246541', '1992-07-08', 'AB+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0913672541', 'Elena', 'Vargas', 'elenavargas@espol.edu.ec', '+593 998765432', '1978-06-20', 'B-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0912486597', 'Fernando', 'Ortiz', 'fortiz_1990@gmail.com', '+593 987654321', '1990-09-12', 'O+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1203567890', 'Camila', 'Torres', 'camilatorres_10@hotmail.com', '022248764', '1987-03-24', 'B+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1202754813', 'Andrés', 'López', 'andreslopez1995@gmail.com', '+593 996541238', '1995-12-16', 'A+');
--Alex
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1754446720', 'Anita', 'Mendez', 'anitamz@gmail.com', '0983715522', '2008-06-12', 'O-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1303753618', 'Bernardo', 'Lopez', 'bernlo@hotmail.com', '0987544896', '2018-02-01', 'B-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1103756134', 'Paul', 'Aguilera', 'paulera2014@hotmail.com', '0987544896', '2014-09-22', 'AB-')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1305267542', 'Oswaldo', 'Almeida', 'oswalmeida4687@udla.edu.ec', '0999888754', '2000-02-15', 'A+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1200984761', 'Marco', 'Alarcon', 'marcoalarkOk@usfq.edu.ec', '0989622101', '1997-04-03', 'O+')
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1711402980', 'Adrian', 'Altamirano', 'AdrianAlt2004@usfq.edu.ec', '0989622101', '2004-03-11', 'B+')
--David
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1101234567', 'María', 'García', 'mgarcia@gmail.com', '0991234567', '2000-05-20', 'AB+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1202345678', 'Juan', 'Pérez', 'jperez@hotmail.com', NULL, '1995-02-10', 'A-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1703456789', 'Pedro', 'Gómez', 'pgomez@yahoo.com', '0987654321', '1980-12-25', 'O+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1404567890', 'Lucía', 'Moreno', 'lmoreno@gmail.com', NULL, '1978-08-15', 'B-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1701710699', 'Jorge', 'Vega', 'jvega@hotmail.com', '0998765432', '1965-04-30', 'O-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0906789012', 'Laura', 'Fernández', 'lfernandez@yahoo.com', '0987654321', '1992-11-07', 'B+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1728174101', 'Jadira', 'Rodriguez', 'jrodri@gmail.com', '0983365449', '2003-01-11', 'O+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1709693251', 'Pablo', 'Quiroz', 'quiroz22@gmail.com', '0987794187', '2000-08-31', 'O-');
--Cristopher
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1726955550', 'Kelly', 'Hernández', 'hernandezkd@uce.edu.ec', '0992823322', '2000-08-02', 'O-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('0606925350', 'Daniela', 'Pozo', 'elapozoc2002@outlook.com', '02912402', '2002-01-10', 'B+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1711044210', 'Melchor', 'Gualan', 'melchorgualan@udla.edu.ec', '0997506111', '1980-02-02', 'O-');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1726964342', 'Ana', 'Jativa', 'anajativa@outlook.com', '0996002328', '2003-02-21', 'B+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1711044213', 'Cesar', 'Herrera', 'cesarherrera@udla.edu.ec', '0997506114', '1970-02-02', 'O+');
INSERT INTO Paciente (cedula, nombre, apellido, mail, telefono, fechaNacimiento, tipoSangre) VALUES ('1726964347', 'Luke', 'Yepez', 'lukeyepez@outlook.com', '0996002321', '2002-02-21', 'B+');
GO

-- Ingreso de datos en la tabla Examen
--Javier M
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de glucosa', 70.000, 99.999, 1, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Perfil Lipídico', 100.000, 199.999, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de orina', 0.000, 10.000, 0, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Hemograma completo', 3.500, 11.000, 1, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de tiroides', 0.400, 4.000, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de creatinina', 0.700, 1.400, 1, 1)
--Adrian Falta
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Eamen de Colesterol', 0.00, 200.00, 1, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de Hemoglobina', 12.00, 16.00, 0, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de Ácido Úrico', 3.50, 7.20, 0, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Prueba de Calcio', 8.50, 10.50, 0, 2)
--Xavi
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Conteo de glóbulos rojos', '4.7', '6.1', '0', '0')
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Conteo de glóbulos blancos', '4.5', '11.0', '0', '0')
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Análisis de colesterol', '125', '200', '1', '2')
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Prueba A1C', '3', '5.7', '1', '2')
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Análisis de TSH-T3', '1.2 ', '2.7', '0', '3')
INSERT INTO Examen (nombre,minimoNormal,maximoNormal,ayuno,diasResultado) VALUES ('Prueba de función renal', '0.5', '1.2', '0', '1')
--Sebas A
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de presión arterial', 80.000, 120.000, 1, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de colesterol', 130.000, 200.000, 1, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de función hepática', 0.000, 40.000, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de glucosa postprandial', 100.000, 140.000, 0, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de orina completa', 0.000, 2.000, 0, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de ácido úrico', 2.500, 6.200, 1, 3)
--Alex
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de Electroforesis de hemoglobina', 0.60, 0.99, 1, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de bilirrubina', 0.1, 0.3, 0, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de albumina', 3.4, 5.4, 0, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de proteinas totales', 6.0, 8.3, 1, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de trigliceridos', 150, 199, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de alanina', 4, 36, 0, 2)
--Ismael J
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Bilirrubina total', 0.000, 1.000, 0, 2)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Fibrinogeno', 200.000, 450.000, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Acido urico', 3.000, 6.999, 0, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Glucosa', 70.000, 119.999, 0, 1)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Trigliceridos', 45.000, 179.000, 1, 3)
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Calcio renal', 8.600, 10.700, 0, 2)
--David
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Hemoglobina', 12.0, 18.0, 0, 2);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Glucemia', 70.0, 110.0, 8, 1);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Colesterol', 125.0, 200.0, 12, 3);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('HDL', 40.0, 60.0, 12, 3);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('LDL', 0.0, 130.0, 12, 3);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Vitamina D', 20.0, 50.0, 8, 2);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('TSH', 0.4, 4.0, 8, 2);
INSERT INTO Examen(nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Creatinina', 0.6, 1.2, 12, 3);
--Cristopher
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ( 'Examen de coagulación', 10.000, 13.000, 1, 2);
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Examen de hormonas sexuales', 200.000, 800.000, 1, 3);
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ( 'Prueba de amilasa', 1.000, 137.000, 1, 2);
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Prueba de anticuerpos antinucleares', 11.000, 75.000, 1, 3);
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ( 'Prueba de inmunofijación', 40.000, 180.000, 1, 3);
INSERT INTO Examen (nombre, minimoNormal, maximoNormal, ayuno, diasResultado) VALUES ('Prueba de la médula ósea', 15.000, 100.000, 1, 2);
GO

--Ingreso de datos en la tabla Resultado
--Javier M
EXECUTE ingresoResultado 'Hemograma completo', '1102508772', '2023-04-19 09:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','7500'
--Adrian Falta
EXECUTE ingresoResultado 'Examen de glucosa', '1102508772', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-21 10:00:00','90'
EXECUTE ingresoResultado 'Examen de tiroides', '0912390649', '2023-04-19 11:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','2.5'
EXECUTE ingresoResultado 'Perfil Lipídico', '0912390649', '2023-04-19 12:00:00','2023-04-22 12:00:00','2023-04-25 12:00:00','175'
EXECUTE ingresoResultado 'Examen de orina', '0703521160', '2023-04-19 13:00:00','2023-04-21 13:00:00','2023-04-23 13:00:00','7'
EXECUTE ingresoResultado 'Examen de creatinina', '0703521160', '2023-04-19 14:00:00','2023-04-20 14:00:00','2023-04-21 14:00:00','0.9'
EXECUTE ingresoResultado 'Hemograma completo', '0801567892', '2023-04-19 15:00:00','2023-04-21 15:00:00','2023-04-23 15:00:00','6500'
EXECUTE ingresoResultado 'Examen de glucosa', '0801567892', '2023-04-19 16:00:00','2023-04-20 16:00:00','2023-04-21 16:00:00','100'
EXECUTE ingresoResultado 'Examen de tiroides', '0502479531', '2023-04-19 17:00:00','2023-04-20 17:00:00','2023-04-22 17:00:00','1.8'
EXECUTE ingresoResultado 'Hemograma completo', '0912390649', '2023-04-19 09:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','9000'
EXECUTE ingresoResultado 'Examen de glucosa', '1102508772', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-21 10:00:00','93.333'
EXECUTE ingresoResultado 'Examen de tiroides', '0703521160', '2023-04-19 11:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','0.666'
EXECUTE ingresoResultado 'Perfil Lipídico', '1102508772', '2023-04-19 12:00:00','2023-04-22 12:00:00','2023-04-25 12:00:00','160'
EXECUTE ingresoResultado 'Examen de orina', '1102508772', '2023-04-19 13:00:00','2023-04-21 13:00:00','2023-04-23 13:00:00','3'
EXECUTE ingresoResultado 'Examen de creatinina', '0703521160', '2023-04-19 14:00:00','2023-04-20 14:00:00','2023-04-21 14:00:00','1'
EXECUTE ingresoResultado 'Hemograma completo', '1204870963', '2023-04-19 15:00:00','2023-04-21 15:00:00','2023-04-23 15:00:00','6800'
EXECUTE ingresoResultado 'Examen de glucosa', '1204870963', '2023-04-19 16:00:00','2023-04-20 16:00:00','2023-04-21 16:00:00','65'
EXECUTE ingresoResultado 'Examen de tiroides', '1102508772', '2023-04-19 17:00:00','2023-04-20 17:00:00','2023-04-22 17:00:00','2.8'
--Xavi
EXECUTE ingresoResultado 'Conteo de glóbulos blancos','1721694285','05-29-2022 11:00:00','05-30-2022 11:00:00','05-30-2022 11:00:00','6.2'
EXECUTE ingresoResultado 'Análisis de colesterol','1721694285','05-29-2022 11:00:00','05-30-2022 11:00:00','05-31-2022 11:00:00','130'
EXECUTE ingresoResultado 'Prueba A1C','1705862756','02-18-2022 12:00:00','02-20-2022 12:00:00','02-22-2022 15:00:00','3.2'
EXECUTE ingresoResultado 'Conteo de glóbulos rojos','1705862756','02-18-2022 12:00:00','02-20-2022 12:30:00','02-20-2022 15:00:00','5.4'
EXECUTE ingresoResultado 'Análisis de colesterol','1705862756','02-18-2022 12:00:00','02-20-2022 13:00:00','02-22-2022 15:00:00','150'
EXECUTE ingresoResultado 'Prueba de función renal','1741643297','06-15-2022 9:00:00','06-18-2022 9:00:00','06-19-2022 11:00:00','0.7'
EXECUTE ingresoResultado 'Conteo de glóbulos blancos','1741643297','06-15-2022 9:00:00','06-18-2022 9:30:00','06-18-2022 11:00:00','10.5'
EXECUTE ingresoResultado 'Conteo de glóbulos rojos','1741643297','06-15-2022 9:00:00','06-18-2022 10:00:00','06-18-2022 11:00:00','4.7'
EXECUTE ingresoResultado 'Conteo de glóbulos blancos','0400609954','10-04-2022 15:00:00','10-10-2022 15:00:00','10-10-2022 15:00:00','4.6'
EXECUTE ingresoResultado 'Análisis de colesterol','0400609954','10-04-2022 15:00:00','10-10-2022 15:00:00','10-12-2022 15:00:00','160'
EXECUTE ingresoResultado 'Prueba A1C','0400609954','10-04-2022 15:00:00','10-10-2022 15:00:00','10-12-2022 15:00:00','5.4'
EXECUTE ingresoResultado 'Análisis de colesterol','0412864712','11-01-2022 16:00:00','11-20-2022 16:00:00','11-22-2022 16:00:00','190'
EXECUTE ingresoResultado 'Análisis de TSH-T3','0412864712','11-01-2022 16:00:00','11-20-2022 16:30:00','11-23-2022 16:00:00','1.3'
EXECUTE ingresoResultado 'Prueba de función renal','0412864712','11-01-2022 16:00:00','11-20-2022 15:00:00','11-21-2022 16:00:00','1.1'
EXECUTE ingresoResultado 'Prueba A1C','1708071024','12-12-2022 08:00:00','12-23-2022 08:00:00','12-25-2022 08:00:00','4.4'
EXECUTE ingresoResultado 'Análisis de TSH-T3','1708071024','12-12-2022 08:00:00','12-23-2022 08:15:00','12-26-2022 08:00:00','2.6'
EXECUTE ingresoResultado 'Prueba de función renal','1708071024','12-12-2022 08:00:00','12-23-2022 08:30:00','12-24-2022 08:00:00','0.9'
EXECUTE ingresoResultado 'Conteo de glóbulos rojos','0412864712','01-29-2023 09:00:00','02-10-2023 09:00:00','02-10-2023 09:00:00','6.1'
EXECUTE ingresoResultado 'Conteo de glóbulos blancos','0400609954','02-26-2023 12:00:00','03-05-2023 13:00:00','03-05-2023 14:00:00','5.5'
--Sebas A
EXECUTE ingresoResultado 'Hemograma completo', '1102508772', '2023-04-19 09:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','7500'
EXECUTE ingresoResultado 'Examen de Electroforesis de hemoglobina', '1102508772', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-21 10:00:00','90'
EXECUTE ingresoResultado 'Examen de tiroides', '0912390649', '2023-04-19 11:00:00','2023-04-20 11:00:00','2023-04-22 11:00:00','2.5'
EXECUTE ingresoResultado 'Perfil Lipídico', '0912390649', '2023-04-19 12:00:00','2023-04-22 12:00:00','2023-04-25 12:00:00','175'
EXECUTE ingresoResultado 'Examen de orina', '0703521160', '2023-04-19 13:00:00','2023-04-21 13:00:00','2023-04-23 13:00:00','7'
EXECUTE ingresoResultado 'Examen de creatinina', '0703521160', '2023-04-19 14:00:00','2023-04-20 14:00:00','2023-04-21 14:00:00','0.9'
EXECUTE ingresoResultado 'Hemograma completo', '0801567892', '2023-04-19 15:00:00','2023-04-21 15:00:00','2023-04-23 15:00:00','6500'
EXECUTE ingresoResultado 'Examen de glucosa', '0801567892', '2023-04-19 16:00:00','2023-04-20 16:00:00','2023-04-21 16:00:00','100'
EXECUTE ingresoResultado 'Examen de tiroides', '0502479531', '2023-04-19 17:00:00','2023-04-20 17:00:00','2023-04-22 17:00:00','1.8'
EXECUTE ingresoResultado 'Perfil Lipídico', '0502479531', '2023-04-19 18:00:00','2023-04-22 18:00:00','2023-04-25 18:00:00','150'
EXECUTE ingresoResultado 'Examen de orina', '0801567892', '2023-04-19 12:30:00','2023-04-20 12:30:00','2023-04-21 12:30:00','5.5'
EXECUTE ingresoResultado 'Examen de creatinina', '0502479531', '2023-04-19 13:45:00','2023-04-20 13:45:00','2023-04-21 13:45:00','1.1'
EXECUTE ingresoResultado 'Hemograma completo', '1204870963', '2023-04-19 14:00:00','2023-04-20 14:00:00','2023-04-21 14:00:00','8.2'
EXECUTE ingresoResultado 'Examen de tiroides', '1757797202', '2023-04-19 15:15:00','2023-04-20 15:15:00','2023-04-21 15:15:00','2.5'
EXECUTE ingresoResultado 'Perfil Lipídico', '0912390649', '2023-04-19 16:30:00','2023-04-20 16:30:00','2023-04-23 16:30:00','145'
EXECUTE ingresoResultado 'Examen de orina', '0703521160', '2023-04-19 17:45:00','2023-04-20 17:45:00','2023-04-21 17:45:00','7'
EXECUTE ingresoResultado 'Examen de tiroides', '1102508772', '2023-04-19 18:00:00','2023-04-20 18:00:00','2023-04-23 18:00:00','1.8'
EXECUTE ingresoResultado 'Examen de glucosa', '0502479531', '2023-04-19 19:15:00','2023-04-20 19:15:00','2023-04-20 19:15:00','80'
EXECUTE ingresoResultado 'Examen de orina', '1204870963', '2023-04-19 20:30:00','2023-04-20 20:30:00','2023-04-22 20:30:00','8.5'
EXECUTE ingresoResultado 'Examen de creatinina', '0912390649', '2023-04-19 21:45:00','2023-04-20 21:45:00','2023-04-21 21:45:00','1.2'
--Alex
EXECUTE ingresoResultado 'Examen de Electroforesis de hemoglobina', '1754446720', '2023-04-19 17:00:00','2023-04-25 17:00:00','2023-04-27 17:00:00','0.7'
EXECUTE ingresoResultado 'Examen de glucosa', '1103756134', '2023-04-19 19:00:00','2023-04-22 19:00:00','2023-04-24 19:00:00','0.8'
EXECUTE ingresoResultado 'Examen de glucosa', '1200984761', '2023-04-19 18:00:00','2023-04-20 18:00:00','2023-04-22 18:00:00','0.9'
EXECUTE ingresoResultado 'Examen de bilirrubina', '1711402980', '2023-04-19 16:00:00','2023-04-23 16:00:00','2023-04-24 16:00:00','0.1'
EXECUTE ingresoResultado 'Examen de bilirrubina', '1305267542', '2023-04-19 16:30:00','2023-04-21 16:30:00','2023-04-22 16:30:00','1.2'
EXECUTE ingresoResultado 'Examen de bilirrubina', '1754446720', '2023-04-19 17:30:00','2023-04-20 17:30:00','2023-04-26 17:30:00','0.1'
EXECUTE ingresoResultado 'Examen de albumina', '1103756134', '2023-04-19 18:30:00','2023-04-23 18:30:00','2023-04-25 18:30:00','3.8'
EXECUTE ingresoResultado 'Examen de albumina', '1200984761', '2023-04-19 19:30:00','2023-04-25 19:30:00','2023-04-26 19:30:00','4.4'
EXECUTE ingresoResultado 'Examen de albumina', '1711402980', '2023-04-19 20:30:00','2023-04-21 20:30:00','2023-04-23 20:30:00','2.5'
EXECUTE ingresoResultado 'Examen de proteinas totales', '1305267542', '2023-04-19 20:00:00','2023-04-20 20:00:00','2023-04-23 20:00:00','6.8'
EXECUTE ingresoResultado 'Examen de proteinas totales', '1303753618', '2023-04-19 21:00:00','2023-04-22 21:00:00','2023-04-26 21:00:00','8.0'
EXECUTE ingresoResultado 'Examen de proteinas totales', '1754446720', '2023-04-19 21:30:00','2023-04-25 21:30:00','2023-04-27 21:30:00','8.6'
EXECUTE ingresoResultado 'Examen de trigliceridos', '1103756134', '2023-04-19 18:30:00','2023-04-23 18:30:00','2023-04-28 18:30:00','160'
EXECUTE ingresoResultado 'Examen de trigliceridos', '1200984761', '2023-04-19 18:00:00','2023-04-21 18:00:00','2023-04-22 18:00:00','170'
EXECUTE ingresoResultado 'Examen de trigliceridos', '1711402980', '2023-04-19 19:00:00','2023-04-20 19:00:00','2023-04-24 19:00:00','180'
EXECUTE ingresoResultado 'Examen de alanina', '1754446720', '2023-04-19 19:00:00','2023-04-24 19:00:00','2023-04-29 19:00:00','3.3'
EXECUTE ingresoResultado 'Examen de alanina', '1303753618', '2023-04-19 19:30:00','2023-04-20 19:30:00','2023-04-21 19:30:00','6.7'
EXECUTE ingresoResultado 'Examen de alanina', '1103756134', '2023-04-19 20:30:00','2023-04-25 20:30:00','2023-04-26 20:30:00','11'
EXECUTE ingresoResultado 'Examen de albumina', '1305267542', '2023-04-19 20:00:00','2023-04-23 20:00:00','2023-04-26 20:00:00','4.8'
EXECUTE ingresoResultado 'Examen de albumina', '1305267542', '2023-04-19 20:00:00','2023-04-23 20:00:00','2023-04-26 20:00:00','5.8'
--Ismael J
EXECUTE ingresoResultado 'Trigliceridos', '1104491862', '2023-04-19 23:00:00','2023-04-19 23:30:00','2023-04-22 23:30:00','78'
EXECUTE ingresoResultado 'Calcio renal', '0703521160', '2023-04-19 08:00:00','2023-04-20 13:00:00','2023-04-22 13:00:00','9.1'
EXECUTE ingresoResultado 'Acido urico', '1301167859', '2023-04-19 10:00:00','2023-04-19 11:25:00','2023-04-22 11:25:00','4.6'
EXECUTE ingresoResultado 'Glucosa', '1301167859', '2023-04-19 10:00:00','2023-04-19 11:30:00','2023-04-20 11:30:00','89.6'
EXECUTE ingresoResultado 'Acido urico', '1705682925', '2023-04-19 07:00:00','2023-04-21 10:45:00','2023-04-24 10:45:00','4.3'
EXECUTE ingresoResultado 'Bilirrubina total', '0502479531', '2023-04-20 15:00:00','2023-04-22 09:45:00','2023-04-24 09:45:00','0.68'
EXECUTE ingresoResultado 'Trigliceridos', '1705682925', '2023-04-20 07:20:00','2023-04-20 14:00:00','2023-04-23 14:00:00','120.6'
EXECUTE ingresoResultado 'Glucosa', '0502479531', '2023-04-20 15:00:00','2023-04-22 09:50:00','2023-04-23 09:50:00','107.2'
EXECUTE ingresoResultado 'Calcio renal', '1104491862', '2023-04-21 09:50:00','2023-04-21 12:30:00','2023-04-23 12:30:00','9.45'
EXECUTE ingresoResultado 'Fibrinogeno', '0703521160', '2023-04-21 08:45:00','2023-04-21 06:50:00','2023-04-24 06:50:00','345.12'
EXECUTE ingresoResultado 'Trigliceridos', '0911276548', '2023-04-22 09:10:00','2023-04-23 10:00:00','2023-04-26 10:00:00','147.3'
EXECUTE ingresoResultado 'Bilirrubina total', '1301167859', '2023-04-22 09:15:00','2023-04-22 07:30:00','2023-04-24 07:30:00','0.78'
EXECUTE ingresoResultado 'Glucosa', '1705682925', '2023-04-23 17:00:00','2023-04-24 10:00:00','2023-04-25 10:00:00','97.16'
EXECUTE ingresoResultado 'Calcio renal', '1301167859', '2023-04-21 18:00:00','2023-04-22 08:45:00','2023-04-24 08:45:00','8.7'
EXECUTE ingresoResultado 'Fibrinogeno', '1705682925', '2023-04-22 10:00:00','2023-04-22 15:45:00','2023-04-25 15:45:00','342.91'
EXECUTE ingresoResultado 'Acido urico', '1301167859', '2023-04-22 08:00:00','2023-04-22 08:30:00','2023-04-25 08:30:00','5.34'
EXECUTE ingresoResultado 'Bilirrubina total', '1104491862', '2023-04-23 10:45:00','2023-04-24 08:00:00','2023-04-26 08:00:00','0.47'
EXECUTE ingresoResultado 'Glucosa', '1705682925', '2023-05-01 08:00:00','2023-05-01 10:30:00','2023-05-02 10:30:00','81.3'
EXECUTE ingresoResultado 'Calcio renal', '1705682925', '2023-04-24 10:00:00','2023-04-24 13:00:00','2023-04-26 13:00:00','7.45'
EXECUTE ingresoResultado 'Fibrinogeno', '0911276548', '2023-04-24 09:45:00','2023-04-25 10:05:00','2023-04-28 10:00:00','415.8'
--David
EXECUTE ingresoResultado 'Hemoglobina', '1101234567', '2023-04-18 10:00:00', '2023-04-19 08:00:00', '2023-04-19 12:00:00', 15.7;
EXECUTE ingresoResultado 'Colesterol', '1202345678', '2023-04-18 10:00:00', '2023-04-19 09:00:00', '2023-04-19 12:30:00', 114.8;
EXECUTE ingresoResultado 'Hemoglobina', '1404567890', '2023-04-18 10:00:00', '2023-04-19 10:00:00', '2023-04-19 12:45:00', 16.5;
EXECUTE ingresoResultado 'TSH', '1701710699', '2023-04-18 10:00:00', '2023-04-19 09:30:00', '2023-04-19 12:30:00', 5.76;
EXECUTE ingresoResultado'Hemoglobina', '0906789012', '2023-04-18 10:00:00', '2023-04-19 08:15:00', '2023-04-19 11:45:00', 13.8;
EXECUTE ingresoResultado 'Hemoglobina', '1728174101', '2023-04-18 10:00:00', '2023-04-19 11:00:00', '2023-04-19 13:00:00', 12.1;
EXECUTE ingresoResultado'Hemoglobina', '1709693251', '2023-04-18 10:00:00', '2023-04-19 09:45:00', '2023-04-19 12:45:00', 15.4;
EXECUTE ingresoResultado 'TSH', '0906789012', '2023-04-11 14:00:00', '2023-04-13 09:30:00', '2023-04-15 12:00:00', 3.2;
EXECUTE ingresoResultado 'HDL', '1404567890', '2023-04-11 08:00:00', '2023-04-12 11:00:00', '2023-04-15 14:00:00', 50.0;
EXECUTE ingresoResultado 'Colesterol', '1703456789', '2023-04-10 14:30:00', '2023-04-13 09:00:00', '2023-04-16 14:00:00', 205.0;
EXECUTE ingresoResultado 'Glucemia', '1202345678', '2023-04-11 10:00:00', '2023-04-12 10:30:00', '2023-04-13 16:00:00', 90.0;
EXECUTE ingresoResultado 'Glucemia', '1202345678', '2023-04-19 08:00:00', '2023-04-19 09:00:00', '2023-04-20 12:00:00', 90.5;
EXECUTE ingresoResultado 'Colesterol', '1703456789', '2023-04-19 07:00:00', '2023-04-19 08:00:00', '2023-04-22 09:00:00', 150.3;
EXECUTE ingresoResultado 'HDL', '1404567890', '2023-04-19 08:00:00', '2023-04-19 09:00:00', '2023-04-22 11:00:00', 55.8;
EXECUTE ingresoResultado 'LDL', '1701710699', '2023-04-19 06:00:00', '2023-04-19 07:00:00', '2023-04-22 08:00:00', 110.5;
EXECUTE ingresoResultado 'Vitamina D', '0906789012', '2023-04-19 10:00:00', '2023-04-19 11:00:00', '2023-04-21 13:00:00', 40.2;
EXECUTE ingresoResultado 'TSH', '1728174101', '2023-04-19 07:00:00', '2023-04-19 08:00:00', '2023-04-21 10:00:00', 2.8;
EXECUTE ingresoResultado 'Creatinina', '1709693251', '2023-04-19 09:00:00', '2023-04-19 10:00:00', '2023-04-22 12:00:00', 0.9;
EXECUTE ingresoResultado 'Colesterol', '1701710699', '2023-04-10 14:30:00', '2023-04-13 09:00:00', '2023-04-16 14:00:00', 209.0;
--Cristopher
EXECUTE ingresoResultado 'Prueba de inmunofijación', '1711044210', '2023-04-19 08:00:00','2023-04-21 08:00:00','2023-04-22 11:00:00','45.100'
EXECUTE ingresoResultado 'Prueba de la médula ósea', '1711044210', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-23 10:00:00','25.400'
EXECUTE ingresoResultado 'Prueba de inmunofijación', '1711044210', '2023-04-18 11:00:00','2023-04-20 11:00:00','2023-04-21 11:00:00','56.900'
EXECUTE ingresoResultado 'Prueba de la médula ósea', '1726964342', '2023-04-18 12:00:00','2023-04-19 08:00:00','2023-04-19 12:00:00','90.000'
EXECUTE ingresoResultado 'Prueba de inmunofijación', '1726964342', '2023-04-19 14:00:00','2023-04-21 14:00:00','2023-04-21 15:00:00','98.300'
EXECUTE ingresoResultado 'Prueba de la médula ósea', '1726964342', '2023-04-19 09:00:00','2023-04-20 09:00:00','2023-04-21 14:00:00','45.200'
EXECUTE ingresoResultado 'Prueba de amilasa', '1711044213', '2023-04-19 08:00:00','2023-04-21 08:00:00','2023-04-22 11:00:00','40.100'
EXECUTE ingresoResultado 'Prueba de anticuerpos antinucleares', '1711044213', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-23 10:00:00','15.400'
EXECUTE ingresoResultado 'Prueba de amilasa', '1711044213', '2023-04-18 11:00:00','2023-04-20 11:00:00','2023-04-21 11:00:00','80.900'
EXECUTE ingresoResultado 'Prueba de anticuerpos antinucleares', '1726964347', '2023-04-18 12:00:00','2023-04-19 08:00:00','2023-04-19 12:00:00','54.000'
EXECUTE ingresoResultado 'Prueba de amilasa', '1726964347', '2023-04-19 14:00:00','2023-04-21 14:00:00','2023-04-21 15:00:00','120.300'
EXECUTE ingresoResultado 'Prueba de anticuerpos antinucleares', '1726964347', '2023-04-19 09:00:00','2023-04-20 09:00:00','2023-04-21 14:00:00','45.200'
EXECUTE ingresoResultado 'Examen de coagulación', '1726955550', '2023-04-19 08:00:00','2023-04-21 08:00:00','2023-04-22 11:00:00','10.400'
EXECUTE ingresoResultado 'Examen de coagulación', '0606925350', '2023-04-19 10:00:00','2023-04-20 10:00:00','2023-04-23 10:00:00','12.400'
EXECUTE ingresoResultado 'Examen de tiroides', '0606925350', '2023-04-18 11:00:00','2023-04-20 11:00:00','2023-04-21 11:00:00','4.100'
EXECUTE ingresoResultado 'Examen de hormonas sexuales', '1726955550', '2023-04-18 12:00:00','2023-04-19 08:00:00','2023-04-22 12:00:00','430.000'
EXECUTE ingresoResultado 'Examen de coagulación', '0703521160', '2023-04-19 14:00:00','2023-04-21 14:00:00','2023-04-21 15:00:00','14.000'
EXECUTE ingresoResultado 'Examen de creatinina', '0606925350', '2023-04-19 09:00:00','2023-04-20 09:00:00','2023-04-21 14:00:00','1.200'
EXECUTE ingresoResultado 'Examen de hormonas sexuales', '0606925350', '2023-04-19 09:30:00','2023-04-21 08:00:00','2023-04-24 15:00:00','309.000'

GO
