import os
import sys
import gc
import importlib
import json
from types import ModuleType
from typing import List, Callable, Optional

from pluginutils import AtbPlugins
from pluginutils.swt import get_entries, clear_entries, clear_unloads, clear_loads, get_unloads, get_hooks, get_loads, clear_hooks


def load_plugins(atb_plugins: AtbPlugins, mode: int, cwd: Optional[str] | None = None) -> List[List[Callable], List[set]]:
    _cwd = cwd or atb_plugins._get_cwd()

    entries: List[Callable] = []

    os.chdir(atb_plugins.search_path)

    for plugin in atb_plugins.plugins:
        os.chdir(plugin)

        with open("plugin.json", "r", encoding="utf-8") as f:
            config = json.load(f)

        entry_mod_name = config.get("entry") or plugin

        clear_entries()
        clear_hooks()
        clear_unloads()

        if os.getcwd() not in sys.path:
            sys.path.insert(0, os.getcwd())

        mod: ModuleType = importlib.import_module(entry_mod_name)

        plugin_entries = get_entries() + get_hooks("entry")
        plugin_unloads = get_unloads()
        plugin_hooks = get_hooks('load') + get_loads()

        if atb_plugins.logger:
            atb_plugins.logger.info(f"[PluginLoader] {plugin} -> {str(len(plugin_entries))} entries, {str(len(plugin_unloads))} unloads, {str(len(plugin_hooks))} load hooks")

        entries.extend(plugin_entries)

        # Call load hooks if not already called in preload
        if mode == 0:
            for hook in plugin_hooks:
                try:
                    hook()
                except Exception as e:
                    if atb_plugins.logger:
                        atb_plugins.logger.error(f"[PluginLoader] load hook error in {plugin}: {e}, Skipping...")
        elif mode == 1:
            for entry in plugin_entries:
                try:
                    entry()
                except Exception as e:
                    if atb_plugins.logger:
                        atb_plugins.logger.error(f"[PluginLoader] load hook error in {plugin}: {e}, Skipping...")

        os.chdir("..")

    os.chdir(_cwd)

    return entries




def unload_plugins(mod_names):
    for f in get_unloads():
        try:
            f()
        except Exception as e:
            pass

    clear_unloads()
    clear_entries()
    clear_hooks()

    for name in mod_names:
        if name in sys.modules:
            del sys.modules[name]

    gc.collect()