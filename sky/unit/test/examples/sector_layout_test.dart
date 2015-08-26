import 'package:test/test.dart';
import '../rendering/layout_utils.dart';
import '../../../../examples/rendering/sector_layout.dart';

void main() {
  test('Sector layout can paint', () {
    RenderingTester tester = new RenderingTester(root: buildSectorExample());
    tester.pumpFrame();
  });
}
