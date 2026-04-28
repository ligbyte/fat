import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'rust_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RustBridge.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          seedColor: const Color(0xFF5B8DEF),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF5B8DEF),
          secondary: const Color(0xFF8B5CF6),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: const Color(0xFF5B8DEF).withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 20),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          iconTheme: IconThemeData(color: Color(0xFF5B8DEF)),
        ),
      ),
      home: const MyHomePage(title: 'FileCat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    _loadFilecatPath();
    _loadAutostartPreference();
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
      
      if (!_folderContents.containsKey(path)) {
        _loadFolderContents(path);
      }
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEEF2F7),
            ],
          ),
        ),
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
                        _buildFolderCard(),
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

  Widget _buildFolderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8DEF).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B8DEF), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B8DEF).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '共享文件夹路径',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _filecatPath.isEmpty ? '加载中...' : _filecatPath,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _changeFilecatPath,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: BorderSide(
                color: Colors.grey.shade400,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              backgroundColor: Colors.grey.shade100,
            ),
            child: Text(
              '更改路径',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryContents() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8DEF).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          const Text(
            '目录内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _directoryContents.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '文件夹为空',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _directoryContents.length,
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
        content: Text('已复制: $fullUrl'),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/loading_cat.gif',
                width: 34,
                height: 34,
              ),
              const SizedBox(width: 4),
              Text(
                _serverRunning ? '当前服务正在运行' : '当前服务启动失败，请检查端口是否被占用',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _serverRunning
                      ? const Color(0xFF029b00)
                      : const Color(0xFFff696a),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '开机自启动',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.75,
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
                  activeColor: const Color(0xFF5B8DEF),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16 + (indentLevel * 24),
            right: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDir 
                  ? const Color(0xFF5B8DEF).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDir 
                  ? (isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded)
                  : Icons.insert_drive_file_rounded,
              color: isDir ? const Color(0xFF5B8DEF) : Colors.grey.shade600,
              size: 24,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: isDir 
              ? null 
              : Text(
                  '${_formatFileSize(size)}  ${_formatDateTime(item['modified'] as int? ?? 0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
          trailing: isDir
              ? Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  color: Colors.grey.shade600,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isPressed 
              ? const Color(0xFF5B8DEF).withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.copy_rounded,
          color: _isPressed ? const Color(0xFF5B8DEF) : Colors.grey.shade600,
          size: 20,
        ),
      ),
    );
  }
}
