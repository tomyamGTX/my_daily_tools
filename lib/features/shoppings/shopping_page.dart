import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final box = Hive.box("shoppingBox");

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  /// ================= LOAD =================
  void loadItems() {
    final data = box.get("items");

    if (data != null) {
      items = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
  }

  /// ================= SAVE =================
  void saveItems() => box.put("items", items);

  /// ================= ADD =================
  void addItem() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      items.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "name": _controller.text.trim(),
        "bought": false,
      });
    });

    saveItems();
    _controller.clear();
    _focusNode.requestFocus();

    /// Auto scroll to bottom
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
  void toggleItem(int index) {
    setState(() {
      items[index]["bought"] = !items[index]["bought"];
    });

    saveItems();
  }

  /// ================= DELETE =================
  void deleteItem(int index) {
    setState(() => items.removeAt(index));
    saveItems();
  }

  /// ================= REORDER =================
  void reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });

    saveItems();
  }

  /// ================= EMPTY =================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Items Yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the + button below\nto add your first shopping item 🛒.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).requestFocus(_focusNode);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Note"),
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
      appBar: AppBar(title: const Text("Shopping List")),

      body: Column(
        children: [
          /// ===== LIST =====
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    scrollController: _scrollController,
                    itemCount: items.length,
                    onReorder: reorderItems,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        key: ValueKey(item["id"]),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          color: item["bought"]
                              ? Colors.grey.shade100
                              : Theme.of(context).cardColor,

                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => toggleItem(index),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              child: Row(
                                children: [
                                  /// ☑️ CHECKBOX
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: item["bought"],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (_) => toggleItem(index),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// 🛒 ITEM NAME
                                  Expanded(
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: item["bought"] ? 0.6 : 1,

                                      child: Text(
                                        item["name"],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          decoration: item["bought"]
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
                                    onPressed: () => deleteItem(index),
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

          /// ===== INPUT BAR (INLINE) =====
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
                      hintText: "Add new item...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addItem,
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
