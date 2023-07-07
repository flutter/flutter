library impl.entropy;

import 'dart:typed_data';

/// Defines an entropy source, this is not to be confused with a rng.
/// Entropy sources are used to supply seed material.
abstract class EntropySource {
  Uint8List getBytes(int len);
}
