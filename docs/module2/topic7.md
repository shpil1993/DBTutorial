# Тема 7. Мови запитів

## 7.1. Поняття запиту

**Запит** — це звернення до СКБД з вимогою отримати чи змінити дані, що відповідають
заданим умовам. Результат запиту на вибірку — **нове відношення** (таблиця), яке можна
використати в іншому запиті.

Мови запитів поділяються на:

* **процедурні (навігаційні)** — описують, *як* отримати дані (крок за кроком, як у
  ієрархічних і мережних СКБД);
* **декларативні (непроцедурні)** — описують, *що* треба отримати, а спосіб виконання
  обирає оптимізатор СКБД.

Дві класичні декларативні мови реляційних СКБД:

| | QBE | SQL |
|-|-----|-----|
| Повна назва | Query By Example — запит за зразком | Structured Query Language — структурована мова запитів |
| Автор | М. Злуф, IBM, 1975 | Д. Чемберлен, Р. Бойс, IBM, 1974 (SEQUEL) |
| Форма | графічна: користувач заповнює **бланк-зразок** таблиці | текстова: оператори мови |
| Де використовується | MS Access, конструктори запитів (SSMS, LibreOffice Base) | усі реляційні СКБД; стандарт ISO/IEC 9075 |
| Для кого | кінцеві користувачі | розробники, аналітики, адміністратори |

## 7.2. Вибірка даних з використанням мови QBE

У QBE користувач бачить **бланк запиту**: у верхній частині — схеми таблиць, у нижній —
сітку, де кожен стовпець відповідає полю. Рядки сітки: **Поле**, **Таблиця**,
**Групування**, **Сортування**, **Виведення на екран**, **Умова відбору**, **або**.

!!! tip "QBE в SQL Server Management Studio"
    У SSMS аналог QBE — **Query Designer**: у вікні запиту натисніть ++ctrl+shift+q++
    (*Query → Design Query in Editor*), додайте таблиці та позначте поля. Конструктор
    сам згенерує текст SQL, який можна порівняти з бланком.

### Вибірка з умовою

Бланк QBE: «студенти з Києва, відсортовані за прізвищем»:

| | | | |
|-|-|-|-|
| **Поле:** | LastName | FirstName | City |
| **Таблиця:** | Student | Student | Student |
| **Сортування:** | за зростанням | | |
| **Виведення:** | ☑ | ☑ | ☐ |
| **Умова відбору:** | | | `"Київ"` |

Умови в **одному** рядку об'єднуються через **І**, у **різних** рядках («або») — через **АБО**.
Еквівалентний SQL:

```sql
USE UniversityDB;

SELECT LastName, FirstName
FROM dbo.Student
WHERE City = N'Київ'
ORDER BY LastName;
```

### Використання результуючих (підсумкових) функцій

У рядку **Групування** обирають: `Group By`, `Sum`, `Avg`, `Min`, `Max`, `Count`.

| | | |
|-|-|-|
| **Поле:** | Code | Score |
| **Таблиця:** | StudentGroup | Grade |
| **Групування:** | Group By | Avg |
| **Сортування:** | | за спаданням |

```sql
SELECT g.Code, AVG(CAST(gr.Score AS DECIMAL(5,2))) AS AvgScore
FROM dbo.StudentGroup AS g
JOIN dbo.Student AS s  ON s.GroupId    = g.GroupId
JOIN dbo.Grade   AS gr ON gr.StudentId = s.StudentId
GROUP BY g.Code
ORDER BY AvgScore DESC;
```

### Обчислення в запитах

Обчислюване поле записують у рядку **Поле** у вигляді `Ім'я: вираз`, наприклад
`Стипендія_рік: [Scholarship]*12`.

```sql
SELECT LastName, Scholarship, Scholarship * 12 AS ScholarshipPerYear
FROM dbo.Student
WHERE Scholarship > 0;
```

### Операції додавання, видалення і модифікації

У QBE є спеціальні типи запитів (у MS Access — *запит на додавання*, *на видалення*,
*на оновлення*). Бланк оновлення має рядок **Оновлення**: у стовпці `Scholarship` пишуть
`[Scholarship]*1.1`, а в рядку умови — `>0`. Відповідники в SQL:

