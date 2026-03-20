import 'package:flutter/material.dart';

import '../../../features/workout/presentation/active_workout/models/exercise_library_item.dart';

class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({
    required this.exercises,
    super.key,
  });

  final List<ExerciseLibraryItem> exercises;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<ExerciseLibraryItem> filtered = _filterExercises(_query);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vælg øvelse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (String value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Søg øvelse',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Ingen øvelser matcher søgningen'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final ExerciseLibraryItem item = filtered[index];
                        return ListTile(
                          title: Text(item.navnDa),
                          subtitle: Text('${item.primaerMuskelgruppe} • ${item.udstyr}'),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<ExerciseLibraryItem> _filterExercises(String query) {
    if (query.isEmpty) {
      return widget.exercises;
    }

    final String normalized = query.toLowerCase();
    return widget.exercises.where((ExerciseLibraryItem item) {
      return item.navnDa.toLowerCase().contains(normalized) ||
          item.primaerMuskelgruppe.toLowerCase().contains(normalized) ||
          item.udstyr.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }
}