import subprocess
import time
import os
import sys
os.chdir(".\\build\\main\\bin")
EXE = ".\\start.bat"
os.system("chcp 936 > nul")
process = subprocess.Popen([EXE], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
# process.stdin.write("no\n".encode("gbk"))
# process.stdin.close()
# 在15秒内记录stdout和stderr到变量
try:
    stdout, stderr = process.communicate(timeout=15, input="no\r\n".encode("gbk", errors="ignore"))
except subprocess.TimeoutExpired:
    process.kill()
    stdout, stderr = process.communicate()
try:
    process.terminate()
except:
    pass

try:
    print("STDOUT:")
    print(stdout.decode("gbk"))
    print("STDERR: (ignore the unsupported redirection error)")
    print(stderr.decode("gbk").replace('错误: 不支持输入重新定向，立即退出此进程。\r\n', ''))
except (UnicodeEncodeError, UnicodeDecodeError):
    print(stdout.decode("utf-8", errors="ignore"))
    print("STDERR: (ignore the unsupported redirection error)")
    print(stderr.decode("utf-8", errors="ignore").replace('错误: 不支持输入重新定向，立即退出此进程。\r\n'))

try:
    str_stdout = stdout.decode("gbk")
except (UnicodeEncodeError, UnicodeDecodeError):
    str_stdout = stdout.decode("utf-8", errors="ignore")
if "XTC AllToolBox 控制台&主菜单" in str_stdout:
    sys.exit(0)
sys.exit(1)
