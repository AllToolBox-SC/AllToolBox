import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'package:path/path.dart' as p;

/// Clean StartController implementation used by the UI.
class StartController {
  final void Function(String) write;
  final StringBuffer _buffer = StringBuffer();
  Process? _currentProcess;
  bool _interactive = false;
  int? _hostHwnd;
  Timer? _hostResizeTimer;
  List<int>? _pendingHostRect;

  StartController(this.write);

  String get buffer => _buffer.toString();

  Future<int> runStartPy(List<String> args) async {
    final scriptPath = p.join(Directory.current.path, 'flutter', 'atb_ui', 'python', 'start.py');
    const exe = 'python';
    final fullArgs = [scriptPath] + args;
    write('\n> $exe ${fullArgs.join(' ')}\n');
    try {
      _currentProcess = await Process.start(exe, fullArgs, runInShell: true);
      void listen(Stream<List<int>> s) {
        s.listen((chunk) async {
          String text;
          try {
            text = utf8.decode(chunk);
          } catch (_) {
            try {
              text = await CharsetConverter.decode('gbk', Uint8List.fromList(chunk));
            } catch (_) {
              text = const Utf8Decoder(allowMalformed: true).convert(chunk);
            }
          }
          _buffer.write(text);
          write(text);
        });
      }

      listen(_currentProcess!.stdout);
      listen(_currentProcess!.stderr);
      final code = await _currentProcess!.exitCode;
      _currentProcess = null;
      write('\n[Process exited with code $code]\n');
      return code;
    } catch (e) {
      write('\n[Failed to start process: $e]\n');
      _currentProcess = null;
      return -1;
    }
  }

  Future<int> startEmbeddedCmder({String? cmderExePath}) async {
    // Embedding Cmder has been disabled for release builds per project policy.
    write('[startEmbeddedCmder] embedding disabled; use startExternalCmd() to open a visible CMD window.\n');
    return -1;
  }

