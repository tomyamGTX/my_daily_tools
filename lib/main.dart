import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/notes/note_pages.dart';
import 'features/shoppings/shopping_page.dart';
import 'features/todo/todo_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("todoBox");
  await Hive.openBox("notesBox");
  await Hive.openBox("shoppingBox");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDaily Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeDashboard(),
    );
  }
}

/// ===============================
/// HOME DASHBOARD
/// ===============================
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        "title": "To-Do List",
        "icon": Icons.check_circle,
        "enabled": true,
        "page": const TodoPage(),
      },
      {
        "title": "Notes",
        "icon": Icons.note,
        "enabled": true,
        "page": const NotesPage(),
      },
      {
        "title": "Shopping List",
        "icon": Icons.shopping_cart,
        "enabled": true,
        "page": const ShoppingPage(),
      },
      {
        "title": "Habit Tracker",
        "icon": Icons.local_fire_department,
        "enabled": false,
      },
      {"title": "Calculator", "icon": Icons.calculate, "enabled": false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("MyDaily Tools"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];

            return GestureDetector(
              onTap: tool["enabled"] == true
                  ? () {
                      final page = tool["page"] as Widget;

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => page),
                      );
                    }
                  : null, // Disabled → no click trigger

              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tool["icon"] as IconData,
                      size: 40,
                      color: tool["enabled"] == true
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tool["title"].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tool["enabled"] == true
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
