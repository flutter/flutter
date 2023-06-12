import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../common/common.dart';
import '../widgets/widgets.dart';

class FortuneWheelPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final alignment = useState(Alignment.topCenter);
    final selected = useStreamController<int>();
    final selectedIndex = useStream(selected.stream, initialData: 0).data ?? 0;
    final isAnimating = useState(false);

    final alignmentSelector = AlignmentSelector(
      selected: alignment.value,
      onChanged: (v) => alignment.value = v!,
    );

    void handleRoll() {
      selected.add(
        roll(Constants.fortuneValues.length),
      );
    }

    return AppLayout(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            alignmentSelector,
            SizedBox(height: 8),
            RollButtonWithPreview(
              selected: selectedIndex,
              items: Constants.fortuneValues,
              onPressed: isAnimating.value ? null : handleRoll,
            ),
            SizedBox(height: 8),
            Expanded(
              child: FortuneWheel(
                alignment: alignment.value,
                selected: selected.stream,
                onAnimationStart: () => isAnimating.value = true,
                onAnimationEnd: () => isAnimating.value = false,
                onFling: handleRoll,
                indicators: [
                  FortuneIndicator(
                    alignment: alignment.value,
                    child: TriangleIndicator(),
                  ),
                ],
                items: [
                  for (var it in Constants.fortuneValues)
                    FortuneItem(child: Text(it), onTap: () => print(it))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