```sql
BEGIN TRAN;   -- щоб не зіпсувати тестові дані, відкотимо зміни наприкінці

-- Запит на оновлення: підвищити всі стипендії на 10 %
UPDATE dbo.Student SET Scholarship = Scholarship * 1.1 WHERE Scholarship > 0;

-- Запит на додавання: додати рядки з результату іншого запиту
INSERT INTO dbo.Payment (StudentId, Amount, Purpose)
SELECT StudentId, 350, N'Гуртожиток' FROM dbo.Student WHERE City <> N'Київ' AND IsActive = 1;

-- Запит на видалення
DELETE FROM dbo.Payment WHERE Purpose = N'Гуртожиток';

SELECT COUNT(*) AS PaymentsLeft FROM dbo.Payment;

ROLLBACK;
```

## 7.3. Базові оператори мови SQL та особливості їх запису

| Група | Оператори | Призначення |
|-------|-----------|-------------|
| **DDL** — опис даних | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` | створення та зміна об'єктів |
| **DML** — маніпулювання | `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `MERGE` | вибірка та зміна даних |
| **DCL** — керування доступом | `GRANT`, `REVOKE`, `DENY` | права |
| **TCL** — керування транзакціями | `BEGIN TRAN`, `COMMIT`, `ROLLBACK`, `SAVE TRAN` | [Тема 8](topic8.md) |

Особливості запису в T-SQL (діалект SQL Server):

* ключові слова **нечутливі до регістру** (`SELECT` = `select`); чутливість імен і даних
  залежить від правила сортування (collation) — у `UniversityDB` `Cyrillic_General_CI_AS`,
  де `CI` = case-insensitive;
* оператор бажано завершувати `;`;
* коментарі: `-- до кінця рядка` та `/* блок */`;
* імена з пропусками чи зарезервованими словами беруть у `[квадратні дужки]`;
* рядкові константи — в одинарних лапках; **Unicode-рядки** (кирилиця!) — з префіксом
  `N`: `N'Київ'`; апостроф усередині рядка подвоюється: `N'комп''ютерних'`;
* `GO` — не оператор SQL, а розділювач пакетів для SSMS/sqlcmd.

## 7.4. Опис даних мовою SQL

```sql
-- Створення таблиці з обмеженнями
CREATE TABLE dbo.Olympiad (
    OlympiadId  INT IDENTITY(1,1) CONSTRAINT PK_Olympiad PRIMARY KEY,
    Title       NVARCHAR(100) NOT NULL,
    HeldOn      DATE NOT NULL,
    CourseId    INT NULL CONSTRAINT FK_Olympiad_Course REFERENCES dbo.Course(CourseId),
    MaxScore    TINYINT NOT NULL CONSTRAINT DF_Olympiad_MaxScore DEFAULT (100),
    CONSTRAINT CK_Olympiad_Date CHECK (HeldOn >= '2020-01-01')
);

-- Зміна структури
ALTER TABLE dbo.Olympiad ADD Location NVARCHAR(100) NULL;
ALTER TABLE dbo.Olympiad ALTER COLUMN Title NVARCHAR(200) NOT NULL;
ALTER TABLE dbo.Olympiad ADD CONSTRAINT UQ_Olympiad UNIQUE (Title, HeldOn);

-- Індекс і представлення
CREATE INDEX IX_Olympiad_HeldOn ON dbo.Olympiad(HeldOn);
GO
CREATE VIEW dbo.vUpcomingOlympiads AS
    SELECT Title, HeldOn FROM dbo.Olympiad WHERE HeldOn >= CAST(GETDATE() AS DATE);
GO

-- Видалення
DROP VIEW dbo.vUpcomingOlympiads;
DROP TABLE dbo.Olympiad;
```

## 7.5. Маніпулювання даними мовою SQL

