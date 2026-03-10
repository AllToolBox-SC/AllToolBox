import ctypes
kernel32 = ctypes.windll.kernel32
hOut = kernel32.GetStdHandle(-11)
mode = ctypes.c_uint()
if kernel32.GetConsoleMode(hOut, ctypes.byref(mode)):
    kernel32.SetConsoleMode(hOut, mode.value | 0x0004)
print('\x1b[31mVT-ENABLED-TEST\x1b[0m')
