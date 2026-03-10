import importlib.util, sys
spec = importlib.util.spec_from_file_location('mm', 'src/menu.py')
mm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mm)
print(repr(mm._style_spec_to_ansi('red')))
print(repr(mm._style_spec_to_ansi('fg:red')))
print(repr(mm._style_spec_to_ansi('fg:#ff0000 bold')))
