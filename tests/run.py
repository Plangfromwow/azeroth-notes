from pathlib import Path
from lupa.luajit21 import LuaRuntime
import os
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
os.chdir(root)
ET.parse(root / 'AzerothNotes' / 'Bindings.xml')
for line in (root / 'AzerothNotes' / 'AzerothNotes.toc').read_text().splitlines():
    if line.strip() and not line.startswith('#'):
        assert (root / 'AzerothNotes' / line).is_file(), f'Missing TOC file: {line}'
lua = LuaRuntime(unpack_returned_tuples=True)
for path in sorted((root / 'AzerothNotes').glob('*.lua')):
    lua.execute('assert(loadfile(...))', path.as_posix())
for path in sorted((root / 'tests').glob('*_test.lua')):
    print(f'Running {path.name}', flush=True)
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute('dofile(...)', path.as_posix())
print('All syntax and behavior checks passed.')
