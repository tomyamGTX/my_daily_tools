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
    _focusNode.requestFocus();

    /// Auto scroll
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

  /// ================= DELETE =================
  void deleteNote(int index) {
    setState(() => notes.removeAt(index));
    saveNotes();
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
              "Tap the + button below\nto add your first note below ✍️",
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
      appBar: AppBar(title: const Text("Notes")),

      body: Column(
        children: [
          /// ===== LIST =====
          Expanded(
            child: notes.isEmpty
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
                                  /// 📝 NOTE CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

                                  /// ✏️ EDIT
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue.shade400,
                                    ),
                                    onPressed: () => editNote(index),
                                  ),

                                  /// 🗑 DELETE
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () => deleteNote(index),
                                  ),

                                  /// ↕️ DRAG
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

          /// ===== INPUT BAR (Same style as Todo) =====
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
                      hintText: "Write a new note...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addNote(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addNote,
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
