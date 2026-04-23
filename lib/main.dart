import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rust_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RustBridge.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
        // 使用更柔和的颜色主题，类似iOS/MacOS风格
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.grey.shade800,
          secondary: Colors.blue.shade600,
          surface: Colors.grey.shade50,
        ),
        useMaterial3: true,
        cardTheme: CardTheme.of(context).copyWith(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const MyHomePage(title: 'Flutter Rust File Operations'),
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
  String _result = '';
  String _filePath = 'test_file.txt';
  String _fileContent = 'Hello from Flutter!';
  String _filecatPath = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFilecatPath();
  }

  void _loadFilecatPath() async {
    // 先从SharedPreferences读取保存的路径
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('filecat_path');
    
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _filecatPath = savedPath;
      });
    } else {
      // 如果没有保存的路径，从Rust获取默认路径
      final path = RustBridge.getFilecatPath();
      if (path != null) {
        // 解析JSON响应获取路径
        try {
          final jsonMap = {
            'success': true,
            'data': path.contains('"data":"') 
                ? path.split('"data":"')[1].split('"')[0]
                : path,
          };
          setState(() {
            _filecatPath = jsonMap['data'] as String;
          });
        } catch (e) {
          setState(() {
            _filecatPath = path;
          });
        }
      }
    }
  }

  void _changeFilecatPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      setState(() {
        _filecatPath = selectedDirectory;
      });
      
      // 保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('filecat_path', selectedDirectory);
    }
  }

  void _createFile() async {
    final result = RustBridge.createFile(_filePath);
    setState(() {
      _result = result ?? 'Error: Result is null';
    });
  }

  void _readFile() async {
    final result = RustBridge.readFile(_filePath);
    setState(() {
      _result = result ?? 'Error: Result is null';
    });
  }

  void _writeFile() async {
    final result = RustBridge.writeFile(_filePath, _fileContent);
    setState(() {
      _result = result ?? 'Error: Result is null';
    });
  }

  void _getFileInfo() async {
    final result = RustBridge.getFileInfo(_filePath);
    setState(() {
      _result = result ?? 'Error: Result is null';
    });
  }

  void _deleteFile() async {
    final result = RustBridge.deleteFile(_filePath);
    setState(() {
      _result = result ?? 'Error: Result is null';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 16),
              const Condition.equals(name: TABLET, value: 18),
              const Condition.equals(name: DESKTOP, value: 20),
            ]).value,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              setState(() {
                _result = '';
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use the actual screen width instead of forcing a fixed scaled width
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveValue<double>(context, conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 12.0),
                  const Condition.equals(name: TABLET, value: 16.0),
                  const Condition.equals(name: DESKTOP, value: 24.0),
                ]).value,
                vertical: ResponsiveValue<double>(context, conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 8.0),
                  const Condition.equals(name: TABLET, value: 16.0),
                  const Condition.equals(name: DESKTOP, value: 20.0),
                ]).value,
              ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveValue<double>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: double.infinity),
                    const Condition.equals(name: TABLET, value: 800),
                    const Condition.equals(name: DESKTOP, value: 1200),
                    const Condition.equals(name: '4K', value: 1400),
                  ]).value,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
              // Input fields
              Text(
                'Shared folder',
                style: TextStyle(
                  fontSize: ResponsiveValue<double>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 16),
                    const Condition.equals(name: TABLET, value: 18),
                    const Condition.equals(name: DESKTOP, value: 20),
                  ]).value,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Filecat path display
              Card(
                child: Padding(
                  padding: ResponsiveValue<EdgeInsets>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: EdgeInsets.all(12.0)),
                    const Condition.equals(name: TABLET, value: EdgeInsets.all(16.0)),
                    const Condition.equals(name: DESKTOP, value: EdgeInsets.all(16.0)),
                  ]).value,
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.secondary,
                        size: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 20),
                          const Condition.equals(name: TABLET, value: 24),
                          const Condition.equals(name: DESKTOP, value: 24),
                        ]).value,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text(
                            //   'Shared folder',
                            //   style: TextStyle(
                            //     fontSize: ResponsiveValue<double>(context, conditionalValues: [
                            //       const Condition.equals(name: MOBILE, value: 12),
                            //       const Condition.equals(name: TABLET, value: 14),
                            //       const Condition.equals(name: DESKTOP, value: 14),
                            //     ]).value,
                            //     fontWeight: FontWeight.w600,
                            //     color: Theme.of(context).colorScheme.primary,
                            //   ),
                            // ),
                            // const SizedBox(height: 4),
                            Text(
                              _filecatPath.isEmpty ? 'Loading...' : _filecatPath,
                              style: TextStyle(
                                fontSize: ResponsiveValue<double>(context, conditionalValues: [
                                  const Condition.equals(name: MOBILE, value: 11),
                                  const Condition.equals(name: TABLET, value: 12),
                                  const Condition.equals(name: DESKTOP, value: 13),
                                ]).value,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _changeFilecatPath,
                        child: Text(
                          '更改路径',
                          style: TextStyle(
                            fontSize: ResponsiveValue<double>(context, conditionalValues: [
                              const Condition.equals(name: MOBILE, value: 12),
                              const Condition.equals(name: TABLET, value: 13),
                              const Condition.equals(name: DESKTOP, value: 14),
                            ]).value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Card(
                child: Padding(
                  padding: ResponsiveValue<EdgeInsets>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: EdgeInsets.all(12.0)),
                    const Condition.equals(name: TABLET, value: EdgeInsets.all(16.0)),
                    const Condition.equals(name: DESKTOP, value: EdgeInsets.all(16.0)),
                  ]).value,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'File Path',
                          hintText: 'Enter file path (e.g., test.txt)',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _filePath = value;
                          });
                        },
                        controller: TextEditingController()..text = _filePath,
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 10),
                          const Condition.equals(name: TABLET, value: 12),
                          const Condition.equals(name: DESKTOP, value: 12),
                        ]).value,
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'File Content',
                          hintText: 'Enter content to write',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          setState(() {
                            _fileContent = value;
                          });
                        },
                        controller: TextEditingController()..text = _fileContent,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Text(
                'Operations',
                style: TextStyle(
                  fontSize: ResponsiveValue<double>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 16),
                    const Condition.equals(name: TABLET, value: 18),
                    const Condition.equals(name: DESKTOP, value: 20),
                  ]).value,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: ResponsiveValue<double>(context, conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 6),
                  const Condition.equals(name: TABLET, value: 8),
                  const Condition.equals(name: DESKTOP, value: 8),
                ]).value,
                runSpacing: ResponsiveValue<double>(context, conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 6),
                  const Condition.equals(name: TABLET, value: 8),
                  const Condition.equals(name: DESKTOP, value: 8),
                ]).value,
                children: [
                  OutlinedButton.icon(
                    onPressed: _createFile,
                    icon: Icon(Icons.add, 
                      size: ResponsiveValue<double>(context, conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 18),
                        const Condition.equals(name: DESKTOP, value: 18),
                      ]).value,
                    ),
                    label: Text('Create File',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 14),
                          const Condition.equals(name: DESKTOP, value: 14),
                        ]).value,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _writeFile,
                    icon: Icon(Icons.edit,
                      size: ResponsiveValue<double>(context, conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 18),
                        const Condition.equals(name: DESKTOP, value: 18),
                      ]).value,
                    ),
                    label: Text('Write File',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 14),
                          const Condition.equals(name: DESKTOP, value: 14),
                        ]).value,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _readFile,
                    icon: Icon(Icons.visibility,
                      size: ResponsiveValue<double>(context, conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 18),
                        const Condition.equals(name: DESKTOP, value: 18),
                      ]).value,
                    ),
                    label: Text('Read File',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 14),
                          const Condition.equals(name: DESKTOP, value: 14),
                        ]).value,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _getFileInfo,
                    icon: Icon(Icons.info,
                      size: ResponsiveValue<double>(context, conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 18),
                        const Condition.equals(name: DESKTOP, value: 18),
                      ]).value,
                    ),
                    label: Text('Get Info',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 14),
                          const Condition.equals(name: DESKTOP, value: 14),
                        ]).value,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _deleteFile,
                    icon: Icon(Icons.delete,
                      size: ResponsiveValue<double>(context, conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 18),
                        const Condition.equals(name: DESKTOP, value: 18),
                      ]).value,
                    ),
                    label: Text('Delete File',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(context, conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 14),
                          const Condition.equals(name: DESKTOP, value: 14),
                        ]).value,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Result section
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Result',
                              style: TextStyle(
                                fontSize: ResponsiveValue<double>(context, conditionalValues: [
                                  const Condition.equals(name: MOBILE, value: 14),
                                  const Condition.equals(name: TABLET, value: 16),
                                  const Condition.equals(name: DESKTOP, value: 18),
                                ]).value,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Rust Powered',
                              style: TextStyle(
                                fontSize: ResponsiveValue<double>(context, conditionalValues: [
                                  const Condition.equals(name: MOBILE, value: 10),
                                  const Condition.equals(name: TABLET, value: 12),
                                  const Condition.equals(name: DESKTOP, value: 14),
                                ]).value,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: SelectableText(
                                  _result.isEmpty 
                                      ? 'Results from file operations will appear here...\n\nTry creating, writing, or reading a file to see results.' 
                                      : _result,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
                ),
              ),
            ),
        );
          },
        ),
      ),
    );
  }
}