```sql
BEGIN TRAN;

-- INSERT: кілька рядків; OUTPUT повертає згенеровані значення
INSERT INTO dbo.Student (GroupId, RecordBookNo, LastName, FirstName, BirthDate, Gender, City)
OUTPUT inserted.StudentId, inserted.LastName
VALUES (5, '24040001', N'Бойко',  N'Ярослав', '2006-03-14', 'M', N'Київ'),
       (5, '24040002', N'Ковальчук', N'Ганна', '2006-08-02', 'F', N'Біла Церква');

-- UPDATE з умовою, що використовує іншу таблицю (через JOIN)
UPDATE s
SET    s.Scholarship = 2000
FROM   dbo.Student AS s
JOIN   dbo.StudentGroup AS g ON g.GroupId = s.GroupId
WHERE  g.Code = N'ФН-24' AND s.IsContract = 0;

-- DELETE з підзапитом
DELETE FROM dbo.Student
WHERE GroupId = (SELECT GroupId FROM dbo.StudentGroup WHERE Code = N'ФН-24')
  AND City <> N'Київ';

-- MERGE: «вставити або оновити» за один оператор
MERGE dbo.Course AS target
USING (VALUES ('DB101', N'Бази даних', 6.5),
              ('WEB201', N'Веб-технології', 4.0)) AS src(Code, Title, Credits)
   ON target.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET target.Credits = src.Credits
WHEN NOT MATCHED THEN
    INSERT (DepartmentId, Code, Title, Credits) VALUES (1, src.Code, src.Title, src.Credits)
OUTPUT $action AS Action, inserted.Code, inserted.Credits;

ROLLBACK;
```

## 7.6. Формування запитів мовою SQL

Загальний вигляд оператора `SELECT`:

```text
SELECT   [DISTINCT] [TOP (n)] список_виразів
FROM     джерела [JOIN ...]
WHERE    умова_відбору_рядків
GROUP BY стовпці_групування
HAVING   умова_відбору_груп
ORDER BY порядок_сортування [OFFSET ... FETCH ...]
```

!!! note "Логічний порядок виконання"
    СКБД обробляє речення не в порядку запису, а так:
    **FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → TOP/OFFSET**.
    Тому псевдонім стовпця з `SELECT` можна використати в `ORDER BY`, але не у `WHERE`.

### Обчислення в запитах

```sql
SELECT LastName + N' ' + LEFT(FirstName, 1) + N'.'  AS ShortName,      -- конкатенація
       Salary,
       Salary * 0.195                               AS EmployerTax,    -- арифметика
       Salary * 12                                  AS YearSalary,
       DATEDIFF(YEAR, HireDate, '2025-09-01')       AS Experience      -- стаж (років)
FROM dbo.Teacher
ORDER BY Salary DESC;
```

### Вибірка рядків конструкцією WHERE

```sql
-- Порівняння та логічні оператори
SELECT LastName, City, Scholarship FROM dbo.Student
WHERE Scholarship > 0 AND (City = N'Київ' OR City = N'Львів');

-- BETWEEN (діапазон включно з межами)
SELECT LastName, BirthDate FROM dbo.Student
WHERE BirthDate BETWEEN '2004-01-01' AND '2004-12-31';

-- IN (належність до множини)
SELECT LastName, Position FROM dbo.Teacher
WHERE Position IN (N'доцент', N'професор');

-- LIKE: % — будь-яка кількість символів, _ — рівно один символ
SELECT LastName FROM dbo.Student WHERE LastName LIKE N'%енко';
SELECT Code, Title FROM dbo.Course WHERE Code LIKE 'PRG_0_';

-- IS NULL (порівняння = NULL не працює!)
SELECT LastName FROM dbo.Student WHERE Email IS NULL;
```

### Сортування результатів (ORDER BY)

