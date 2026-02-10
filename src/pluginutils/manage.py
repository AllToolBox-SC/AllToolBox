import tarfile
import os
import sys
import py7zr
import subprocess

class PluginPackage(object):
    def __init__(self, pluginfile: str, install_dir: str):
        self.pluginfile: str = pluginfile
        self.extract_dir: str = self.extract_to(install_dir) or install_dir
        
    def extract_to(self, target_dir: str) -> str:
        if self.pluginfile.endswith('.7z'):
            with py7zr.SevenZipFile(self.pluginfile, 'r') as archive:
                archive.extractall(path=target_dir)
        elif self.pluginfile.endswith('.tar.xz') or self.pluginfile.endswith('.txz'):
            with tarfile.open(self.pluginfile, 'r:*') as tar:
                tar.extractall(path=target_dir)
        else:
            raise ValueError("Unsupported file type")
        return target_dir
    

    def install_to(self) -> dict:
        """ TODO: Signature Verfication """
        pass
