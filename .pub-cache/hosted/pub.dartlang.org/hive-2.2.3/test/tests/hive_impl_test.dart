@TestOn('vm')

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import 'common.dart';

class _TestAdapter extends TypeAdapter<int> {
  _TestAdapter([this.typeId = 0]);

  @override
  final int typeId;

  @override
  int read(_) => 5;

  @override
  void write(_, __) {}
}

void main() {
  group('HiveImpl', () {
    Future<HiveImpl> initHive() async {
      var tempDir = await getTempDir();
      var hive = HiveImpl();
      hive.init(tempDir.path);
      return hive;
    }

    test('.init()', () {
      var hive = HiveImpl();

      expect(() => hive.init('MYPATH'), returnsNormally);
      expect(hive.homePath, 'MYPATH');

      expect(
        hive.findAdapterForValue(DateTime.now())!.adapter,
        isA<DateTimeWithTimezoneAdapter>(),
      );
      expect(hive.findAdapterForTypeId(16)!.adapter, isA<DateTimeAdapter>());
    });

    group('.openBox()', () {
      group('box already open', () {
        test('opened box is returned if it exists', () async {
          var hive = await initHive();

          var testBox = await hive.openBox('TESTBOX');
          var testBox2 = await hive.openBox('testBox');
          expect(testBox == testBox2, true);

          await hive.close();
        });

        test('throw HiveError if opened box is lazy', () async {
          var hive = await initHive();

          await hive.openLazyBox('LAZYBOX');
          await expectLater(
            () => hive.openBox('lazyBox'),
            throwsHiveError('is already open and of type LazyBox<dynamic>'),
          );

          await hive.close();
        });

        test('throw HiveError if already opening box is lazy', () async {
          var hive = await initHive();

          await Future.wait([
            hive.openLazyBox('TESTBOX'),
            expectLater(hive.openBox('testbox'),
                throwsHiveError('is already open and of type LazyBox<dynamic>'))
          ]);
        });

        test('same box returned if it is already opening', () async {
          var hive = await initHive();

          Box? box1;
          Box? box2;
          await Future.wait([
            hive.openBox('TESTBOX').then((value) => box1 = value),
            hive.openBox('testbox').then((value) => box2 = value)
          ]);

          expect(box1 == box2, true);
        });
      });
    });

    group('.openLazyBox()', () {
      group('box already open', () {
        test('opened box is returned if it exists', () async {
          var hive = await initHive();

          var testBox = await hive.openLazyBox('TESTBOX');
          var testBox2 = await hive.openLazyBox('testBox');
          expect(testBox == testBox2, true);

          await hive.close();
        });

        test('same box returned if it is already opening', () async {
          LazyBox? box1;
          LazyBox? box2;

          var hive = await initHive();
          await Future.wait([
            hive.openLazyBox('LAZYBOX').then((value) => box1 = value),
            hive.openLazyBox('lazyBox').then((value) => box2 = value)
          ]);

          expect(box1 == box2, true);
        });

        test('throw HiveError if opened box is not lazy', () async {
          var hive = await initHive();

          await hive.openBox('LAZYBOX');
          await expectLater(
            () => hive.openLazyBox('lazyBox'),
            throwsHiveError('is already open and of type Box<dynamic>'),
          );

          await hive.close();
        });

        test('throw HiveError if already opening box is not lazy', () async {
          var hive = await initHive();

          await Future.wait([
            hive.openBox('LAZYBOX'),
            expectLater(hive.openLazyBox('lazyBox'),
                throwsHiveError('is already open and of type Box<dynamic>'))
          ]);
        });
      });
    });

    group('.box()', () {
      test('returns already opened box', () async {
        var hive = await initHive();

        var box = await hive.openBox('TESTBOX');
        expect(hive.box('testBox'), box);
        expect(() => hive.box('other'), throwsHiveError('not found'));

        await hive.close();
      });

      test('throws HiveError if box type does not match', () async {
        var hive = await initHive();

        await hive.openBox<int>('INTBOX');
        expect(
          () => hive.box('intBox'),
          throwsHiveError('is already open and of type Box<int>'),
        );

        await hive.openBox('DYNAMICBOX');
        expect(
          () => hive.box<int>('dynamicBox'),
          throwsHiveError('is already open and of type Box<dynamic>'),
        );

        await hive.openLazyBox('LAZYBOX');
        expect(
          () => hive.box('lazyBox'),
          throwsHiveError('is already open and of type LazyBox<dynamic>'),
        );

        await hive.close();
      });
    });

    group('.lazyBox()', () {
      test('returns already opened box', () async {
        var hive = await initHive();

        var box = await hive.openLazyBox('TESTBOX');
        expect(hive.lazyBox('testBox'), box);
        expect(() => hive.lazyBox('other'), throwsHiveError('not found'));

        await hive.close();
      });

      test('throws HiveError if box type does not match', () async {
        var hive = await initHive();

        await hive.openLazyBox<int>('INTBOX');
        expect(
          () => hive.lazyBox('intBox'),
          throwsHiveError('is already open and of type LazyBox<int>'),
        );

        await hive.openLazyBox('DYNAMICBOX');
        expect(
          () => hive.lazyBox<int>('dynamicBox'),
          throwsHiveError('is already open and of type LazyBox<dynamic>'),
        );

        await hive.openBox('BOX');
        expect(
          () => hive.lazyBox('box'),
          throwsHiveError('is already open and of type Box<dynamic>'),
        );

        await hive.close();
      });
    });

    test('isBoxOpen()', () async {
      var hive = await initHive();

      await hive.openBox('testBox');

      expect(hive.isBoxOpen('testBox'), true);
      expect(hive.isBoxOpen('nonExistingBox'), false);

      await hive.close();
    });

    test('.close()', () async {
      var hive = await initHive();

      var box1 = await hive.openBox('box1');
      var box2 = await hive.openBox('box2');
      expect(box1.isOpen, true);
      expect(box2.isOpen, true);

      await hive.close();
      expect(box1.isOpen, false);
      expect(box2.isOpen, false);
    });

    test('.generateSecureKey()', () {
      var hive = HiveImpl();

      var key1 = hive.generateSecureKey();
      var key2 = hive.generateSecureKey();

      expect(key1.length, 32);
      expect(key2.length, 32);
      expect(key1, isNot(key2));
    });

    group('.deleteBoxFromDisk()', () {
      test('deletes open box', () async {
        var hive = await initHive();

        var box1 = await hive.openBox('testBox1');
        await box1.put('key', 'value');
        var box1File = File(box1.path!);

        await hive.deleteBoxFromDisk('testBox1');
        expect(await box1File.exists(), false);
        expect(hive.isBoxOpen('testBox1'), false);

        await hive.close();
      });

      test('deletes closed box', () async {
        var hive = await initHive();

        var box1 = await hive.openBox('testBox1');
        await box1.put('key', 'value');
        var path = box1.path!;
        await box1.close();
        var box1File = File(path);

        await hive.deleteBoxFromDisk('testBox1');
        expect(await box1File.exists(), false);
        expect(hive.isBoxOpen('testBox1'), false);

        await hive.close();
      });

      test('does nothing if files do not exist', () async {
        var hive = await initHive();
        await hive.deleteBoxFromDisk('testBox1');
        await hive.close();
      });
    });

    test('.deleteFromDisk()', () async {
      var hive = await initHive();

      var box1 = await hive.openBox('testBox1');
      await box1.put('key', 'value');
      var box1File = File(box1.path!);

      var box2 = await hive.openBox('testBox2');
      await box2.put('key', 'value');
      var box2File = File(box1.path!);

      await hive.deleteFromDisk();
      expect(await box1File.exists(), false);
      expect(await box2File.exists(), false);
      expect(hive.isBoxOpen('testBox1'), false);
      expect(hive.isBoxOpen('testBox2'), false);

      await hive.close();
    });

    group('.boxExists()', () {
      test('returns true if a box was created', () async {
        var hive = await initHive();
        await hive.openBox('testBox1');
        expect(await hive.boxExists('testBox1'), true);
        await hive.close();
      });

      test('returns false if no box was created', () async {
        var hive = await initHive();
        expect(await hive.boxExists('testBox1'), false);
        await hive.close();
      });

      test('returns false if box was created and then deleted', () async {
        var hive = await initHive();
        await hive.openBox('testBox1');
        await hive.deleteBoxFromDisk('testBox1');
        expect(await hive.boxExists('testBox1'), false);
        await hive.close();
      });
    });

    group('.resetAdapters()', () {
      test('returns normally', () async {
        final hive = await initHive();
        expect(hive.resetAdapters, returnsNormally);
      });

      test('clears an adapter', () async {
        final hive = await initHive();
        final adapter = _TestAdapter(1);

        expect(hive.isAdapterRegistered(adapter.typeId), isFalse);
        hive.registerAdapter(adapter);
        expect(hive.isAdapterRegistered(adapter.typeId), isTrue);

        hive.resetAdapters();
        expect(hive.isAdapterRegistered(adapter.typeId), isFalse);
      });
    });
  });
}
