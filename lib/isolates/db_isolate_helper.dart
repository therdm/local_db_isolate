import 'dart:isolate';
import '../database/database_helper.dart';
import '../models/note.dart';

class IsolateHelper {
  static Future<void> syncNotesToDB(List<Note> notes) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _syncNotesIsolate,
      _IsolateData(
        sendPort: receivePort.sendPort,
        notes: notes,
      ),
    );

    // Wait for the isolate to finish
    await receivePort.first;
  }

  static Future<void> _syncNotesIsolate(_IsolateData data) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      for (final note in data.notes) {
        await dbHelper.insertOrReplaceNote(note);
      }
      
      // Send completion signal
      data.sendPort.send(true);
    } catch (e) {
      // Send error signal
      data.sendPort.send(false);
    }
  }
}

class _IsolateData {
  final SendPort sendPort;
  final List<Note> notes;

  _IsolateData({
    required this.sendPort,
    required this.notes,
  });
}
