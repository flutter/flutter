@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../tests/backend/vm/storage_backend_vm_test.dart';
import '../tests/common.dart';
import '../tests/frames.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var bytes = getFrameBytes(testFrames);
  var frames = testFrames;

  framesSetLengthOffset(frames, frameBytes);

  var dir = await getTempDir();
  var hive = HiveImpl();
  hive.init(dir.path);

  for (var i = 0; i < bytes.length; i++) {
    var subBytes = bytes.sublist(0, i + 1);
    var boxFile = File(path.join(dir.path, 'testbox$i.hive'));
    await boxFile.writeAsBytes(subBytes);

    var subFrames = frames.takeWhile((f) => f.offset + f.length! <= i + 1);
    var subKeystore = Keystore.debug(frames: subFrames);
    if (lazy) {
      var box = await hive.openLazyBox('testbox$i');
      expect(box.keys, subKeystore.getKeys());
      await box.compact();
      await box.close();
    } else {
      var box = await hive.openBox('testbox$i');
      var map = Map.fromIterables(
        subKeystore.getKeys(),
        subKeystore.getValues(),
      );
      expect(box.toMap(), map);
      await box.compact();
      await box.close();
    }

    expect(await boxFile.readAsBytes(), getFrameBytes(subFrames));
  }
}

Future _performTestWithoutOutput(bool lazy) {
  return runZoned(
    () => _performTest(lazy),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {},
    ),
  );
}

void main() {
  group('test recovery', () {
    test('normal box', () => _performTestWithoutOutput(false));

    test('lazy box', () => _performTestWithoutOutput(true));
  }, timeout: longTimeout);
}