```sql
-- Сортування за кількома ключами: група за зростанням, бал за спаданням
SELECT GroupCode, StudentName, CourseTitle, Score
FROM dbo.vStudentGrades
ORDER BY GroupCode ASC, Score DESC;

-- Топ-3 найкращі оцінки (WITH TIES — разом з рівними за значенням)
SELECT TOP (3) WITH TIES StudentName, CourseTitle, Score
FROM dbo.vStudentGrades
ORDER BY Score DESC;

-- Посторінковий вивід: друга «сторінка» по 5 рядків
SELECT LastName, FirstName
FROM dbo.Student
ORDER BY LastName
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

### Використання вбудованих функцій

=== "Рядкові"

    ```sql
    SELECT LastName,
           UPPER(LastName)                     AS Upper_,
           LEN(LastName)                       AS Length_,
           SUBSTRING(LastName, 1, 3)           AS First3,
           REPLACE(Email, 'stud.edu.ua', '…')  AS ShortEmail,
           CONCAT(FirstName, N' ', LastName)   AS FullName,
           CHARINDEX(N'енко', LastName)        AS PosEnko
    FROM dbo.Student
    WHERE StudentId <= 3;
    ```

=== "Дата і час"

    ```sql
    SELECT LastName,
           BirthDate,
           YEAR(BirthDate)                          AS BirthYear,
           DATENAME(WEEKDAY, BirthDate)             AS WeekDay_,
           DATEDIFF(YEAR, BirthDate, GETDATE())     AS ApproxAge,
           DATEADD(YEAR, 18, BirthDate)             AS AdultSince,
           EOMONTH(BirthDate)                       AS EndOfMonth,
           FORMAT(BirthDate, 'dd.MM.yyyy')          AS UaFormat
    FROM dbo.Student
    WHERE StudentId <= 3;
    ```

=== "Математичні"

    ```sql
    SELECT Score,
           ROUND(Score / 20.0, 1)   AS FivePoint,
           CEILING(Score / 20.0)    AS Ceil_,
           FLOOR(Score / 20.0)      AS Floor_,
           POWER(Score, 2)          AS Squared,
           SQRT(Score)              AS Root,
           ABS(Score - 75)          AS DistFrom75
    FROM dbo.Grade
    WHERE StudentId = 1;
    ```

=== "Перетворення та NULL"

    ```sql
    SELECT LastName,
           ISNULL(Email, N'—')                         AS Email_,
           COALESCE(Email, City, N'невідомо')          AS FirstNotNull,
           NULLIF(Scholarship, 0)                      AS ScholarshipOrNull,
           CAST(Scholarship AS INT)                    AS AsInt,
           CONVERT(VARCHAR(10), BirthDate, 104)        AS Ddmmyyyy,
           TRY_CAST(RecordBookNo AS INT)               AS RecordAsInt,
           IIF(IsContract = 1, N'контракт', N'бюджет') AS Funding
    FROM dbo.Student
    WHERE StudentId IN (1, 3, 8);
    ```

=== "CASE"

    ```sql
    -- Перетворення 100-бальної оцінки в національну шкалу
    SELECT StudentName, CourseTitle, Score,
           CASE
               WHEN Score >= 90 THEN N'відмінно'
               WHEN Score >= 74 THEN N'добре'
               WHEN Score >= 60 THEN N'задовільно'
               ELSE                  N'незадовільно'
           END AS NationalScale
    FROM dbo.vStudentGrades
    WHERE GroupCode = N'КН-21';
    ```

### Групування результатів

**Агрегатні функції**: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` (а також `STRING_AGG`, `STDEV`, `VAR`).
`COUNT(*)` рахує рядки, `COUNT(стовпець)` — лише значення, відмінні від `NULL`.

```sql
SELECT COUNT(*)              AS Students,
       COUNT(Email)          AS WithEmail,
       COUNT(DISTINCT City)  AS Cities,
       SUM(Scholarship)      AS TotalScholarship,
       MAX(TuitionDebt)      AS MaxDebt
FROM dbo.Student;
```

??? example "Результат"
    | Students | WithEmail | Cities | TotalScholarship | MaxDebt |
    |---:|---:|---:|---:|---:|
    | 17 | 13 | 10 | 13000.00 | 18000.00 |

`GROUP BY` розбиває рядки на групи, `HAVING` відбирає групи (а `WHERE` — рядки до групування):

```sql
-- Середній бал і кількість незадовільних оцінок за дисциплінами,
-- лише дисципліни із середнім балом нижче 75
SELECT c.Title,
       COUNT(*)                                       AS Grades,
       CAST(AVG(CAST(g.Score AS DECIMAL(5,2))) AS DECIMAL(5,1)) AS AvgScore,
       SUM(CASE WHEN g.Score < 60 THEN 1 ELSE 0 END)  AS Fails
FROM dbo.Grade    AS g
JOIN dbo.Teaching AS t ON t.TeachingId = g.TeachingId
JOIN dbo.Course   AS c ON c.CourseId   = t.CourseId
GROUP BY c.Title
HAVING AVG(CAST(g.Score AS DECIMAL(5,2))) < 75
ORDER BY AvgScore;
```

