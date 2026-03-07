# -*- coding: utf-8 -*-
"""
Menu utilities extracted from start.py for reuse by Python and batch callers.
Provides interactive menu rendering plus config-driven action resolution via JSON.
"""
from __future__ import annotations
import asyncio
import time
import threading
import os
import json
import sys
from typing import Iterable, List, Tuple

from prompt_toolkit import HTML, prompt
from prompt_toolkit.application import Application
from prompt_toolkit.application.current import get_app
from prompt_toolkit.key_binding import KeyBindings, merge_key_bindings
from prompt_toolkit.layout import Layout
from prompt_toolkit.layout.containers import Window
from prompt_toolkit.layout.controls import FormattedTextControl
from prompt_toolkit.mouse_events import MouseButton, MouseEventType
from prompt_toolkit.styles import Style, merge_styles

DEFAULT_STYLE: Style | None = None


def _clear_menu_lines(count: int) -> None:
    """Clear the last `count` lines from the terminal (ANSI)."""
    try:
        for _ in range(count):
            sys.stdout.write("\033[F\033[K")  # move cursor up 1 line and clear it
        sys.stdout.flush()
    except Exception:
        pass


class Option:
    def __init__(self, value, label):
        self.value = value
        self.label = label


def set_default_style(style: Style) -> None:
    global DEFAULT_STYLE
    DEFAULT_STYLE = style


