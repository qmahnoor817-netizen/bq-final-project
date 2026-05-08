import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart'; // #5
import 'package:http/http.dart' as http; // #13
import '../model/note.dart';
import 'add_note_screen.dart';
import 'edit_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  final VoidCallback toggleTheme; // Added
  final bool isDarkMode; // Added

  const NotesListScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  String _searchQuery = '';
  String _selectedTag = 'All';
  bool _isSummarizing = false; // #13 - Removed _isDarkMode

  // #13 Local fallback summary - instant
  String _localSummary(String content) {
    final sentences = content.split(RegExp(r'[.!?]\s+')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isEmpty) return 'Empty note';
    if (sentences.length <= 3) {
      return sentences.map((s) => '• ${s.trim()}').join('\n');
    }
    return '• ${sentences.first.trim()}\n• ${sentences[sentences.length ~/ 2].trim()}\n• ${sentences.last.trim()}';
  }

  // #13 AI Summary with fallback
  Future<void> _summarizeNote(Note note) async {
    final plainContent = _getPlainText(note.content);
    if (plainContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note is empty')));
      return;
    }

    setState(() => _isSummarizing = true);

    final truncatedContent = plainContent.length > 2000
        ? '${plainContent.substring(0, 2000)}...'
        : plainContent;

    const apiKey = 'AIzaSyDpEFCnBVBCelTomDO6ztvTDaMQqBXdkHk';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": "Summarize in 3 short bullet points max:\n\n$truncatedContent"}]
          }],
          "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 150,
          }
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['candidates'][0]['content']['parts'][0]['text'];
        _showSummaryDialog(note.title, summary);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      final fallbackSummary = _localSummary(plainContent);
      _showSummaryDialog('${note.title} - Quick Summary', fallbackSummary);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Using offline summary'), duration: Duration(seconds: 2))
        );
      }
    }

    if (mounted) setState(() => _isSummarizing = false);
  }

  void _showSummaryDialog(String title, String summary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Share.share('Summary of "$title":\n\n$summary');
              Navigator.pop(ctx);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  // #5 Share Note - Fixed
  void _shareNote(Note note) async {
    final plainContent = _getPlainText(note.content);
    final tags = note.tags.isNotEmpty? '\n\nTags: ${note.tags.join(', ')}' : '';
    final textToShare = '${note.title}\n\n$plainContent$tags';

    if (textToShare.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to share'))
      );
      return;
    }

    try {
      await Share.share(
        textToShare,
        subject: note.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Share failed: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Stack( // Removed MaterialApp wrapper
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: false,
            elevation: 4,
            shadowColor: Colors.black54,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton( // #12
                icon: Icon(widget.isDarkMode? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle Theme',
                onPressed: widget.toggleTheme, // Changed
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search notes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notes')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No notes yet. Add one!'));
                    }

                    var notes = snapshot.data!.docs.map((doc) => Note.fromFirestore(doc)).toList();

                    final allTags = notes.expand((note) => note.tags).toSet().toList();
                    allTags.sort();
                    final tagsWithAll = ['All',...allTags];

                    if (_searchQuery.isNotEmpty) {
                      notes = notes.where((note) {
                        final titleMatch = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
                        try {
                          final doc = quill.Document.fromJson(jsonDecode(note.content));
                          final contentMatch = doc.toPlainText().toLowerCase().contains(_searchQuery.toLowerCase());
                          return titleMatch || contentMatch;
                        } catch (_) {
                          return titleMatch;
                        }
                      }).toList();
                    }

                    if (_selectedTag!= 'All') {
                      notes = notes.where((note) => note.tags.contains(_selectedTag)).toList();
                    }

                    notes.sort((a, b) {
                      if (a.isPinned &&!b.isPinned) return -1;
                      if (!a.isPinned && b.isPinned) return 1;
                      return b.createdAt.compareTo(a.createdAt);
                    });

                    return Column(
                      children: [
                        if (tagsWithAll.length > 1)
                          SizedBox(
                            height: 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              children: tagsWithAll.map((tag) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(tag),
                                  selected: _selectedTag == tag,
                                  onSelected: (_) => setState(() => _selectedTag = tag),
                                  selectedColor: Colors.purple.shade100,
                                  checkmarkColor: Colors.purple,
                                ),
                              )).toList(),
                            ),
                          ),
                        Expanded(
                          child: notes.isEmpty
                              ? const Center(child: Text('No notes match your search'))
                              : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: notes.length,
                            itemBuilder: (ctx, i) {
                              final note = notes[i];
                              return Dismissible(
                                key: ValueKey(note.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  FirebaseFirestore.instance
                                      .collection('notes')
                                      .doc(note.id)
                                      .delete();
                                },
                                child: Card(
                                  color: Color(note.color).withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (note.isPinned)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 8, top: 2),
                                              child: Icon(Icons.push_pin, color: Colors.orange, size: 20),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        note.title,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.purple,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    PopupMenuButton(
                                                      icon: const Icon(Icons.more_vert, size: 20),
                                                      itemBuilder: (ctx) => [
                                                        const PopupMenuItem(
                                                          value: 'share',
                                                          child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')]),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'summary',
                                                          child: Row(children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('AI Summary')]),
                                                        ),
                                                      ],
                                                      onSelected: (val) {
                                                        if (val == 'share') _shareNote(note);
                                                        if (val == 'summary') _summarizeNote(note);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _getPlainText(note.content),
                                                  style: TextStyle(fontSize: 15, color: widget.isDarkMode? Colors.white70 : Colors.black87), // Changed
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (note.tags.isNotEmpty)...[
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: note.tags.map((t) => Chip(
                                                      label: Text(t, style: const TextStyle(fontSize: 10)),
                                                      visualDensity: VisualDensity.compact,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    )).toList(),
                                                  ),
                                                ],
                                              ],
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
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddNoteScreen()),
            ),
          ),
        ),
        if (_isSummarizing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Generating AI Summary...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getPlainText(String content) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      return doc.toPlainText().replaceAll('\n', ' ');
    } catch (_) {
      return content;
    }
  }
}