??? example "Результат"
    | Title | Grades | AvgScore | Fails |
    |-------|-------:|---------:|------:|
    | Вища математика | 13 | 72.8 | 2 |
    | Основи програмування | 9 | 73.1 | 1 |
    | Економетрія | 4 | 74.0 | 0 |
    | Алгоритми та структури даних | 4 | 74.0 | 0 |
    | Системи штучного інтелекту | 4 | 74.5 | 0 |
    | Бази даних | 8 | 74.8 | 1 |

`ROLLUP` додає проміжні та загальний підсумки; функція `GROUPING()` повертає 1 у
підсумкових рядках:

```sql
SELECT CASE WHEN GROUPING(f.ShortName) = 1 THEN N'УСЬОГО'    ELSE f.ShortName END AS Faculty,
       CASE WHEN GROUPING(g.Code)      = 1 THEN N'— разом —' ELSE g.Code      END AS GroupCode,
       COUNT(s.StudentId) AS Students
FROM dbo.Faculty AS f
JOIN dbo.Department   AS d ON d.FacultyId    = f.FacultyId
JOIN dbo.StudentGroup AS g ON g.DepartmentId = d.DepartmentId
LEFT JOIN dbo.Student AS s ON s.GroupId      = g.GroupId
GROUP BY ROLLUP (f.ShortName, g.Code);
```

??? example "Результат"
    | Faculty | GroupCode | Students |
    |---------|-----------|---------:|
    | ЕФ | ЕК-22 | 4 |
    | ЕФ | ФН-24 | 0 |
    | ЕФ | — разом — | 4 |
    | ФІТ | КН-21 | 4 |
    | ФІТ | ПІ-21 | 5 |
    | ФІТ | ПІ-22 | 4 |
    | ФІТ | — разом — | 13 |
    | УСЬОГО | — разом — | 17 |

### З'єднання таблиць

```sql
-- INNER JOIN: лише пари, що мають відповідність
SELECT t.LastName, c.Title, g.Code
FROM dbo.Teaching AS tg
JOIN dbo.Teacher      AS t ON t.TeacherId = tg.TeacherId
JOIN dbo.Course       AS c ON c.CourseId  = tg.CourseId
JOIN dbo.StudentGroup AS g ON g.GroupId   = tg.GroupId;

-- LEFT JOIN: усі викладачі, навіть ті, що не ведуть занять
SELECT t.LastName, t.Position, COUNT(tg.TeachingId) AS Classes
FROM dbo.Teacher AS t
LEFT JOIN dbo.Teaching AS tg ON tg.TeacherId = t.TeacherId
GROUP BY t.LastName, t.Position
ORDER BY Classes;

-- Самоз'єднання (self join): викладач і його керівник
SELECT e.LastName AS Employee, m.LastName AS Manager
FROM dbo.Teacher AS e
LEFT JOIN dbo.Teacher AS m ON m.TeacherId = e.ManagerId;
```

### Вкладені запити (підзапити)

**Підзапит** — це `SELECT` усередині іншого оператора. Бувають:

* **скалярні** — повертають одне значення;
* **багаторядкові** — використовуються з `IN`, `ANY`, `ALL`, `EXISTS`;
* **корельовані** — посилаються на стовпці зовнішнього запиту і виконуються (логічно) для
  кожного його рядка;
* **табличні** — у реченні `FROM` (похідні таблиці) або у `WITH` (CTE).

