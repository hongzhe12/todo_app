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

  List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _controller = TextEditingController();
  int? _editingId;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  final Set<int> _updatingCompletedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _apiClient.fetchTodos();

      setState(() {
        _todoList = todos;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      if (_editingId == null) {
        await _apiClient.createTodo(title: title);
      } else {
        await _apiClient.updateTodo(_editingId!, title: title);
      }

      _controller.clear();
      _editingId = null;
      await _loadTodos();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _editItem(Map<String, dynamic> item) {
    final id = item['id'] as int?;
    if (id == null) return;

    setState(() {
      _controller.text = (item['title'] ?? '').toString();
      _editingId = id;
    });
  }

  void _cancelEditing() {
    setState(() {
      _controller.clear();
      _editingId = null;
    });
  }

  Future<void> _toggleCompleted(Map<String, dynamic> item, bool value) async {
    final id = item['id'] as int?;
    if (id == null) return;

    if (_updatingCompletedIds.contains(id)) return;

    final index = _todoList.indexWhere((todo) => todo['id'] == id);
    if (index == -1) return;

    final previousValue = _todoList[index]['completed'] == true;

    setState(() {
      _updatingCompletedIds.add(id);
      _todoList[index] = {
        ..._todoList[index],
        'completed': value,
      };
    });

    try {
      await _apiClient.updateTodo(id, completed: value);
    } catch (e) {
      if (mounted) {
        setState(() {
          _todoList[index] = {
            ..._todoList[index],
            'completed': previousValue,
          };
        });
      }
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _updatingCompletedIds.remove(id);
        });
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await _apiClient.deleteTodo(id);

      if (_editingId == id) {
        _controller.clear();
        _editingId = null;
      }

      await _loadTodos();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        appBar: AppBar(
          title: const Text('待办事项'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTodos,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _editingId == null ? '添加任务' : '编辑任务',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.2,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_editingId != null)
                    IconButton(
                      tooltip: '取消编辑',
                      icon: const Icon(Icons.close),
                      onPressed: _submitting ? null : _cancelEditing,
                    ),
                  IconButton(
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_editingId == null ? Icons.add : Icons.edit),
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _todoList.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage == null ? '暂无待办' : _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      itemCount: _todoList.length,
                      itemBuilder: (context, index) {
                        final item = _todoList[index];
                        final id = item['id'] as int?;
                        final title = (item['title'] ?? '').toString();
                        final completed = item['completed'] == true;
                        final updatingCompleted =
                          id != null && _updatingCompletedIds.contains(id);

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          color: completed ? Colors.grey : Colors.green,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: completed,
                                  activeColor: Colors.white,
                                  checkColor: Colors.green,
                                  onChanged: updatingCompleted
                                      ? null
                                      : (value) {
                                    if (value != null) {
                                      _toggleCompleted(item, value);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      decoration: completed
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  onPressed: () => _editItem(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  onPressed: id == null
                                      ? null
                                      : () => _deleteItem(id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ));
  }
}
