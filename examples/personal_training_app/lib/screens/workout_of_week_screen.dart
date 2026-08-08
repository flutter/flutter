import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/firebase_service.dart';

class WorkoutOfWeekScreen extends StatefulWidget {
  final bool canEdit;

  const WorkoutOfWeekScreen({super.key, this.canEdit = false});

  @override
  State<WorkoutOfWeekScreen> createState() => _WorkoutOfWeekScreenState();
}

class _WorkoutOfWeekScreenState extends State<WorkoutOfWeekScreen> {
  final _titleController = TextEditingController();
  final _focusController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _loadWorkoutOfWeek();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutOfWeek() async {
    setState(() => _loading = true);
    final data = await FirebaseService.getWorkoutOfWeek();
    if (!mounted) return;

    if (data != null) {
      _titleController.text = (data['title'] ?? '').toString();
      _focusController.text = (data['focus'] ?? '').toString();
      _detailsController.text = (data['details'] ?? '').toString();

      final updatedAtRaw = data['updatedAt']?.toString();
      _updatedAt = updatedAtRaw == null || updatedAtRaw.isEmpty
          ? null
          : DateTime.tryParse(updatedAtRaw);
    } else {
      _titleController.clear();
      _focusController.clear();
      _detailsController.clear();
      _updatedAt = null;
    }

    setState(() => _loading = false);
  }

  Future<void> _saveWorkoutOfWeek() async {
    final title = _titleController.text.trim();
    final focus = _focusController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title and details.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await FirebaseService.saveWorkoutOfWeek({
      'title': title,
      'focus': focus,
      'details': details,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    await _loadWorkoutOfWeek();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Circuit of the Week saved.')),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasWorkout =
        _titleController.text.trim().isNotEmpty || _detailsController.text.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadWorkoutOfWeek,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Circuit of the Week',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.canEdit
                ? 'Create this week\'s featured workout for all clients.'
                : 'Your instructor\'s featured workout this week.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_updatedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateFormat('EEE, MMM d • h:mm a').format(_updatedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (widget.canEdit) ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Full Body Power Builder',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _focusController,
              decoration: const InputDecoration(
                labelText: 'Focus (optional)',
                hintText: 'e.g. Strength + Core Stability',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              minLines: 5,
              maxLines: 9,
              decoration: const InputDecoration(
                labelText: 'Workout details',
                hintText:
                    'List exercises, sets/reps, rest times, and coaching notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _saveWorkoutOfWeek,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Publish Circuit of the Week'),
            ),
            const SizedBox(height: 20),
          ],
          if (!hasWorkout)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.canEdit
                      ? 'No workout has been published yet. Fill the form above and publish when ready.'
                      : 'No circuit of the week has been posted yet.',
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.trim(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_focusController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _focusController.text.trim(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      _detailsController.text.trim(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}