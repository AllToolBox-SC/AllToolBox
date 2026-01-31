import 'dart:io';

class StartControllerConpty {
  /// Start the native pseudoconsole helper and attach it to [hostHwnd].
  /// [helperPath] should point to the compiled pseudoconsole_host.exe
  static Future<Process?> startConpty(String helperPath, int hostHwnd) async {
    if (!File(helperPath).existsSync()) {
      print('[startConpty] helper not found: $helperPath');
      return null;
    }
    final args = [hostHwnd.toString()];
    print('[startConpty] starting helper: $helperPath args=$args');
    final proc = await Process.start(helperPath, args, mode: ProcessStartMode.detachedWithStdio);
    proc.stdout.transform(SystemEncoding().decoder).listen((d) => print('[conpty stdout] $d'));
    proc.stderr.transform(SystemEncoding().decoder).listen((d) => print('[conpty stderr] $d'));
    print('[startConpty] pid=${proc.pid}');
    return proc;
  }
}
