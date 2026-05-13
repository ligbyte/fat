import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'rust_bridge.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  RustBridge.initialize();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

void _showAboutDialog() {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/icon/close.png',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B8DEF).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FileCat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8DEF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B8DEF),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '一个 Flutter + Rust 混合开发的\n文件管理应用',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '支持系统托盘 · 文件浏览 · 局域网共享',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showSupportDialog() {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/icon/close.png',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/wechat_pay.jpg',
                width: 240,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '支持一下作者吧~~~',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '您的支持是我持续更新的最大动力',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Filecat',
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F54EB),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2F54EB),
          secondary: const Color(0xFF13C2C2),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        textTheme: GoogleFonts.notoSansScTextTheme(const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFF000000)),
          bodyMedium: TextStyle(color: Color(0xFF595959)),
        )),
        primaryTextTheme: GoogleFonts.notoSansScTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF000000),
          iconTheme: IconThemeData(color: Color(0xFF2F54EB)),
          shape: Border(bottom: BorderSide(color: Color(0xFFD9D9D9), width: 1)),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TrayListener, WindowListener {
  String _filecatPath = '';
  List<Map<String, dynamic>> _directoryContents = [];
  Map<String, bool> _expandedFolders = {};
  Map<String, List<Map<String, dynamic>>> _folderContents = {};
  bool _isLoading = false;
  bool _autostartEnabled = false;
  bool _serverRunning = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setPreventClose();
    _initTray();
    _loadFilecatPath();
    _loadAutostartPreference();
  }

  void _setPreventClose() async {
    await windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      _updateTrayMenu(forceVisible: false);
    }
  }

  void onWindowHide() {
    _updateTrayMenu(forceVisible: false);
  }

  void onWindowShow() {
    _updateTrayMenu(forceVisible: true);
  }

  Future<void> _updateTrayMenu({bool? forceVisible}) async {
    bool isVisible = forceVisible ?? await windowManager.isVisible();
    final menu = Menu(
      items: [
        MenuItem(
          key: 'toggle_window',
          label: isVisible ? '隐藏窗口' : '显示窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'support',
          label: '支持作者',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'about',
          label: '关于',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: '退出',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _initTray() async {
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.ico',
    );
    await trayManager.setToolTip('FileCat');
    _updateTrayMenu(forceVisible: true);
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
      _updateTrayMenu(forceVisible: false);
    } else {
      await windowManager.show();
      await windowManager.focus();
      _updateTrayMenu(forceVisible: true);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    _updateTrayMenu().then((_) {
      trayManager.popUpContextMenu();
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'toggle_window') {
      bool isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
        _updateTrayMenu(forceVisible: false);
      } else {
        await windowManager.show();
        await windowManager.focus();
        _updateTrayMenu(forceVisible: true);
      }
    } else if (menuItem.key == 'support') {
      _showSupportDialog();
    } else if (menuItem.key == 'about') {
      _showAboutDialog();
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }

  void _loadAutostartPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final autostartEnabled = prefs.getBool('autostart_enabled') ?? false;
    final serverRunning = RustBridge.isServerRunning();
    setState(() {
      _autostartEnabled = autostartEnabled;
      _serverRunning = serverRunning;
    });
  }

  void _loadFilecatPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('filecat_path');
    
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _filecatPath = savedPath;
      });
      _loadDirectoryContents(savedPath);
      // 启动静态文件服务器
      RustBridge.startStaticServer(savedPath);
    } else {
      final path = RustBridge.getFilecatPath();
      if (path != null) {
        try {
          final pathStr = path.contains('"data":"') 
              ? path.split('"data":"')[1].split('"')[0]
              : path;
          setState(() {
            _filecatPath = pathStr;
          });
          _loadDirectoryContents(pathStr);
          // 启动静态文件服务器
          RustBridge.startStaticServer(pathStr);
        } catch (e) {
          setState(() {
            _filecatPath = path;
          });
          _loadDirectoryContents(path);
          // 启动静态文件服务器
          RustBridge.startStaticServer(path);
        }
      }
    }
  }

  void _loadDirectoryContents(String path) {
    setState(() {
      _isLoading = true;
    });

    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        
        setState(() {
          _directoryContents = jsonList.map((item) => {
            'name': item['name'] as String,
            'is_dir': item['is_dir'] as bool,
            'size': item['size'] as int,
            'modified': item['modified'] as int? ?? 0,
            'path': item['path'] as String,
          }).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _directoryContents = [];
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _extractJsonArray(String response) {
    try {
      final startIndex = response.indexOf('[');
      final endIndex = response.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1) {
        final jsonArray = response.substring(startIndex, endIndex + 1);
        return jsonDecode(jsonArray) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting JSON array: $e');
    }
    return [];
  }

  void _toggleFolder(String path) {
    if (_expandedFolders[path] == true) {
      setState(() {
        _expandedFolders[path] = false;
      });
    } else {
      setState(() {
        _expandedFolders[path] = true;
      });
      
      // 每次展开都重新加载内容，确保数据是最新的
      _loadFolderContents(path);
    }
  }

  void _refreshContents() {
    if (_filecatPath.isNotEmpty) {
      _loadDirectoryContents(_filecatPath);
      // 同时刷新所有已展开的子文件夹
      for (var entry in _expandedFolders.entries) {
        if (entry.value) {
          _loadFolderContents(entry.key);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已刷新目录内容'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadFolderContents(String path) {
    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        
        setState(() {
          _folderContents[path] = jsonList.map((item) => {
            'name': item['name'] as String,
            'is_dir': item['is_dir'] as bool,
            'size': item['size'] as int,
            'modified': item['modified'] as int? ?? 0,
            'path': item['path'] as String,
          }).toList();
        });
      } catch (e) {
        debugPrint('Error loading folder contents: $e');
      }
    }
  }

  void _changeFilecatPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      setState(() {
        _filecatPath = selectedDirectory;
        _directoryContents = [];
        _expandedFolders = {};
        _folderContents = {};
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('filecat_path', selectedDirectory);
      
      _loadDirectoryContents(selectedDirectory);
      // 更新静态文件服务器路径并重启
      RustBridge.updateServerPath(selectedDirectory);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    final k = 1024;
    final sizes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes.toDouble()) / log(k)).floor();
    final index = i.clamp(0, sizes.length - 1);
    return '${(bytes / pow(k, index)).toStringAsFixed(1)} ${sizes[index]}';
  }

  String _formatDateTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final year = dt.year;
    final month = dt.month;
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    
    return '$year年$month月$day日，$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobileLayout = width <= 450;
              final isTabletLayout = width > 450 && width <= 800;
              
              double maxWidth;
              if (isMobileLayout) {
                maxWidth = double.infinity;
              } else if (isTabletLayout) {
                maxWidth = 850;
              } else {
                maxWidth = 1100;
              }
              
              double horizontalPadding;
              if (isMobileLayout) {
                horizontalPadding = 16.0;
              } else if (isTabletLayout) {
                horizontalPadding = 24.0;
              } else {
                horizontalPadding = 32.0;
              }
              
              return Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 16,
                  bottom: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPathSelection(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildDirectoryContents(),
                        ),
                        const SizedBox(height: 4),
                        _buildAutostartCheckbox(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPathSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2F54EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: Color(0xFF2F54EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('共享文件夹路径', style: TextStyle(fontSize: 12, color: Color(0xFF8C8C8C))), const SizedBox(height: 2), Text(_filecatPath.isEmpty ? '加载中...' : _filecatPath, style: const TextStyle(fontSize: 14, color: Color(0xFF000000), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)] )),
          const SizedBox(width: 16),
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: _changeFilecatPath,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '更改路径',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF595959),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryContents() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '目录内容',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _refreshContents,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: '刷新目录',
                  color: const Color(0xFF2F54EB),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: _directoryContents.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '文件夹为空',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _directoryContents.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, index) {
                      final item = _directoryContents[index];
                      return _buildDirectoryItem(item, 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _copyFileRelativePath(Map<String, dynamic> item) {
    final filePath = item['path'] as String;
    String relativePath = filePath;

    if (_filecatPath.isNotEmpty && filePath.startsWith(_filecatPath)) {
      relativePath = filePath.substring(_filecatPath.length);
      if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
        relativePath = relativePath.substring(1);
      }
    }

    relativePath = relativePath.replaceAll('\\', '/');

    final ipResult = RustBridge.getLocalIp();
    String ip = '127.0.0.1';
    if (ipResult != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(ipResult);
        if (json['success'] == true) {
          ip = json['data'] as String;
        }
      } catch (e) {
        debugPrint('Error parsing local IP: $e');
      }
    }

    final fullUrl = 'http://$ip:9202/file/$relativePath';

    Clipboard.setData(ClipboardData(text: fullUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: $fullUrl',style: const TextStyle(fontSize: 13,color: Colors.white),),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildAutostartCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/loading_cat.gif',
                width: 28,
                height: 28,
              ),

              const SizedBox(width: 8),
              const Text(
                '服务运行中',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF52C41A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                '开机自启动',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _autostartEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      if (value) {
                        final result = RustBridge.enableAutostart('FileCat');
                        if (result != null) {
                          try {
                            final json = jsonDecode(result);
                            if (json['success'] == true) {
                              await prefs.setBool('autostart_enabled', true);
                              setState(() {
                                _autostartEnabled = true;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error enabling autostart: $e');
                          }
                        }
                      } else {
                        final result = RustBridge.disableAutostart('FileCat');
                        if (result != null) {
                          try {
                            final json = jsonDecode(result);
                            if (json['success'] == true) {
                              await prefs.setBool('autostart_enabled', false);
                              setState(() {
                                _autostartEnabled = false;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error disabling autostart: $e');
                          }
                        }
                      }
                    },
                    activeColor: const Color(0xFF2F54EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryItem(Map<String, dynamic> item, int indentLevel) {
    final isDir = item['is_dir'] as bool;
    final name = item['name'] as String;
    final path = item['path'] as String;
    final size = item['size'] as int;
    final isExpanded = _expandedFolders[path] == true;

    // 根据文件/文件夹名称获取对应的 Helium 图标
    String getHeliumIcon() {
      if (isDir) {
        final folderName = name.toLowerCase();
        // 常见的文件夹映射
        const folderMap = {
          'src': 'folder-src',
          'source': 'folder-src',
          'sources': 'folder-src',
          'dist': 'folder-dist',
          'out': 'folder-dist',
          'build': 'folder-dist',
          'release': 'folder-dist',
          'bin': 'folder-dist',
          'css': 'folder-css',
          'styles': 'folder-css',
          'style': 'folder-css',
          'sass': 'folder-sass',
          'scss': 'folder-sass',
          'images': 'folder-images',
          'image': 'folder-images',
          'img': 'folder-images',
          'icons': 'folder-images',
          'icon': 'folder-images',
          'scripts': 'folder-scripts',
          'script': 'folder-scripts',
          'node_modules': 'folder-node',
          'js': 'folder-javascript',
          'javascript': 'folder-javascript',
          'font': 'folder-font',
          'fonts': 'folder-font',
          'test': 'folder-test',
          'tests': 'folder-test',
          'spec': 'folder-test',
          'specs': 'folder-test',
          'doc': 'folder-docs',
          'docs': 'folder-docs',
          'documents': 'folder-docs',
          '.git': 'folder-git',
          '.github': 'folder-github',
          '.vscode': 'folder-vscode',
          'views': 'folder-views',
          'pages': 'folder-views',
          'components': 'folder-components',
          'assets': 'folder-resource',
          'res': 'folder-resource',
          'resource': 'folder-resource',
          'resources': 'folder-resource',
          'lib': 'folder-lib',
          'libs': 'folder-lib',
          'vendor': 'folder-lib',
          'themes': 'folder-theme',
          'theme': 'folder-theme',
          'public': 'folder-public',
          'www': 'folder-public',
          'include': 'folder-include',
          'docker': 'folder-docker',
          'db': 'folder-database',
          'database': 'folder-database',
          'sql': 'folder-database',
          'log': 'folder-log',
          'logs': 'folder-log',
          'temp': 'folder-temp',
          'tmp': 'folder-temp',
          'cache': 'folder-temp',
          'video': 'folder-video',
          'videos': 'folder-video',
          'audio': 'folder-audio',
          'music': 'folder-audio',
          'api': 'folder-api',
          'app': 'folder-app',
          'config': 'folder-config',
          'settings': 'folder-config',
          'tools': 'folder-tools',
          'helper': 'folder-helper',
          'helpers': 'folder-helper',
        };
        
        String iconName = folderMap[folderName] ?? 'folder-resource';
        if (isExpanded) {
          return 'assets/helium_icons/$iconName-open.svg';
        }
        return 'assets/helium_icons/$iconName.svg';
      } else {
        final ext = name.split('.').last.toLowerCase();
        final fileName = name.toLowerCase();
        
        // 精确文件名匹配
        const fileNameMap = {
          'package.json': 'nodejs',
          'package-lock.json': 'nodejs',
          'tsconfig.json': 'json',
          'dockerfile': 'docker',
          'docker-compose.yml': 'docker',
          'docker-compose.yaml': 'docker',
          'gitignored': 'git',
          '.gitignore': 'git',
          '.gitattributes': 'git',
          'readme.md': 'readme',
          'license': 'certificate',
          'license.md': 'certificate',
          'license.txt': 'certificate',
          'makefile': 'makefile',
        };
        
        if (fileNameMap.containsKey(fileName)) {
          return 'assets/helium_icons/${fileNameMap[fileName]}.svg';
        }

        // 扩展名匹配
        const extMap = {
          'html': 'html',
          'htm': 'html',
          'css': 'css',
          'scss': 'sass',
          'sass': 'sass',
          'less': 'less',
          'js': 'javascript',
          'mjs': 'javascript',
          'ts': 'typescript',
          'tsx': 'react_ts',
          'jsx': 'react',
          'json': 'json',
          'yaml': 'yaml',
          'yml': 'yaml',
          'xml': 'xml',
          'md': 'markdown',
          'markdown': 'markdown',
          'py': 'python',
          'pyc': 'python-misc',
          'whl': 'python-misc',
          'java': 'java',
          'jar': 'java',
          'c': 'c',
          'cpp': 'cpp',
          'cc': 'cpp',
          'h': 'h',
          'hpp': 'hpp',
          'go': 'go',
          'rb': 'ruby',
          'rs': 'rust',
          'swift': 'swift',
          'dart': 'dart',
          'php': 'php',
          'sql': 'database',
          'sh': 'console',
          'bash': 'console',
          'bat': 'console',
          'cmd': 'console',
          'ps1': 'powershell',
          'pdf': 'pdf',
          'png': 'image',
          'jpg': 'image',
          'jpeg': 'image',
          'gif': 'image',
          'svg': 'svg',
          'ico': 'image',
          'webp': 'image',
          'zip': 'zip',
          'tar': 'zip',
          'gz': 'zip',
          '7z': 'zip',
          'rar': 'zip',
          'mp3': 'audio',
          'wav': 'audio',
          'mp4': 'video',
          'mov': 'video',
          'avi': 'video',
          'exe': 'exe',
          'msi': 'exe',
          'apk': 'android',
          'doc': 'word',
          'docx': 'word',
          'xls': 'table',
          'xlsx': 'table',
          'csv': 'table',
          'ppt': 'powerpoint',
          'pptx': 'powerpoint',
          'ini': 'settings',
          'conf': 'settings',
          'config': 'settings',
          'toml': 'settings',
        };
        
        String iconName = extMap[ext] ?? 'file';
        return 'assets/helium_icons/$iconName.svg';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16 + (indentLevel * 24),
            right: 16,
            top: 4,
            bottom: 4,
          ),
          hoverColor: const Color(0xFFF5F5F5),
          leading: SvgPicture.asset(
            getHeliumIcon(),
            width: 20,
            height: 20,
            placeholderBuilder: (context) => Icon(
              isDir 
                  ? (isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined)
                  : Icons.article_outlined,
              color: isDir ? const Color(0xFF2F54EB) : const Color(0xFF8C8C8C),
              size: 20,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
          ),
          subtitle: isDir 
              ? null 
              : Text(
                  '${_formatFileSize(size)}  ·  ${_formatDateTime(item['modified'] as int? ?? 0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
          trailing: isDir
              ? Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  color: const Color(0xFFBFBFBF),
                  size: 20,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CopyButton(onTap: () => _copyFileRelativePath(item)),
                  ],
                ),
          onTap: isDir ? () => _toggleFolder(path) : null,
        ),
        if (isDir && isExpanded && _folderContents.containsKey(path))
          ..._folderContents[path]!.map((childItem) => 
            _buildDirectoryItem(childItem, indentLevel + 1),
          ).toList(),
      ],
    );
  }
}

class CopyButton extends StatefulWidget {
  final VoidCallback onTap;

  const CopyButton({super.key, required this.onTap});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isPressed 
              ? const Color(0xFF2F54EB).withOpacity(0.05) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.content_copy_outlined,
          color: _isPressed ? const Color(0xFF2F54EB) : const Color(0xFF8C8C8C),
          size: 16,
        ),
      ),
    );
  }
}
