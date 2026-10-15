# Тема 5. Фізична організація баз даних

Фізична організація визначає, **як** дані розміщуються в пам'яті та на диску і **як** до
них отримати доступ. Від неї залежить швидкодія, але не логіка запитів (фізична
незалежність даних, [Тема 1](topic1.md)).

## 5.1. Спискові структури

**Лінійний список** — упорядкована послідовність елементів (x<sub>1</sub>, x<sub>2</sub>, …, x<sub>n</sub>),
де для кожного елемента (крім крайніх) визначено попередній і наступний.

Окремі випадки лінійних списків за способом доступу:

| Структура | Принцип | Де трапляється в СКБД |
|-----------|---------|------------------------|
| **Стек** | LIFO: останнім прийшов — першим вийшов | стек викликів процедур, відкат вкладених операцій |
| **Черга** | FIFO: першим прийшов — першим вийшов | черга запитів на блокування, Service Broker |
| **Дек** | вставка/видалення з обох кінців | буферний пул сторінок |

### Послідовний розподіл пам'яті

Елементи списку розміщуються в **суміжних** комірках пам'яті (як масив). Адреса
i-го елемента обчислюється за формулою:

> **Addr(x<sub>i</sub>) = Addr(x<sub>1</sub>) + (i − 1) · L**, де L — довжина елемента.

* ✅ прямий доступ до будь-якого елемента за номером, мінімум службової пам'яті;
* ❌ вставка й видалення в середині вимагають зсуву всіх наступних елементів;
  розмір треба знати заздалегідь.

### Зв'язний розподіл пам'яті

