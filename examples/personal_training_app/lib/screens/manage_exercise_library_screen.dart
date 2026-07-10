import 'package:flutter/material.dart';
import '../models/exercise_library.dart';
import '../utils/firebase_service.dart';

class ManageExerciseLibraryScreen extends StatefulWidget {
  const ManageExerciseLibraryScreen({super.key});

  @override
  State<ManageExerciseLibraryScreen> createState() => _ManageExerciseLibraryScreenState();
}

class _ManageExerciseLibraryScreenState extends State<ManageExerciseLibraryScreen> {
    Future<void> _syncToCloud() async {
      await FirebaseService.syncExerciseLibraryToFirebase(exerciseLibrary);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise library synced to cloud!')),
        );
      }
    }
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController youtubeUrlController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController difficultyController = TextEditingController();
  final TextEditingController muscleGroupsController = TextEditingController();

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: youtubeUrlController,
                  decoration: const InputDecoration(labelText: 'YouTube URL'),
                ),
                TextField(
                  controller: equipmentController,
                  decoration: const InputDecoration(labelText: 'Equipment'),
                ),
                TextField(
                  controller: difficultyController,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                ),
                TextField(
                  controller: muscleGroupsController,
                  decoration: const InputDecoration(labelText: 'Muscle Groups (comma separated)'),
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
                _addExercise();
                Navigator.of(context).pop();
              },
              child: const Text('Add Exercise'),
            ),
          ],
        );
      },
    );
  }

  void _addExercise() async {
    final exercise = ExerciseDemo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      category: categoryController.text.trim(),
      youtubeUrl: youtubeUrlController.text.trim(),
      equipment: equipmentController.text.trim(),
      difficulty: difficultyController.text.trim(),
      muscleGroups: muscleGroupsController.text.split(',').map((e) => e.trim()).toList(),
      isCustom: true,
    );
    setState(() {
      exerciseLibrary.add(exercise);
    });
    await saveExerciseLibraryToStorage();
    nameController.clear();
    categoryController.clear();
    youtubeUrlController.clear();
    equipmentController.clear();
    difficultyController.clear();
    muscleGroupsController.clear();
  }

  void _deleteExercise(String id) async {
    setState(() {
      exerciseLibrary.removeWhere((e) => e.id == id);
    });
    await saveExerciseLibraryToStorage();
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredExercises = searchQuery.isEmpty
        ? exerciseLibrary
        : exerciseLibrary.where((e) =>
            e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.category.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Exercise',
            onPressed: _showAddExerciseDialog,
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
                labelText: 'Search Exercises',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text('Current Exercises:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = filteredExercises[index];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(exercise.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) {
                                final editNameController = TextEditingController(text: exercise.name);
                                final editCategoryController = TextEditingController(text: exercise.category);
                                final editYoutubeUrlController = TextEditingController(text: exercise.youtubeUrl);
                                final editEquipmentController = TextEditingController(text: exercise.equipment);
                                final editDifficultyController = TextEditingController(text: exercise.difficulty);
                                final editMuscleGroupsController = TextEditingController(text: exercise.muscleGroups.join(", "));
                                return AlertDialog(
                                  title: const Text('Edit Exercise'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: editNameController,
                                          decoration: const InputDecoration(labelText: 'Exercise Name'),
                                        ),
                                        TextField(
                                          controller: editCategoryController,
                                          decoration: const InputDecoration(labelText: 'Category'),
                                        ),
                                        TextField(
                                          controller: editYoutubeUrlController,
                                          decoration: const InputDecoration(labelText: 'YouTube URL'),
                                        ),
                                        TextField(
                                          controller: editEquipmentController,
                                          decoration: const InputDecoration(labelText: 'Equipment'),
                                        ),
                                        TextField(
                                          controller: editDifficultyController,
                                          decoration: const InputDecoration(labelText: 'Difficulty'),
                                        ),
                                        TextField(
                                          controller: editMuscleGroupsController,
                                          decoration: const InputDecoration(labelText: 'Muscle Groups (comma separated)'),
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
                                          final updated = ExerciseDemo(
                                            id: exercise.id,
                                            name: editNameController.text.trim(),
                                            category: editCategoryController.text.trim(),
                                            youtubeUrl: editYoutubeUrlController.text.trim(),
                                            equipment: editEquipmentController.text.trim(),
                                            difficulty: editDifficultyController.text.trim(),
                                            muscleGroups: editMuscleGroupsController.text.split(',').map((e) => e.trim()).toList(),
                                            isCustom: exercise.isCustom,
                                          );
                                          final idx = exerciseLibrary.indexWhere((e) => e.id == exercise.id);
                                          if (idx != -1) exerciseLibrary[idx] = updated;
                                        });
                                        saveExerciseLibraryToStorage();
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
                                  onPressed: () => _deleteExercise(exercise.id),
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
