"""Lua syntax and behavioral checks using system liblua; no Roblox runtime required."""
import ctypes
import ctypes.util
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
lib = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]

def run(path, execute=False):
    state = lib.luaL_newstate()
    try:
        lib.luaL_openlibs(state)
        setup = ('ROOT = ' + json.dumps(str(root))).encode()
        assert lib.luaL_loadstring(state, setup) == 0
        assert lib.lua_pcallk(state, 0, 0, 0, 0, None) == 0
        result = lib.luaL_loadfilex(state, str(path).encode(), None)
        if result == 0 and execute:
            result = lib.lua_pcallk(state, 0, 0, 0, 0, None)
        if result:
            raise AssertionError(lib.lua_tolstring(state, -1, None).decode())
    finally:
        lib.lua_close(state)

for path in root.rglob('*.lua'):
    run(path)
run(root / 'tests/rules.lua', True)
run(root / 'tests/combat.lua', True)
run(root / 'tests/lifecycle.lua', True)
project = json.loads((root / 'default.project.json').read_text())
assert project['tree']['ServerScriptService']['$path'] == 'src/ServerScriptService'
assert json.loads((root / 'src/StarterPack/Rifle/init.meta.json').read_text())['className'] == 'Tool'
assert not (root / 'src/StarterPack/Rifle/Tool.meta.json').exists()
print('PASS: Lua syntax, mode rules, mocked combat/lifecycle, Rojo metadata')
