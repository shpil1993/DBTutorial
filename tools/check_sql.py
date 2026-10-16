#!/usr/bin/env python3
"""Виконує всі ```sql блоки сторінок курсу на SQL Server і показує помилки.

Перед кожною сторінкою база UniversityDB перестворюється скриптами docs/sql/01-03.
Блоки ```tsql не виконуються (вони потребують компонентів, яких немає на одному сервері).

Використання:
    python3 tools/check_sql.py docs/module1/topic4.md [інші.md ...] [-v] [--blocks 3,5]

Змінні середовища:
    MSSQL_CONTAINER  ім'я Docker-контейнера з SQL Server (за замовчуванням: mssql)
    MSSQL_SA_PASSWORD пароль користувача sa (за замовчуванням: Test_Passw0rd!)
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SETUP = ['01_create_database.sql', '02_seed_data.sql', '03_knowledge_base.sql']
CONTAINER = os.environ.get('MSSQL_CONTAINER', 'mssql')
PASSWORD = os.environ.get('MSSQL_SA_PASSWORD', 'Test_Passw0rd!')


def run_sql(sql: str, db: str = 'master') -> str:
    with tempfile.NamedTemporaryFile('w', suffix='.sql', encoding='utf-8', delete=False) as f:
        f.write(sql)
        path = f.name
    os.chmod(path, 0o644)   # sqlcmd у контейнері працює не від root
    try:
        cp = subprocess.run(['docker', 'cp', path, f'{CONTAINER}:/tmp/check.sql'], capture_output=True, text=True)
        if cp.returncode != 0:
            sys.exit(f'Контейнер {CONTAINER!r} недоступний ({cp.stderr.strip()}). Див. CLAUDE.md, розділ «Перевірка SQL».')
        res = subprocess.run(
            ['docker', 'exec', CONTAINER, '/opt/mssql-tools18/bin/sqlcmd', '-I', '-C',
             '-S', 'localhost', '-U', 'sa', '-P', PASSWORD, '-d', db,
             '-f', '65001', '-W', '-s', ' | ', '-i', '/tmp/check.sql'],
            capture_output=True, text=True, encoding='utf-8')
        return res.stdout + res.stderr
    finally:
        os.unlink(path)


def reset_db() -> None:
    for name in SETUP:
        out = run_sql((ROOT / 'docs' / 'sql' / name).read_text(encoding='utf-8'))
        if 'Msg ' in out or 'Sqlcmd: Error' in out:
            sys.exit(f'Не вдалося виконати {name}:\n{out}')


def sql_blocks(page: Path):
    text = page.read_text(encoding='utf-8')
    for m in re.finditer(r'^([ \t]*)```sql[^\n]*\n(.*?)^\1```', text, re.M | re.S):
        indent, body = m.group(1), m.group(2)
        if '--8<--' in body:          # вставка файлу через pymdownx.snippets
            continue
        lines = [l[len(indent):] if l.startswith(indent) else l for l in body.split('\n')]
        yield '\n'.join(lines)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('pages', nargs='+', type=Path)
    ap.add_argument('-v', '--verbose', action='store_true', help='показувати вивід усіх блоків')
    ap.add_argument('--blocks', help='номери блоків через кому')
    ap.add_argument('--no-reset', action='store_true', help='не перестворювати БД')
    args = ap.parse_args()
    only = {int(x) for x in args.blocks.split(',')} if args.blocks else None

    for page in args.pages:
        print(f'#### {page}')
        if not args.no_reset:
            reset_db()
        for i, block in enumerate(sql_blocks(page), 1):
            if only and i not in only:
                continue
            out = run_sql(block, 'UniversityDB')
            status = 'ERR' if ('Msg ' in out or 'Sqlcmd: Error' in out) else 'ok'
            first = block.strip().splitlines()[0][:70] if block.strip() else ''
            print(f'== block {i} [{status}] {first}')
            if status == 'ERR' or args.verbose:
                print(out.strip(), '\n')


if __name__ == '__main__':
    main()
