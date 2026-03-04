import 'package:flutter/material.dart';

import 'data/active_workout_mock_data.dart';
import 'models/active_workout_models.dart';
import 'widgets/autopilot_toggle_row.dart';
import 'widgets/segmented_selector.dart';
import 'widgets/settings_card.dart';
import 'widgets/timer_card.dart';
import 'widgets/workout_ui_tokens.dart';

class ActiveWorkoutControlsPage extends StatefulWidget {
  const ActiveWorkoutControlsPage({super.key});

  @override
  State<ActiveWorkoutControlsPage> createState() => _ActiveWorkoutControlsPageState();
}

class _ActiveWorkoutControlsPageState extends State<ActiveWorkoutControlsPage> {
  int _durationTarget = 60;
  bool _timerPaused = false;
  bool _timeAutopilot = true;
  bool _intensityAutopilot = true;
  IntensityLevel _intensity = IntensityLevel.normal;
  CrowdLevel _crowd = CrowdLevel.normal;
  bool _volumeExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutUiTokens.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Workout kontrol'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WorkoutUiTokens.sidePadding,
          6,
          WorkoutUiTokens.sidePadding,
          28,
        ),
        children: <Widget>[
          TimerCard(
            timer: '00:54',
            pauseLabel: 'Pause 01:43',
            isPaused: _timerPaused,
            onPause: () => setState(() => _timerPaused = !_timerPaused),
            onReset: () {},
          ),
          const SizedBox(height: 14),
          SettingsCard(
            title: 'Varighed',
            trailing: Text(
              '$_durationTarget min',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Slider(
                  value: _durationTarget.toDouble(),
                  min: 30,
                  max: 90,
                  divisions: 12,
                  activeColor: WorkoutUiTokens.accentGreen,
                  onChanged: (double value) => setState(() => _durationTarget = value.round()),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _durationTarget = (_durationTarget - 5).clamp(30, 90)),
                        child: const Text('-5'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _durationTarget = (_durationTarget + 5).clamp(30, 90)),
                        child: const Text('+5'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Mål: $_durationTarget min',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: WorkoutUiTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ActiveWorkoutMockData.durationTags()
                      .map(
                        (String tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: WorkoutUiTokens.softBlue,
                            borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
                          ),
                          child: Text(tag),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.black.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                AutopilotToggleRow(
                  title: 'Time Budget Autopilot',
                  description:
                      'Pauser, sæt og øvelsesrækkefølge justeres live for at ramme din måltid.',
                  value: _timeAutopilot,
                  onChanged: (bool value) => setState(() => _timeAutopilot = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsCard(
            title: 'Intensitet',
            trailing: Text(
              _intensity.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SegmentedSelector<IntensityLevel>(
                  values: IntensityLevel.values,
                  labelBuilder: (IntensityLevel value) => value.label,
                  groupValue: _intensity,
                  onValueChanged: (IntensityLevel value) => setState(() => _intensity = value),
                ),
                const SizedBox(height: 12),
                AutopilotToggleRow(
                  title: 'Intensity Autopilot',
                  description: 'Næste sæt kan justeres live ud fra performance, træthed og valgt intensitet.',
                  value: _intensityAutopilot,
                  onChanged: (bool value) => setState(() => _intensityAutopilot = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsCard(
            title: 'Crowd',
            trailing: Text(
              _crowd.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: SegmentedSelector<CrowdLevel>(
              values: CrowdLevel.values,
              labelBuilder: (CrowdLevel value) => value.label,
              groupValue: _crowd,
              onValueChanged: (CrowdLevel value) => setState(() => _crowd = value),
            ),
          ),
          const SizedBox(height: 14),
          SettingsCard(
            title: 'Volumen',
            trailing: Text(
              '1/9 sæt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Column(
              children: <Widget>[
                InkWell(
                  onTap: () => setState(() => _volumeExpanded = !_volumeExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Vis volumenkontroller',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Icon(_volumeExpanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                if (_volumeExpanded) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WorkoutUiTokens.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('Volumen controls placeholder: sætfordeling, trim og progression.'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
