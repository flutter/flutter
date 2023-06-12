// Digest example 1

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

//================================================================
// Demonstrations

//----------------------------------------------------------------
/// Demonstrate the use of `process` to provide the data completely.

Uint8List completeExample(Uint8List dataToDigest) {
  var d = Digest('SHA-256');

  final hash = d.process(dataToDigest);

  return hash;
}

//----------------------------------------------------------------
/// Demonstrates the use of `updateByte`, `update` and `doFinal`
/// to provide the data progressively.

Uint8List progressiveExample() {
  var d = Digest('SHA-256');

  final chunk1 = utf8.encode('cellophane');
  final chunk2 = utf8.encode('world');

  d.updateByte(0x48); // 'H'
  d.update(Uint8List.fromList(chunk1), 1, 4);
  d.updateByte(0x20); // ' '
  d.update(Uint8List.fromList(chunk2), 0, chunk2.length);
  d.updateByte(0x21); // '!'

  final hash = Uint8List(d.digestSize);

  d.doFinal(hash, 0); // hash of 'Hello world!'

  return hash;
}

//----------------------------------------------------------------
/// Demonstrate the effect of `reset`.

void resetExample() {
  final data1 = utf8.encode('Hello ');
  final data2 = utf8.encode('world!');

  print('\nEffect of `reset`:');

  {
    print('  Using `process` automatically resets:');

    var d = Digest('SHA-256');

    final h1 = d.process(Uint8List.fromList(data1));
    print('    ${bin2hex(h1)}');

    final h2 = d.process(Uint8List.fromList(data2));
    print('    ${bin2hex(h2)}');
  }

  {
    print('  Using `doFinal` automatically resets:');

    var d = Digest('SHA-256');

    final h1 = Uint8List(d.digestSize);
    d.update(Uint8List.fromList(data1), 0, data1.length);
    d.doFinal(h1, 0);
    print('    ${bin2hex(h1)}');

    d.reset();

    final h2 = Uint8List(d.digestSize);
    d.update(Uint8List.fromList(data2), 0, data2.length);
    d.doFinal(h2, 0);
    print('    ${bin2hex(h2)}');
  }

  {
    final part1 = utf8.encode('Hello ');
    final part2 = utf8.encode('world!');

    var d = Digest('SHA-256');
    final hash = Uint8List(d.digestSize);

    // With reset

    d.update(Uint8List.fromList(part1), 0, part1.length);
    d.reset();
    d.update(Uint8List.fromList(part2), 0, part2.length);
    d.doFinal(hash, 0); // hash of 'world!'
    print('  Using `update` with reset:\n    ${bin2hex(hash)}');

    // Without rest

    d.update(Uint8List.fromList(part1), 0, part1.length);
    d.update(Uint8List.fromList(part2), 0, part2.length);
    d.doFinal(hash, 0); // hash of 'Hello world!'
    print('  Using `update` without reset:\n    ${bin2hex(hash)}');
  }
}

//----------------------------------------------------------------
/// Shows digest works on arbitrary binary data and not just
/// text converted into bytes as utf8.
///
/// These examples are taken from the text examples from section 8.5 of RFC 6234
/// <https://tools.ietf.org/html/rfc6234#section-8.5>
/// Test inputs are from page 92 and 93 of RFC 6234.
/// Test vectors and results from page 97 and 98 of RFC 6234.

void binaryExample() {
  print('\nExamples from RFC 2634:');

  var d = Digest('SHA-256');

  // TEST1

  final test1 = ascii.encode('abc');
  assert(test1[0] == 0x61);
  assert(test1[1] == 0x62);
  assert(test1[2] == 0x63);
  assert(test1.length == 3);

  final expected1 = 'BA7816BF8F01CFEA4141'
      '40DE5DAE2223B00361A396177A9CB410FF61F20015AD';

  final hash1 = bin2hex(d.process(test1));

  print('  TEST1:     $hash1');
  if (hash1 != expected1.toLowerCase()) {
    print('Error: SHA-256 of TEST1 did not produce the correct hash\n');
  }

  /* This doesn't work yet. Need to investigate why.
  // TEST7_256

  final test7_256 = Uint8List.fromList(
      '\xbe\x27\x46\xc6\xdb\x52\x76\x5f\xdb\x2f\x88\x70\x0f\x9a\x73'.codeUnits);
  assert(test7_256[0] == 0xbe);
  assert(test7_256[1] == 0x27);
  assert(test7_256[2] == 0x46);
  assert(test7_256[3] == 0xc6);
  assert(test7_256.last == 0x73);
  final repeatCount7 = 1;
  final extraBits7 = 0x60;
  final numberExtraBits7 = 3;

  final expected7 = '77EC1DC8'
      '9C821FF2A1279089FA091B35B8CD960BCAF7DE01C6A7680756BEB972';

  for (var repeat = 0; repeat < repeatCount7; repeat++) {
    d.update(test7_256, 0, test7_256.length);
  }
  for (var extra = 0; extra < numberExtraBits7; extra++) {
    d.updateByte(extraBits7);
  }

  final hash7bytes = Uint8List(d.digestSize);
  d.doFinal(hash7bytes, 0);
  final hash7 = bin2hex(hash7bytes);

  print('  TEST7_256: $hash7');
  if (hash7 != expected7.toLowerCase()) {
    print('Error: SHA-256 of TEST7_256 did not produce the correct hash\n');
  }
   */
}

//================================================================
// Utility functions

//----------------------------------------------------------------
/// Represent bytes in hexadecimal
///
/// If a [separator] is provided, it is placed the hexadecimal characters
/// representing each byte. Otherwise, all the hexadecimal characters are
/// simply concatenated together.

String bin2hex(Uint8List bytes, {String? separator, int? wrap}) {
  var len = 0;
  final buf = StringBuffer();
  for (final b in bytes) {
    final s = b.toRadixString(16);
    if (buf.isNotEmpty && separator != null) {
      buf.write(separator);
      len += separator.length;
    }

    if (wrap != null && wrap < len + 2) {
      buf.write('\n');
      len = 0;
    }

    buf.write('${(s.length == 1) ? '0' : ''}$s');
    len += 2;
  }
  return buf.toString();
}
//----------------------------------------------------------------

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print('Usage: digest-demo');
    return;
  }

  // Calculate digest with complete data
  //
  // Note: the progressive example is hardcoded to produce the digest of
  // 'Hello world!', so there is no point in changing the 'data' if you want
  // to see they both produce the same result.

  const dataForComplete = 'Hello world!';

  print('SHA-256 digest of "$dataForComplete":');
  final hash1 =
      completeExample(Uint8List.fromList(utf8.encode(dataForComplete)));
  print('   with complete data: ${bin2hex(hash1)}');

  // Calculate digest by providing the data progressively

  final hash2 = progressiveExample();
  print('with progressive data: ${bin2hex(hash1)}');

  // Prove they both produce the same digest value

  for (var x = 0; x < hash1.length; x++) {
    if (hash1[x] != hash2[x]) {
      print('Error: hashes are different');
    }
  }

  // Other examples

  resetExample();

  binaryExample();
}
