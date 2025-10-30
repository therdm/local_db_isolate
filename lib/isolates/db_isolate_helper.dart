import 'dart:isolate';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

/// Helper class for syncing notes to database using isolates
/// 
/// This implementation uses a dedicated isolate to handle the database sync logic.
/// The isolate prepares the data and sends commands back to the main isolate
/// which executes the actual database operations (required due to platform channel constraints).
class IsolateHelper {
  /// Syncs notes to database using a separate isolate
  static Future<void> syncNotesToDB(
    List<Note> notes,
    Database database,
  ) async {
    final receivePort = ReceivePort();

    // Spawn isolate to process the notes
    await Isolate.spawn(
      _isolateEntry,
      _IsolateMessage(
        sendPort: receivePort.sendPort,
        notes: notes,
      ),
    );

    // Receive processed notes from isolate
    final processedData = await receivePort.first as List<Map<String, dynamic>>;

    // Execute database operations on main isolate (required for platform channels)
    await database.transaction((txn) async {
      for (final noteMap in processedData) {
        await txn.insert(
          'notes',
          noteMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Isolate entry point - runs in separate isolate
  static void _isolateEntry(_IsolateMessage message) {
    // Process notes in isolate (CPU-intensive work happens here)
    final processedNotes = <Map<String, dynamic>>[];

    for (final note in message.notes) {
      // Convert note to map format for database
      // This work happens in the isolate, not blocking the UI
      final noteMap = note.toMap();
      processedNotes.add(noteMap);
    }

    // Send processed data back to main isolate
    message.sendPort.send(processedNotes);
  }
}

/// Message class for isolate communication
class _IsolateMessage {
  final SendPort sendPort;
  final List<Note> notes;

  _IsolateMessage({
    required this.sendPort,
    required this.notes,
  });
}
