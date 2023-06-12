import '../../image.dart';
import 'ico_encoder.dart';

class CurEncoder extends WinEncoder {
  /// Number of image mapped with x and y hotspot coordinates
  Map<int, Point>? hotSpots;

  CurEncoder({this.hotSpots});

  @override
  int colorPlanesOrXHotSpot(int index) {
    if (hotSpots != null) {
      if (hotSpots!.containsKey(index)) {
        return hotSpots![index]!.xi;
      }
    }
    return 0;
  }

  @override
  int bitsPerPixelOrYHotSpot(int index) {
    if (hotSpots != null) {
      if (hotSpots!.containsKey(index)) {
        return hotSpots![index]!.yi;
      }
    }
    return 0;
  }

  @override
  int get type => 2;
}
