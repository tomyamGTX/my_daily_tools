import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final box = Hive.box("todoBox");

  List<Map<String, dynamic>> todos = [];

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  /// ================= LOAD =================
  void loadTodos() {
    final data = box.get("todos");

    if (data != null) {
      todos = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
  }

  /// ================= SAVE =================
  void saveTodos() => box.put("todos", todos);

  /// ================= ADD =================
  void addTodo() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      todos.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "title": _controller.text.trim(),
        "done": false,
      });
    });

    saveTodos();
    _controller.clear();
    _focusNode.requestFocus();

    /// Auto scroll to latest
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ================= TOGGLE =================
  void toggleTodo(int index) {
    setState(() {
      todos[index]["done"] = !todos[index]["done"];
    });

    saveTodos();
  }

  /// ================= DELETE =================
  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });

    saveTodos();
  }

  /// ================= REORDER =================
  void reorderTodo(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);
    });

    saveTodos();
  }

  /// ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Tasks Yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the + button below\nto add your first task.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).requestFocus(_focusNode);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("To-Do List")),

      body: Column(
        children: [
          /// ===== LIST =====
          Expanded(
            child: todos.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    scrollController: _scrollController,
                    itemCount: todos.length,
                    onReorder: reorderTodo,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final todo = todos[index];

                      return Container(
                        key: ValueKey(todo["id"]),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          color: todo["done"]
                              ? Colors.grey.shade100
                              : Theme.of(context).cardColor,

                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => toggleTodo(index),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              child: Row(
                                children: [
                                  /// ✅ CHECKBOX
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: todo["done"],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (_) => toggleTodo(index),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// 📝 TITLE
                                  Expanded(
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: todo["done"] ? 0.6 : 1,

                                      child: Text(
                                        todo["title"],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          decoration: todo["done"]
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// 🗑 DELETE
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () => deleteTodo(index),
                                  ),

                                  /// ↕️ DRAG HANDLE
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          /// ===== INPUT BAR =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      hintText: "Add new task...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addTodo(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTodo,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
