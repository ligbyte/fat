class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // 删除: 计数器状态变量
  String _result = '';
  String _filePath = 'test_file.txt';
  String _fileContent = 'Hello from Flutter!';

  void _incrementCounter() { // 删除: 计数器递增方法
    setState(() {
      _counter++;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              //   margin: EdgeInsets.only(bottom: 16),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text('Button Press Counter'),
              //       Text('$_counter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              //     ],
              //   ),
              // ),

            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _incrementCounter(); // 删除: 调用计数器递增方法
          // 其他操作...
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

