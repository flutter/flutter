import 'package:flutter/material.dart';

import '../../../app/state/training_controller.dart';
import '../../../app/state/training_scope.dart';
import '../domain/program.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrainingController controller = TrainingScope.of(context);
    final Program activeProgram = controller.activeProgram;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: ListTile(
            title: const Text('Current program'),
            subtitle: Text('${activeProgram.name} • Week ${activeProgram.currentWeek} of ${activeProgram.totalWeeks}'),
          ),
        ),
        const SizedBox(height: 12),
        ...controller.programs.map(
          (program) => Card(
            child: ListTile(
              title: Text(program.name),
              subtitle: Text('${program.workouts.length} workouts per cycle'),
              trailing: program.id == activeProgram.id
                  ? const Icon(Icons.check_circle)
                  : OutlinedButton(
                      onPressed: () => controller.selectProgram(program.id),
                      child: const Text('Use'),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
