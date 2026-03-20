import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../widgets/active_workout_empty_state.dart';
import '../widgets/add_exercise_button.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_header_row.dart';
import '../widgets/set_row.dart';
import '../widgets/workout_header.dart';

class ActiveWorkoutScreen extends StatefulWidget {
	const ActiveWorkoutScreen({
		required this.onMinimize,
		required this.onFinish,
		required this.onAddExercise,
		this.previewExercises,
		this.startedAt,
		super.key,
	});

	final VoidCallback onMinimize;
	final VoidCallback onFinish;
	final VoidCallback onAddExercise;
	final List<ExerciseCardData>? previewExercises;
	final DateTime? startedAt;

	@override
	State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
	Timer? _ticker;
	int _elapsedSeconds = 0;

	@override
	void initState() {
		super.initState();
		_startTicker();
	}

	@override
	void didUpdateWidget(covariant ActiveWorkoutScreen oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (oldWidget.startedAt != widget.startedAt) {
			_startTicker();
		}
	}

	@override
	void dispose() {
		_ticker?.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final List<ExerciseCardData> exercises = widget.previewExercises ?? _defaultPreviewExercises;
		final bool isEmpty = exercises.isEmpty;

		return Scaffold(
			backgroundColor: AppColors.background,
			body: SafeArea(
				child: SingleChildScrollView(
					padding: AppSpacing.screenPadding,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							WorkoutHeader(
								elapsed: _formatDuration(_elapsedSeconds),
								onMinimize: widget.onMinimize,
								onFinish: widget.onFinish,
							),
							const SizedBox(height: AppSpacing.xl),
							Text(
								'Øvelser i træning',
								style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
							),
							const SizedBox(height: AppSpacing.xs),
							Text(
								'Log dine sæt med fokus og tempo',
								style: Theme.of(context).textTheme.bodySmall,
							),
							const SizedBox(height: AppSpacing.md),
							if (isEmpty)
								ActiveWorkoutEmptyState(onAddExercise: widget.onAddExercise)
							else
								Column(
									children: <Widget>[
										for (final ExerciseCardData exercise in exercises) ...<Widget>[
											ExerciseCard(
												data: exercise,
												onAddSet: () {},
												onKgChanged: (_, __) {},
												onRepsChanged: (_, __) {},
												onSetCompletedChanged: (_, __) {},
											),
											const SizedBox(height: AppSpacing.md),
										],
										AddExerciseButton(onPressed: widget.onAddExercise),
									],
								),
							if (isEmpty) ...<Widget>[
								const SizedBox(height: AppSpacing.lg),
								AddExerciseButton(onPressed: widget.onAddExercise),
							],
						],
					),
				),
			),
		);
	}

	void _startTicker() {
		_ticker?.cancel();

		final DateTime startedAt = widget.startedAt ?? DateTime.now();
		_elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;

		_ticker = Timer.periodic(const Duration(seconds: 1), (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
			});
		});
	}

	String _formatDuration(int seconds) {
		final int hours = seconds ~/ 3600;
		final int minutes = (seconds % 3600) ~/ 60;
		final int remainingSeconds = seconds % 60;
		if (hours > 0) {
			return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
		}
		return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
	}
}

const List<ExerciseCardData> _defaultPreviewExercises = <ExerciseCardData>[
	ExerciseCardData(
		id: 'ex-ab-wheel',
		name: 'Ab Wheel',
		leadingIcon: Icons.accessibility_new,
		actions: <ExerciseHeaderAction>[
			ExerciseHeaderAction(icon: Icons.more_horiz),
			ExerciseHeaderAction(icon: Icons.upload_outlined),
		],
		tags: <String>['Note', 'Ubehag'],
		notes: 'Add notes here...',
		restLabel: 'Pause mellem sæt: 2m',
		sets: <SetRowData>[
			SetRowData(id: 's1', setNumber: 1, previousLabel: '97.5kg x 8', kg: '97.5', reps: '8'),
			SetRowData(id: 's2', setNumber: 2, previousLabel: '97.5kg x 8', kg: '97.5', reps: '8'),
			SetRowData(id: 's3', setNumber: 3, previousLabel: '97.5kg x 8', kg: '97.5', reps: '8'),
		],
	),
	ExerciseCardData(
		id: 'ex-back',
		name: 'Back',
		leadingIcon: Icons.fitness_center,
		actions: <ExerciseHeaderAction>[
			ExerciseHeaderAction(icon: Icons.more_horiz),
		],
		tags: <String>['Note'],
		restLabel: 'Pause mellem sæt: 2m',
		sets: <SetRowData>[
			SetRowData(id: 's1', setNumber: 1, previousLabel: '70kg x 10', kg: '70', reps: '10', completed: true),
			SetRowData(id: 's2', setNumber: 2, previousLabel: '70kg x 9', kg: '70', reps: '10'),
		],
	),
];
