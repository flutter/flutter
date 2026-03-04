import 'package:flutter/material.dart';
import '../../../app/state/training_scope.dart';
import '../domain/workout_template.dart';
import '../domain/exercise.dart';

import '../../../app/state/training_controller.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int? _selectedExerciseIndex;
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final TrainingController controller = TrainingScope.of(context);
    final WorkoutTemplate? activeWorkout = controller.activeWorkout;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (activeWorkout == null) {
      final WorkoutTemplate nextWorkout = controller.nextWorkout;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          const SizedBox(height: 6),
          _TopControls(
            minimizeLabel: 'Minimer',
            onMinimize: () {
              setState(() {
                _isMinimized = false;
              });
            },
            onFinish: null,
          ),
          const SizedBox(height: 22),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Ny træning', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Tryk for at omdøbe',
                          style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.timer_outlined, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('00:00', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => controller.startWorkout(nextWorkout),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Start ${nextWorkout.name}'),
          ),
        ],
      );
    }

    final List<Exercise> exercises = activeWorkout.exercises;
    final int targetSets = controller.suggestedSessionSetTarget;
    final int completedSets = controller.activeSessionSetCount;
    final int remainingSets = (targetSets - completedSets).clamp(0, targetSets);
    final String elapsed = _formatDuration(controller.activeSessionDuration);

    final int currentExerciseIndex = _resolveCurrentExerciseIndex(exercises, controller);
    final Exercise? currentExercise = exercises.isEmpty ? null : exercises[currentExerciseIndex];
    final int currentExerciseSets = currentExercise == null ? 0 : controller.setsForExercise(currentExercise.id);
    final String previousExerciseText =
        currentExerciseIndex > 0 ? exercises[currentExerciseIndex - 1].name : 'Ingen endnu';
    final String nextExerciseText =
        currentExerciseIndex + 1 < exercises.length ? exercises[currentExerciseIndex + 1].name : 'Afslut pas';
    final int progressPercent = targetSets == 0 ? 0 : ((completedSets / targetSets) * 100).round();

    return Stack(
      children: <Widget>[
        ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _isMinimized ? 116 : 24),
          children: <Widget>[
        const SizedBox(height: 6),
        _TopControls(
          minimizeLabel: _isMinimized ? 'Udvid' : 'Minimer',
          onMinimize: () {
            setState(() {
              _isMinimized = !_isMinimized;
            });
          },
          onFinish: controller.finishWorkout,
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: colorScheme.outlineVariant),
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.tertiaryContainer.withValues(alpha: 0.35),
                colorScheme.primaryContainer.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(activeWorkout.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    _PillLabel(
                      text: 'Normal',
                      backgroundColor: colorScheme.surface,
                      textColor: colorScheme.onSurface,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Aktivt pas',
                  style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(28)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.timer_outlined, color: colorScheme.onSurface),
                      const SizedBox(width: 10),
                      Text(elapsed, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricTile(
                        label: 'Sæt',
                        value: '$completedSets',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Resterer',
                        value: '$remainingSets',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _MetricTile(
                        label: 'Mål tid',
                        value: '60m',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!_isMinimized) ...<Widget>[
        const SizedBox(height: 18),
        SizedBox(
          width: 68,
          height: 68,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              side: BorderSide(color: colorScheme.outlineVariant),
              padding: EdgeInsets.zero,
            ),
            child: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant, size: 34),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.secondaryContainer.withValues(alpha: 0.38),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.psychology_alt_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Deload aktiv',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vi har reduceret lokal belastning og prioriteret sikre alternativer pga. smerte/restriktioner.',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Næste: Start kort version af dagens pas',
                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(exercises.length, (int index) {
              final Exercise exercise = exercises[index];
              final isSelected = index == currentExerciseIndex;
              final int sets = controller.setsForExercise(exercise.id);
              return Padding(
                padding: EdgeInsets.only(right: index == exercises.length - 1 ? 0 : 8),
                child: ChoiceChip(
                  label: Text('${exercise.name} ($sets/3)'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedExerciseIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Træningslog', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    _PillLabel(
                      text: '$progressPercent%',
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      textColor: colorScheme.onSurface,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Nu: ${currentExercise?.name ?? 'Ingen øvelse'}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (currentExercise != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '${currentExercise.primaryMuscle} • $currentExerciseSets/3 sæt',
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 10),
                _SetProgressDots(current: currentExerciseSets, target: 3),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (currentExerciseSets / 3).clamp(0, 1),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sidste: $previousExerciseText',
                  style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Næste: $nextExerciseText',
                  style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: currentExercise == null
                            ? null
                            : () {
                                controller.logSet(currentExercise.id);
                                _selectNextIncompleteExercise(exercises, controller);
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Log aktuelt sæt'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: currentExercise == null
                            ? null
                            : () {
                                final int? nextIndex = _nextExerciseIndex(exercises.length, currentExerciseIndex);
                                if (nextIndex == null) {
                                  controller.finishWorkout();
                                  return;
                                }
                                setState(() {
                                  _selectedExerciseIndex = nextIndex;
                                });
                              },
                        icon: const Icon(Icons.arrow_circle_right_outlined),
                        label: const Text('Gå til næste øvelse'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (currentExercise != null)
                  TextButton.icon(
                    onPressed: currentExerciseSets == 0 ? null : () => controller.removeSet(currentExercise.id),
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Fortryd sidste sæt'),
                  ),
              ],
            ),
          ),
        ),
          const SizedBox(height: 14),
          ...activeWorkout.exercises.map(
            (Exercise exercise) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                title: Text(exercise.name),
                subtitle: Text('${exercise.primaryMuscle} • ${controller.setsForExercise(exercise.id)} sæt'),
                trailing: IconButton(
                  onPressed: () => controller.logSet(exercise.id),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Log sæt',
                ),
              ),
            ),
          ),
        ],
      ],
        ),
        if (_isMinimized)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _MinimizedStickyBar(
                exerciseName: currentExercise?.name ?? 'Ingen øvelse',
                elapsed: elapsed,
                completedSets: completedSets,
                onLogSet: currentExercise == null
                    ? null
                    : () {
                        controller.logSet(currentExercise.id);
                        _selectNextIncompleteExercise(exercises, controller);
                      },
                onExpand: () {
                  setState(() {
                    _isMinimized = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  int _resolveCurrentExerciseIndex(List<Exercise> exercises, TrainingController controller) {
    if (exercises.isEmpty) {
      _selectedExerciseIndex = 0;
      return 0;
    }

    final int? selected = _selectedExerciseIndex;
    if (selected != null && selected >= 0 && selected < exercises.length) {
      return selected;
    }

    final int autoIndex = exercises.indexWhere((Exercise exercise) => controller.setsForExercise(exercise.id) < 3);
    final int resolved = autoIndex == -1 ? exercises.length - 1 : autoIndex;
    _selectedExerciseIndex = resolved;
    return resolved;
  }

  void _selectNextIncompleteExercise(List<Exercise> exercises, TrainingController controller) {
    if (exercises.isEmpty) {
      return;
    }

    final int startIndex = _selectedExerciseIndex ?? 0;
    for (var index = startIndex; index < exercises.length; index++) {
      if (controller.setsForExercise(exercises[index].id) < 3) {
        setState(() {
          _selectedExerciseIndex = index;
        });
        return;
      }
    }

    final int? nextIndex = _nextExerciseIndex(exercises.length, startIndex);
    if (nextIndex != null) {
      setState(() {
        _selectedExerciseIndex = nextIndex;
      });
    }
  }

  int? _nextExerciseIndex(int length, int current) {
    if (length == 0) {
      return null;
    }
    final int candidate = current + 1;
    return candidate < length ? candidate : null;
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    final String minuteText = minutes.toString().padLeft(2, '0');
    final String secondText = seconds.toString().padLeft(2, '0');
    return '$minuteText:$secondText';
  }
}

class _MinimizedStickyBar extends StatelessWidget {
  const _MinimizedStickyBar({
    required this.exerciseName,
    required this.elapsed,
    required this.completedSets,
    required this.onLogSet,
    required this.onExpand,
  });

  final String exerciseName;
  final String elapsed;
  final int completedSets;
  final VoidCallback? onLogSet;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Nu: $exerciseName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$elapsed • $completedSets sæt',
                    style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onExpand,
              tooltip: 'Udvid',
              icon: const Icon(Icons.unfold_more_rounded),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onLogSet,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Log sæt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({required this.onMinimize, required this.onFinish, required this.minimizeLabel});

  final VoidCallback onMinimize;
  final VoidCallback? onFinish;
  final String minimizeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _ActionPill(
          text: minimizeLabel,
          onPressed: onMinimize,
        ),
        const Spacer(),
        _ActionPill(
          text: 'Afslut',
          onPressed: onFinish,
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text, required this.backgroundColor, required this.textColor});

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SetProgressDots extends StatelessWidget {
  const _SetProgressDots({required this.current, required this.target});

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: List<Widget>.generate(target, (int index) {
        final bool done = index < current;
        return Padding(
          padding: EdgeInsets.only(right: index == target - 1 ? 0 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: done ? 24 : 16,
            height: 10,
            decoration: BoxDecoration(
              color: done ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
