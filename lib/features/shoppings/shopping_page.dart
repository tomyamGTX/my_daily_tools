import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final box = Hive.box("shoppingBox");
  List<Map<String, dynamic>> items = [];

  /// Quick add items
  final List<String> commonItems = [
    "Milk",
    "Eggs",
    "Bread",
    "Cheese",
    "Butter",
    "Rice",
    "Chicken",
    "Fruits",
    "Vegetables",
    "Coffee",
  ];

  String? selectedQuickItem; // currently selected quick item

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
  void addItem(String name, int quantity) {
    if (name.isEmpty || quantity <= 0) return;

    setState(() {
      items.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "name": name,
        "quantity": quantity,
        "bought": false,
      });
      selectedQuickItem = null;
    });

    saveItems();
    _controller.clear();
    _quantityController.text = "1";

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
    setState(() => items[index]["bought"] = !items[index]["bought"]);
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

  /// ================= MODAL SHEET =================
  void showAddItemSheet() {
    _controller.clear();
    _quantityController.text = "1";
    selectedQuickItem = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void handleAdd() {
              final name = selectedQuickItem ?? _controller.text.trim();
              final quantity =
                  int.tryParse(_quantityController.text.trim()) ?? 1;
              if (name.isEmpty || quantity <= 0) return;
              addItem(name, quantity);
              Navigator.pop(context);
            }

            void selectQuickItem(String item) {
              setModalState(() {
                selectedQuickItem = item;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    "Add Shopping Item",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  /// Selected item display
                  if (selectedQuickItem != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Selected item: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(selectedQuickItem!)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setModalState(() {
                                selectedQuickItem = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  /// Name input for manual entry
                  if (selectedQuickItem == null) ...[
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Item name",
                        hintText: "Enter item name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Or select a common item below:",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonItems
                          .map(
                            (item) => ElevatedButton(
                              onPressed: () => selectQuickItem(item),
                              child: Text(item),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  /// Quantity input always visible when item is selected or manual input ready
                  if (selectedQuickItem != null ||
                      _controller.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        hintText: "Enter quantity (e.g., 2, 3)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: handleAdd,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Item"),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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
              "Tap the + button below to add your first shopping item 🛒.",
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Shopping List")),
      body: items.isEmpty
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
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: item["bought"] ? 0.6 : 1,
                                child: Text(
                                  "${item["name"]} (x${item["quantity"]})",
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
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => deleteItem(index),
                            ),
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

      /// ===== BOTTOM ADD BUTTON =====
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: showAddItemSheet,
          icon: const Icon(Icons.add),
          label: const Text("Add Item"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
