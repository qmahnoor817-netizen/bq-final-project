import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill; 
import '../model/note.dart';

class EditNoteScreen extends StatefulWidget {
  final Note note;
  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController; 
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController(); 
  var _isLoading = false;

  late int _selectedColor; 
  late List<String> _selectedTags; 
  late bool _isPinned; 

  final List<Color> _noteColors = [ 
    Colors.white, Colors.red.shade100, Colors.orange.shade100, Colors.yellow.shade100,
    Colors.green.shade100, Colors.blue.shade100, Colors.purple.shade100, Colors.pink.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _selectedColor = widget.note.color;
    _selectedTags = List.from(widget.note.tags); 
    _isPinned = widget.note.isPinned; 

    // Load Quill content 
    try {
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(widget.note.content)),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      _quillController = quill.QuillController.basic();
    }
  }

  void _addTag() { 
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty &&!_selectedTags.contains(tag)) {
      setState(() => _selectedTags.add(tag));
      _tagController.clear();
    }
  }

  void _updateNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    await FirebaseFirestore.instance
        .collection('notes')
        .doc(widget.note.id)
        .update({
      'title': _titleController.text.trim(),
      'content': contentJson, 
      'color': _selectedColor, 
      'tags': _selectedTags, 
      'isPinned': _isPinned, 
    });

    if (mounted) Navigator.of(context).pop();
  }

  void _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .delete();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'), 
        actions: [
          IconButton( 
            icon: Icon(_isPinned? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isPinned =!_isPinned),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty? 'Enter a title' : null,
              ),
              const SizedBox(height: 10),

              // Quill Toolbar 
              quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(),
              ),

              // Quill Editor
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    config: const quill.QuillEditorConfig(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tags 
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(labelText: 'Add Tag', border: OutlineInputBorder()),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
                ],
              ),
              Wrap(
                spacing: 6,
                children: _selectedTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _selectedTags.remove(tag)),
                )).toList(),
              ),
              const SizedBox(height: 10),

              // Color picker
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _noteColors.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = _noteColors[i].value),
                    child: Container(
                      width: 40, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _noteColors[i], shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == _noteColors[i].value? Colors.black : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _updateNote,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Update Note', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose(); 
    _tagController.dispose(); 
    super.dispose();
  }
}
