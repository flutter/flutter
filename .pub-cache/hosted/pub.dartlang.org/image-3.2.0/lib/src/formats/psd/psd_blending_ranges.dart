import 'dart:typed_data';

import '../../util/input_buffer.dart';

class PsdBlendingRanges {
  int? grayBlackSrc;
  int? grayWhiteSrc;
  int? grayBlackDst;
  int? grayWhiteDst;
  late Uint16List blackSrc;
  late Uint16List whiteSrc;
  late Uint16List blackDst;
  late Uint16List whiteDst;

  PsdBlendingRanges(InputBuffer input) {
    grayBlackSrc = input.readUint16();
    grayWhiteSrc = input.readUint16();

    grayBlackDst = input.readUint16();
    grayWhiteDst = input.readUint16();

    final len = input.length;
    final numChannels = len ~/ 8;

    if (numChannels > 0) {
      blackSrc = Uint16List(numChannels);
      whiteSrc = Uint16List(numChannels);
      blackDst = Uint16List(numChannels);
      whiteDst = Uint16List(numChannels);

      for (var i = 0; i < numChannels; ++i) {
        blackSrc[i] = input.readUint16();
        whiteSrc[i] = input.readUint16();
        blackDst[i] = input.readUint16();
        whiteDst[i] = input.readUint16();
      }
    }
  }
}
