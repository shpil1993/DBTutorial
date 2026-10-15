/* =====================================================================
   UniversityDB — тестова база даних для прикладів курсу «Бази даних»
   Скрипт 1: створення бази даних, таблиць, обмежень, індексів, представлень.
   Потрібен SQL Server 2017 або новіший (Express / Developer / Docker).
   ===================================================================== */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- потрібно для фільтрованих індексів (sqlcmd за замовчуванням OFF)
GO

USE master;
GO

IF DB_ID(N'UniversityDB') IS NOT NULL
BEGIN
    ALTER DATABASE UniversityDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UniversityDB;
END
GO

CREATE DATABASE UniversityDB COLLATE Cyrillic_General_CI_AS;
GO

-- Дозволяє рівень ізоляції SNAPSHOT (див. Тему 8)
ALTER DATABASE UniversityDB SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE UniversityDB;
GO

/* ---------- Довідники структури університету ---------- */

CREATE TABLE dbo.Faculty (
    FacultyId   INT IDENTITY(1,1) CONSTRAINT PK_Faculty PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL CONSTRAINT UQ_Faculty_Name UNIQUE,
    ShortName   NVARCHAR(10)  NOT NULL
);

CREATE TABLE dbo.Department (
    DepartmentId INT IDENTITY(1,1) CONSTRAINT PK_Department PRIMARY KEY,
    FacultyId    INT NOT NULL
                 CONSTRAINT FK_Department_Faculty REFERENCES dbo.Faculty(FacultyId),
    Name         NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Department_Name UNIQUE (FacultyId, Name)
);

