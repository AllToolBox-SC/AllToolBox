import os
import sys
import logging
from typing import List, Optional


class PluginNotFoundException(Exception): pass

class UnsupportCheckAndModify(Exception): pass


class AtbPlugins(object):
    def __init__(self, plugins: List[str], search_path: str, logger: Optional[logging.Logger] | None = None):
        self.plugins = plugins
        self.search_path = search_path
        self.logger = logger

    @staticmethod
    def _get_cwd() -> str:
        cwd: str # noqa
        if getattr(sys, 'frozen', False):
            # PyInstaller Support
            cwd = os.path.dirname(sys.executable)
        else:
            # Use __file__ to support Nuitka
            cwd = os.path.dirname(os.path.abspath(__file__))

        return cwd

    def check_plugin_exists(self, check: bool = False, modify: bool = False) -> list[str] | None:
        if check and modify:
            raise UnsupportCheckAndModify("Cannot running checked and modify")

        if not os.path.exists(self.search_path):
            raise FileNotFoundError("The search path is not exists")

        if not os.path.isdir(self.search_path):
            raise NotADirectoryError("The search path is not a folder")

        plugin_dirs: List[str] = []

        for name in os.listdir(self.search_path):
            full = os.path.join(self.search_path, name)
            if os.path.isdir(full) and os.path.exists(os.path.join(full, "plugin.json")):
                plugin_dirs.append(name)

        found_plugins: List[str] = []
        plugins_not_found: List[str] = []

        for p in self.plugins:
            if p in plugin_dirs:
                found_plugins.append(p)
            else:
                plugins_not_found.append(p)

        if check and plugins_not_found:
            raise PluginNotFoundException(
                f"Plugin(s) not found: {', '.join(plugins_not_found)}"
            )

        if modify:
            self.plugins = found_plugins

        if check:
            return None

        return found_plugins

