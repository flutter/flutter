import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/exercise_library.dart';
import 'package:firebase_database/firebase_database.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Chest',
      'Back',
      'Legs',
      'Shoulders',
      'Arms',
      'Core',
    ];

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('exerciseLibrary').onValue,
        builder: (context, snapshot) {
          List<ExerciseDemo> exercises = [];
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as List<dynamic>?;
            if (data != null) {
              exercises = data
                  .where((e) => e != null)
                  .map(
                    (e) => ExerciseDemo.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList();
            }
          } else {
            exercises = exerciseLibrary;
          }
          final filteredExercises = exercises
              .where(
                (e) =>
                    (selectedCategory == 'All' ||
                        e.category == selectedCategory) &&
                    (_searchQuery.isEmpty ||
                        e.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        )),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return ExerciseCard(exercise: exercise);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final ExerciseDemo exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            title: Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            subtitle: Text(widget.exercise.category),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF2563EB),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Difficulty',
                    widget.exercise.difficulty,
                    _getDifficultyColor(widget.exercise.difficulty),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Equipment', widget.exercise.equipment, null),
                  const SizedBox(height: 12),
                  Text(
                    'Muscle Groups',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: widget.exercise.muscleGroups
                        .map(
                          (muscle) => Chip(
                            label: Text(muscle),
                            backgroundColor: const Color(
                              0xFF16A34A,
                            ).withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Watch Demo',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final url = Uri.parse(widget.exercise.youtubeUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (e) {
                          print('Error launching URL: $e');
                        }
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch on YouTube'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B7280),
          ),
        ),
        if (color != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          )
        else
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return const Color(0xFF16A34A);
      case 'Intermediate':
        return const Color(0xFFF59E0B);
      case 'Advanced':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