```sql
-- Скалярний: викладачі з окладом вище середнього
SELECT LastName, Salary
FROM dbo.Teacher
WHERE Salary > (SELECT AVG(Salary) FROM dbo.Teacher);

-- IN: студенти, які мають хоча б одну незадовільну оцінку
SELECT LastName FROM dbo.Student
WHERE StudentId IN (SELECT StudentId FROM dbo.Grade WHERE Score < 60);

-- NOT EXISTS: дисципліни, які ніде не викладаються
SELECT c.Title FROM dbo.Course AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Teaching AS t WHERE t.CourseId = c.CourseId);

-- ALL: оцінки, вищі за ВСІ оцінки групи ПІ-22
SELECT StudentName, CourseTitle, Score FROM dbo.vStudentGrades
WHERE Score > ALL (SELECT Score FROM dbo.vStudentGrades WHERE GroupCode = N'ПІ-22');

-- Корельований: студенти, чий середній бал вищий за середній бал їхньої групи
SELECT s.LastName, s.GroupId
FROM dbo.Student AS s
WHERE (SELECT AVG(g.Score * 1.0) FROM dbo.Grade AS g WHERE g.StudentId = s.StudentId)
    > (SELECT AVG(g2.Score * 1.0)
       FROM dbo.Grade AS g2
       JOIN dbo.Student AS s2 ON s2.StudentId = g2.StudentId
       WHERE s2.GroupId = s.GroupId);

-- Табличний підзапит (похідна таблиця) і CTE
SELECT GroupCode, MaxAvg
FROM (SELECT GroupCode, MAX(AvgScore) AS MaxAvg
      FROM (SELECT GroupCode, StudentId, AVG(Score * 1.0) AS AvgScore
            FROM dbo.vStudentGrades GROUP BY GroupCode, StudentId) AS perStudent
      GROUP BY GroupCode) AS perGroup;
```

**Віконні функції** (розширення SQL) обчислюють значення по «вікну» рядків без
згортання їх у групи — наприклад, рейтинг студентів у групі:

```sql
WITH Avgs AS (
    SELECT GroupCode, StudentName, AVG(Score * 1.0) AS AvgScore
    FROM dbo.vStudentGrades
    GROUP BY GroupCode, StudentName
)
SELECT GroupCode, StudentName,
       CAST(AvgScore AS DECIMAL(5,1)) AS AvgScore,
       RANK() OVER (PARTITION BY GroupCode ORDER BY AvgScore DESC) AS RankInGroup
FROM Avgs
ORDER BY GroupCode, RankInGroup;
```

## 7.7. Процедурна мова SQL: процедури, що зберігаються, та тригери

**Transact-SQL** розширює SQL процедурними засобами: змінні, умови, цикли, обробка помилок.

```sql
DECLARE @group NVARCHAR(10) = N'ПІ-21',
        @avg   DECIMAL(5,2);

SELECT @avg = AVG(Score * 1.0) FROM dbo.vStudentGrades WHERE GroupCode = @group;

IF @avg >= 75
    PRINT CONCAT(N'Група ', @group, N' має добру успішність: ', @avg);
ELSE
    PRINT CONCAT(N'Група ', @group, N' потребує уваги: ', @avg);

DECLARE @i INT = 1;
WHILE @i <= 3
BEGIN
    PRINT CONCAT(N'Ітерація ', @i);
    SET @i += 1;
END;
```

### Процедури, що зберігаються

**Збережена процедура** — іменований набір операторів T-SQL, що зберігається в БД і
виконується на сервері. Переваги: повторне використання, менший мережевий трафік, план
виконання кешується, можна дати право виконувати процедуру без прав на таблиці, захист від
SQL-ін'єкцій (параметри).

```sql
CREATE OR ALTER PROCEDURE dbo.usp_GetGroupReport
    @GroupCode NVARCHAR(10),
    @MinScore  TINYINT = 0,                  -- параметр зі значенням за замовчуванням
    @Count     INT OUTPUT                    -- вихідний параметр
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.StudentGroup WHERE Code = @GroupCode)
    BEGIN
        RAISERROR(N'Групу %s не знайдено', 16, 1, @GroupCode);
        RETURN -1;
    END;

    SELECT StudentName, CourseTitle, Score, EctsGrade
    FROM dbo.vStudentGrades
    WHERE GroupCode = @GroupCode AND Score >= @MinScore
    ORDER BY StudentName, CourseTitle;

    SET @Count = @@ROWCOUNT;
    RETURN 0;
END;
GO

DECLARE @n INT, @rc INT;
EXEC @rc = dbo.usp_GetGroupReport @GroupCode = N'КН-21', @MinScore = 80, @Count = @n OUTPUT;
SELECT @rc AS ReturnCode, @n AS RowsReturned;

EXEC dbo.usp_GetGroupReport @GroupCode = N'XX-99', @Count = @n OUTPUT;   -- помилка
```

Процедура оплати навчання з обробкою помилок. `THROW` перериває пакет, тому кожен
виклик, що завершується помилкою, відокремлено `GO` (транзакції детально — у [Темі 8](topic8.md)):

