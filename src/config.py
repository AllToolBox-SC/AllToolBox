from prompt_toolkit.styles import Style

style = Style.from_dict(
    {
        "yellow": "fg:yellow",
        "red": "fg:red",
        "orange": "fg:orange",
        "info": "fg:#3B78FF",
        "black": "fg:black",
        "cyan": "fg:cyan",
        "green": "fg:green",
        "blue": "fg:blue",
        "magenta": "fg:magenta",
        "white": "fg:white",
        "reset": "",
        "number": "bold",
        "selected-option": "underline bold",
    }
)

INFO = "<info>[信息]</info>"
ERROR = "<red>[错误]</red>"
WARN = "<orange>[警告]</orange>"
LINE = "-" * 68
