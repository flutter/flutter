import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../widgets/crowd_card.dart';
import '../widgets/duration_card.dart';
import '../widgets/intensity_card.dart';
import '../widgets/timer_card.dart';
import '../widgets/volume_card.dart';

class WorkoutControlsScreen extends StatefulWidget {
  const WorkoutControlsScreen({super.key});

  @override
  State<WorkoutControlsScreen> createState() => _WorkoutControlsScreenState();
}

class _WorkoutControlsScreenState extends State<WorkoutControlsScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _pausedSeconds = 0;

  int _durationTarget = 60;
  bool _timeAutopilot = false;

  String _intensity = 'Normal';
  bool _intensityAutopilot = false;

  String _crowd = 'Normal';

  int _completedSets = 1;
  int _totalSets = 9;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Controls'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: <Widget>[
              TimerCard(
                elapsed: _formatDuration(_elapsedSeconds),
                pausedDurationLabel: 'Paused: ${_formatDuration(_pausedSeconds)}',
                onPause: _pauseSession,
                onSecondaryAction: _skipToNext,
                secondaryActionLabel: 'Næste',
              ),
              const SizedBox(height: AppSpacing.lg),
              DurationCard(
                durationMinutes: _durationTarget,
                onDurationChanged: (double value) {
                  setState(() {
                    _durationTarget = value.round();
                  });
                },
                onDecrease: () {
                  setState(() {
                    _durationTarget = (_durationTarget - 5).clamp(15, 120);
                  });
                },
                onIncrease: () {
                  setState(() {
                    _durationTarget = (_durationTarget + 5).clamp(15, 120);
                  });
                },
                autopilotEnabled: _timeAutopilot,
                onAutopilotChanged: (bool value) {
                  setState(() {
                    _timeAutopilot = value;
                  });
                },
                tags: const <String>['Upper body', 'Push', 'Core'],
              ),
              const SizedBox(height: AppSpacing.lg),
              IntensityCard(
              const SizedBox(height: AppSpacing.lg),
                onSelectionChanged: (String value) {
                  setState(() {
                    _intensity = value;
                  });
                },
                autopilotEnabled: _intensityAutopilot,
                onAutopilotChanged: (bool value) {
                  setState(() {
                    _intensityAutopilot = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const SizedBox(height: AppSpacing.lg),
                selection: _crowd,
                onSelectionChanged: (String value) {
                  setState(() {
                    _crowd = value;
                  });
                },
                const SizedBox(height: AppSpacing.lg),
              const SizedBox(height: AppSpacing.lg),
              VolumeCard(
                completedSets: _completedSets,
                totalSets: _totalSets,
                const SizedBox(height: AppSpacing.sm),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _pauseSession() {
    setState(() {
      _pausedSeconds += 30;
    });
  }

  void _skipToNext() {
    setState(() {
      _completedSets = (_completedSets + 1).clamp(0, _totalSets);
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
