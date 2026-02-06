# pluginutils/swt.py

from typing import Callable, List, Optional

_ENTRIES: List[Callable] = []


def entry(func: Callable) -> Callable:
    _ENTRIES.append(func)
    return func


def get_entries() -> List[Callable]:
    return list(_ENTRIES)


def clear_entries():
    _ENTRIES.clear()


_LOADS: List[Callable] = []


def preload(func: Callable) -> Callable:
    _LOADS.append(func)
    return func


def get_loads() -> List[Callable]:
    return list(_ENTRIES)


def clear_loads():
    _LOADS.clear()


_UNLOADS = []


def unload(func):
    _UNLOADS.append(func)
    return func


def get_unloads():
    return list(_UNLOADS)


def clear_unloads():
    _UNLOADS.clear()


_HOOKS = {}


def hook(name: str, data: Optional[set] | None = None):
    """
    Docstring for hook
    
    接收name参数，当name为load时将在atb启动时加载
    为entry时将于手动运行插件时加载
    TODO: 替换v1-bat插件api为这个ATB-PDK-v2Api
    TODO: 为register-mainmenu时，将注册主菜单新项目然后调用data: 在主菜单注入的名称和回调，示例：('新项目', lambda...)
    """
    def decorator(func: Callable) -> Callable:
        if name not in _HOOKS:
            _HOOKS[name] = []
        _HOOKS[name].append(func)
        return func
    return decorator


def get_hooks(name: str) -> List[Callable]:
    return list(_HOOKS.get(name, []))


def clear_hooks():
    _HOOKS.clear()