Кожен елемент зберігає **покажчик (посилання)** на наступний (однозв'язний список)
або на наступний і попередній (двозв'язний список). Елементи можуть лежати будь-де.

```mermaid
flowchart LR
    H(["Голова"]) --> A["Петренко | •"] --> B["Іваненко | •"] --> C["Сидоренко | ∅"]
```

* ✅ вставка й видалення за O(1), якщо відома позиція; розмір не обмежений;
* ❌ доступ лише послідовний; додаткова пам'ять на покажчики.

Зв'язний список можна змоделювати в таблиці, де «покажчик» — ідентифікатор наступного
рядка. Обхід списку — рекурсивний запит:

```sql
USE UniversityDB;

-- Черга студентів на поселення в гуртожиток як однозв'язний список
CREATE TABLE dbo.DormQueue (
    NodeId    INT PRIMARY KEY,
    StudentId INT NOT NULL REFERENCES dbo.Student(StudentId),
    NextId    INT NULL REFERENCES dbo.DormQueue(NodeId)    -- «покажчик» на наступний вузол
);

-- Вузли лежать «у довільному місці», порядок задають лише покажчики
INSERT INTO dbo.DormQueue (NodeId, StudentId, NextId) VALUES
 (30, 13, NULL),   -- хвіст
 (10, 2,  20),     -- голова
 (20, 7,  30);

-- Обхід списку від голови
WITH Walk AS (
    SELECT q.NodeId, q.StudentId, q.NextId, 1 AS Pos
    FROM dbo.DormQueue AS q
    WHERE q.NodeId NOT IN (SELECT NextId FROM dbo.DormQueue WHERE NextId IS NOT NULL)
    UNION ALL
    SELECT q.NodeId, q.StudentId, q.NextId, w.Pos + 1
    FROM dbo.DormQueue AS q
    JOIN Walk AS w ON q.NodeId = w.NextId
)
SELECT w.Pos, s.LastName, w.NodeId, w.NextId
FROM Walk AS w JOIN dbo.Student AS s ON s.StudentId = w.StudentId
ORDER BY w.Pos;

-- Вставка в середину: змінюємо лише два покажчики, без зсуву інших елементів
INSERT INTO dbo.DormQueue (NodeId, StudentId, NextId) VALUES (25, 15, 30);
UPDATE dbo.DormQueue SET NextId = 25 WHERE NodeId = 20;
```

??? example "Результат обходу (до вставки)"
    | Pos | LastName | NodeId | NextId |
    |----:|----------|-------:|-------:|
    | 1 | Іваненко | 10 | 20 |
    | 2 | Павленко | 20 | 30 |
    | 3 | Демченко | 30 | NULL |

### Нелінійні зв'язні структури

Якщо елемент має **кілька** покажчиків, отримуємо нелінійні структури:

* **дерева** — кожен вузол має покажчики на нащадків (B-дерево індексу, [Тема 3](topic3.md));
* **багатозв'язні списки** — елемент одночасно входить у кілька списків (наприклад,
  рядок `Teaching` — у список дисциплін викладача і в список дисциплін групи);
* **графи** — довільні зв'язки (мережна модель, графові таблиці).

### Як це влаштовано в SQL Server

Дані зберігаються **сторінками по 8 КБ**. Сторінки одного рівня індексу утворюють
**двозв'язний список** (кожна сторінка має покажчики на попередню та наступну), а рівні
утворюють **B-дерево**. Перевіримо на демонстраційній таблиці з «широкими» рядками
(по 3 рядки на сторінку):

```sql
CREATE TABLE dbo.PageDemo (
    Id     INT NOT NULL PRIMARY KEY,
    Filler CHAR(2000) NOT NULL DEFAULT 'x'
);

INSERT INTO dbo.PageDemo (Id)
SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM sys.all_objects;

-- Сторінки таблиці: кореневий вузол B-дерева та двозв'язний список листків
SELECT allocated_page_page_id AS PageId, page_type_desc, page_level,
       previous_page_page_id  AS PrevPage, next_page_page_id AS NextPage
FROM sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID(N'dbo.PageDemo'), 1, NULL, 'DETAILED')
WHERE is_allocated = 1 AND page_type_desc IN ('DATA_PAGE', 'INDEX_PAGE')
ORDER BY page_level DESC, PageId;

-- Фізична адреса рядка: (файл:сторінка:слот)
SELECT Id, sys.fn_PhysLocFormatter(%%physloc%%) AS RowLocation
FROM dbo.PageDemo
WHERE Id IN (1, 2, 3, 4, 20);

DROP TABLE dbo.PageDemo;
```

??? example "Результат (номери сторінок у вас будуть інші)"
    | PageId | page_type_desc | page_level | PrevPage | NextPage |
    |-------:|----------------|-----------:|---------:|---------:|
    | 1001 | INDEX_PAGE | 1 | NULL | NULL |
    | 1000 | DATA_PAGE | 0 | NULL | 1002 |
    | 1002 | DATA_PAGE | 0 | 1000 | 1003 |
    | 1003 | DATA_PAGE | 0 | 1002 | 1004 |
    | … | … | … | … | … |
    | 1007 | DATA_PAGE | 0 | 1006 | NULL |

    | Id | RowLocation |
    |---:|-------------|
    | 1 | (1:1000:0) |
    | 2 | (1:1000:1) |
    | 3 | (1:1000:2) |
    | 4 | (1:1002:0) |
    | 20 | (1:1007:1) |

## 5.2. Представлення рядкових даних

Рядки (записи, текстові значення) бувають **фіксованої** та **змінної** довжини.

* **Фіксована довжина** — під кожне значення відводиться однакова кількість байтів;
  короткі значення доповнюються пропусками. Просто обчислювати адреси, але пам'ять
  витрачається марно.
* **Змінна довжина** — займає стільки, скільки треба, але потрібен спосіб визначити,
  де закінчується значення. Два підходи:

**Векторне представлення з дескриптором.** Перед даними (або окремо) зберігається
**дескриптор** — службова інформація: довжина значення, адреса початку. Так працюють
типи `VARCHAR`/`NVARCHAR` у SQL Server: у кожному записі є **масив зміщень** кінців
стовпців змінної довжини.

```text
┌──────────┬──────────────────────────┬──────────────────────┐
│ Довжина=8│ П е т р е н к о           │ ...                  │   ← дескриптор + дані
└──────────┴──────────────────────────┴──────────────────────┘
```

**Векторне представлення з граничним маркером.** Значення закінчується спеціальним
символом-**маркером**, якого немає в самих даних (наприклад, `\0` у мові C). Довжину
знаходять скануванням до маркера.

```text
┌───────────────────────────┬────┬───────────────────┐
│ П е т р е н к о            │ \0 │ І в а н е н к о \0 │   ← дані + маркер кінця
└───────────────────────────┴────┴───────────────────┘
```

| | Дескриптор | Граничний маркер |
|-|-----------|------------------|
| Визначення довжини | одразу, O(1) | скануванням, O(n) |
| Обмеження на дані | немає | маркер не може траплятися в даних |
| Службова пам'ять | поле довжини | 1 символ |

Порівняння фіксованої і змінної довжини в SQL Server:

```sql
DECLARE @fixed   CHAR(20)     = 'Petrenko',
        @var     VARCHAR(20)  = 'Petrenko',
        @nvar    NVARCHAR(20) = N'Петренко';

SELECT DATALENGTH(@fixed) AS CharBytes,      -- 20: доповнено пропусками до повної довжини
       DATALENGTH(@var)   AS VarcharBytes,   -- 8:  лише значення (+2 байти зміщення в записі)
       DATALENGTH(@nvar)  AS NVarcharBytes,  -- 16: UTF-16, по 2 байти на символ
       LEN(@fixed)        AS CharLen;        -- 8:  LEN ігнорує кінцеві пропуски

-- Скільки місця реально займають рядки таблиці Student
SELECT AVG(DATALENGTH(LastName)) AS AvgLastNameBytes,
       MAX(DATALENGTH(LastName)) AS MaxLastNameBytes
FROM dbo.Student;
```

## 5.3. Індексні методи доступу

**Індекс** — допоміжна структура, що зіставляє значенням **ключа пошуку** адреси записів.
Без індексу для пошуку треба переглянути всю таблицю (**сканування**); з індексом —
лише кілька сторінок (**пошук**, seek).

| Вид індексу | Опис | У SQL Server |
|-------------|------|--------------|
| **Щільний** | запис індексу для кожного запису файлу | некластерний індекс |
| **Розріджений** | запис індексу для кожного блоку (сторінки) | верхні рівні кластерного індексу |
| **Первинний / кластерний** | файл упорядкований за ключем індексу | `CLUSTERED` (один на таблицю) |
| **Вторинний / некластерний** | окрема структура з покажчиками на рядки | `NONCLUSTERED` (до 999) |

### Індексно-послідовний метод доступу (ISAM)

**ISAM** (Indexed Sequential Access Method) поєднує:

* **послідовний файл**, упорядкований за ключем (зручно читати діапазони);
* **багаторівневий індекс** (розріджений): індекс циліндрів → індекс доріжок → блоки;
* **області переповнення** для нових записів, що не вміщаються на своє місце.

Недолік класичного ISAM — статичний індекс: після багатьох вставок ланцюжки
переповнення ростуть і пошук сповільнюється, потрібна періодична реорганізація.
Сучасні СКБД замість ISAM використовують **B+-дерева**, які автоматично
балансуються при вставках (у SQL Server це кластерний індекс: листки впорядковані за
ключем і зв'язані в список, а верхні рівні — розріджений індекс).

### Порівняння: сканування проти пошуку за індексом

Створимо таблицю з 100 000 рядків і порівняємо кількість прочитаних сторінок:

```sql
SET NOCOUNT ON;

CREATE TABLE dbo.BigStudent (
    Id       INT IDENTITY PRIMARY KEY,                  -- кластерний індекс
    LastName NVARCHAR(50) NOT NULL,
    City     NVARCHAR(50) NOT NULL,
    Score    INT NOT NULL
);

WITH Numbers AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b
)
INSERT INTO dbo.BigStudent (LastName, City, Score)
SELECT N'Студент' + CAST(n AS NVARCHAR(10)),
       CHOOSE(n % 5 + 1, N'Київ', N'Львів', N'Одеса', N'Харків', N'Дніпро'),
       n * 37 % 101
FROM Numbers;

SET STATISTICS IO ON;   -- вкладка «Messages» покаже logical reads

-- 1) Пошук за неіндексованим стовпцем: сканування всієї таблиці (сотні сторінок)
SELECT Id, City FROM dbo.BigStudent WHERE LastName = N'Студент77777';

-- 2) Створюємо некластерний індекс
CREATE INDEX IX_BigStudent_LastName ON dbo.BigStudent(LastName);

-- 3) Той самий запит: пошук по B-дереву (кілька сторінок)
SELECT Id, City FROM dbo.BigStudent WHERE LastName = N'Студент77777';

-- 4) Діапазонний запит за кластерним ключем — послідовне читання сусідніх сторінок
SELECT COUNT(*) FROM dbo.BigStudent WHERE Id BETWEEN 1000 AND 2000;

SET STATISTICS IO OFF;
```

??? example "Повідомлення STATISTICS IO (приблизно)"
    ```text
    -- 1) Table 'BigStudent'. Scan count 1, logical reads 887 ...   ← прочитано всю таблицю
    -- 3) Table 'BigStudent'. Scan count 1, logical reads 6 ...     ← лише шлях по B-дереву
    -- 4) Table 'BigStudent'. Scan count 1, logical reads 12 ...    ← сусідні сторінки діапазону
    ```

Щоб побачити план виконання, у SSMS натисніть ++ctrl+m++ (*Include Actual Execution Plan*):
у першому запиті буде `Clustered Index Scan`, у третьому — `Index Seek` + `Key Lookup`.

## 5.4. Адресні методи доступу. Хешування

**Адресний (прямий) метод**: адреса запису обчислюється безпосередньо зі значення ключа
за допомогою **хеш-функції** h(K) → номер комірки (кошика, bucket) з діапазону 0…M−1.

Вимоги до хеш-функції: швидко обчислюватися та **рівномірно** розподіляти ключі.
Найпростіша — ділення з остачею: **h(K) = K mod M** (M бажано брати простим числом).

Якщо h(K<sub>1</sub>) = h(K<sub>2</sub>) при K<sub>1</sub> ≠ K<sub>2</sub>, виникає
**колізія**. Два основні способи їх розв'язання:

### Метод відкритої адресації

Усі записи зберігаються в самій таблиці. При колізії шукається інша вільна комірка за
правилом **пробування**: лінійне (h + 1, h + 2, …), квадратичне (h + 1², h + 2², …),
подвійне хешування.

Модель лінійного пробування в T-SQL — розмістимо номери залікових книжок у хеш-таблиці
на 11 комірок:

```sql
DECLARE @M INT = 11;
DECLARE @HashTable TABLE (Slot INT PRIMARY KEY, KeyValue INT NULL, Probes INT NULL);

INSERT INTO @HashTable (Slot)
SELECT TOP (@M) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 FROM sys.all_objects;

DECLARE @keys TABLE (Ord INT IDENTITY, K INT);
INSERT INTO @keys (K)
SELECT CAST(RecordBookNo AS INT) FROM dbo.Student WHERE GroupId IN (1, 3) ORDER BY StudentId;

DECLARE @i INT = 1, @n INT = (SELECT COUNT(*) FROM @keys), @k INT, @slot INT, @probes INT;
WHILE @i <= @n
BEGIN
    SELECT @k = K FROM @keys WHERE Ord = @i;
    SET @slot = @k % @M;          -- хеш-функція h(K) = K mod M
    SET @probes = 1;
    WHILE EXISTS (SELECT 1 FROM @HashTable WHERE Slot = @slot AND KeyValue IS NOT NULL)
    BEGIN
        SET @slot = (@slot + 1) % @M;   -- лінійне пробування: наступна комірка
        SET @probes += 1;
    END;
    UPDATE @HashTable SET KeyValue = @k, Probes = @probes WHERE Slot = @slot;
    SET @i += 1;
END;

SELECT Slot, KeyValue, KeyValue % @M AS HomeSlot, Probes
FROM @HashTable ORDER BY Slot;
```

Рядки, де `HomeSlot ≠ Slot`, потрапили не у «свою» комірку через колізію, а `Probes`
показує, скільки комірок довелося перевірити.

### Метод ланцюжків

Кожна комірка хеш-таблиці містить **покажчик на список** (ланцюжок) записів з однаковим
значенням хеш-функції. Колізії не заважають одна одній, таблиця не «переповнюється»,
але довгі ланцюжки сповільнюють пошук.

```sql
-- Модель методу ланцюжків: групуємо ключі за значенням хеш-функції
SELECT CAST(RecordBookNo AS INT) % 7 AS Bucket,
       STRING_AGG(CAST(RecordBookNo AS NVARCHAR(8)), N' → ') WITHIN GROUP (ORDER BY StudentId) AS Chain,
       COUNT(*) AS ChainLength
FROM dbo.Student
GROUP BY CAST(RecordBookNo AS INT) % 7
ORDER BY Bucket;
```

### Хеш-індекси в SQL Server

Справжні хеш-індекси (метод ланцюжків!) є в **таблицях в оперативній пам'яті**
(In-Memory OLTP). Їх варто використовувати для пошуку за **точним** значенням ключа;
для діапазонів (`BETWEEN`, `>`) хеш-індекс не підходить.

```sql
-- Одноразово: файлова група для таблиць в оперативній пам'яті
ALTER DATABASE UniversityDB ADD FILEGROUP UniversityDB_mod CONTAINS MEMORY_OPTIMIZED_DATA;
DECLARE @path NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(400));
EXEC (N'ALTER DATABASE UniversityDB ADD FILE (NAME = ''UniversityDB_mod'', FILENAME = '''
      + @path + N'UniversityDB_mod'') TO FILEGROUP UniversityDB_mod');
GO

CREATE TABLE dbo.SessionCache (
    SessionKey INT NOT NULL
        PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1024),
    StudentId  INT NOT NULL,
    LoginAt    DATETIME2 NOT NULL
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY);
GO

INSERT INTO dbo.SessionCache (SessionKey, StudentId, LoginAt)
SELECT StudentId * 7919, StudentId, SYSDATETIME() FROM dbo.Student;

-- Статистика хеш-індексу: кількість кошиків, порожні кошики, довжина ланцюжків
SELECT OBJECT_NAME(hs.object_id) AS TableName,
       hs.total_bucket_count, hs.empty_bucket_count,
       hs.avg_chain_length, hs.max_chain_length
FROM sys.dm_db_xtp_hash_index_stats AS hs
WHERE hs.object_id = OBJECT_ID(N'dbo.SessionCache');
```

## 5.5. Інвертований метод

**Інвертований файл (індекс)** будується за **неключовим** атрибутом: для кожного
значення атрибута зберігається **список адрес** записів, що мають це значення.
«Інвертований», бо замість «запис → значення» зберігається «значення → записи».
Дозволяє швидко відповідати на запити за вторинними ключами та їх комбінаціями
(перетином списків).

```sql
-- Інвертований список за атрибутом City: значення → список записів
SELECT City,
       STRING_AGG(CAST(StudentId AS VARCHAR(10)), ', ') WITHIN GROUP (ORDER BY StudentId) AS StudentIds
FROM dbo.Student
GROUP BY City
ORDER BY City;

-- Запит «з Києва І бюджетник» = перетин двох інвертованих списків
SELECT StudentId FROM dbo.Student WHERE City = N'Київ'
INTERSECT
SELECT StudentId FROM dbo.Student WHERE IsContract = 0;
```

??? example "Інвертований список (результат першого запиту)"
    | City | StudentIds |
    |------|------------|
    | Вінниця | 5 |
    | Дніпро | 15 |
    | Житомир | 4 |
    | Київ | 1, 3, 6, 8, 12, 14, 16 |
    | Львів | 2, 10 |
    | Одеса | 11 |
    | Полтава | 9 |
    | Суми | 17 |
    | Харків | 13 |
    | Черкаси | 7 |

У SQL Server інвертованими за своєю суттю є:

* **некластерні індекси** за неключовими стовпцями (`IX_Student_LastName`) — значення
  ключа індексу → покажчики на рядки;
* **повнотекстові індекси** — слово → список документів, де воно трапляється
  (потрібен компонент Full-Text Search):

```tsql
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
CREATE FULLTEXT INDEX ON dbo.Course(Title LANGUAGE 1058)   -- 1058 = українська
    KEY INDEX PK_Course;

SELECT Code, Title FROM dbo.Course WHERE CONTAINS(Title, N'програмування');
```

## Контрольні питання

1. Чим послідовний розподіл пам'яті відрізняється від зв'язного? Переваги та недоліки кожного.
2. Як обчислюється адреса елемента при послідовному розподілі?
3. Порівняйте представлення рядків змінної довжини з дескриптором і з граничним маркером.
4. Що таке ISAM? Які його недоліки усувають B+-дерева?
5. Чим кластерний індекс відрізняється від некластерного?
6. Що таке колізія хешування? Порівняйте метод відкритої адресації та метод ланцюжків.
7. Для яких запитів хеш-індекс ефективний, а для яких — ні?
8. Що таке інвертований файл? Наведіть приклад його використання.
