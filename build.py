# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import requests
import venv
import py7zr
import shutil
import argparse
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
        url_response = requests.get("https://atb.xgj.qzz.io/other/binary_link.txt")
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


def run_step(cmd, bar, **kwargs):
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        **kwargs
    )
    for line in p.stdout:
        tqdm.write(line.rstrip())
    p.wait()
    bar.update(1)


def main(python_builder: int, profile: int):
    print("Build script running...")
    print("Release build") if profile == 0 else print("Debug Build")
    if not os.path.exists("bin.7z"):
        print("Download bin.7z first...")
        result = download_dependency()
        if not result:
            print("Failed to download dependency.")
            return 1

    os.makedirs("build", exist_ok=True)
    os.makedirs("./build/main", exist_ok=True)
    os.makedirs("./build/main/bin", exist_ok=True)
    os.makedirs("./build/rust", exist_ok=True)

    if not os.path.exists("./.venv/Scripts/python.exe"):
        venv.create("./.venv", with_pip=True)

    steps = [
        "windres",
        "g++",
        "pip",
        "nuitka run_cmd",
        "nuitka repair",
        "nuitka start",
        "cargo",
        "extract",
    ]

    with tqdm(
        total=len(steps),
        desc="Setting up ATB",
        unit="step",
        ncols=80,
        position=0,
        leave=True
    ) as bar:

        bar.set_description("Generating ICON Source")

        run_step(
            ["windres.exe", "-i", "./src/launch.rc", "-o", "./build/icon.o"],
            bar
        )

        bar.set_description("Building launcher")
        run_step(
            ["g++.exe", "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
             "-o", "build/main/双击运行.exe".encode("utf-8"),
             "-finput-charset=UTF-8", "-fexec-charset=GBK",
             "-lstdc++", "-lpthread", "-O3"],
            bar
        ) if profile == 0 else run_step(
            ["g++.exe", "-Wall", "-static", "./src/launch.cpp", "./build/icon.o", "-municode",
             "-o", "build/main/双击运行.exe".encode("utf-8"),
             "-finput-charset=UTF-8", "-fexec-charset=GBK",
             "-lstdc++", "-lpthread", "-Og"],
            bar
        )

        bar.set_description("Installing requirements")
        run_step(
            [os.path.join("./.venv", "Scripts", "pip.exe"), "install", "-r", "requirements.txt"],
            bar
        )

        if python_builder == 1:
            bar.set_description("Preparing Nuitka")
            gcc = os.path.dirname(
                subprocess.run(
                    ["cmd", "/c", "where", "gcc.exe"],
                    stdout=subprocess.PIPE
                ).stdout.decode("utf-8").replace("\r\n", "")
            )

            nuitka_gcc = os.getenv("LOCALAPPDATA") + r"\Nuitka\Nuitka\Cache\downloads\gcc\x86_64\14.2.0posix-19.1.1-12.0.0-msvcrt-r2\mingw64"
            if not os.path.exists(nuitka_gcc):
                os.makedirs(nuitka_gcc, exist_ok=True)
                os.symlink(gcc, nuitka_gcc + r"\bin")
            if profile == 0:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/run_cmd.py", "--mingw64"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/repair.py", "--mingw64"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=yes", "--output-dir=./build/py/dist",
                    "src/start.py", "--mingw64"],
                    bar
                )
            else:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug",
                    "src/run_cmd.py", "--mingw64"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug",
                    "src/repair.py", "--mingw64"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "python.exe"), "-m", "nuitka",
                    "--onefile", "--lto=no", "--output-dir=./build/py/dist", "--debug",
                    "src/start.py", "--mingw64"],
                    bar
                )
        else:
            if profile == 0:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist",
                    "src/run_cmd.py"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist",
                    "src/repair.py"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist",
                    "src/start.py"],
                    bar
                )
            else:
                bar.set_description("run_cmd.py -> run_cmd.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist", "-d", "all",
                    "src/run_cmd.py"],
                    bar
                )

                bar.set_description("repair.py -> repair.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist", "-d", "all",
                    "src/repair.py"],
                    bar
                )
                
                bar.set_description("start.py -> main.exe")
                run_step(
                    [os.path.join("./.venv", "Scripts", "pyinstaller.exe"), 
                    "--onefile", "--distpath", "./build/py/dist", "-d", "all",
                    "src/start.py"],
                    bar
                )

        bar.set_description("Building Rust Sources")
        run_step(
            ["cargo", "build", "--release", "--target-dir", "./build/rust"],
            bar,
            shell=True
        ) if profile == 0 else run_step(
            ["cargo", "build", "--target-dir", "./build/rust"],
            bar,
            shell=True
        )

        bar.set_description("Extracting Binaries")
        with py7zr.SevenZipFile('bin.7z', mode='r') as z:
            z.extractall(path='./build/main/bin')
        bar.update(1)

    src = "./src/bats/"
    dst = "./build/main/bin"
    for root, dirs, files in os.walk(src):
        for file in files:
            src_path = os.path.join(root, file)
            rel = os.path.relpath(src_path, src)
            dst_path = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)

    shutil.copy2("./build/py/dist/run_cmd.exe", "./build/main/bin/run_cmd.exe")
    shutil.copy2("./build/py/dist/start.exe", "./build/main/bin/main.exe")
    shutil.copy2("./build/py/dist/repair.exe", "./build/main/bin/repair.exe")
    shutil.copy2("./build/rust/release/jsonutil.exe", "./build/main/bin/jsonutil.exe")
    shutil.copy2("./build/rust/release/lolcat.exe", "./build/main/bin/lolcat.exe")

    print("Build completed.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build ATB.")
    parser.add_argument(
        "-t", "--type",
        choices=["release", "debug"],
        type=str.lower,
        default="release",
        help="Set build profile (release | debug). Default: release"
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--pyinstaller",
        action="store_true",
        help="Use PyInstaller (default)"
    )
    group.add_argument(
        "--nuitka",
        action="store_true",
        help="Use Nuitka"
    )
    args = parser.parse_args()

    if args.nuitka:
        pybuilder = 1
    else:
        pybuilder = 0
    
    profile = 0 if args.type == "release" else 1
    
    sys.exit(main(pybuilder, profile))
