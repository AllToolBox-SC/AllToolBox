import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'start_controller_clean.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtbApp());
}

class AtbApp extends StatelessWidget {
  const AtbApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATB UI',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.transparent),
      home: const MainWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({Key? key}) : super(key: key);

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  final StringBuffer _output = StringBuffer();
  late final StartController controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = StartController(_appendOutput);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _appendOutput(String s) {
    setState(() {
      _output.write(s);
    });
  }


  Future<void> _runAction(String action) async {
    _appendOutput('\n[执行动作 $action]\n');
    await controller.runActionExtended(action);
  }

  Widget _menuItem(IconData icon, String label, int idx) {
    final selected = _selectedIndex == idx;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.cyan : Colors.white70),
      title: Text(label, style: TextStyle(color: selected ? Colors.cyan : Colors.white70)),
      selected: selected,
      onTap: () => setState(() => _selectedIndex = idx),
    );
  }

  Widget _menuItemCompact(IconData icon, String label, int idx) {
    final selected = _selectedIndex == idx;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.cyan : Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? Colors.cyan : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(String label, Function()? onPressed) {
    return ElevatedButton(
      onPressed: onPressed != null ? () { onPressed(); } : null,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: const Color(0xFF5A3E7A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label),
    );
  }

  Widget _contentForIndex(int idx) {
    if (idx == 0) return _buildHome();
    if (idx == 1) return _buildPlaceholder('一键ROOT', 'onekeyroot');
    if (idx == 2) return _buildShellPage();
    if (idx == 3) return _buildModsPage();
    if (idx == 4) return _buildCommonPage();
    if (idx == 5) return _buildHelpPage();
    if (idx == 6) return _buildAppSetPage();
    if (idx == 7) return _buildUserDebugPage();
    if (idx == 8) return _buildMagiskPage();
    if (idx == 9) return _buildDebugPage();

    return Center(
      child: ElevatedButton(onPressed: () => _runAction('about'), child: const Text('关于')),
    );
  }

  Widget _buildPlaceholder(String title, String action) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => _runAction(action), child: const Text('执行')),
        ],
      ),
    );
  }

  Widget _buildShellPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('打开 CMD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await controller.startExternalCmd();
            },
            icon: const Icon(Icons.terminal),
            label: const Text('打开 CMD'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActionListPage(String title, String base, List<List<String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: items.map((it) {
              return Card(
                child: ListTile(
                  title: Text(it[1]),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _runAction('$base:${it[0]}'),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSetPage() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('应用管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pillButton('安装应用', () async { await controller.runCmd('call userinstapp'); }),
          const SizedBox(height: 8),
          _pillButton('卸载应用', () async { await controller.runCmd('call unapp'); }),
          const SizedBox(height: 8),
          _pillButton('安装xtc状态栏', () async { await controller.runCmd('call xtcztl'); }),
          const SizedBox(height: 8),
          _pillButton('设置微信QQ开机自启', () async { await controller.runCmd('call qqwxautestart'); }),
          const SizedBox(height: 8),
          _pillButton('解除z10安装限制', () async { await controller.runCmd('call z10openinst'); }),
        ]),
      )
    ]);
  }

  Widget _buildUserDebugPage() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('开发合集', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pillButton('手表信息', () async { await controller.runCmd('call listbuild'); }),
          const SizedBox(height: 8),
          _pillButton('打开充电可用', () async { await controller.runCmd('call opencharge'); }),
          const SizedBox(height: 8),
          _pillButton('型号与innermodel对照表', () async { await controller.runCmd('call innermodel'); }),
          const SizedBox(height: 8),
          _pillButton('导入本地root文件', () async {
            final fp = await _pickFile();
            if (fp != null) {
              final dest = '${Directory.current.path}\\${p.basename(fp)}';
              await controller.runCmd('copy /Y "${fp}" "${dest}"');
              await controller.runCmd('call pashroot');
            }
          }),
          const SizedBox(height: 8),
          _pillButton('一键root（不刷userdata）', () async { await controller.runCmd('call root "nouserdata"'); }),
          const SizedBox(height: 8),
          _pillButton('恢复出厂设置', () async { await controller.runCmd('call miscre'); }),
          const SizedBox(height: 8),
          _pillButton('开机自刷Recovery', () async { await controller.runCmd('call pashtwrppro'); }),
          const SizedBox(height: 8),
          _pillButton('强制加好友（已失效）', () async { await controller.runCmd('call friend'); }),
        ]),
      )
    ]);
  }

  Widget _buildMagiskPage() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('magisk模块管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _pillButton('刷入Magisk模块', () async { await controller.runCmd('call userinstmodule'); }),
    ]);
  }

  Widget _buildDebugPage() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('DEBUG 菜单', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pillButton('色卡', () async { await controller.runCmd('call color'); }),
          const SizedBox(height: 8),
          _pillButton('调整为未使用状态', () async { await controller.runCmd('echo 1 > whoyou.txt'); }),
          const SizedBox(height: 8),
          _pillButton('调整为使用状态', () async { await controller.runCmd('echo 2 > whoyou.txt'); }),
          const SizedBox(height: 8),
          _pillButton('调整为更新状态', () async { await controller.runCmd('echo 3 > whoyou.txt'); }),
          const SizedBox(height: 8),
          _pillButton('debug sel', () async { await controller.runCmd('call sel'); }),
          const SizedBox(height: 8),
          _pillButton('导入文件', () async {
            final fp = await _pickFile();
            if (fp != null) {
              await controller.runCmd('copy /Y "${fp}" "%CD%\\"');
              _appendOutput('\n[已复制到当前目录]\n');
            }
          }),
        ]),
      )
    ]);
  }

  Future<String?> _pickFile() async {
    String? result;
    final TextEditingController ctl = TextEditingController();
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('选择文件（粘贴或输入路径）'),
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: '输入完整路径或拖拽粘贴')),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); }, child: const Text('取消')),
          TextButton(onPressed: () { result = ctl.text.trim(); Navigator.of(ctx).pop(); }, child: const Text('确定')),
        ],
      );
    });
    if (result == null || result!.isEmpty) return null;
    if (File(result!).existsSync()) return result;
    _appendOutput('\n[未找到文件: $result]\n');
    return null;
  }

  Future<String?> _pickDirectory() async {
    String? result;
    final TextEditingController ctl = TextEditingController();
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('选择目录（粘贴或输入路径）'),
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: '输入目录完整路径')),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); }, child: const Text('取消')),
          TextButton(onPressed: () { result = ctl.text.trim(); Navigator.of(ctx).pop(); }, child: const Text('确定')),
        ],
      );
    });
    if (result == null || result!.isEmpty) return null;
    if (Directory(result!).existsSync()) return result;
    _appendOutput('\n[未找到目录: $result]\n');
    return null;
  }

  void _showTextFileContent(String path) {
    try {
      final content = File(path).readAsStringSync(encoding: const Utf8Codec());
      showDialog(context: context, builder: (ctx) {
        return AlertDialog(title: Text('文件: ${path.split('\\').last}'), content: SingleChildScrollView(child: SelectableText(content)), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭'))]);
      });
    } catch (e) {
      _appendOutput('\n[读取文件失败: $e]\n');
    }
  }

  Widget _buildModsPage() {
    final items = [
      {'label': '运行已安装扩展', 'type': 'runInstalled'},
      {'label': '安装扩展', 'cmd': 'call instmodule'},
      {'label': '卸载扩展', 'cmd': 'call unmod'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('扩展管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          children: items.map((it) {
            final label = it['label'] as String;
            return Card(
              child: ListTile(
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (it['type'] == 'runInstalled') {
                    final modDir = Directory('${Directory.current.path}\\mod');
                    if (!modDir.existsSync()) { _appendOutput('\n[未找到 mod 目录]\n'); return; }
                    final dirs = modDir.listSync().whereType<Directory>().map((d) => d.path).toList();
                    if (dirs.isEmpty) { _appendOutput('\n[未发现任何扩展]\n'); return; }
                    final picked = await _pickDirectory();
                    if (picked == null) return;
                    await controller.runCmd('cd /d "${picked.replaceAll('"', '\\"')}" && call main.bat');
                  } else if (it.containsKey('cmd')) {
                    await controller.runCmd(it['cmd'] as String);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildCommonPage() {
    final items = [
      ['call listbuild', 'ADB/自检校验码计算'],
      ['call ota', '离线OTA升级'],
      ['call pashtwrp', '刷入TWRP'],
      ['call xtcpatch', '刷入XTC Patch'],
      ['call backup', '备份与恢复'],
      ['call rootpro', '安卓8.1root后优化'],
      ['call qmmi', '进入qmmi[9008]'],
      ['call scrcpy-ui.bat', 'scrcpy投屏'],
      ['call rebootpro', '高级重启'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('常用合集', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          children: items.map((it) {
            return Card(
              child: ListTile(
                title: Text(it[1]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => controller.runCmd(it[0]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildHelpPage() {
    final items = [
      ['start https://www.123865.com/s/Q5JfTd-hEbWH', '超级恢复文件下载'],
      ['start https://www.123865.com/s/Q5JfTd-HEbWH', '离线OTA下载'],
      ['start https://www.123684.com/s/Q5JfTd-cEbWH', '面具模块下载'],
      ['start https://www.123684.com/s/Q5JfTd-ZEbWH', 'APK下载'],
      ['start https://atb.xgj.qzz.io', '工具箱官网'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('帮助与链接', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          children: [
            ...items.map((it) => Card(
              child: ListTile(title: Text(it[1]), trailing: const Icon(Icons.chevron_right), onTap: () => controller.runCmd(it[0])),
            )),
            Card(
              child: ListTile(
                title: const Text('开发文档'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final candidates = ["开发文档.txt", "开发文档/开发文档.txt"];
                  String? found;
                  for (final c in candidates) {
                    final p = '${Directory.current.path}\\$c';
                    if (File(p).existsSync()) { found = p; break; }
                  }
                  if (found == null) {
                    final fp = await _pickFile();
                    if (fp != null) _showTextFileContent(fp);
                  } else {
                    _showTextFileContent(found);
                  }
                },
              ),
            ),
            Card(
              child: ListTile(title: const Text('123云盘解除下载限制'), trailing: const Icon(Icons.chevron_right), onTap: () async { await controller.runCmd('call patch123'); }),
            ),
          ],
        ),
      ),
    ]);
  }

  // 仪表盘已移除：替换为简洁主页面（动作列表）
  Widget _buildHome() {
    final items = [
      ['onekeyroot', '一键ROOT'],
      ['openshell', '打开 Shell'],
      ['about', '关于'],
      ['mods', '扩展管理'],
      ['commonly', '常用合集'],
      ['help-links', '帮助与链接'],
      ['man-apps', '应用管理'],
      ['user-debug', '开发合集'],
      ['magisk-mod', 'magisk模块管理'],
      ['debug', 'DEBUG菜单'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('主页面', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: items.map((it) {
              final action = it[0];
              final label = it[1];
              return Card(
                child: ListTile(
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _runAction(action),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final double outerW = constraints.maxWidth * 0.98;
        final double outerH = constraints.maxHeight * 0.98;
        // embedding removed; no host rect updates
        return Center(
          child: SizedBox(
            width: outerW,
            height: outerH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.lightBlue.withOpacity(0.06), Colors.blue.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: Colors.blue.withOpacity(0.04)),
                ),
                child: Column(children: [
                  // Top bar
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: const Row(children: [Icon(Icons.widgets, color: Colors.white, size: 20), SizedBox(width: 8), Text('XTC AllToolBox', style: TextStyle(color: Colors.white70)), Spacer(), Text('仪表盘', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)), Spacer(), Icon(Icons.search, color: Colors.white54), SizedBox(width: 8), Icon(Icons.notifications_none, color: Colors.white54), SizedBox(width: 12), CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white54))]),
                  ),
                  // Body
                  Expanded(
                    child: Row(children: [
                      // Left menu (compact list-style)
                      Container(
                        width: math.max(120, outerW * 0.12),
                        decoration: BoxDecoration(color: Colors.lightBlue.withOpacity(0.04), border: Border(right: BorderSide(color: Colors.blue.withOpacity(0.03)))),
                        child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [
                          _menuItemCompact(Icons.dashboard, '仪表盘', 0),
                          _menuItemCompact(Icons.flash_on, '一键ROOT', 1),
                          _menuItemCompact(Icons.terminal, '打开 Shell', 2),
                          _menuItemCompact(Icons.extension, '扩展管理', 3),
                          _menuItemCompact(Icons.star_border, '常用工具', 4),
                          _menuItemCompact(Icons.help_outline, '帮助与链接', 5),
                        ])), Padding(padding: const EdgeInsets.all(12.0), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _runAction('exit'), icon: const Icon(Icons.power_settings_new), label: const Text('退出'))))]),
                      ),

                      // Main content
                      Expanded(child: Padding(padding: const EdgeInsets.all(18.0), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: Colors.white.withOpacity(0.02), child: Padding(padding: const EdgeInsets.all(16.0), child: _contentForIndex(_selectedIndex)))))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}
