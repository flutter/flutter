/// Wrapper for needed NodeJS Crypto library function and require.
@JS()
library nodecryto;

import 'package:js/js.dart';

external dynamic require(String id);

@JS()
class NodeCrypto {
  external randomFillSync(buf);
}