def menu_choice(
    message: str,
    options: Iterable[Tuple[str, str]],
    default: str | None = None,
    style_override: Style | None = None,
    extra_bindings: KeyBindings | None = None,
):
    option_list: List[tuple] = list(options)
    if not option_list:
        raise ValueError("menu_choice requires at least one option")

    selected_index = 0
    display_index = 0
    animate_in = True
    visible_count = 0 if animate_in else len(option_list)
    move_task = None

    if default is not None:
        for idx, (value, _) in enumerate(option_list):
            if value == default:
                selected_index = idx
                display_index = idx
                break

    kb = KeyBindings()

    @kb.add("enter", eager=True)
    @kb.add(" ", eager=True)
    def _(event):
        idx = selected_index or 0
        event.app.exit(result=option_list[idx][0])

    digit_buf = {"text": "", "t": 0.0}

    def _select_by_number(event, digit: str) -> None:
        now = time.monotonic()
        if now - digit_buf["t"] > 0.2:
            digit_buf["text"] = ""
        digit_buf["text"] += digit
        digit_buf["t"] = now
        try:
            idx = int(digit_buf["text"]) - 1
        except ValueError:
            return
        if 0 <= idx < len(option_list):
            _set_selection(idx, event.app)

    for d in "0123456789":
        @kb.add(d, eager=True)
        def _(event, _d=d):
            _select_by_number(event, _d)

    def _clamp(idx: int) -> int:
        count = len(option_list)
        return max(0, min(count - 1, idx))

    def _animate_move(target: int, app):
        nonlocal display_index, move_task
        if move_task and not move_task.done():
            move_task.cancel()

        async def _run():
            nonlocal display_index
            while display_index != target:
                step = 1 if display_index < target else -1
                display_index += step
                app.invalidate()
                await asyncio.sleep(0.02)
            app.invalidate()

        move_task = app.create_background_task(_run())

    def _set_selection(idx: int, app):
        nonlocal selected_index, display_index
        selected_index = _clamp(idx)
        _animate_move(selected_index, app)

    @kb.add("up")
    @kb.add("k")
    def _(event):
        _set_selection(selected_index - 1, event.app)

    @kb.add("down")
    @kb.add("j")
    def _(event):
        _set_selection(selected_index + 1, event.app)

    last_click = {"idx": None, "t": 0.0}

    def mouse_handler(mouse_event):
        nonlocal selected_index
        if mouse_event.event_type != MouseEventType.MOUSE_UP:
            return NotImplemented

        y = mouse_event.position.y
        current_len = visible_count if animate_in else len(option_list)
        if current_len == 0:
            return None
        if 0 <= y < current_len:
            _set_selection(y, get_app())

        if mouse_event.event_type == MouseEventType.MOUSE_UP and mouse_event.button == MouseButton.LEFT:
            now = time.monotonic()
            idx = selected_index
            if idx == last_click["idx"] and (now - last_click["t"]) <= 0.5:
                value = option_list[idx][0]
                get_app().exit(result=value)
            last_click["idx"] = idx
            last_click["t"] = now
        return None

    def render_lines():
        fragments = []
        current_len = visible_count if animate_in else len(option_list)
        if current_len == 0:
            current_len = 1
        current_len = min(current_len, len(option_list))
        sel = min(display_index, current_len - 1)

        for idx, (_, label) in enumerate(option_list[:current_len]):
            pointer = ">" if idx == sel else " "
            prefix = f" {pointer} " if idx == sel else "   "
            text = f"{prefix}{idx + 1}. {label}"
            style_class = "class:radio-selected" if idx == sel else "class:radio"
            fragments.append((style_class, text))
            if idx != current_len - 1:
                fragments.append(("", "\n"))
        return fragments

    class MenuControl(FormattedTextControl):
        def __init__(self, render_fn, handler):
            super().__init__(render_fn, focusable=True, show_cursor=False)
            self._handler = handler

        def mouse_handler(self, mouse_event):
            return self._handler(mouse_event)

    control = MenuControl(render_lines, mouse_handler)
    window = Window(content=control, always_hide_cursor=True, dont_extend_width=True, dont_extend_height=True)

    radio_style = Style.from_dict(
        {
            "radio-list": "",
            "radio": "fg:#cbd6e2",
            "radio-selected": "fg:#e6edf3 bold underline",
            "radio-checked": "fg:#7ad1a8",
            "radio-number": "fg:#9dcffb bold",
        }
    )

    chosen_style = style_override or DEFAULT_STYLE
    app_style = merge_styles([chosen_style, radio_style]) if chosen_style else radio_style

    kb_final = merge_key_bindings([kb, extra_bindings]) if extra_bindings else kb

    app = Application(
        layout=Layout(window, focused_element=control),
        key_bindings=kb_final,
        mouse_support=True,
        full_screen=False,
        style=app_style,
    )

    if animate_in:
        async def _animate_in():
            nonlocal visible_count, selected_index
            for i in range(1, len(option_list) + 1):
                visible_count = i
                if selected_index >= visible_count:
                    selected_index = visible_count - 1
                get_app().invalidate()
                await asyncio.sleep(0.03)
        app.pre_run_callables.append(lambda: app.create_background_task(_animate_in()))

    result = app.run()
    if result is None:
        sel = selected_index or 0
        result = option_list[sel][0]
    # Clear only the menu lines from the terminal, preserving earlier output.
    _clear_menu_lines(len(option_list))
    return result


def choose(message: str, options: Iterable[Option], default: str | None = None, extra_bindings: KeyBindings | None = None, style_override: Style | None = None):
    return menu_choice(message=message, options=options, default=default, style_override=style_override or DEFAULT_STYLE, extra_bindings=extra_bindings)


def load_action_from_json(path: str) -> str | None:
    """Read action name from a JSON file.

    Compatible expectations:
    - File may be a dict with key "action": {"action": "value"}
    - Or nested: {"config": {"action": "value"}}

    Returns the action string (stripped) or None on error.
    """
    try:
        if not path or not os.path.isfile(path):
            return None
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        if isinstance(data, dict):
            action_value = data.get("action")
            if not action_value and isinstance(data.get("config"), dict):
                action_value = data["config"].get("action")
            if action_value:
                return str(action_value).strip()
    except Exception:
        return None
    return None


def resolve_action_with_json(path: str | None) -> str | None:
    if path:
        action = load_action_from_json(path)
        if action:
            return action
    # Default fallback path (JSON)
    default_path = os.path.join(os.getcwd(), "menu_action.json")
    return load_action_from_json(default_path)


