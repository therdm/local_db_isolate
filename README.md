# local_db_isolate

A Flutter note-taking app demonstrating sqflite operations in isolates.

## Features

- **Add Notes**: Create notes with title and content
- **In-Memory Write**: Notes are first saved to an in-memory list
- **Sync to DB**: A dedicated button syncs all unsynced notes to SQLite database in a separate isolate
- **Read from DB**: App loads all notes from database on startup
- **Visual Indicators**: Shows which notes are synced vs unsynced

## Architecture

### Data Flow

1. **Read**: On app start, notes are loaded from SQLite database
2. **Write**: When adding a note, it's stored in an in-memory list (`_unsyncedNotes`)
3. **Sync**: "Sync to DB" button writes all unsynced notes to database using a separate isolate

### Isolate Architecture

The app demonstrates a hybrid isolate approach that works within sqflite's platform channel constraints:

1. **Main Isolate**: Handles UI and database operations (required for platform channels)
2. **Worker Isolate**: Processes and prepares note data (CPU-intensive serialization work)
3. **Communication**: Uses `SendPort`/`ReceivePort` for isolate message passing

**Flow**:
- User triggers sync → Main isolate spawns worker isolate
- Worker isolate processes notes (converts to database format)
- Worker sends processed data back to main isolate
- Main isolate executes database transaction with the prepared data

This architecture demonstrates isolate usage while respecting sqflite's platform channel architecture.

### Components

- **Note Model** (`lib/models/note.dart`): Data model for notes
- **DatabaseHelper** (`lib/database/database_helper.dart`): Manages SQLite operations
- **IsolateHelper** (`lib/isolates/db_isolate_helper.dart`): Handles database sync in separate isolate using `Isolate.spawn()`
- **Main UI** (`lib/main.dart`): Note-taking interface

### Key Features

- Uses `Isolate.spawn()` to create a separate isolate for data processing
- Uses `ConflictAlgorithm.replace` for database inserts
- Demonstrates proper isolate communication with SendPort/ReceivePort
- Visual feedback for synced/unsynced notes
- Simple and clean Material Design UI

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
