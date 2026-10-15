/* =====================================================================
   UniversityDB — скрипт 3: схема kb для прикладів Теми 6 «Організація баз знань».
   Запускати після 01 і 02. Потрібен SQL Server 2019+ (графові таблиці + SHORTEST_PATH).
   ===================================================================== */
SET QUOTED_IDENTIFIER ON;
GO

USE UniversityDB;
GO

IF SCHEMA_ID(N'kb') IS NULL EXEC (N'CREATE SCHEMA kb');
GO

DROP TABLE IF EXISTS kb.RuleCondition, kb.[Rule], kb.Fact,
                     kb.Slot, kb.Frame, kb.Link, kb.Concept,
                     kb.Road, kb.City, kb.CityNode, kb.RoadEdge;
GO

SET NOCOUNT ON;

/* ---------- 1. Продукційна модель (правила «ЯКЩО … ТО …») ---------- */

CREATE TABLE kb.Fact (
    FactCode    VARCHAR(30)   NOT NULL CONSTRAINT PK_Fact PRIMARY KEY,
    Description NVARCHAR(200) NOT NULL
);

CREATE TABLE kb.[Rule] (
    RuleId         INT         NOT NULL CONSTRAINT PK_Rule PRIMARY KEY,
    ConclusionCode VARCHAR(30) NOT NULL CONSTRAINT FK_Rule_Fact REFERENCES kb.Fact(FactCode),
    Certainty      DECIMAL(3,2) NOT NULL CONSTRAINT DF_Rule_Certainty DEFAULT (1.00)
);

-- Умови правила об'єднуються через «І»
CREATE TABLE kb.RuleCondition (
    RuleId   INT         NOT NULL CONSTRAINT FK_RuleCondition_Rule REFERENCES kb.[Rule](RuleId),
    FactCode VARCHAR(30) NOT NULL CONSTRAINT FK_RuleCondition_Fact REFERENCES kb.Fact(FactCode),
    CONSTRAINT PK_RuleCondition PRIMARY KEY (RuleId, FactCode)
);

INSERT INTO kb.Fact (FactCode, Description) VALUES
 ('avg_ge_90',          N'Середній бал не нижче 90'),
 ('avg_ge_75',          N'Середній бал не нижче 75'),
 ('no_fails',           N'Немає незадовільних оцінок'),
 ('has_fails',          N'Є незадовільні оцінки'),
 ('budget',             N'Навчається за бюджетом'),
 ('social_activity',    N'Бере участь у громадському житті'),
 ('excellent',          N'Відмінник'),
 ('scholarship',        N'Має право на академічну стипендію'),
 ('high_scholarship',   N'Має право на підвищену стипендію'),
 ('risk',               N'Група ризику (потребує консультацій)');

INSERT INTO kb.[Rule] (RuleId, ConclusionCode, Certainty) VALUES
 (1, 'excellent',        1.00),   -- ЯКЩО avg_ge_90 І no_fails            ТО excellent
 (2, 'scholarship',      1.00),   -- ЯКЩО avg_ge_75 І no_fails І budget   ТО scholarship
 (3, 'high_scholarship', 0.90),   -- ЯКЩО excellent І scholarship І social_activity ТО high_scholarship
 (4, 'risk',             0.80);   -- ЯКЩО has_fails                       ТО risk

INSERT INTO kb.RuleCondition (RuleId, FactCode) VALUES
 (1, 'avg_ge_90'), (1, 'no_fails'),
 (2, 'avg_ge_75'), (2, 'no_fails'), (2, 'budget'),
 (3, 'excellent'), (3, 'scholarship'), (3, 'social_activity'),
 (4, 'has_fails');

/* ---------- 2. Семантична мережа (графові таблиці SQL Server) ---------- */

CREATE TABLE kb.Concept (
    ConceptId INT           NOT NULL PRIMARY KEY,
    Name      NVARCHAR(50)  NOT NULL UNIQUE
) AS NODE;

CREATE TABLE kb.Link (
    RelType NVARCHAR(30) NOT NULL       -- is_a, part_of, works_at, teaches, studies ...
) AS EDGE;

INSERT INTO kb.Concept (ConceptId, Name) VALUES
 (1, N'Людина'), (2, N'Студент'), (3, N'Викладач'), (4, N'Група'),
 (5, N'Кафедра'), (6, N'Факультет'), (7, N'Дисципліна'), (8, N'Університет');

INSERT INTO kb.Link ($from_id, $to_id, RelType)
SELECT f.$node_id, t.$node_id, v.RelType
FROM (VALUES
        (N'Студент',    N'Людина',      N'is_a'),
        (N'Викладач',   N'Людина',      N'is_a'),
        (N'Студент',    N'Група',       N'part_of'),
        (N'Група',      N'Кафедра',     N'part_of'),
        (N'Кафедра',    N'Факультет',   N'part_of'),
        (N'Факультет',  N'Університет', N'part_of'),
        (N'Викладач',   N'Кафедра',     N'works_at'),
        (N'Викладач',   N'Дисципліна',  N'teaches'),
        (N'Студент',    N'Дисципліна',  N'studies')
     ) AS v(FromName, ToName, RelType)