  /// Quick fallback: start system cmd.exe (or powershell) as external window and attach if possible.
  Future<int> startFallbackCmd({bool usePowerShell = false}) async {
    final exe = usePowerShell ? 'powershell.exe' : 'cmd.exe';
    write('[startFallbackCmd] starting $exe\n');
    try {
      _currentProcess = await Process.start(exe, [], runInShell: true);
      _interactive = true;
      write('[startFallbackCmd] started pid=${_currentProcess!.pid}\n');

      final pid = _currentProcess!.pid;
      // attempt to find and attach window similarly
      for (var i = 0; i < 30; i++) {
        final w = _findWindowByProcessId(pid);
        write('[startFallbackCmd] find-window attempt $i -> hwnd=$w\n');
        if (w != 0 && _hostHwnd != null && _hostHwnd != 0) {
          final attached = _attachProcessWindowToHost(w, _hostHwnd!);
          write('[startFallbackCmd] attach result=$attached\n');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _currentProcess!.exitCode.then((_) {
        _interactive = false;
        _currentProcess = null;
      });
      return 0;
    } catch (e) {
      write('[startFallbackCmd] failed to start: $e\n');
      return -1;
    }
  }

  /// Start an external cmd (or powershell) in the current working directory without embedding.
  Future<int> startExternalCmd({bool usePowerShell = false}) async {
    final cwd = Directory.current.path;
    if (!usePowerShell) {
      // Use cmd.exe /c start "" cmd to open a visible new cmd window
      write('[startExternalCmd] launching visible cmd via start at $cwd\n');
      try {
        await Process.start('cmd.exe', ['/c', 'start', '""', 'cmd.exe'], runInShell: true, workingDirectory: cwd);
        write('[startExternalCmd] launched visible cmd\n');
        return 0;
      } catch (e) {
        write('[startExternalCmd] failed to launch visible cmd: $e\n');
        return -1;
      }
    } else {
      // Fallback: launch powershell -NoExit in new window via cmd start
      write('[startExternalCmd] launching visible powershell via start at $cwd\n');
      try {
        await Process.start('cmd.exe', ['/c', 'start', '""', 'powershell.exe', '-NoExit'], runInShell: true, workingDirectory: cwd);
        write('[startExternalCmd] launched visible powershell\n');
        return 0;
      } catch (e) {
        write('[startExternalCmd] failed to launch powershell: $e\n');
        return -1;
      }
    }
  }

  /// Start the native ConPTY helper executable and pass host HWND for embedding.
  Future<int> startConptyHelper(String helperPath) async {
    if (!await File(helperPath).exists()) {
      write('[startConptyHelper] helper not found: $helperPath\n');
      return -1;
    }

    // Ensure host window exists; create it if necessary.
    if (_hostHwnd == null || _hostHwnd == 0) {
      final ptr = TEXT('ATB UI');
      try {
        var parent = FindWindow(nullptr, ptr);
        if (parent == 0) parent = GetForegroundWindow();
        if (parent == 0) {
          write('[startConptyHelper] no parent window found to create host\n');
          return -1;
        }
        final host = _createHostWindow(parent);
        if (host == 0) {
          write('[startConptyHelper] failed to create host window\n');
          return -1;
        }
        _hostHwnd = host;
        // start periodic resize updates
        _hostResizeTimer?.cancel();
        _hostResizeTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
          try {
            _adjustHostSize(parent);
          } catch (_) {}
        });
      } finally {
        calloc.free(ptr);
      }
    }

    try {
      write('[startConptyHelper] starting helper: $helperPath host=${_hostHwnd!}\n');
      _currentProcess = await Process.start(helperPath, [_hostHwnd!.toString()], runInShell: false);
      _interactive = true;
      _currentProcess!.stdout.listen((b) async {
        String text;
        try {
          text = utf8.decode(b);
        } catch (_) {
          try {
            text = await CharsetConverter.decode('gbk', Uint8List.fromList(b));
          } catch (_) {
            text = const Utf8Decoder(allowMalformed: true).convert(b);
          }
        }
        write(text);
      });
      _currentProcess!.stderr.listen((b) async {
        String text;
        try {
          text = utf8.decode(b);
        } catch (_) {
          try {
            text = await CharsetConverter.decode('gbk', Uint8List.fromList(b));
          } catch (_) {
            text = const Utf8Decoder(allowMalformed: true).convert(b);
          }
        }
        write(text);
      });
      write('[startConptyHelper] started pid=${_currentProcess!.pid}\n');

      _currentProcess!.exitCode.then((_) {
        _interactive = false;
        _currentProcess = null;
        _hostResizeTimer?.cancel();
        _destroyHostWindow();
      });
      return 0;
    } catch (e) {
      write('[startConptyHelper] failed: $e\n');
      return -1;
    }
  }

  int _createHostWindow(int parentHwnd) {
    final className = TEXT('STATIC');
    final wndName = TEXT('cmder_host_${DateTime.now().millisecondsSinceEpoch}');
    final hInstance = GetModuleHandle(nullptr);
    const style = WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
    final host = CreateWindowEx(0, className, wndName, style, 0, 0, 100, 100, parentHwnd, 0, hInstance, nullptr);
    calloc.free(className);
    calloc.free(wndName);
    if (host == 0) return 0;
    _adjustHostSize(parentHwnd);
    return host;
  }

  void _destroyHostWindow() {
    if (_hostHwnd != null && _hostHwnd != 0) {
      DestroyWindow(_hostHwnd!);
      _hostHwnd = null;
    }
  }

  void _adjustHostSize(int parentHwnd) {
    if (_hostHwnd == null || _hostHwnd == 0) return;
    if (_pendingHostRect != null) {
      final p = _pendingHostRect!;
      MoveWindow(_hostHwnd!, p[0], p[1], p[2], p[3], TRUE);
      return;
    }
    final rect = calloc<RECT>();
    try {
      if (GetClientRect(parentHwnd, rect) == 0) return;
      final w = rect.ref.right - rect.ref.left;
      final h = rect.ref.bottom - rect.ref.top;
      MoveWindow(_hostHwnd!, 0, 0, w, h, TRUE);
    } finally {
      calloc.free(rect);
    }
  }

  void updateHostRect(int x, int y, int w, int h) {
    _pendingHostRect = [x, y, w, h];
    if (_hostHwnd != null && _hostHwnd != 0) MoveWindow(_hostHwnd!, x, y, w, h, TRUE);
  }

