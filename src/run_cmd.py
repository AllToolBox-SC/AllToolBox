import argparse
import subprocess
import sys
import datetime

def get_timestamp():
    return datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def execute_command(command):
    print(f'''[{get_timestamp()}] 执行命令: {command}''')
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
    print(result.stdout)
    return True


def main():
    parser = argparse.ArgumentParser(description='执行命令并格式化输出结果')
    parser.add_argument('command', help='要执行的命令')
    args = parser.parse_args()
    success = execute_command(args.command)
    print(f'''[{get_timestamp()}] 执行完毕''')
    if success:
        return None
    retry = input('执行失败，是否重试？(y/n): ').strip().lower()
    if retry != 'y':
        return None

if __name__ == '__main__':
    sys.exit(main())
