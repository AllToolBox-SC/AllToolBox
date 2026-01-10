import requests
import os, sys
import time
import tqdm
import py7zr
import filehash


def main():
    print("AllToolBox 修复工具")
    with open(".\\bin\\bugversion.txt", "r") as fv:
        vcf = open(".\\bin\\version.txt")
        vc = vcf.read().strip()
        vcf.close()
        webv = requests.get(f"https://atb.xgj.qzz.io/other/bugup/{vc}/manifest.json", headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'})
        webvc = webv.json()["latestBugUpdate"]["ver"]
        filev = int(fv.read().strip())
        if webvc > filev:
            print("即将更新漏洞补丁...", end="")
            time.sleep(3)
            print("开始", end="\n")
            url = webv.json()["latestBugUpdate"]["url"]
            md5 = webv.json()["latestBugUpdate"]["md5"]
            response = requests.get(url, stream=True)
            size = int(response.headers.get("content-length", 0))
            with tqdm.tqdm(total=size, unit="B", unit_scale=True, desc="bugjump.7z") as bar:
               with open("bugjump.7z", "wb") as bj:
                   for data in response.iter_content(chunk_size=1024):
                       bj.write(data)
                       bar.update(len(data))
            md5f = filehash.FileHash("md5").hash_file("bugjump.7z")
            if md5f != md5:
                print("校验失败")
                os.system("pause")
                sys.exit(1)
            print("下载完成，开始解压...", end="")
            with py7zr.SevenZipFile("bugjump.7z", mode="r") as a:
                a.extractall(path=".\\")
            print("成功", end="\n")
            time.sleep(3)
            os.system("cmd /c start 双击运行.exe")
            
if __name__ == "__main__":
    main()
    sys.exit(0)