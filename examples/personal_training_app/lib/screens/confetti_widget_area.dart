import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiWidgetArea extends StatefulWidget {
  final TextEditingController feedbackController;
  final dynamic workout;
  final Function(dynamic) onWorkoutReviewed;

  const ConfettiWidgetArea({
    super.key,
    required this.feedbackController,
    required this.workout,
    required this.onWorkoutReviewed,
  });

  @override
  State<ConfettiWidgetArea> createState() => _ConfettiWidgetAreaState();
}

class _ConfettiWidgetAreaState extends State<ConfettiWidgetArea> {
  late ConfettiController _controller;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitReview(BuildContext context) {
    final reviewedWorkout = widget.workout.copyWith(
      isReviewedByInstructor: true,
      instructorReview: widget.feedbackController.text,
    );
    widget.onWorkoutReviewed(reviewedWorkout);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Congratulations! Review submitted.'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _showConfetti,
              onChanged: (val) {
                setState(() {
                  _showConfetti = val ?? false;
                });
              },
            ),
            const Text('Show confetti for congratulations'),
          ],
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    if (_showConfetti) _controller.play();
                    _submitReview(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Submit Review'),
                ),
              ],
            ),
            ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              emissionFrequency: 0.6,
              maxBlastForce: 45,
              minBlastForce: 20,
              gravity: 0.08,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFFFFD700),
                Color(0xFF00D4FF),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
