import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill; 

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic(); 
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController(); 
  var _isLoading = false;

  int _selectedColor = Colors.white.value; 
  List<String> _selectedTags = []; 
  bool _isPinned = false; 

  final List<Color> _noteColors = [
    Colors.white, Colors.red.shade100, Colors.orange.shade100, Colors.yellow.shade100,
    Colors.green.shade100, Colors.blue.shade100, Colors.purple.shade100, Colors.pink.shade100,
  ];

  void _addTag() { 
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty &&!_selectedTags.contains(tag)) {
      setState(() => _selectedTags.add(tag));
      _tagController.clear();
    }
  }

  void _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    await FirebaseFirestore.instance.collection('notes').add({
      'title': _titleController.text.trim(),
      'content': contentJson, N
      'createdAt': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'color': _selectedColor, 
      'tags': _selectedTags, 
      'isPinned': _isPinned, 
    });

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Note'), 
        actions: [ 
          IconButton(
            icon: Icon(_isPinned? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isPinned =!_isPinned),
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

              // Quill Editor - Replace TextFormField
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
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
                  child: const Text('Save Note', style: TextStyle(color: Colors.white)),
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
