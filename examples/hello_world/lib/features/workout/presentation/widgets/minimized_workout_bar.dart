import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radii.dart';
import '../../../../theme/app_spacing.dart';

class MinimizedWorkoutBar extends StatefulWidget {
  const MinimizedWorkoutBar({
    required this.startedAt,
    required this.summary,
    required this.onRestore,
    this.label = 'Workout i gang',
    super.key,
  });

  final DateTime startedAt;
  final String summary;
  final String label;
  final VoidCallback onRestore;

  @override
  State<MinimizedWorkoutBar> createState() => _MinimizedWorkoutBarState();
}

class _MinimizedWorkoutBarState extends State<MinimizedWorkoutBar> {
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant MinimizedWorkoutBar oldWidget) {
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.card,
            onTap: widget.onRestore,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDuration(_elapsedSeconds)} • ${widget.summary}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _elapsedSeconds = DateTime.now().difference(widget.startedAt).inSeconds;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _elapsedSeconds = DateTime.now().difference(widget.startedAt).inSeconds;
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
