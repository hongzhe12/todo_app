import 'package:flutter/material.dart';

import 'utils/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();
  List<String> todoList = [];
  final TextEditingController _controller = TextEditingController();
  int _editingIndex = -1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _apiClient.fetchTodos();
      setState(() {
        todoList = todos
            .map((item) => (item['title'] ?? '').toString())
            .where((title) => title.isNotEmpty)
            .toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _submit() {
    if (_controller.text.isEmpty) return;
    setState(() {
      if (_editingIndex == -1) {
        todoList.add(_controller.text);
      } else {
        todoList[_editingIndex] = _controller.text;
        _editingIndex = -1;
      }
      _controller.clear();
    });
  }

  void _editItem(int index) {
    setState(() {
      _controller.text = todoList[index];
      _editingIndex = index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('待办事项')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(title: const Text('待办事项')),
        body: Column(
          children: [
            Expanded(
              flex: 8,
              child: ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    color: Colors.green,
                    child: Container(
                      margin: const EdgeInsets.only(left: 20),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 80,
                            child: Text(
                              todoList[index],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _editItem(index),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () =>
                                setState(() => todoList.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _editingIndex == -1 ? '添加任务' : '编辑任务',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 10),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.2, // 行高，让文字上下更舒展
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_editingIndex == -1 ? Icons.add : Icons.edit),
                      onPressed: _submit,
                    ),
                  ],
                ))
          ],
        ));
  }
}
