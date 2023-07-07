#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import 'test_util.dart';

typedef RoundtripTester<T> = void Function(T value, List<int> bytes);

void main() {
  ByteData makeData(Uint8List bytes) => ByteData.view(bytes.buffer);

  Uint8List Function(dynamic) convertToBytes(fieldType) => (value) {
        var writer = CodedBufferWriter()..writeField(0, fieldType, value);
        return writer.toBuffer().sublist(1);
      };

  RoundtripTester<T> roundtripTester<T>(
      {T Function(CodedBufferReader bytes)? fromBytes,
      List<int> Function(T value)? toBytes}) {
    return (T value, List<int> bytes) {
      expect(fromBytes!(CodedBufferReader(bytes)), equals(value));
      expect(toBytes!(value), bytes);
    };
  }

  final int32ToBytes = convertToBytes(PbFieldType.O3);

  test('testInt32RoundTrips', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readInt32(),
        toBytes: int32ToBytes);
    roundtrip(0, [0x00]);
    roundtrip(1, [0x01]);
    roundtrip(206, [0xce, 0x01]);
    roundtrip(300, [0xac, 0x02]);
    roundtrip(2147483647, [0xff, 0xff, 0xff, 0xff, 0x07]);
    roundtrip(-2147483648,
        [0x80, 0x80, 0x80, 0x80, 0xf8, 0xff, 0xff, 0xff, 0xff, 0x01]);
    roundtrip(-1, [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01]);
    roundtrip(-2, [0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01]);
  });

  test('testSint32', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readSint32(),
        toBytes: convertToBytes(PbFieldType.OS3));

    roundtrip(0, [0x00]);
    roundtrip(-1, [0x01]);
    roundtrip(1, [0x02]);
    roundtrip(-2, [0x03]);
  });

  test('testSint64', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readSint64(),
        toBytes: convertToBytes(PbFieldType.OS6));

    roundtrip(make64(0), [0x00]);
    roundtrip(make64(-1), [0x01]);
    roundtrip(make64(1), [0x02]);
    roundtrip(make64(-2), [0x03]);
  });

  test('testFixed32', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readFixed32(),
        toBytes: convertToBytes(PbFieldType.OF3));

    roundtrip(0, [0x00, 0x00, 0x00, 0x00]);
    roundtrip(1, [0x01, 0x00, 0x00, 0x00]);
    roundtrip(4294967295, [0xff, 0xff, 0xff, 0xff]);
    roundtrip(2427130573, [0xcd, 0x12, 0xab, 0x90]);
  });

  test('testFixed64', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readFixed64(),
        toBytes: convertToBytes(PbFieldType.OF6));

    roundtrip(make64(0, 0), [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    roundtrip(make64(1, 0), [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    roundtrip(make64(0xffffffff, 0xffffffff),
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    roundtrip(make64(0x00000001, 0x40000000),
        [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40]);
  });

  test('testSfixed32', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readSfixed32(),
        toBytes: convertToBytes(PbFieldType.OSF3));

    roundtrip(0, [0x00, 0x00, 0x00, 0x00]);
    roundtrip(1, [0x01, 0x00, 0x00, 0x00]);
    roundtrip(-2147483648, [0x00, 0x00, 0x00, 0x80]);
    roundtrip(-1, [0xff, 0xff, 0xff, 0xff]);
  });

  test('testSfixed64', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readSfixed64(),
        toBytes: convertToBytes(PbFieldType.OSF6));

    roundtrip(make64(0), [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    roundtrip(make64(-1), [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    roundtrip(make64(1), [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    roundtrip(make64(-2), [0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    roundtrip(make64(0xffffffff, 0x7fffffff),
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]);
    roundtrip(make64(0x00000000, 0x80000000),
        [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80]);
  });

  test('testBool', () {
    bool readBool(List<int> bytes) => CodedBufferReader(bytes).readBool();

    expect(readBool([0x00]), isFalse);
    expect(readBool([0x01]), isTrue);
    expect(readBool([0xff, 0x01]), isTrue);
  });

  // Compare two doubles, where NaNs and same-sign inifinities compare equal.
  // For normal values, use equals.
  Matcher doubleEquals(double expected) => expected.isNaN
      ? predicate<double>((x) => x.isNaN, 'NaN expected')
      : equals(expected);

  List<int> dataToBytes(ByteData byteData) => Uint8List.view(byteData.buffer);
  final floatToBytes = convertToBytes(PbFieldType.OF);
  int floatToBits(double value) =>
      makeData(floatToBytes(value)).getUint32(0, Endian.little);

  void _test32(int bits, double value) {
    double readFloat(int bits) {
      var bytes = dataToBytes(ByteData(4)..setUint32(0, bits, Endian.little));
      return CodedBufferReader(bytes).readFloat();
    }

    expect(floatToBits(value), bits);
    expect(readFloat(bits), doubleEquals(value));
  }

  final doubleToBytes = convertToBytes(PbFieldType.OD);

  void _test64(List<int> hilo, double value) {
    // Encode a double to its wire format.
    var data = makeData(doubleToBytes(value));
    var actualHilo = [
      data.getUint32(4, Endian.little),
      data.getUint32(0, Endian.little)
    ];
    //int encoded = data.getUint64(0, Endian.little);
    expect(actualHilo, hilo);

    // Decode it again (round trip).
    var bytes = dataToBytes(data);
    var reencoded = CodedBufferReader(bytes).readDouble();
    expect(reencoded, doubleEquals(value));
  }

  test('testFloat', () {
    // Denorms.
    _test32(0x1, 1.401298464324817E-45);
    _test32(0x2, 1.401298464324817E-45 * 2.0);
    _test32(0x3, 1.401298464324817E-45 * 3.0);
    _test32(0x00ba98, 1.401298464324817E-45 * 0x00ba98);
    _test32(8034422, 1.401298464324817E-45 * 8034422);
    _test32(0x7fffff, 1.401298464324817E-45 * 0x7fffff);
    _test32(0x80000001, -1.401298464324817E-45);
    _test32(0x80000002, -1.401298464324817E-45 * 2.0);
    _test32(0x80000003, -1.401298464324817E-45 * 3.0);
    _test32(0x8000ba98, -1.401298464324817E-45 * 0x00ba98);
    _test32(0x807a9876, -1.401298464324817E-45 * 0x7a9876);
    _test32(0x807fffff, -1.401298464324817E-45 * 0x7fffff);
    // Very small non-denorms.
    _test32(0x00800000, 1.1754943508222875E-38);
    _test32(0x00800001, 1.175494490952134E-38);
    _test32(0x00801234, 1.176147355906663E-38);
    _test32(0x80800000, -1.1754943508222875E-38);
    _test32(0x80800001, -1.175494490952134E-38);
    _test32(0x80801234, -1.176147355906663E-38);
    // Out of range.
    expect(floatToBits(1.401298464324816E-45), 0x00000000);
    expect(floatToBits(-1.401298464324816E-45), 0x80000000);
    expect(floatToBits(3.4028234663852888E38), 0x7f800000);
    expect(floatToBits(-3.4028234663852888E38), 0xff800000);

    // Numbers smaller than the smallest representable float round to +/- 0.
    expect(floatToBits(1.0E-50), 0x0);
    expect(floatToBits(-1.0E-50), 0x80000000);

    _test32(0x0, 0.0);
    _test32(0x80000000, -0.0);
    _test32(0x7fc00000, double.nan);
    _test32(0x7f800000, double.infinity);
    _test32(0xff800000, double.negativeInfinity);
    _test32(0x3f800000, 1.0);
    _test32(0x40000000, 2.0);
    _test32(0x3f7ffffe, 0.9999998807907104);
    _test32(0x3f800001, 1.0000001192092896);
    _test32(0x3fffffff, 1.9999998807907104);
    _test32(0x40000000, 2.0);
    _test32(0x3dcccccd, 0.10000000149011612);
    _test32(0xbdcccccd, -0.10000000149011612);
    _test32(0x3e4ccccd, 0.20000000298023224);
    _test32(0xbe4ccccd, -0.20000000298023224);
    _test32(0x42f6e9e0, 123.456787109375);
    _test32(0xc2f6e9e0, -123.456787109375);
    // Max float.
    _test32(0x7f7fffff, 3.4028234663852886E38);
    _test32(0xff7fffff, -3.4028234663852886E38);
    _test32(0x80000001, -1.401298464324817E-45);
    _test32(0x3e4cdcd4, 0.2000611424446106);
    _test32(0x3f4ef68e, 0.8084496259689331);
    _test32(0x3dd77088, 0.10519510507583618);
    _test32(0x3e16156c, 0.14656609296798706);
    _test32(0x3ea3776c, 0.3192704916000366);
    _test32(0x3f510cbb, 0.816600501537323);
    _test32(0x3ed6e3d6, 0.4197070002555847);
    _test32(0x3f2209e6, 0.6329635381698608);
    _test32(0x3f20fdd3, 0.6288730502128601);
    _test32(0x3ecd6df2, 0.4012294411659241);
    _test32(0x3f1a107a, 0.6018139123916626);
    _test32(0x3f47e6d3, 0.7808658480644226);
    _test32(0x3da82010, 0.08209240436553955);
    _test32(0x3d1c0c20, 0.038097500801086426);
    _test32(0x3f0adc42, 0.5424233675003052);
    _test32(0x3f5fae9f, 0.8737582564353943);
    _test32(0x3f4eba38, 0.8075289726257324);
    _test32(0x3f23d86a, 0.6400209665298462);
    _test32(0x3ea11a1a, 0.3146522641181946);
    _test32(0x3e7a8824, 0.24465996026992798);
    _test32(0x3ef758b2, 0.483098566532135);
    _test32(0x3e8d1874, 0.275577187538147);
    _test32(0x3dbc6968, 0.09199792146682739);
    _test32(0x3e940d00, 0.28916168212890625);
    _test32(0x3edd7ba2, 0.43258386850357056);
    _test32(0x3edf10da, 0.4356754422187805);
    _test32(0x3e9a3f84, 0.3012658357620239);
    _test32(0x3f21db08, 0.6322484016418457);
    _test32(0x3f10f0c8, 0.5661740303039551);
    _test32(0x3f7b5bc9, 0.9818692803382874);
    _test32(0x3f786c68, 0.9704041481018066);
    _test32(0x3f3b3106, 0.7312167882919312);
    _test32(0x3eef40e6, 0.46729201078414917);
    _test32(0x3f2120ea, 0.6294084787368774);
    _test32(0x3ece201c, 0.40258872509002686);
    _test32(0x3f26e082, 0.6518632173538208);
    _test32(0x3e1edd60, 0.15514135360717773);
    _test32(0x3d2c6760, 0.042090773582458496);
    _test32(0x3f1c99e3, 0.6117231249809265);
    _test32(0x3f62a5de, 0.8853434324264526);
    _test32(0x3f3ca39f, 0.7368716597557068);
    _test32(0x3f2890bd, 0.6584585309028625);
    _test32(0x3d7568a0, 0.059914231300354004);
    _test32(0x3e96620e, 0.2937168478965759);
    _test32(0x3d358bb0, 0.044322669506073);
    _test32(0x3e9e2728, 0.30889248847961426);
    _test32(0x3e887622, 0.2665262818336487);
    _test32(0x3ec71942, 0.38886457681655884);
    _test32(0x3f3ecf0c, 0.7453467845916748);
    _test32(0x3f1d8b64, 0.615408182144165);
    _test32(0x3f22e45e, 0.6362971067428589);
    _test32(0x3f1bc5c0, 0.6084861755371094);
    _test32(0x3ef2ce7c, 0.4742316007614136);
    _test32(0x3ee6d16a, 0.45081645250320435);
    _test32(0x3e22dbf4, 0.15904217958450317);
    _test32(0x3ec8462e, 0.39116042852401733);
    _test32(0x3eed4110, 0.46338701248168945);
    _test32(0x3e7d46f0, 0.24734091758728027);
    _test32(0x3ee4ed1a, 0.44712144136428833);
    _test32(0x3e171310, 0.14753365516662598);
    _test32(0x3f07ee13, 0.5309764742851257);
    _test32(0x3ea82356, 0.3283945918083191);
    _test32(0x3eaad676, 0.33366745710372925);
    _test32(0x3f0b7415, 0.5447400212287903);
    _test32(0x3e5da494, 0.2164481282234192);
    _test32(0x3eb24b98, 0.3482329845428467);
    _test32(0x3dbcf808, 0.09226995706558228);
    _test32(0x3ebff9ec, 0.37495362758636475);
    _test32(0x3ea1c5c6, 0.315962016582489);
    _test32(0x3e922946, 0.2854711413383484);
    _test32(0x3eb24736, 0.3481995463371277);
    _test32(0x3d870700, 0.06593132019042969);
    _test32(0x3db58dc0, 0.08864927291870117);
    _test32(0x3f2fbba4, 0.6864569187164307);
    _test32(0x3e67b5b4, 0.22627907991409302);
    _test32(0x3e1b35d8, 0.151572585105896);
    _test32(0x3eb18776, 0.3467366099357605);
    _test32(0x3e4a1108, 0.19733059406280518);
    _test32(0x3f77debb, 0.968242347240448);
    _test32(0x3f2f3f2c, 0.6845576763153076);
    _test32(0x3ee68150, 0.45020532608032227);
    _test32(0x3da1ca40, 0.07899904251098633);
    _test32(0x3f1a6205, 0.6030581593513489);
    _test32(0x3e596a8c, 0.2123205065727234);
    _test32(0x3f2b9b3d, 0.6703374981880188);
    _test32(0x3f5a41df, 0.8525676131248474);
    _test32(0x3f2ba95b, 0.6705529093742371);
    _test32(0x3c636740, 0.013879597187042236);
    _test32(0x3ea13618, 0.3148658275604248);
    _test32(0x3ef32f54, 0.4749704599380493);
    _test32(0x3db49fd8, 0.08819550275802612);
    _test32(0x3ed2654e, 0.4109291434288025);
    _test32(0x3f18e527, 0.5972465872764587);
    _test32(0x3e86438e, 0.2622341513633728);
    _test32(0x3d94d468, 0.07267075777053833);
    _test32(0x3dec0730, 0.11524808406829834);
    _test32(0x3e746c68, 0.23869478702545166);
    _test32(0x3f7176bc, 0.9432179927825928);
    _test32(0x3eb06baa, 0.34457141160964966);
    _test32(0x3ec7873e, 0.3897036910057068);

    _test32(0x3337354c, 4.2656481014091696E-8);
    _test32(0xcef68e86, -2.068267776E9);
    _test32(0x1aee11a3, 9.846298654970688E-23);
    _test32(0x25855b49, 2.313367945844274E-16);
    _test32(0x51bbb6d8, 1.0077831168E11);
    _test32(0xd10cbbd1, -3.7777903616E10);
    _test32(0x6b71ebcc, 2.9246464178639103E26);
    _test32(0xa209e607, -1.868873766564279E-18);
    _test32(0xa0fdd3be, -4.299998635695525E-19);
    _test32(0x66b6f9c2, 4.320389591649362E23);
    _test32(0x9a107a3f, -2.987725166002456E-23);
    _test32(0xc7e6d303, -118182.0234375);
    _test32(0x1504020d, 2.6658805490381716E-26);
    _test32(0x9c0c256, 4.640507130264806E-33);
    _test32(0x8adc428e, -2.1210264479196232E-32);
    _test32(0xdfae9f63, -2.516576947109521E19);
    _test32(0xceba38f7, -1.562147712E9);
    _test32(0xa3d86a36, -2.346374900739753E-17);
    _test32(0x508d0d6d, 1.8931738624E10);
    _test32(0x3ea209d0, 0.3164811134338379);
    _test32(0x7bac59a0, 1.7897857412574353E36);
    _test32(0x468c3af4, 17949.4765625);
    _test32(0x178d2da8, 9.123436692979724E-25);
    _test32(0x4a068058, 2203670.0);
    _test32(0x6ebdd138, 2.937279840252836E28);
    _test32(0x6f886d95, 8.444487576529374E28);
    _test32(0x4d1fc258, 1.67519616E8);
    _test32(0xa1db0894, -1.48422878466768E-18);
    _test32(0x90f0c84b, -9.497190880745409E-29);
    _test32(0xfb5bc94f, -1.1411960353742999E36);
    _test32(0xf86c6851, -1.9179653854596293E34);
    _test32(0xbb31060d, -0.00270116631872952);
    _test32(0x77a07357, 6.508647400938524E33);
    _test32(0xa120ea93, -5.452056501780286E-19);
    _test32(0x67100ede, 6.802950247361373E23);
    _test32(0xa6e082db, -1.5578590790627281E-15);
    _test32(0x27b7589e, 5.088878232380797E-15);
    _test32(0xac6764c, 1.9111204788084013E-32);
    _test32(0x9c99e3b0, -1.0183546536936767E-21);
    _test32(0xe2a5de8f, -1.5298749044800828E21);
    _test32(0xbca39f3d, -0.0199733916670084);
    _test32(0xa890bd69, -1.6069355115761082E-14);
    _test32(0xf568a12, 1.0577605982258498E-29);
    _test32(0x4b310752, 1.1601746E7);
    _test32(0xb58bb7e, 4.1741140243391215E-32);
    _test32(0x4f139499, 2.475989248E9);
    _test32(0x443b1161, 748.2715454101562);
    _test32(0x638ca14d, 5.188334233065301E21);
    _test32(0xbecf0c69, -0.4043915569782257);
    _test32(0x9d8b6455, -3.689673453519375E-21);
    _test32(0xa2e45ebb, -6.189982361684887E-18);
    _test32(0x9bc5c04c, -3.2715185077444394E-22);
    _test32(0x79673ea0, 7.504317251393587E34);
    _test32(0x7368b523, 1.8436992802490676E31);
    _test32(0x28b6fdf6, 2.031619704824343E-14);
    _test32(0x6423179d, 1.2034083200995491E22);
    _test32(0x76a0886c, 1.627996995533634E33);
    _test32(0x3f51bc17, 0.8192762732505798);
    _test32(0x72768dd4, 4.883505414291899E30);
    _test32(0x25c4c43e, 3.4133559007908424E-16);
    _test32(0x87ee1312, -3.582146842575625E-34);
    _test32(0x5411ab9d, 2.502597804032E12);
    _test32(0x556b3b74, 1.616503635968E13);
    _test32(0x8b741536, -4.700864797886097E-32);
    _test32(0x3769256b, 1.3896594282414299E-5);
    _test32(0x5925cc76, 2.916761145966592E15);
    _test32(0x179f010a, 1.0275396467808127E-24);
    _test32(0x5ffcf643, 3.6455660418215444E19);
    _test32(0x50e2e3b3, 3.0452586496E10);
    _test32(0x4914a300, 608816.0);
    _test32(0x59239bd2, 2.878234215579648E15);
    _test32(0x10e0e0b4, 8.869863136638123E-29);
    _test32(0x16b1b8a0, 2.8712407025600733E-25);
    _test32(0xafbba4b9, -3.413214433312106E-10);
    _test32(0x39ed6d41, 4.528556310106069E-4);
    _test32(0x26cd7698, 1.4256877403358119E-15);
    _test32(0x58c3bbb6, 1.721687838031872E15);
    _test32(0x32844205, 1.53968446880981E-8);
    _test32(0xf7debb7d, -9.035098568054132E33);
    _test32(0xaf3f2c18, -1.738701405074039E-10);
    _test32(0x7340a8d9, 1.5264063021291595E31);
    _test32(0x1439482f, 9.354348821593712E-27);
    _test32(0x9a62050f, -4.673979090873511E-23);
    _test32(0x365aa321, 3.257948492318974E-6);
    _test32(0xab9b3d23, -1.1030381252483124E-12);
    _test32(0xda41dfad, -1.3642651156873216E16);
    _test32(0xaba95bd7, -1.2033662911623E-12);
    _test32(0x38d9d45, 8.323342486879323E-37);
    _test32(0x509b0cf8, 2.08105472E10);
    _test32(0x7997aaa7, 9.843725829681495E34);
    _test32(0x1693fb40, 2.3907691910171116E-25);
    _test32(0x6932a7e3, 1.3498851156559247E25);
    _test32(0x98e52756, -5.923483173240392E-24);
    _test32(0x4321c7ba, 161.78018188476562);
    _test32(0x129a8db3, 9.753697906689189E-28);
    _test32(0x1d80e684, 3.411966546003519E-21);
    _test32(0x3d1b1a71, 0.03786701336503029);
    _test32(0xf176bcf8, -1.221788185872419E30);
    _test32(0x5835d550, 7.99711099355136E14);
    _test32(0x63c39f88, 7.217221064844452E21);
  });

  test('testDouble', () {
    // Special values.
    _test64([0x00000000, 0x00000000], 0.0);
    _test64([0x80000000, 0x00000000], -0.0);
    _test64([0x7ff80000, 0x00000000], double.nan);
    _test64([0x7ff00000, 0x00000000], double.infinity);
    _test64([0xfff00000, 0x00000000], double.negativeInfinity);
    _test64([0x3ff00000, 0x00000000], 1.0);
    _test64([0x40000000, 0x00000000], 2.0);

    // Values around 1.0 and 2.0.
    _test64([0x3fefffff, 0xfffffff7], 0.999999999999999);
    _test64([0x3ff00000, 0x00000005], 1.000000000000001);
    _test64([0x3fffffff, 0xfffffffb], 1.999999999999999);
    _test64([0x40000000, 0x00000002], 2.000000000000001);

    _test64([0x3fb99999, 0x9999999a], 0.1);
    _test64([0xbfb99999, 0x9999999a], -0.1);
    _test64([0x017527e6, 0xd48c1653], 0.1234e-300);
    _test64([0x817527e6, 0xd48c1653], -0.1234e-300);
    _test64([0x7e0795f2, 0xd9000b3f], 0.1234e300);
    _test64([0xfe0795f2, 0xd9000b3f], -0.1234e300);
    _test64([0x3fc99999, 0x9999999a], 0.2);
    _test64([0x4272c359, 0x8dd61e72], 1289389399393.902892);
    _test64([0x405edd3c, 0x07ee0b0b], 123.456789);
    _test64([0xc05edd3c, 0x07ee0b0b], -123.456789);

    // Max value.
    _test64([0x7fefffff, 0xffffffff], 1.7976931348623157E308);
    _test64([0xffefffff, 0xffffffff], -1.7976931348623157E308);
    // Min normalized value.
    _test64([0x00100000, 0x00000000], 2.2250738585072014E-308);
    _test64([0x80100000, 0x00000000], -2.2250738585072014E-308);
    // Denormalized values.
    _test64([0x000ff6a8, 0xebe79958], 2.22E-308);
    _test64([0x00019999, 0x9999999a], 2.2250738585072014E-309);
    _test64([0x800016b9, 0xf3c0e51d], -1.234567E-310);
    _test64([0x000016b9, 0xf3c0e51d], 1.234567E-310);
    _test64([0x00000245, 0xcb934a1c], 1.234567E-311);
    _test64([0x0000003a, 0x2df52103], 1.234567E-312);
    _test64([0x00000005, 0xd165501a], 1.234567E-313);
    _test64([0x00000000, 0x94f08803], 1.234567E-314);
    _test64([0x00000000, 0x0ee4da67], 1.234567E-315);
    _test64([0x00000000, 0x017d490a], 1.234567E-316);
    _test64([0x00000000, 0x002620e7], 1.234567E-317);
    _test64([0x00000000, 0x0003d017], 1.234567E-318);
    _test64([0x00000000, 0x0000619c], 1.234567E-319);
    _test64([0x00000000, 0x000009c3], 1.234567E-320);
    _test64([0x00000000, 0x000000fa], 1.234567E-321);
    _test64([0x00000000, 0x00000019], 1.234567E-322);
    _test64([0x00000000, 0x00000002], 1.234567E-323);
    _test64([0x00000000, 0x00000001], 4.9E-324);
    _test64([0x80000000, 0x00000001], -4.9E-324);

    // Random values between 0 and 1.
    _test64([0x3fe9b9bc, 0xd3c39dab], 0.8039230476396616);
    _test64([0x3fe669d4, 0xa374efc4], 0.700418776752024);
    _test64([0x3fd92b7c, 0xa312ca7e], 0.39327922749649946);
    _test64([0x3fbc74aa, 0x296b7e18], 0.11115516196468211);
    _test64([0x3feea888, 0xcdfcb13d], 0.95807304603435);
    _test64([0x3fd88b23, 0xcfa7eada], 0.3834924247636714);
    _test64([0x3fd62865, 0x167eb9bc], 0.3462155074766107);
    _test64([0x3fe5772b, 0x57e62b3f], 0.6707970349101301);
    _test64([0x3fbd0998, 0x8fb96be0], 0.11342767247099017);
    _test64([0x3fb64329, 0x6d7fa050], 0.08696230815223882);
    _test64([0x3fde7f76, 0x986c1bd4], 0.4765297401904125);
    _test64([0x3fef4b44, 0x33f8efac], 0.9779377951704098);
    _test64([0x3fd374e5, 0x30a19278], 0.3040097212708939);
    _test64([0x3fc17adf, 0x98fc3368], 0.1365622994420861);
    _test64([0x3fd6beb0, 0xe5a5055a], 0.355388855230634);
    _test64([0x3fc3d812, 0x8b76ba20], 0.1550315075850941);
    _test64([0x3fc47c50, 0x27f58900], 0.16004373503808011);
    _test64([0x3fe0ba6a, 0x91eeb5a7], 0.522755894684157);
    _test64([0x3fe68f01, 0x9034c7b9], 0.704956800129586);
    _test64([0x3fe3990d, 0xbaf329c4], 0.6124333049167991);
    _test64([0x3faded64, 0x23ccf8f0], 0.058451775903891945);
    _test64([0x3fe51aeb, 0xf7ee4537], 0.6595363466641747);
    _test64([0x3fe937bb, 0x75080f7d], 0.7880532537242143);
    _test64([0x3fc693d4, 0x47054de4], 0.17638638942535956);
    _test64([0x3fd95091, 0xde22548e], 0.39554259007247417);
    _test64([0x3fe93b21, 0xf50b1a41], 0.788468340492564);
    _test64([0x3fd77d9f, 0x7da868b8], 0.36704242011331756);
    _test64([0x3fcb8aba, 0xe3f1c05c], 0.2151712048539619);
    _test64([0x3feec9ed, 0x25ddcf3], 0.9621491476272283);
    _test64([0x3fda1ac9, 0xbf0e59c0], 0.4078850141317183);
    _test64([0x3fe66e66, 0x602de93e], 0.7009765509131183);
    _test64([0x3fe6da29, 0x63aecb21], 0.714131064122146);
    _test64([0x3fb306bb, 0x648e4ae0], 0.07432147221542662);
    _test64([0x3fd06b98, 0x77b9b50e], 0.25656711284575884);
    _test64([0x3fce8705, 0x99f3a28c], 0.2384955407826691);
    _test64([0x3fe14a5c, 0x59d8ce59], 0.5403272394964446);
    _test64([0x3fb118ac, 0x2dc6a700], 0.06678272359445359);
    _test64([0x3fafb0e2, 0x3ecbc770], 0.06189639107277756);
    _test64([0x3fe4475a, 0x31a9723a], 0.633710000034234);
    _test64([0x3fdd5e0f, 0x4a0296f6], 0.4588659498934783);
    _test64([0x3fefbc13, 0xbb0b2b44], 0.991708627051914);
    _test64([0x3fde5c60, 0x1db8b162], 0.4743881502388573);
    _test64([0x3fdda642, 0x89b8cde6], 0.4632726998272275);
    _test64([0x3fea1866, 0xf99c86b], 0.8154783539487317);
    _test64([0x3fec3946, 0xd8a8808], 0.8819914116359096);
    _test64([0x3fd6a294, 0x37ecfad4], 0.3536730333470761);
    _test64([0x3fe1c31f, 0xcb975395], 0.5550688721074147);
    _test64([0x3fc78444, 0x8f1277b0], 0.18372399316734578);
    _test64([0x3fe78d52, 0xa1f7d63c], 0.7360013163985921);
    _test64([0x3feb0d9b, 0xee281702], 0.8454112674232592);
    _test64([0x3fc382ec, 0x2f0ee738], 0.15243294046177325);
    _test64([0x3fe61657, 0x7bf4b8d5], 0.6902272625937039);
    _test64([0x3fdd6ffc, 0xb6caedac], 0.4599601540646414);
    _test64([0x3fdfa267, 0xb07ca0e4], 0.49428741679231636);
    _test64([0x3fcdc368, 0x8fcb9f34], 0.23252589246043842);
    _test64([0x3fc6bd12, 0x4233708], 0.1776449699595377);
    _test64([0x3fd75236, 0xcfc8fafe], 0.364392950930707);
    _test64([0x3fef3468, 0xbd4ce47], 0.9751472693519155);
    _test64([0x3fc634b5, 0xd386b93c], 0.17348358944350106);
    _test64([0x3feaf69a, 0xbdedcf4b], 0.8426030835675901);
    _test64([0x3fdcf973, 0x748a67e0], 0.45272528057978256);
    _test64([0x3fec8f61, 0x55ecd410], 0.8925024679398366);
    _test64([0x3fe3e8d8, 0x466d453a], 0.6221734405063792);
    _test64([0x3fdfa7ff, 0x50fced6a], 0.4946287432573714);
    _test64([0x3fe536d9, 0xd49d33be], 0.6629456665628977);
    _test64([0x3fdfdff0, 0xe8e048ae], 0.4980432771855118);
    _test64([0x3feb4abc, 0x3a80aeac], 0.8528729574804479);
    _test64([0x3fbf44d0, 0x11fd7950], 0.12214374961101737);
    _test64([0x3fdb59c2, 0x1a7ecd6a], 0.4273534067862871);
    _test64([0x3fbb4128, 0xfb635888], 0.10646301400569957);
    _test64([0x3fc03e9c, 0x906fa23c], 0.12691075375120586);
    _test64([0x3f976c37, 0x38766d00], 0.022873747655109078);
    _test64([0x3fd9a620, 0x96187b4e], 0.4007646051194812);
    _test64([0x3fdcea7d, 0xef3c0528], 0.45181225168933503);
    _test64([0x3fe20ea2, 0x3d703cb2], 0.5642863464326153);
    _test64([0x3fd6f2c3, 0xedcf5bf4], 0.35856722091324333);
    _test64([0x3fef2c3c, 0x9e7a6dc0], 0.9741499991682119);
    _test64([0x3fcc2142, 0xc7ab8c28], 0.21976504086987458);
    _test64([0x3fea41a3, 0xe626ff58], 0.8205127234614151);
    _test64([0x3fe4162d, 0x28c9abe8], 0.6277070805202785);
    _test64([0x3fce8826, 0xa9ca117c], 0.23852999964232058);
    _test64([0x3fe07fbd, 0x24b88c67], 0.5155931203083924);
    _test64([0x3fdb39c6, 0x6484189a], 0.4254013043977324);
    _test64([0x3fcb830d, 0x50fac7b0], 0.21493689016420836);
    _test64([0x3fd927cc, 0xb62342c8], 0.3930541781128736);
    _test64([0x3fb553b2, 0x448dd6d8], 0.08330835508044332);
    _test64([0x3fef870d, 0x8a9f527b], 0.9852359492748087);
    _test64([0x3febe929, 0xc4bac429], 0.8722122995733389);
    _test64([0x3fc9cc2d, 0x6286a01c], 0.20154349623521817);
    _test64([0x3fe5b506, 0x615ab5c6], 0.6783477689220312);
    _test64([0x3fe26c9e, 0xa02bdfe], 0.5757589526673994);
    _test64([0x3fe6daf5, 0x4806b05c], 0.7142282873878787);
    _test64([0x3fefc9bb, 0xb28f362e], 0.9933756339539224);
    _test64([0x3fbd4557, 0x82e84968], 0.1143393225286552);
    _test64([0x3fe1f097, 0x44a3d0b7], 0.5606190052626719);
    _test64([0x3fb1c833, 0xb64b5470], 0.06946109009307277);
    _test64([0x3fec1407, 0x50dfb23b], 0.8774448947493235);
    _test64([0x3fc3b307, 0x46f5e6bc], 0.15390101399298384);
    _test64([0x3fe844de, 0xac963963], 0.7584069605671114);
    _test64([0x3fd45d6e, 0x91a9989e], 0.31820263123371173);

    // Random values throughout the double range.
    _test64([0xcdcde6aa, 0x7873b572], -6.297893811982062E66);
    _test64([0xb34ea52b, 0x6e9df882], -1.4898867990306772E-61);
    _test64([0x64adf2aa, 0x312ca7e1], 9.480996430600118E176);
    _test64([0x1c74aa06, 0xa5adf865], 1.3367811675349397E-171);
    _test64([0xf5444671, 0xbf9627b5], -7.610810186261922E256);
    _test64([0x622c8f3e, 0xfa7eadb0], 8.223166382138422E164);
    _test64([0x58a19471, 0x67eb9bcc], 8.86632413276402E118);
    _test64([0xabb95a84, 0xfcc567f2], -4.6366137067352683E-98);
    _test64([0x1d099884, 0x3ee5af9a], 8.477749983935152E-169);
    _test64([0x1643296d, 0xb5fe8140], 1.9557345103545524E-201);
    _test64([0x79fdda74, 0x86c1bd5f], 4.2335912871234087E279);
    _test64([0xfa5a219d, 0x7f1df591], -2.3716857301453343E281);
    _test64([0x4dd394c4, 0xa192798], 8.248528934271815E66);
    _test64([0x22f5bf1f, 0xc7e19b49], 2.853336355041256E-140);
    _test64([0x5afac3aa, 0x5a5055b7], 1.8552153438817665E130);
    _test64([0x27b02519, 0x5bb5d113], 1.6005805986130906E-117);
    _test64([0x28f8a05a, 0x3fac4815], 2.5600128085455218E-111);
    _test64([0x85d354a0, 0x3dd6b4f3], -1.3311552586579328E-280);
    _test64([0xb4780c89, 0x698f727], -6.129954074000813E-56);
    _test64([0x9cc86de8, 0x5e65389a], -5.057128159830759E-170);
    _test64([0xef6b230, 0x4799f1f0], 1.3941634112607635E-236);
    _test64([0xa8d75f9f, 0xfdc8a6fc], -6.0744368561933565E-112);
    _test64([0xc9bddb8f, 0xa101efb6], -1.7045710739729275E47);
    _test64([0x2d27a89b, 0x382a6f20], 3.6294490400055576E-91);
    _test64([0x65424775, 0xe22548f8], 5.925748939163494E179);
    _test64([0xc9d90fb1, 0xa1634836], -5.722990169624538E47);
    _test64([0x5df67dbf, 0xda868b9e], 4.3882436353810935E144);
    _test64([0x371575e9, 0x1f8e02ee], 2.4058151686870744E-43);
    _test64([0xf64f681f, 0x4bbb9e72], -7.726253195850651E261);
    _test64([0x686b26cf, 0xf0e59c06], 9.910208820012368E194);
    _test64([0xb373331d, 0x5bd27ce], -7.467486715472904E-61);
    _test64([0xb6d14b2b, 0x75d96425], -1.211676991363774E-44);
    _test64([0x1306bb60, 0x92392b97], 5.1516895067444726E-217);
    _test64([0x41ae61d4, 0x7b9b50e7], 2.548639338033516E8);
    _test64([0x3d0e0b31, 0xcf9d1469], 1.3342095786138988E-14);
    _test64([0x8a52e2e0, 0x3b19cb38], -6.141707139267237E-259);
    _test64([0x1118ac38, 0xb71a9c13], 2.603758248081968E-226);
    _test64([0xfd87101, 0x7d978ee5], 2.459857504627046E-232);
    _test64([0xa23ad18a, 0x352e4745], -8.590863325618324E-144);
    _test64([0x75783d29, 0xa0296f70], 7.278962913424277E257);
    _test64([0xfde09de5, 0x61656888], -2.1734648688870485E298);
    _test64([0x79718077, 0xdb8b1623], 9.695260031659742E276);
    _test64([0x76990a37, 0x9b8cde6d], 1.971192366484015E263);
    _test64([0xd0c3304f, 0xf3390d67], -1.1376138095726657E81);
    _test64([0xe1ca3067, 0xb1510109], -1.1782242328468048E163);
    _test64([0x5a8a50c4, 0x7ecfad55], 1.425081729881992E128);
    _test64([0x8e18fe50, 0x72ea72a0], -9.37063623070425E-241);
    _test64([0x2f08893a, 0x7893bd8d], 4.0416231167192477E-82);
    _test64([0xbc6a9509, 0x3efac79f], -1.1528179597119854E-17);
    _test64([0xd86cdf4e, 0xc502e047], -9.101010985774022E117);
    _test64([0x2705d86b, 0x787739cf], 1.0574785023773003E-120);
    _test64([0xb0b2bbf8, 0x7e971aa7], -4.141881119170908E-74);
    _test64([0x75bff2d4, 0x6caedac7], 1.5350675559647406E259);
    _test64([0x7e899eea, 0x7ca0e54], 3.4316079097255617E301);
    _test64([0x3b86d127, 0x7e5cf9a3], 6.039611960807865E-22);
    _test64([0x2d7a243c, 0x2119b84a], 1.2833127546095387E-89);
    _test64([0x5d48db16, 0xfc8faff2], 2.3679693140335752E141);
    _test64([0xf9a34049, 0x7a99c8ef], -8.531434157588162E277);
    _test64([0x2c696ba4, 0x9c35c9f4], 9.520836999385529E-95);
    _test64([0xd7b4d5da, 0xbdb9e964], -3.206856786877124E114);
    _test64([0x73e5cde7, 0x48a67e04], 1.9514110919532497E250);
    _test64([0xe47b0a84, 0xbd9a821e], -1.0700933026823467E176);
    _test64([0x9f46c209, 0xcda8a753], -5.179951037444452E-158);
    _test64([0x7e9ffd4f, 0xfced6b4], 8.569252835514251E301);
    _test64([0xa9b6ce98, 0x93a677d6], -9.711135665099199E-108);
    _test64([0x7f7fc397, 0x8e048af9], 1.3940913327465408E306);
    _test64([0xda55e1fe, 0x5015d581], -1.4812924721906427E127);
    _test64([0x1f44d038, 0x47f5e54d], 4.737338914555982E-158);
    _test64([0x6d670848, 0xa7ecd6b5], 1.016307848543568E219);
    _test64([0x1b4128e3, 0xed8d6230], 2.117302740808736E-177);
    _test64([0x207d392f, 0x837d11f6], 3.4873269549337505E-152);
    _test64([0x5db0dd6, 0x38766d17], 1.8630149420804414E-280);
    _test64([0x66988256, 0x6187b4e0], 1.6662694932683939E186);
    _test64([0x73a9f7ac, 0xf3c05283], 1.452500477811838E249);
    _test64([0x907511ce, 0xae07965b], -2.1713947206680943E-229);
    _test64([0x5bcb0f90, 0xdcf5bf4e], 1.5366281556927236E134);
    _test64([0xf961e4e2, 0xcf4db80d], -4.956276753857123E276);
    _test64([0x3842859a, 0x3d5c6147], 1.0886185451514296E-37);
    _test64([0xd20d1f11, 0xc4dfeb10], -1.8103414291013452E87);
    _test64([0xa0b16972, 0x19357d01], -3.32451488002257E-151);
    _test64([0x3d104d58, 0x4e508be4], 1.44791988988344E-14);
    _test64([0x83fde937, 0x97118ce8], -1.9182940419362316E-289);
    _test64([0x6ce719b2, 0x484189a7], 3.9816763934214935E216);
    _test64([0x37061aa6, 0x87d63d94], 1.238977854703573E-43);
    _test64([0x649f32e0, 0x62342c83], 4.938493427207422E176);
    _test64([0x1553b277, 0x12375b61], 6.135160266378285E-206);
    _test64([0xfc386c6b, 0x53ea4f67], -2.3801480044660797E290);
    _test64([0xdf494e02, 0x9758853e], -1.0354031977895994E151);
    _test64([0x33985ae9, 0x143500f8], 3.7890569411337005E-60);
    _test64([0xada8332b, 0x2b56b8c5], -9.503956824431546E-89);
    _test64([0x9364f07f, 0x4057bfca], -3.0370938126636166E-215);
    _test64([0xb6d7aa7b, 0xd60b8c], -1.6581522255623348E-44);
    _test64([0xfe4ddda6, 0x51e6c5ca], -2.500115798151869E300);
    _test64([0x1d45578c, 0xba125ba], 1.1310118263643858E-167);
    _test64([0x8f84ba31, 0x947a16ff], -6.518932884318998E-234);
    _test64([0x11c833a9, 0xd92d51dc], 5.230715225679756E-223);
    _test64([0xe0a03a90, 0x1bf64771], -2.7851790876803525E157);
    _test64([0x27660eb6, 0x37af35f9], 6.833565753907854E-119);
    _test64([0xc226f54e, 0x92c72c68], -4.930242390758673E10);
    _test64([0x5175ba4e, 0x1a9989e3], 2.6381145200142355E84);
  });

  test('testVarint64', () {
    final roundtrip = roundtripTester(
        fromBytes: (CodedBufferReader reader) => reader.readUint64(),
        toBytes: convertToBytes(PbFieldType.OU6));

    roundtrip(make64(0), [0x00]);
    roundtrip(make64(3), [0x03]);
    roundtrip(make64(0x80), [0x80, 0x01]);
    roundtrip(make64(0x96), [0x96, 0x01]);
    roundtrip(make64(0xce), [0xce, 0x01]);
    roundtrip(make64(0xff), [0xff, 0x01]);
    roundtrip(make64(0x0e01), [0x81, 0x1c]);
    roundtrip(make64(0x9600), [0x80, 0xac, 0x02]);
    roundtrip(make64(0x9e5301), [0x81, 0xa6, 0xf9, 0x04]);
    roundtrip(make64(0x7fffffff), [0xff, 0xff, 0xff, 0xff, 0x07]);
    roundtrip(make64(0xffffffff), [0xff, 0xff, 0xff, 0xff, 0x0f]);
    roundtrip(make64(0xffffffff, 0xffffff),
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]);
    roundtrip(make64(0xffffffff, 0xffffffff),
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01]);
    roundtrip(make64(0xffff2f34, 0xffffffff),
        [180, 222, 252, 255, 255, 255, 255, 255, 255, 1]);
    roundtrip(make64(0x00000001, 0x40000000),
        [0x81, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x40]);
  });

  test('testWriteTo', () {
    var writer = CodedBufferWriter()..writeField(0, PbFieldType.O3, 1337);
    expect(writer.lengthInBytes, 3);
    var buffer = Uint8List(5);
    buffer[0] = 0x55;
    buffer[4] = 0xAA;
    var expected = writer.toBuffer();
    expect(writer.writeTo(buffer, 1), isTrue);
    expect(buffer[0], 0x55);
    expect(buffer[4], 0xAA);
    expect(buffer.sublist(1, 4), expected);
    expect(writer.writeTo(buffer, 3), isFalse);
  });
}
