import 'package:flutter/widgets.dart';
import 'training_controller.dart';

class TrainingScope extends InheritedNotifier<TrainingController> {
  const TrainingScope({
    required TrainingController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static TrainingController of(BuildContext context) {
    final TrainingScope? scope = context.dependOnInheritedWidgetOfExactType<TrainingScope>();
    assert(scope != null, 'TrainingScope not found in widget tree');
    return scope!.notifier!;
  }
}
