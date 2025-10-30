import 'package:flutter/material.dart';
import 'models/note.dart';
import 'database/database_helper.dart';
import 'isolates/db_isolate_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final List<Note> _unsyncedNotes = [];
  List<Note> _allNotes = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadNotesFromDB();
  }

  Future<void> _loadNotesFromDB() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await DatabaseHelper.instance.readAllNotes();
      setState(() {
        _allNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notes: $e')),
        );
      }
    }
  }

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final note = Note(
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: DateTime.now(),
                );

                setState(() {
                  _unsyncedNotes.add(note);
                  _allNotes.insert(0, note);
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncToDB() async {
    if (_unsyncedNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes to sync')),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await IsolateHelper.syncNotesToDB(_unsyncedNotes);

      setState(() {
        _unsyncedNotes.clear();
        _isSyncing = false;
      });

      await _loadNotesFromDB();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes synced successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing notes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Notes App'),
        actions: [
          if (_unsyncedNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Chip(
                  label: Text('${_unsyncedNotes.length} unsynced'),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allNotes.isEmpty
              ? const Center(
                  child: Text(
                    'No notes yet. Tap + to add one!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _allNotes.length,
                  itemBuilder: (context, index) {
                    final note = _allNotes[index];
                    final isUnsynced = _unsyncedNotes.contains(note);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: isUnsynced ? Colors.yellow[50] : null,
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.content.isNotEmpty)
                              Text(note.content),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(note.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: isUnsynced
                            ? const Icon(Icons.cloud_upload, color: Colors.orange)
                            : const Icon(Icons.cloud_done, color: Colors.green),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_unsyncedNotes.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'sync',
              onPressed: _isSyncing ? null : _syncToDB,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sync to DB'),
              backgroundColor: Colors.green,
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addNote,
            tooltip: 'Add Note',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
