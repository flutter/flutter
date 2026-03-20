import 'package:flutter/material.dart';

import '../../../../widgets/foundation/primary_pill_button.dart';

class AddExerciseButton extends StatelessWidget {
  const AddExerciseButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryPillButton(
      label: 'Tilføj øvelse',
      icon: Icons.add,
      onPressed: onPressed,
    );
  }
}