  Future<void> stopInteractiveShell() async {
    try {
      if (_currentProcess != null) {
        _currentProcess!.kill(ProcessSignal.sigkill);
        _currentProcess = null;
        _interactive = false;
      }
    } catch (_) {}
  }

  bool get isInteractiveRunning => _interactive && _currentProcess != null;

  void sendInput(String input) {
    if (_currentProcess != null) {
      // Use CRLF for Windows console compatibility
      var payload = input.endsWith('\n') ? input : '$input\n';
      payload = payload.replaceAll('\n', '\r\n');
      write('[sendInput] -> ${payload.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}\n');
      _currentProcess!.stdin.add(utf8.encode(payload));
    }
  }

  /// Send raw bytes to the interactive process without appending CRLF.
  void sendRaw(String input) {
    if (_currentProcess != null) {
      write('[sendRaw] -> ${input.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}\n');
      _currentProcess!.stdin.add(utf8.encode(input));
    }
  }

  Future<int> runAction(String action) async {
    write('\n> action: $action\n');
    if (action == 'openshell') return await startExternalCmd();
    if (action == 'onekeyroot') {
      return await _runBatch('call root.bat');
    }
    if (action == 'about') {
      // Ported minimal about text to UI
      write('\nAllToolBox UI\n');
      write('\n[信息] 本工具由快乐小公爵236等开发者制作\n');
      write('[信息] 工具官网：https://atb.xgj.qzz.io\n');
      write('[信息] 作者QQ：3247039462\n');
      write('[信息] 工具箱交流与反馈QQ群：907491503\n');
      // run uplog and thank scripts if present
      await _runBatch('call uplog.bat');
      await _runBatch('call thank.bat');
      return 0;
    }
    // default: defer to existing python start.py behavior
    return await runStartPy(['--action', action]);
  }

  /// Public wrapper to run an arbitrary cmd/batch via cmd.exe.
  Future<int> runCmd(String cmd) async {
    return await _runBatch(cmd);
  }

  Future<int> _runBatch(String cmd) async {
    final cwd = Directory.current.path;
    write('\n> cmd /c $cmd\n');
    try {
      _currentProcess = await Process.start('cmd.exe', ['/c', cmd], runInShell: true, workingDirectory: cwd);
      void listen(Stream<List<int>> s) {
        s.listen((chunk) async {
          String text;
          try {
            text = utf8.decode(chunk);
          } catch (_) {
            try {
              text = await CharsetConverter.decode('gbk', Uint8List.fromList(chunk));
            } catch (_) {
              text = const Utf8Decoder(allowMalformed: true).convert(chunk);
            }
          }
          _buffer.write(text);
          write(text);
        });
      }

      listen(_currentProcess!.stdout);
      listen(_currentProcess!.stderr);
      final code = await _currentProcess!.exitCode;
      _currentProcess = null;
      write('\n[Process exited with code $code]\n');
      return code;
    } catch (e) {
      write('\n[Failed to run batch: $e]\n');
      _currentProcess = null;
      return -1;
    }
  }

  Future<int> runActionExtended(String action) async => runAction(action);

  int _findWindowByProcessId(int pid) {
    var hwnd = GetTopWindow(NULL);
    while (hwnd != 0) {
      final pidBuf = calloc<Uint32>();
      try {
        GetWindowThreadProcessId(hwnd, pidBuf);
        if (pidBuf.value == pid) return hwnd;
      } finally {
        calloc.free(pidBuf);
      }
      hwnd = GetWindow(hwnd, GW_HWNDNEXT);
    }
    return 0;
  }

  bool _attachProcessWindowToHost(int wnd, int host) {
    if (wnd == 0 || host == 0) return false;
    final cur = GetWindowLongPtr(wnd, GWL_STYLE);
    final newStyle = (cur & ~WS_POPUP & ~WS_CAPTION & ~WS_SYSMENU & ~WS_THICKFRAME) | WS_CHILD;
    SetParent(wnd, host);
    SetWindowLongPtr(wnd, GWL_STYLE, newStyle);
    MoveWindow(wnd, 0, 0, 100, 100, TRUE);
    ShowWindow(wnd, SW_SHOW);
    return true;
  }
}
