import 'package:flutter/material.dart';
import '../models/stretching_library.dart';
import '../utils/firebase_service.dart';

class ManageStretchingLibraryScreen extends StatefulWidget {
  const ManageStretchingLibraryScreen({super.key});

  @override
  State<ManageStretchingLibraryScreen> createState() => _ManageStretchingLibraryScreenState();
}

class _ManageStretchingLibraryScreenState extends State<ManageStretchingLibraryScreen> {
    Future<void> _syncToCloud() async {
      await FirebaseService.syncStretchingLibraryToFirebase(stretchingLibrary);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stretching library synced to cloud!')),
        );
      }
    }
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController youtubeUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController difficultyController = TextEditingController();

  void _showAddStretchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Stretch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Stretch Name'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration'),
                ),
                TextField(
                  controller: youtubeUrlController,
                  decoration: const InputDecoration(labelText: 'YouTube URL'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: difficultyController,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addStretch();
                Navigator.of(context).pop();
              },
              child: const Text('Add Stretch'),
            ),
          ],
        );
      },
    );
  }

  void _addStretch() async {
    final stretch = StretchingExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      category: categoryController.text.trim(),
      duration: durationController.text.trim(),
      youtubeUrl: youtubeUrlController.text.trim(),
      description: descriptionController.text.trim(),
      difficulty: difficultyController.text.trim(),
      isCustom: true,
    );
    setState(() {
      stretchingLibrary.add(stretch);
    });
    await saveStretchingLibraryToStorage();
    nameController.clear();
    categoryController.clear();
    durationController.clear();
    youtubeUrlController.clear();
    descriptionController.clear();
    difficultyController.clear();
  }

  void _deleteStretch(String id) async {
    setState(() {
      stretchingLibrary.removeWhere((e) => e.id == id);
    });
    await saveStretchingLibraryToStorage();
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStretches = searchQuery.isEmpty
        ? stretchingLibrary
        : stretchingLibrary.where((s) =>
            s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.description.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stretching Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Stretch',
            onPressed: _showAddStretchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Sync to Cloud',
            onPressed: _syncToCloud,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Stretches',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text('Current Stretches:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: filteredStretches.length,
                itemBuilder: (context, index) {
                  final stretch = filteredStretches[index];
                  return ListTile(
                    title: Text(stretch.name),
                    subtitle: Text(stretch.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) {
                                final editNameController = TextEditingController(text: stretch.name);
                                final editCategoryController = TextEditingController(text: stretch.category);
                                final editDurationController = TextEditingController(text: stretch.duration);
                                final editYoutubeUrlController = TextEditingController(text: stretch.youtubeUrl);
                                final editDescriptionController = TextEditingController(text: stretch.description);
                                final editDifficultyController = TextEditingController(text: stretch.difficulty);
                                return AlertDialog(
                                  title: const Text('Edit Stretch'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: editNameController,
                                          decoration: const InputDecoration(labelText: 'Stretch Name'),
                                        ),
                                        TextField(
                                          controller: editCategoryController,
                                          decoration: const InputDecoration(labelText: 'Category'),
                                        ),
                                        TextField(
                                          controller: editDurationController,
                                          decoration: const InputDecoration(labelText: 'Duration'),
                                        ),
                                        TextField(
                                          controller: editYoutubeUrlController,
                                          decoration: const InputDecoration(labelText: 'YouTube URL'),
                                        ),
                                        TextField(
                                          controller: editDescriptionController,
                                          decoration: const InputDecoration(labelText: 'Description'),
                                        ),
                                        TextField(
                                          controller: editDifficultyController,
                                          decoration: const InputDecoration(labelText: 'Difficulty'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          final updated = StretchingExercise(
                                            id: stretch.id,
                                            name: editNameController.text.trim(),
                                            category: editCategoryController.text.trim(),
                                            duration: editDurationController.text.trim(),
                                            youtubeUrl: editYoutubeUrlController.text.trim(),
                                            description: editDescriptionController.text.trim(),
                                            difficulty: editDifficultyController.text.trim(),
                                            isCustom: stretch.isCustom,
                                          );
                                          final idx = stretchingLibrary.indexWhere((e) => e.id == stretch.id);
                                          if (idx != -1) stretchingLibrary[idx] = updated;
                                        });
                                        saveStretchingLibraryToStorage();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStretch(stretch.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
