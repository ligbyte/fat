import 'package:flutter/material.dart';
import 'rust_bridge.dart';
import 'dart:convert';

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
      title: 'Flutter Rust Demo',
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
  int _counter = 0;
  String _result = '';
  String _filePath = 'test_file.txt';
  String _fileContent = 'Hello from Flutter!';
  final ScrollController _scrollController = ScrollController();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
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
            fontSize: 18,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Counter card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Button Press Counter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$_counter',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Input fields
              Text(
                'File Operations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(height: 12),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _createFile,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create File'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _writeFile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Write File'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _readFile,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Read File'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _getFileInfo,
                    icon: const Icon(Icons.info, size: 18),
                    label: const Text('Get Info'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _deleteFile,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete File'),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Rust Powered',
                              style: TextStyle(
                                fontSize: 12,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment Counter',
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}