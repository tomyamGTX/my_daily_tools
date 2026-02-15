import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final box = Hive.box("notesBox");

  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  /// ================= LOAD =================
  void loadNotes() {
    final data = box.get("notes");
    if (data != null) {
      notes = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
  }

  /// ================= SAVE =================
  void saveNotes() => box.put("notes", notes);

  /// ================= ADD =================
  void addNote() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      notes.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "content": _controller.text.trim(),
        "date": DateTime.now().toString(),
      });
    });

    saveNotes();
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
  void showAddNoteSheet() {
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
                "Add New Note",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Write your note here...",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => addNote(),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: addNote,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Note"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= EDIT =================
  void editNote(int index) {
    _controller.text = notes[index]["content"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Note"),
        content: TextField(
          controller: _controller,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.clear();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                notes[index]["content"] = _controller.text.trim();
                notes[index]["date"] = DateTime.now().toString();
              });
              saveNotes();
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// ================= DELETE =================
  void deleteNote(int index) {
    setState(() => notes.removeAt(index));
    saveNotes();
  }

  /// ================= REORDER =================
  void reorderNotes(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = notes.removeAt(oldIndex);
      notes.insert(newIndex, item);
    });
    saveNotes();
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
              Icons.note_alt_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Notes Yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the + button below\nto add your first note ✍️",
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
        appBar: AppBar(title: const Text("Notes")),

        /// ===== LIST =====
        body: notes.isEmpty
            ? _buildEmptyState()
            : ReorderableListView.builder(
                scrollController: _scrollController,
                itemCount: notes.length,
                onReorder: reorderNotes,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final note = notes[index];

                  return Container(
                    key: ValueKey(note["id"]),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).cardColor,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => editNote(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note["content"],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      note["date"].toString().split(".")[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue.shade400,
                                ),
                                onPressed: () => editNote(index),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () => deleteNote(index),
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
            onPressed: showAddNoteSheet,
            icon: const Icon(Icons.add),
            label: const Text("Add Note"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