```sql
CREATE OR ALTER PROCEDURE dbo.usp_PayTuition
    @StudentId INT,
    @Amount    DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
            INSERT INTO dbo.Payment (StudentId, Amount) VALUES (@StudentId, @Amount);

            UPDATE dbo.Student
            SET TuitionDebt = TuitionDebt - @Amount     -- CHECK (TuitionDebt >= 0) не дасть переплатити
            WHERE StudentId = @StudentId AND IsContract = 1;

            IF @@ROWCOUNT = 0
                THROW 50001, N'Студент не знайдений або навчається за бюджетом', 1;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;   -- передаємо помилку викликачу
    END CATCH;
END;
GO

EXEC dbo.usp_PayTuition @StudentId = 7, @Amount = 4000;       -- успішно: борг 9000 → 5000
SELECT StudentId, TuitionDebt FROM dbo.Student WHERE StudentId = 7;

GO
EXEC dbo.usp_PayTuition @StudentId = 7, @Amount = 99999;      -- помилка CHECK, усе відкочено
GO
EXEC dbo.usp_PayTuition @StudentId = 1, @Amount = 100;        -- помилка 50001 (бюджетник)
GO
SELECT COUNT(*) AS Payments FROM dbo.Payment WHERE StudentId IN (1, 7);   -- 2: зайвих оплат немає
```

**Функції** користувача повертають значення і можуть використовуватися в запитах:

```sql
-- Скалярна функція
CREATE OR ALTER FUNCTION dbo.fn_StudentAvg (@StudentId INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    RETURN (SELECT AVG(CAST(Score AS DECIMAL(5,2))) FROM dbo.Grade WHERE StudentId = @StudentId);
END;
GO

-- Вбудована таблична функція (параметризоване представлення)
CREATE OR ALTER FUNCTION dbo.fn_GroupStudents (@GroupCode NVARCHAR(10))
RETURNS TABLE
AS
RETURN
    SELECT s.StudentId, s.LastName, s.FirstName
    FROM dbo.Student AS s
    JOIN dbo.StudentGroup AS g ON g.GroupId = s.GroupId
    WHERE g.Code = @GroupCode;
GO

SELECT LastName, dbo.fn_StudentAvg(StudentId) AS AvgScore
FROM dbo.fn_GroupStudents(N'ПІ-22');
```

### Тригери

**Тригер** — спеціальна процедура, яку СКБД **автоматично** запускає у відповідь на подію:
`INSERT`, `UPDATE`, `DELETE` (DML-тригери) або `CREATE`, `ALTER`, `DROP` (DDL-тригери).

* `AFTER` — спрацьовує після виконання оператора (і перевірки обмежень);
* `INSTEAD OF` — виконується **замість** оператора (зручно для представлень).

У тілі DML-тригера доступні псевдотаблиці **`inserted`** (нові версії рядків) і
**`deleted`** (старі версії). `UPDATE` = `deleted` (до) + `inserted` (після).
Тригер спрацьовує **один раз на оператор**, тому має коректно обробляти багато рядків.

**Тригер аудиту** — журналює зміни оцінок:

```sql
CREATE OR ALTER TRIGGER dbo.trg_Grade_Audit
ON dbo.Grade
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditLog (TableName, Operation, RecordKey, Details)
    SELECT N'Grade',
           CASE WHEN i.StudentId IS NOT NULL AND d.StudentId IS NOT NULL THEN 'UPDATE'
                WHEN i.StudentId IS NOT NULL THEN 'INSERT'
                ELSE 'DELETE' END,
           CONCAT(COALESCE(i.StudentId, d.StudentId), N'/', COALESCE(i.TeachingId, d.TeachingId)),
           CONCAT(N'Score: ', d.Score, N' → ', i.Score)
    FROM inserted AS i
    FULL JOIN deleted AS d ON d.StudentId = i.StudentId AND d.TeachingId = i.TeachingId;
END;
GO

-- Перевірка: перескладання — оцінки < 60 підвищуємо до 60
UPDATE dbo.Grade SET Score = 60 WHERE Score < 60;

SELECT Operation, RecordKey, Details, ChangedBy, ChangedAt FROM dbo.AuditLog;
```

