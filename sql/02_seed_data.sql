/* =====================================================================
   UniversityDB — скрипт 2: тестові дані.
   Запускати після 01_create_database.sql.
   Ідентифікатори задані явно, щоб приклади в темах давали однакові результати.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON;
GO

USE UniversityDB;
GO

SET NOCOUNT ON;

SET IDENTITY_INSERT dbo.Faculty ON;
INSERT INTO dbo.Faculty (FacultyId, Name, ShortName) VALUES
 (1, N'Факультет інформаційних технологій', N'ФІТ'),
 (2, N'Економічний факультет',              N'ЕФ');
SET IDENTITY_INSERT dbo.Faculty OFF;

SET IDENTITY_INSERT dbo.Department ON;
INSERT INTO dbo.Department (DepartmentId, FacultyId, Name) VALUES
 (1, 1, N'Кафедра програмної інженерії'),
 (2, 1, N'Кафедра комп''ютерних наук'),
 (3, 2, N'Кафедра економічної кібернетики'),
 (4, 2, N'Кафедра фінансів');
SET IDENTITY_INSERT dbo.Department OFF;

SET IDENTITY_INSERT dbo.Teacher ON;
INSERT INTO dbo.Teacher
 (TeacherId, DepartmentId, ManagerId, LastName, FirstName, Position, HireDate, Salary, Email) VALUES
 ( 1, 1, NULL, N'Коваленко', N'Олександр', N'завідувач кафедри', '2005-09-01', 42000, 'o.kovalenko@univ.edu.ua'),
 ( 2, 1, 1,    N'Шевченко',  N'Ірина',     N'професор',          '2008-09-01', 38000, 'i.shevchenko@univ.edu.ua'),
 ( 3, 1, 1,    N'Бондар',    N'Андрій',    N'доцент',            '2012-09-01', 31000, 'a.bondar@univ.edu.ua'),
 ( 4, 1, 3,    N'Ткаченко',  N'Марія',     N'асистент',          '2021-09-01', 19000, 'm.tkachenko@univ.edu.ua'),
 ( 5, 2, NULL, N'Мельник',   N'Сергій',    N'завідувач кафедри', '2003-09-01', 43000, 's.melnyk@univ.edu.ua'),
 ( 6, 2, 5,    N'Кравченко', N'Олена',     N'доцент',            '2010-02-01', 32000, 'o.kravchenko@univ.edu.ua'),
 ( 7, 2, 5,    N'Олійник',   N'Дмитро',    N'старший викладач',  '2016-09-01', 25000, 'd.oliinyk@univ.edu.ua'),
 ( 8, 3, NULL, N'Лисенко',   N'Наталія',   N'завідувач кафедри', '2007-09-01', 41000, 'n.lysenko@univ.edu.ua'),
 ( 9, 3, 8,    N'Мороз',     N'Віктор',    N'доцент',            '2014-09-01', 30000, 'v.moroz@univ.edu.ua'),
 (10, 4, NULL, N'Савченко',  N'Тетяна',    N'завідувач кафедри', '2001-09-01', 44000, 't.savchenko@univ.edu.ua'),
 (11, 4, 10,   N'Руденко',   N'Юрій',      N'асистент',          '2023-09-01', 18000, 'y.rudenko@univ.edu.ua');
SET IDENTITY_INSERT dbo.Teacher OFF;

SET IDENTITY_INSERT dbo.StudentGroup ON;
INSERT INTO dbo.StudentGroup (GroupId, DepartmentId, CuratorId, Code, AdmissionYear) VALUES
 (1, 1, 3,    N'ПІ-21', 2021),
 (2, 1, 4,    N'ПІ-22', 2022),
 (3, 2, 6,    N'КН-21', 2021),
 (4, 3, 9,    N'ЕК-22', 2022),
 (5, 4, NULL, N'ФН-24', 2024);   -- нова група: ще без куратора і без студентів
SET IDENTITY_INSERT dbo.StudentGroup OFF;

SET IDENTITY_INSERT dbo.Student ON;
INSERT INTO dbo.Student
 (StudentId, GroupId, RecordBookNo, LastName, FirstName, BirthDate, Gender, Email, City,
  IsContract, Scholarship, TuitionDebt, IsActive) VALUES
 ( 1, 1, '21010001', N'Петренко',    N'Іван',      '2003-04-12', 'M', 'i.petrenko@stud.edu.ua',    N'Київ',     0, 2000,     0, 1),
 ( 2, 1, '21010002', N'Іваненко',    N'Олена',     '2003-07-25', 'F', 'o.ivanenko@stud.edu.ua',    N'Львів',    0, 2500,     0, 1),
 ( 3, 1, '21010003', N'Сидоренко',   N'Максим',    '2002-11-03', 'M', NULL,                        N'Київ',     1,    0, 18000, 1),
 ( 4, 1, '21010004', N'Гончаренко',  N'Анна',      '2003-01-19', 'F', 'a.honcharenko@stud.edu.ua', N'Житомир',  1,    0,     0, 1),
 ( 5, 1, '21010005', N'Литвиненко',  N'Богдан',    '2003-09-30', 'M', 'b.lytvynenko@stud.edu.ua',  N'Вінниця',  0,    0,     0, 0),
 ( 6, 2, '22010001', N'Захарченко',  N'Софія',     '2004-02-14', 'F', 's.zakharchenko@stud.edu.ua',N'Київ',     0, 2000,     0, 1),
 ( 7, 2, '22010002', N'Павленко',    N'Денис',     '2004-06-08', 'M', 'd.pavlenko@stud.edu.ua',    N'Черкаси',  1,    0,  9000, 1),
 ( 8, 2, '22010003', N'Кузьменко',   N'Юлія',      '2004-10-21', 'F', NULL,                        N'Київ',     0,    0,     0, 1),
 ( 9, 2, '22010004', N'Романенко',   N'Артем',     '2003-12-05', 'M', 'a.romanenko@stud.edu.ua',   N'Полтава',  1,    0, 18000, 1),
 (10, 3, '21020001', N'Левченко',    N'Марія',     '2003-03-17', 'F', 'm.levchenko@stud.edu.ua',   N'Львів',    0, 2500,     0, 1),
 (11, 3, '21020002', N'Мартиненко',  N'Олег',      '2002-08-29', 'M', 'o.martynenko@stud.edu.ua',  N'Одеса',    1,    0,     0, 1),
 (12, 3, '21020003', N'Яковенко',    N'Дарина',    '2003-05-11', 'F', 'd.yakovenko@stud.edu.ua',   N'Київ',     0, 2000,     0, 1),
 (13, 3, '21020004', N'Демченко',    N'Віталій',   '2003-12-01', 'M', NULL,                        N'Харків',   1,    0,  4500, 1),
 (14, 4, '22030001', N'Федоренко',   N'Катерина',  '2004-01-09', 'F', 'k.fedorenko@stud.edu.ua',   N'Київ',     0, 2000,     0, 1),
 (15, 4, '22030002', N'Василенко',   N'Роман',     '2004-04-23', 'M', 'r.vasylenko@stud.edu.ua',   N'Дніпро',   1,    0, 15000, 1),
 (16, 4, '22030003', N'Тимошенко',   N'Вікторія',  '2004-07-16', 'F', 'v.tymoshenko@stud.edu.ua',  N'Київ',     1,    0,     0, 1),
 (17, 4, '22030004', N'Харченко',    N'Назар',     '2003-10-02', 'M', NULL,                        N'Суми',     0,    0,     0, 1);
SET IDENTITY_INSERT dbo.Student OFF;

SET IDENTITY_INSERT dbo.Course ON;
INSERT INTO dbo.Course (CourseId, DepartmentId, Code, Title, Credits) VALUES
 (1, 1, 'DB101',   N'Бази даних',                          6.0),
 (2, 1, 'PRG101',  N'Основи програмування',                5.0),
 (3, 1, 'PRG201',  N'Об''єктно-орієнтоване програмування', 5.0),
 (4, 2, 'ALG201',  N'Алгоритми та структури даних',        4.5),
 (5, 2, 'AI301',   N'Системи штучного інтелекту',          4.0),
 (6, 3, 'MATH101', N'Вища математика',                     6.0),
 (7, 3, 'ECO201',  N'Економетрія',                         4.0),
 (8, 4, 'FIN201',  N'Фінанси',                             3.5),
 (9, 2, 'DIST401', N'Розподілені системи',                 4.0);  -- поки що ніде не викладається
SET IDENTITY_INSERT dbo.Course OFF;

INSERT INTO dbo.CoursePrerequisite (CourseId, PrereqCourseId) VALUES
 (1, 2),   -- Бази даних           <- Основи програмування
 (3, 2),   -- ООП                  <- Основи програмування
 (4, 2),   -- Алгоритми            <- Основи програмування
 (5, 4),   -- Штучний інтелект     <- Алгоритми
 (5, 6),   -- Штучний інтелект     <- Вища математика
 (7, 6),   -- Економетрія          <- Вища математика
 (9, 1),   -- Розподілені системи  <- Бази даних
 (9, 4);   -- Розподілені системи  <- Алгоритми

SET IDENTITY_INSERT dbo.Teaching ON;
INSERT INTO dbo.Teaching
 (TeachingId, CourseId, TeacherId, GroupId, AcademicYear, Semester, ControlType) VALUES
 ( 1, 6, 9,  1, '2024/2025', 1, N'екзамен'),
 ( 2, 2, 3,  1, '2024/2025', 1, N'екзамен'),
 ( 3, 1, 2,  1, '2024/2025', 2, N'екзамен'),
 ( 4, 3, 4,  1, '2024/2025', 2, N'залік'),
 ( 5, 2, 3,  2, '2024/2025', 1, N'екзамен'),
 ( 6, 6, 9,  2, '2024/2025', 1, N'екзамен'),
 ( 7, 4, 6,  3, '2024/2025', 1, N'екзамен'),
 ( 8, 1, 2,  3, '2024/2025', 2, N'екзамен'),
 ( 9, 5, 7,  3, '2024/2025', 2, N'залік'),
 (10, 6, 8,  4, '2024/2025', 1, N'екзамен'),
 (11, 7, 9,  4, '2024/2025', 2, N'екзамен'),
 (12, 8, 11, 4, '2024/2025', 2, N'залік');
SET IDENTITY_INSERT dbo.Teaching OFF;

-- Оцінки генеруються детерміновано: кожен студент групи отримує оцінку
-- з кожної дисципліни своєї групи. Відрахований студент (IsActive = 0)
-- має оцінки лише за 1-й семестр.
INSERT INTO dbo.Grade (StudentId, TeachingId, Score, ExamDate)
SELECT s.StudentId,
       t.TeachingId,
       55 + (s.StudentId * 17 + t.TeachingId * 29) % 46,
       DATEADD(DAY, t.TeachingId % 7,
               CASE t.Semester WHEN 1 THEN CAST('2025-01-13' AS DATE)
                               ELSE CAST('2025-06-09' AS DATE) END)
FROM dbo.Student  AS s
JOIN dbo.Teaching AS t ON t.GroupId = s.GroupId
WHERE s.IsActive = 1 OR t.Semester = 1;

INSERT INTO dbo.Payment (StudentId, Amount, PaidAt, Purpose) VALUES
 ( 3,  9000, '2024-09-01T10:15:00', N'Оплата навчання'),
 ( 4, 18000, '2024-09-02T12:00:00', N'Оплата навчання'),
 ( 7,  9000, '2024-09-05T09:30:00', N'Оплата навчання'),
 (11, 18000, '2024-08-28T14:45:00', N'Оплата навчання'),
 (13, 13500, '2024-09-10T11:20:00', N'Оплата навчання'),
 (16, 18000, '2024-09-03T16:05:00', N'Оплата навчання'),
 (15,  3000, '2024-10-01T10:00:00', N'Оплата навчання'),
 ( 2,   350, '2024-11-12T13:10:00', N'Гуртожиток');
GO

PRINT N'UniversityDB: тестові дані завантажено.';
