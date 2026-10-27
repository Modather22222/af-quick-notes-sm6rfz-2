import 'package:flutter/material.dart';

import 'notes_page.dart';
import 'notes_store.dart';

void main() {
  runApp(QuickNotesApp(store: NotesStore()));
}

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key, required this.store});

  final NotesStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: NotesPage(store: store),
    );
  }
}
