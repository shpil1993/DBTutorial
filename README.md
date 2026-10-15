# Бази даних — навчальний курс

Сайт курсу: https://shpil1993.github.io/DBTutorial/ (зібрано за допомогою [MkDocs Material](https://squidfunk.github.io/mkdocs-material/)).

Курс охоплює 9 тем програми дисципліни «Бази даних» (2 змістові модулі). Приклади написані на
Microsoft SQL Server (T-SQL) і виконуються на тестовій базі `UniversityDB`.

## Структура

```
docs/
  index.md              головна сторінка і зміст
  database.md           опис тестової БД UniversityDB, ER-діаграма
  sql/                  скрипти створення БД (01–03)
  module1/topic1-6.md   Модуль 1. Основи проектування БД
  module2/topic7-9.md   Модуль 2. Запити, транзакції, розподілені БД
mkdocs.yml              налаштування сайту та меню
```

## Локальний перегляд

```bash
pip install -r requirements.txt
mkdocs serve   # http://127.0.0.1:8000
```

## Тестова база даних

Виконайте в SQL Server 2019+ по черзі `docs/sql/01_create_database.sql`,
`02_seed_data.sql`, `03_knowledge_base.sql`. Скрипт 01 перестворює базу, тож ним же можна
повернути дані до початкового стану.

Пуш у гілку за замовчуванням публікує сайт у гілку `gh-pages` через GitHub Actions.
