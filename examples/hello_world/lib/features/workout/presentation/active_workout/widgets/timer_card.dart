import 'package:flutter/material.dart';

import 'settings_card.dart';
import 'workout_ui_tokens.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({
    required this.timer,
    required this.pauseLabel,
    required this.isPaused,
    required this.onPause,
    required this.onReset,
    super.key,
  });

  final String timer;
  final String pauseLabel;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: 'Tidsmåler',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                timer,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: WorkoutUiTokens.textPrimary,
                    ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: WorkoutUiTokens.softBlue,
                  borderRadius: BorderRadius.circular(WorkoutUiTokens.radiusPill),
                ),
                child: Text(
                  pauseLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: WorkoutUiTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onPause,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: WorkoutUiTokens.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isPaused ? 'Fortsæt' : 'Pause'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.refresh_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