def load_options_from_json(path: str) -> List[Tuple[str, str]]:
    """Read menu options from JSON.

    Supported formats:
    - A list of option objects: [{"value": "root", "label": "一键Root"}, ...]
    - An object with an "options" list: {"options": [...]}

    Returns a list of (value, label) tuples.
    """
    options_list: List[Tuple[str, str]] = []
    try:
        if not path or not os.path.isfile(path):
            return options_list
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        entries = []
        if isinstance(data, dict) and isinstance(data.get("options"), list):
            entries = data.get("options")
        elif isinstance(data, list):
            entries = data
        else:
            return options_list

        for entry in entries:
            if not isinstance(entry, dict):
                continue
            value = entry.get("value")
            label = entry.get("label")
            # fallback name/text fields
            if not label:
                if entry.get("text"):
                    label = str(entry.get("text")).strip()
                elif entry.get("name"):
                    label = str(entry.get("name")).strip()

            if value is not None and label:
                options_list.append((str(value), str(label)))
    except Exception:
        return []
    return options_list


def choose_action(options: List[Tuple[str, str]] | None = None, message: str = "请选择操作") -> str:
    if not options:
        raise ValueError("菜单选项为空，请提供JSON或手动传入options")
    if not DEFAULT_STYLE:
        # Fallback style for standalone/batch usage
        fallback_style = Style.from_dict({
            "radio": "fg:#cbd6e2",
            "radio-selected": "fg:#e6edf3 bold underline",
            "radio-checked": "fg:#7ad1a8",
            "radio-number": "fg:#9dcffb bold",
        })
        set_default_style(fallback_style)
    return choose(message, options, default=options[0][0])


def pause(message: str = "按任意键继续...", style_override: Style | None = None, timeout: float | None = None) -> None:
    """显示一个短暂的提示，等待任意键或鼠标/触摸点击继续。

    - 支持键盘任意按键确认。
    - 支持鼠标/触摸点击（左键单击或触控）确认。
    - 可选 `timeout`（秒）在超时后自动继续。
    """
    # 确保有样式可用
    chosen_style = style_override or DEFAULT_STYLE
    if chosen_style is None:
        fallback_style = Style.from_dict({
            "pause": "fg:#cbd6e2",
        })
        set_default_style(fallback_style)
        chosen_style = DEFAULT_STYLE

    pause_style = Style.from_dict({"pause": "fg:#9dcffb bold"})
    app_style = merge_styles([chosen_style, pause_style]) if chosen_style else pause_style

    kb = KeyBindings()

    @kb.add("enter", eager=True)
    @kb.add(" ", eager=True)
    def _enter(event):
        event.app.exit()

    @kb.add('<any>')
    def _any(event):
        event.app.exit()

    def _mouse_handler(mouse_event):
        # 仅在抬起事件时响应，兼容触控行为
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

    # 运行并阻塞，直到用户按键或点击，或超时
    try:
        app.run()
    except Exception:
        # 任何错误时回退到简单的输入提示
        try:
            input(message)
        except Exception:
            pass


if __name__ == "__main__":
    
    if len(sys.argv) != 2:
        print("[错误]请提供JSON配置文件的路径作为命令行参数")
        sys.exit(1)
    
    config_path = sys.argv[1]
    
    if not os.path.isfile(config_path):
        print(f"[错误]找不到文件 '{config_path}'")
        sys.exit(1)
    
    loaded = load_options_from_json(config_path)
    if not loaded:
        print("[错误]JSON文件中没有找到有效的菜单项")
        sys.exit(1)
    
    try:
        selection = choose_action(loaded)
    except Exception as e:
        print(f"[错误]菜单选择时发生错误: {str(e)}")
        sys.exit(1)
    
    with open("menutmp.txt", "w", encoding="utf-8") as f:
        f.write(selection)