??? example "Результат"
    | Operation | RecordKey | Details | ChangedBy | ChangedAt |
    |-----------|-----------|---------|-----------|-----------|
    | UPDATE | 6/6 | Score: 55 → 60 | sa | … |
    | UPDATE | 4/4 | Score: 55 → 60 | sa | … |
    | UPDATE | 3/3 | Score: 55 → 60 | sa | … |
    | UPDATE | 2/2 | Score: 55 → 60 | sa | … |
    | UPDATE | 1/1 | Score: 55 → 60 | sa | … |

    Один оператор `UPDATE` змінив 5 рядків, тригер спрацював **один раз** і записав 5 рядків журналу.

**Тригер бізнес-правила** — стипендію можна призначити лише бюджетникові, і не більше
ніж 5000 грн:

```sql
CREATE OR ALTER TRIGGER dbo.trg_Student_ScholarshipRule
ON dbo.Student
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Scholarship) AND NOT UPDATE(IsContract) RETURN;

    IF EXISTS (SELECT 1 FROM inserted
               WHERE Scholarship > 0 AND (IsContract = 1 OR Scholarship > 5000))
    BEGIN
        ROLLBACK;   -- скасовує весь оператор, що викликав тригер
        THROW 50002, N'Стипендія можлива лише для бюджетників і не більше 5000 грн', 1;
    END;
END;
GO

UPDATE dbo.Student SET Scholarship = 1500 WHERE StudentId = 3;   -- помилка: контрактник
GO
UPDATE dbo.Student SET Scholarship = 3000 WHERE StudentId = 1;   -- успішно
```

**Тригер `INSTEAD OF`** дозволяє вставляти дані в представлення, яке з'єднує кілька
таблиць (без тригера така вставка неможлива):

```sql
CREATE OR ALTER VIEW dbo.vStudentCard
AS
SELECT s.StudentId, s.RecordBookNo, s.LastName, s.FirstName, s.BirthDate, s.Gender, g.Code AS GroupCode
FROM dbo.Student AS s
JOIN dbo.StudentGroup AS g ON g.GroupId = s.GroupId;
GO

CREATE OR ALTER TRIGGER dbo.trg_vStudentCard_Insert
ON dbo.vStudentCard
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Student (GroupId, RecordBookNo, LastName, FirstName, BirthDate, Gender)
    SELECT g.GroupId, i.RecordBookNo, i.LastName, i.FirstName, i.BirthDate, i.Gender
    FROM inserted AS i
    JOIN dbo.StudentGroup AS g ON g.Code = i.GroupCode;     -- шифр групи → ключ
END;
GO

INSERT INTO dbo.vStudentCard (RecordBookNo, LastName, FirstName, BirthDate, Gender, GroupCode)
VALUES ('24040010', N'Мазур', N'Остап', '2006-05-05', 'M', N'ФН-24');

SELECT * FROM dbo.vStudentCard WHERE GroupCode = N'ФН-24';
```

**DDL-тригер** рівня бази даних забороняє випадкове видалення таблиць:

```sql
CREATE OR ALTER TRIGGER trg_NoDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT N'Видалення таблиць заборонено. Спершу вимкніть тригер trg_NoDropTable.';
    ROLLBACK;
END;
GO

CREATE TABLE dbo.Temp_ (Id INT);
DROP TABLE dbo.Temp_;                         -- буде скасовано
GO

DISABLE TRIGGER trg_NoDropTable ON DATABASE;
DROP TABLE dbo.Temp_;                         -- тепер вдається
DROP TRIGGER trg_NoDropTable ON DATABASE;
```

## Контрольні питання

1. Чим декларативні мови запитів відрізняються від процедурних?
2. Як у бланку QBE задати умови, пов'язані через І та через АБО?
3. На які групи поділяються оператори SQL?
4. У якому порядку логічно виконуються речення оператора `SELECT`?
5. Чим `WHERE` відрізняється від `HAVING`?
6. Чим `COUNT(*)` відрізняється від `COUNT(Email)`?
7. Які види підзапитів ви знаєте? Що таке корельований підзапит?
8. Які переваги дають збережені процедури?
9. Що містять псевдотаблиці `inserted` і `deleted`? Чим тригер `AFTER` відрізняється від `INSTEAD OF`?
