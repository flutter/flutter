import 'package:flutter/material.dart';

import '../../../app/state/training_controller.dart';
import '../../../app/state/training_scope.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrainingController controller = TrainingScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: ListTile(
            title: const Text('Athlete profile'),
            subtitle: Text(
              '${controller.sessionHistory.length} sessions logged • ${controller.completedSessionsThisWeek} this week',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Coach proposal', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(controller.coachProposalPreview),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.applyCoachProposal,
                  child: const Text('Apply suggestion'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
