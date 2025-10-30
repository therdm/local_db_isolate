import '../database/database_helper.dart';
import '../models/note.dart';

/// Helper class for syncing notes to database
/// 
/// Note: Sqflite uses platform channels which cannot be accessed from spawned isolates.
/// The database operations run on background threads managed by the native platform,
/// so explicit Dart isolates are not needed for non-blocking behavior.
class IsolateHelper {
  /// Syncs notes to database using a transaction for atomicity
  /// 
  /// While this doesn't use a separate Dart isolate (due to sqflite's platform
  /// channel architecture), the database operations are still non-blocking
  /// as they run on platform-managed background threads.
  static Future<void> syncNotesToDB(List<Note> notes) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    // Use transaction for better performance and atomicity
    await db.transaction((txn) async {
      for (final note in notes) {
        await txn.insert(
          'notes',
          note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