CREATE TABLE dbo.Teacher (
    TeacherId    INT IDENTITY(1,1) CONSTRAINT PK_Teacher PRIMARY KEY,
    DepartmentId INT NOT NULL
                 CONSTRAINT FK_Teacher_Department REFERENCES dbo.Department(DepartmentId),
    ManagerId    INT NULL      -- безпосередній керівник (рекурсивний зв'язок)
                 CONSTRAINT FK_Teacher_Manager REFERENCES dbo.Teacher(TeacherId),
    LastName     NVARCHAR(50) NOT NULL,
    FirstName    NVARCHAR(50) NOT NULL,
    Position     NVARCHAR(30) NOT NULL
                 CONSTRAINT CK_Teacher_Position CHECK (Position IN
                     (N'асистент', N'старший викладач', N'доцент', N'професор', N'завідувач кафедри')),
    HireDate     DATE NOT NULL,
    Salary       DECIMAL(10,2) NOT NULL CONSTRAINT CK_Teacher_Salary CHECK (Salary > 0),
    Email        VARCHAR(100) NOT NULL CONSTRAINT UQ_Teacher_Email UNIQUE
);

CREATE TABLE dbo.StudentGroup (
    GroupId       INT IDENTITY(1,1) CONSTRAINT PK_StudentGroup PRIMARY KEY,
    DepartmentId  INT NOT NULL
                  CONSTRAINT FK_StudentGroup_Department REFERENCES dbo.Department(DepartmentId),
    CuratorId     INT NULL
                  CONSTRAINT FK_StudentGroup_Curator REFERENCES dbo.Teacher(TeacherId),
    Code          NVARCHAR(10) NOT NULL CONSTRAINT UQ_StudentGroup_Code UNIQUE,
    AdmissionYear SMALLINT NOT NULL
                  CONSTRAINT CK_StudentGroup_Year CHECK (AdmissionYear BETWEEN 2000 AND 2100)
);

CREATE TABLE dbo.Student (
    StudentId    INT IDENTITY(1,1) CONSTRAINT PK_Student PRIMARY KEY,   -- сурогатний ключ
    GroupId      INT NOT NULL
                 CONSTRAINT FK_Student_Group REFERENCES dbo.StudentGroup(GroupId),
    RecordBookNo CHAR(8) NOT NULL CONSTRAINT UQ_Student_RecordBook UNIQUE, -- природний (альтернативний) ключ
    LastName     NVARCHAR(50) NOT NULL,
    FirstName    NVARCHAR(50) NOT NULL,
    BirthDate    DATE NOT NULL,
    Gender       CHAR(1) NOT NULL CONSTRAINT CK_Student_Gender CHECK (Gender IN ('M', 'F')),
    Email        VARCHAR(100) NULL,
    City         NVARCHAR(50) NULL,
    IsContract   BIT NOT NULL CONSTRAINT DF_Student_IsContract DEFAULT (0),
    Scholarship  DECIMAL(10,2) NOT NULL CONSTRAINT DF_Student_Scholarship DEFAULT (0)
                 CONSTRAINT CK_Student_Scholarship CHECK (Scholarship >= 0),
    TuitionDebt  DECIMAL(10,2) NOT NULL CONSTRAINT DF_Student_TuitionDebt DEFAULT (0)
                 CONSTRAINT CK_Student_TuitionDebt CHECK (TuitionDebt >= 0),
    IsActive     BIT NOT NULL CONSTRAINT DF_Student_IsActive DEFAULT (1)
);

-- UNIQUE для стовпця, що допускає NULL: фільтрований унікальний індекс
CREATE UNIQUE INDEX UX_Student_Email ON dbo.Student(Email) WHERE Email IS NOT NULL;

/* ---------- Навчальний процес ---------- */

CREATE TABLE dbo.Course (
    CourseId     INT IDENTITY(1,1) CONSTRAINT PK_Course PRIMARY KEY,
    DepartmentId INT NOT NULL
                 CONSTRAINT FK_Course_Department REFERENCES dbo.Department(DepartmentId),
    Code         VARCHAR(10) NOT NULL CONSTRAINT UQ_Course_Code UNIQUE,
    Title        NVARCHAR(100) NOT NULL,
    Credits      DECIMAL(3,1) NOT NULL CONSTRAINT CK_Course_Credits CHECK (Credits > 0),
    Hours        AS CAST(Credits * 30 AS SMALLINT)    -- обчислюваний стовпець: 1 кредит ЄКТС = 30 год
);

-- Пререквізити: зв'язок M:N дисципліни самої з собою (мережна структура)
CREATE TABLE dbo.CoursePrerequisite (
    CourseId       INT NOT NULL CONSTRAINT FK_CoursePrereq_Course REFERENCES dbo.Course(CourseId),
    PrereqCourseId INT NOT NULL CONSTRAINT FK_CoursePrereq_Prereq REFERENCES dbo.Course(CourseId),
    CONSTRAINT PK_CoursePrerequisite PRIMARY KEY (CourseId, PrereqCourseId),
    CONSTRAINT CK_CoursePrerequisite_Self CHECK (CourseId <> PrereqCourseId)
);

-- Викладання: який викладач читає яку дисципліну якій групі
CREATE TABLE dbo.Teaching (
    TeachingId   INT IDENTITY(1,1) CONSTRAINT PK_Teaching PRIMARY KEY,
    CourseId     INT NOT NULL CONSTRAINT FK_Teaching_Course  REFERENCES dbo.Course(CourseId),
    TeacherId    INT NOT NULL CONSTRAINT FK_Teaching_Teacher REFERENCES dbo.Teacher(TeacherId),
    GroupId      INT NOT NULL CONSTRAINT FK_Teaching_Group   REFERENCES dbo.StudentGroup(GroupId),
    AcademicYear CHAR(9) NOT NULL,                       -- '2024/2025'
    Semester     TINYINT NOT NULL CONSTRAINT CK_Teaching_Semester CHECK (Semester IN (1, 2)),
    ControlType  NVARCHAR(10) NOT NULL
                 CONSTRAINT CK_Teaching_ControlType CHECK (ControlType IN (N'екзамен', N'залік')),
    CONSTRAINT UQ_Teaching UNIQUE (CourseId, GroupId, AcademicYear, Semester)
);

-- Оцінки: складений первинний ключ
CREATE TABLE dbo.Grade (
    StudentId  INT NOT NULL CONSTRAINT FK_Grade_Student  REFERENCES dbo.Student(StudentId),
    TeachingId INT NOT NULL CONSTRAINT FK_Grade_Teaching REFERENCES dbo.Teaching(TeachingId),
    Score      TINYINT NOT NULL CONSTRAINT CK_Grade_Score CHECK (Score BETWEEN 0 AND 100),
    ExamDate   DATE NOT NULL,
    EctsGrade  AS (CASE WHEN Score >= 90 THEN 'A'
                        WHEN Score >= 82 THEN 'B'
                        WHEN Score >= 74 THEN 'C'
                        WHEN Score >= 64 THEN 'D'
                        WHEN Score >= 60 THEN 'E'
                        WHEN Score >= 35 THEN 'FX'
                        ELSE 'F' END) PERSISTED,
    CONSTRAINT PK_Grade PRIMARY KEY (StudentId, TeachingId)
);

/* ---------- Фінанси та аудит ---------- */

CREATE TABLE dbo.Payment (
    PaymentId  INT IDENTITY(1,1) CONSTRAINT PK_Payment PRIMARY KEY,
    StudentId  INT NOT NULL CONSTRAINT FK_Payment_Student REFERENCES dbo.Student(StudentId),
    Amount     DECIMAL(10,2) NOT NULL CONSTRAINT CK_Payment_Amount CHECK (Amount > 0),
    PaidAt     DATETIME2(0) NOT NULL CONSTRAINT DF_Payment_PaidAt DEFAULT (SYSDATETIME()),
    Purpose    NVARCHAR(100) NOT NULL CONSTRAINT DF_Payment_Purpose DEFAULT (N'Оплата навчання')
);

CREATE TABLE dbo.AuditLog (
    AuditId    BIGINT IDENTITY(1,1) CONSTRAINT PK_AuditLog PRIMARY KEY,
    TableName  SYSNAME NOT NULL,
    Operation  VARCHAR(6) NOT NULL,          -- INSERT / UPDATE / DELETE
    RecordKey  NVARCHAR(100) NOT NULL,
    Details    NVARCHAR(400) NULL,
    ChangedBy  SYSNAME NOT NULL CONSTRAINT DF_AuditLog_ChangedBy DEFAULT (ORIGINAL_LOGIN()),
    ChangedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_AuditLog_ChangedAt DEFAULT (SYSDATETIME())
);

/* ---------- Індекси для зовнішніх ключів ---------- */

CREATE INDEX IX_Department_FacultyId   ON dbo.Department(FacultyId);
CREATE INDEX IX_Teacher_DepartmentId   ON dbo.Teacher(DepartmentId);
CREATE INDEX IX_StudentGroup_DeptId    ON dbo.StudentGroup(DepartmentId);
CREATE INDEX IX_Student_GroupId        ON dbo.Student(GroupId);
CREATE INDEX IX_Student_LastName       ON dbo.Student(LastName, FirstName);
CREATE INDEX IX_Course_DepartmentId    ON dbo.Course(DepartmentId);
CREATE INDEX IX_Teaching_TeacherId     ON dbo.Teaching(TeacherId);
CREATE INDEX IX_Teaching_GroupId       ON dbo.Teaching(GroupId);
CREATE INDEX IX_Grade_TeachingId       ON dbo.Grade(TeachingId) INCLUDE (Score);
CREATE INDEX IX_Payment_StudentId      ON dbo.Payment(StudentId);
GO

/* ---------- Представлення (зовнішній рівень архітектури ANSI/SPARC) ---------- */

CREATE VIEW dbo.vStudentGrades
AS
SELECT  s.StudentId,
        s.LastName + N' ' + s.FirstName AS StudentName,
        g.Code        AS GroupCode,
        c.Title       AS CourseTitle,
        t.AcademicYear,
        t.Semester,
        gr.Score,
        gr.EctsGrade
FROM dbo.Grade        AS gr
JOIN dbo.Student      AS s ON s.StudentId  = gr.StudentId
JOIN dbo.StudentGroup AS g ON g.GroupId    = s.GroupId
JOIN dbo.Teaching     AS t ON t.TeachingId = gr.TeachingId
JOIN dbo.Course       AS c ON c.CourseId   = t.CourseId;
GO
