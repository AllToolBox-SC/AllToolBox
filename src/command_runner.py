import subprocess


def run(cmd: str) -> None:
    """Run a command inside cmd.exe with expected ATB environment."""
    subprocess.run(
        [
            "cmd.exe",
            "/c",
            "@echo off && setlocal enabledelayedexpansion > nul "
            "&& call .\\color.bat "
            "&& set PATH=%PATH%;C:\\Windows\\system32;C:\\Windows;"
            "C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;"
            "C:\\Windows\\System32\\OpenSSH\\;%cd%\\ "
            "&& set PATHEXT=%PATHEXT%;.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC; "
            f"&& {cmd} && endlocal",
        ],
        shell=True,
    )