JOIN kb.Concept AS f ON f.Name = v.FromName
JOIN kb.Concept AS t ON t.Name = v.ToName;

/* ---------- 3. Фрейми зі слотами та успадкуванням (IS-A) ---------- */

CREATE TABLE kb.Frame (
    FrameId       INT          NOT NULL CONSTRAINT PK_Frame PRIMARY KEY,
    Name          NVARCHAR(50) NOT NULL CONSTRAINT UQ_Frame_Name UNIQUE,
    ParentFrameId INT          NULL CONSTRAINT FK_Frame_Parent REFERENCES kb.Frame(FrameId)
);

CREATE TABLE kb.Slot (
    FrameId   INT           NOT NULL CONSTRAINT FK_Slot_Frame REFERENCES kb.Frame(FrameId),
    SlotName  NVARCHAR(50)  NOT NULL,
    SlotValue NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Slot PRIMARY KEY (FrameId, SlotName)
);

INSERT INTO kb.Frame (FrameId, Name, ParentFrameId) VALUES
 (1, N'Людина',         NULL),
 (2, N'Студент',        1),
 (3, N'Студент-бюджетник', 2),
 (4, N'Петренко Іван',  3);       -- фрейм-екземпляр

INSERT INTO kb.Slot (FrameId, SlotName, SlotValue) VALUES
 (1, N'Має ім''я',          N'так'),
 (1, N'Громадянство',       N'Україна'),
 (2, N'Навчальний заклад',  N'Університет'),
 (2, N'Форма навчання',     N'денна'),
 (3, N'Фінансування',       N'державний бюджет'),
 (3, N'Стипендія',          N'2000 грн'),
 (4, N'Група',              N'ПІ-21'),
 (4, N'Стипендія',          N'2500 грн');   -- перевизначає успадковане значення

/* ---------- 4. Карта доріг для стратегій пошуку ---------- */

CREATE TABLE kb.City (
    CityId INT          NOT NULL CONSTRAINT PK_City PRIMARY KEY,
    Name   NVARCHAR(50) NOT NULL CONSTRAINT UQ_City_Name UNIQUE,
    -- пряма відстань до Львова (км) — евристика для методу «піднімання вгору»
    StraightToLviv INT  NOT NULL
);

CREATE TABLE kb.Road (
    FromCityId INT NOT NULL CONSTRAINT FK_Road_From REFERENCES kb.City(CityId),
    ToCityId   INT NOT NULL CONSTRAINT FK_Road_To   REFERENCES kb.City(CityId),
    DistanceKm INT NOT NULL CONSTRAINT CK_Road_Distance CHECK (DistanceKm > 0),
    CONSTRAINT PK_Road PRIMARY KEY (FromCityId, ToCityId)
);

INSERT INTO kb.City (CityId, Name, StraightToLviv) VALUES
 ( 1, N'Київ',      470), ( 2, N'Житомир',  340), ( 3, N'Рівне',   180),
 ( 4, N'Львів',       0), ( 5, N'Вінниця',  300), ( 6, N'Хмельницький', 220),
 ( 7, N'Тернопіль',  120), ( 8, N'Умань',    400), ( 9, N'Черкаси', 560),
 (10, N'Полтава',   740), (11, N'Одеса',    640);

-- Дороги задаються в одному напрямку, а потім дзеркалюються (неорієнтований граф).
-- Відстані умовні, для навчальних прикладів.
INSERT INTO kb.Road (FromCityId, ToCityId, DistanceKm) VALUES
 (1, 2, 140), (1, 9, 190), (1, 10, 340), (1, 8, 210),
 (2, 3, 190), (2, 5, 130), (2, 6, 180),
 (3, 4, 210), (3, 7, 160),
 (5, 6, 120), (5, 8, 160),
 (6, 7, 110), (7, 4, 130),
 (8, 9, 190), (8, 11, 270);

INSERT INTO kb.Road (FromCityId, ToCityId, DistanceKm)
SELECT ToCityId, FromCityId, DistanceKm FROM kb.Road;

-- Та сама карта у вигляді графових таблиць (для MATCH / SHORTEST_PATH)
CREATE TABLE kb.CityNode (CityId INT NOT NULL PRIMARY KEY, Name NVARCHAR(50) NOT NULL) AS NODE;
CREATE TABLE kb.RoadEdge (DistanceKm INT NOT NULL) AS EDGE;

INSERT INTO kb.CityNode (CityId, Name) SELECT CityId, Name FROM kb.City;

INSERT INTO kb.RoadEdge ($from_id, $to_id, DistanceKm)
SELECT f.$node_id, t.$node_id, r.DistanceKm
FROM kb.Road AS r
JOIN kb.CityNode AS f ON f.CityId = r.FromCityId
JOIN kb.CityNode AS t ON t.CityId = r.ToCityId;
GO

PRINT N'UniversityDB: схему kb (база знань) створено.';
