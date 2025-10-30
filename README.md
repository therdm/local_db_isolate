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
3. **Sync**: "Sync to DB" button writes all unsynced notes to database in a separate isolate

### Components

- **Note Model** (`lib/models/note.dart`): Data model for notes
- **DatabaseHelper** (`lib/database/database_helper.dart`): Manages SQLite operations
- **IsolateHelper** (`lib/isolates/db_isolate_helper.dart`): Handles database sync in separate isolate
- **Main UI** (`lib/main.dart`): Note-taking interface

### Key Features

- Uses `ConflictAlgorithm.replace` for database inserts
- Database operations run in separate isolate to avoid blocking UI
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
