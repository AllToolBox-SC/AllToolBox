# -*- coding: utf-8 -*-
"""临时脚本：独立测试 pause 实现（避免导入 start.py）"""
import sys
import os
import time
import threading

from prompt_toolkit.application import Application
from prompt_toolkit.application.current import get_app
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.layout import Layout
from prompt_toolkit.layout.containers import Window
from prompt_toolkit.layout.controls import FormattedTextControl
from prompt_toolkit.mouse_events import MouseEventType
from prompt_toolkit.styles import Style, merge_styles


def pause(message: str = "按任意键继续...", style_override=None, timeout: float | None = None) -> None:
    def _console_pause(msg: str, to: float | None):
        sys.stdout.write(msg)
        sys.stdout.flush()
        if to is not None and to <= 0:
            print()
            return
        # Windows
        try:
            import msvcrt
            start = time.time()
            if to is None:
                msvcrt.getwch()
            else:
                while True:
                    if msvcrt.kbhit():
                        msvcrt.getwch()
                        break
                    if time.time() - start >= to:
                        break
                    time.sleep(0.05)
            print()
            return
        except Exception:
            pass

        # POSIX
        try:
            import termios
            import tty
            import select

            fd = sys.stdin.fileno()
            old_attrs = termios.tcgetattr(fd)
            try:
                tty.setraw(fd)
                if to is None:
                    os.read(fd, 1)
                else:
                    rlist, _, _ = select.select([fd], [], [], to)
                    if rlist:
                        os.read(fd, 1)
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_attrs)
            print()
            return
        except Exception:
            pass

        try:
            input()
        except Exception:
            pass

    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        _console_pause(message, timeout)
        return

    try:
        chosen_style = style_override or Style.from_dict({})
        pause_style = Style.from_dict({"pause": "fg:#9dcffb bold"})
        app_style = merge_styles([chosen_style, pause_style]) if chosen_style else pause_style

        kb = KeyBindings()

        @kb.add("enter", eager=True)
        @kb.add(" ", eager=True)
        def _enter(event):
            event.app.exit()

        @kb.add("<any>")
        def _any(event):
            event.app.exit()

        def _mouse_handler(mouse_event):
            if mouse_event.event_type == MouseEventType.MOUSE_UP:
                try:
                    get_app().exit()
                except Exception:
                    pass
            return None

        class PauseControl(FormattedTextControl):
            def __init__(self, render_fn, handler):
                super().__init__(render_fn, focusable=True, show_cursor=False)
                self._handler = handler

            def mouse_handler(self, mouse_event):
                return self._handler(mouse_event)

        control = PauseControl(lambda: [("class:pause", message)], _mouse_handler)
        window = Window(content=control, always_hide_cursor=True, dont_extend_width=False, dont_extend_height=False)

        app = Application(
            layout=Layout(window, focused_element=control),
            key_bindings=kb,
            mouse_support=True,
            full_screen=False,
            style=app_style,
        )

        if timeout is not None and timeout > 0:
            def _timer():
                time.sleep(timeout)
                try:
                    app.exit()
                except Exception:
                    pass

            t = threading.Thread(target=_timer, daemon=True)
            t.start()

        app.run()
    except Exception:
        _console_pause(message, timeout)


if __name__ == "__main__":
    print("Calling pause (1s timeout)...")
    pause("测试 pause (1s)", None, 1)
    print("Returned")
