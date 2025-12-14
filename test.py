import subprocess
import time
import os
import sys
os.chdir(".\\build\\main\\bin")
EXE = ".\\start.bat"

process = subprocess.Popen([EXE], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
# process.stdin.write("no\n".encode("gbk"))
# process.stdin.close()
# 在15秒内记录stdout和stderr到变量
try:
    stdout, stderr = process.communicate(timeout=15, input="no\r\n".encode("gbk"))
except subprocess.TimeoutExpired:
    process.kill()
    stdout, stderr = process.communicate()
try:
    process.terminate()
except:
    pass
print("STDOUT:")
print(stdout.decode("gbk"))
print("STDERR: (ignore the unsupported redirection error)")
print(stderr.decode("gbk").replace('错误: 不支持输入重新定向，立即退出此进程。\r\n', ''))
if "XTC AllToolBox 控制台&主菜单" in stdout.decode("gbk"):
    sys.exit(0)
sys.exit(1)
