import 'package:test/test.dart';

import '../rendering/rendering_tester.dart';
import '../../../../examples/rendering/sector_layout.dart';

void main() {
  test('Sector layout can paint', () {
    layout(buildSectorExample(), phase: EnginePhase.composite);
  });
}
