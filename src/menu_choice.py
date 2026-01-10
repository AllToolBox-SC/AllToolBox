import time
from typing import Iterable, List, Tuple

from prompt_toolkit.application import Application
from prompt_toolkit.application.current import get_app
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.key_binding.key_processor import KeyPressEvent
from prompt_toolkit.layout import Layout
from prompt_toolkit.mouse_events import MouseEventType, MouseButton
from prompt_toolkit.shortcuts import clear
from prompt_toolkit.widgets import RadioList
from prompt_toolkit.styles import Style, merge_styles

from config import style

Option = Tuple[str, str]


def menu_choice(message: str, options: Iterable[Option], default: str | None = None) -> str:
    option_list: List[Option] = list(options)
    if not option_list:
        raise ValueError("menu_choice requires at least one option")

    # 显示标签前加数字序号，去掉星号/括号。
    display_options = [
        (value, f"{i + 1}. {label}")
        for i, (value, label) in enumerate(option_list)
    ]

    radio = RadioList(
        display_options,
        show_numbers=False,
        open_character=" ",
        select_character=" ",
        close_character=" ",
    )

    if default is not None:
        for idx, (value, _) in enumerate(option_list):
            if value == default:
                radio._selected_index = idx
                break

    # Ensure there is always a valid initial selection.
    if radio._selected_index is None:
        radio._selected_index = 0

    kb = KeyBindings()

    @kb.add("enter", eager=True)
    @kb.add(" ", eager=True)
    def _(event: KeyPressEvent) -> None:  # noqa: F811
        idx = radio._selected_index or 0
        event.app.exit(result=option_list[idx][0])

    # 数字快捷键：连续数字支持多位，超过0.25秒自动重置缓冲。
    digit_buf = {"text": "", "t": 0.0}

    def _select_by_number(event: KeyPressEvent, digit: str) -> None:
        now = time.monotonic()
        digit_buf["text"] = digit if (now - digit_buf["t"]) > 0.25 else digit_buf["text"] + digit
        digit_buf["t"] = now
        try:
            idx = int(digit_buf["text"]) - 1
        except ValueError:
            return
        if 0 <= idx < len(option_list):
            radio._selected_index = idx
            event.app.invalidate()

    for d in "0123456789":
        @kb.add(d, eager=True)
        def _(event: KeyPressEvent, _d=d) -> None:  # noqa: F811
            _select_by_number(event, _d)

    orig_mouse_handler = radio.control.mouse_handler
    last_click = {"idx": None, "t": 0.0}

    def mouse_handler(mouse_event) -> None:
        # Let the original handler update selection on click.
        if orig_mouse_handler:
            orig_mouse_handler(mouse_event)
            get_app().invalidate()

        if mouse_event.event_type == MouseEventType.MOUSE_UP and mouse_event.button == MouseButton.LEFT:
            now = time.monotonic()
            idx = radio._selected_index
            if idx == last_click["idx"] and (now - last_click["t"]) <= 0.5:
                sel = idx or 0
                value = radio.current_value or option_list[sel][0]
                get_app().exit(result=value)
            last_click["idx"] = idx
            last_click["t"] = now

    radio.control.mouse_handler = mouse_handler

    app_style = merge_styles(
        [
            style,
            Style.from_dict(
                {
                    "radio-list": "",
                    "radio": "fg:white",
                    "radio-selected": "fg:black bg:ansiyellow bold",
                    "radio-checked": "fg:green",
                    "radio-number": "fg:cyan",
                }
            ),
        ]
    )

    app = Application(
        layout=Layout(radio, focused_element=radio),
        key_bindings=kb,
        mouse_support=True,
        full_screen=False,
        style=app_style,
    )
    result = app.run()
    clear()
    # Fallback: if current_value is None, derive from selected index.
    if result is None:
        sel = radio._selected_index or 0
        result = option_list[sel][0]
    return result


