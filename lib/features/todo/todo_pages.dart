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
    Navigator.pop(context);

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

  /// ================= MODAL INPUT =================
  void showAddTodoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                "Add New Task",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter task...",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => addTodo(),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: addTodo,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Task"),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          ],
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(title: const Text("To-Do List")),

        /// ===== LIST =====
        body: todos.isEmpty
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

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: todo["done"]
                            ? Colors.green.shade50
                            : Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: todo["done"]
                              ? Colors.green.shade200
                              : Colors.grey.shade200,
                        ),
                      ),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => toggleTodo(index),

                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),

                          child: Row(
                            children: [
                              /// ===== STATUS INDICATOR =====
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 10,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: todo["done"]
                                      ? Colors.green
                                      : Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// ===== CHECKBOX =====
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: todo["done"],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (_) => toggleTodo(index),
                                ),
                              ),

                              const SizedBox(width: 6),

                              /// ===== TITLE =====
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: todo["done"]
                                        ? Colors.grey
                                        : Colors.black87,
                                    decoration: todo["done"]
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  child: Text(todo["title"]),
                                ),
                              ),

                              /// ===== DELETE =====
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () => deleteTodo(index),
                                ),
                              ),

                              const SizedBox(width: 4),

                              /// ===== DRAG HANDLE =====
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: Colors.grey.shade500,
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

        /// ===== BOTTOM ADD BUTTON =====
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: showAddTodoSheet,
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
