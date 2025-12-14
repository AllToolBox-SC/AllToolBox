import os
import sys
import subprocess
import requests
import venv
import py7zr
import shutil
from tqdm import tqdm

def download_dependency():
    url = ""
    if os.path.exists("bin.7z"):
        print("bin.7z already exists.")
        return True
    if os.path.exists("binary_link.txt"):
        with open("binary_link.txt", "r") as f:
            url = f.read().strip()
    else:
        url_response = requests.get("https://atb.xgj.qzz.io/binary_link.txt")
        url = url_response.text.strip()
    print(f"Downloading bin.7z from {url} ...")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        total_size = int(response.headers.get('content-length', 0))
        with open("bin.7z", "wb") as f, tqdm(
            desc="Downloading",
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                bar.update(len(chunk))
        print("Downloaded bin.7z successfully.")
        return True
    else:
        print(f"Failed to download bin.7z. Status code: {response.status_code}")
        return False

def main():
    print("Build script running...")
    if not os.path.exists("bin.7z"):
        print("Download bin.7z first...")
        result = download_dependency()
        if not result:
            print("Failed to download dependency.")
            return 1
    if not os.path.exists("build"):
        os.makedirs("build")
    os.makedirs(".\\build\\main", exist_ok=True)
    subprocess.run(["windres.exe", "-i", ".\\src\\launch.rc", "-o", ".\\build\\icon.o"])
    subprocess.run(["g++.exe", "-static", ".\\src\\launch.cpp", ".\\build\\icon.o", "-municode", "-o", ".\\build\\main\\双击运行.exe", "-lstdc++", "-lpthread"])
    os.makedirs(".\\build\\main\\bin", exist_ok=True)
    if not os.path.exists(".\\.venv\\Scripts\\python.exe"):
        venv.create(".\\.venv", with_pip=True)
    subprocess.run([os.path.join(".\\.venv", "Scripts", "pip.exe"), "install", "-r", "requirements.txt"])
    if not os.path.exists(".\\build\\py"):
        os.makedirs(".\\build\\py")
    os.makedirs(".\\build\\py\\dist", exist_ok=True)
    subprocess.run([os.path.join(".\\.venv", "Scripts", "pyinstaller.exe"), "--onefile", "--distpath", ".\\build\\py\\dist", "src\\run_cmd.py"])
    with py7zr.SevenZipFile('bin.7z', mode='r') as z:
        z.extractall(path='.\\build\\main\\bin')

    src = "./src/bats/"
    dst = "./build/main/bin"
    for root, dirs, files in os.walk(src):
        for file in files:
            src_path = os.path.join(root, file)

            rel = os.path.relpath(src_path, src)
            dst_path = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)
    shutil.copy2(".\\build\\py\\dist\\run_cmd.exe", ".\\build\\main\\bin\\run_cmd.exe")
    print("Build completed.")

    return 0

if __name__ == "__main__":
    sys.exit(main())
