import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_notes/main.dart';
import 'package:quick_notes/notes_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('launches into the editor and autosaves typed notes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final NotesStore store = NotesStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(QuickNotesApp(store: store));
    await tester.pump(); // Allow the async initial load to finish.

    // The app opens straight into a text field with an empty note list.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Quick Notes'), findsOneWidget);
    expect(find.textContaining('No notes yet'), findsOneWidget);

    // Typing autosaves the note; it appears in the saved-notes list.
    await tester.enterText(find.byType(TextField), 'First sticky note');
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'First sticky note'), findsOneWidget);

    // Let the debounced local write fire before the test ends.
    await tester.pump(const Duration(milliseconds: 600));
  });
}
