import 'dart:async';

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
      home: AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String _baseUrl = 'http://127.0.0.1:8000/o/app';

  void _updateBaseUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == _baseUrl) return;

    setState(() {
      _baseUrl = normalized;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodoPage(baseUrl: _baseUrl),
      SettingsPage(
        baseUrl: _baseUrl,
        onSave: _updateBaseUrl,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: '待办',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late ApiClient _apiClient;

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
    _apiClient = ApiClient(baseUrl: widget.baseUrl);
    _loadTodos();
  }

  @override
  void didUpdateWidget(covariant TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseUrl != widget.baseUrl) {
      _apiClient = ApiClient(baseUrl: widget.baseUrl);
      _controller.clear();
      _editingId = null;
      _errorMessage = null;
      _loading = true;
      _loadTodos();
    }
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _apiClient.fetchTodos();

      if (!mounted) return;

      setState(() {
        _todoList = todos;
        _errorMessage = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = '请求超时，请检查网络后重试';
      });
    } catch (e) {
      if (!mounted) return;
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
    } on TimeoutException {
      _showError('请求超时，请检查网络后重试');
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
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _todoList[index] = {
            ..._todoList[index],
            'completed': previousValue,
          };
        });
      }
      _showError('请求超时，请检查网络后重试');
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
    } on TimeoutException {
      _showError('请求超时，请检查网络后重试');
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
    const title = '待办事项';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('待办事项')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
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
                      child: _errorMessage == null
                          ? const Text(
                              '暂无待办',
                              style: TextStyle(fontSize: 16),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  size: 42,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadTodos,
                                  child: const Text('重试'),
                                ),
                              ],
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.baseUrl,
    required this.onSave,
  });

  final String baseUrl;
  final ValueChanged<String> onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.baseUrl);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseUrl != widget.baseUrl &&
        _controller.text != widget.baseUrl) {
      _controller.text = widget.baseUrl;
    }
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 baseUrl')),
      );
      return;
    }

    widget.onSave(value);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('baseUrl 已更新')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '接口地址',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://127.0.0.1:8000/o/app',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            const Text(
              '修改后会立即切换到新的接口地址。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存并切换'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
