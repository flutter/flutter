// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/src/winrt/foundation/uri.dart' as winrt_uri;
import 'package:win32/winrt.dart';

// Exhaustively test the WinRT Collections to make sure constructors,
// properties and methods are working correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    group('IMap<GUID, Object?> (MediaPropertySet)', () {
      late IMap<GUID, Object?> map;
      late Arena allocator;

      setUp(() {
        winrtInitialize();
        allocator = Arena();
        final pPoint = allocator<Point>()
          ..ref.X = 3
          ..ref.Y = -3;
        final pRect = allocator<Rect>()
          ..ref.Height = 100
          ..ref.Width = 200
          ..ref.X = 2
          ..ref.Y = -2;
        final pSize = allocator<Size>()
          ..ref.Height = 1500
          ..ref.Width = 300;

        map = IMap()
          ..insert(
              GUIDFromString(IID_IFileOpenPicker, allocator: allocator).ref,
              null)
          ..insert(GUIDFromString(IID_ICalendar, allocator: allocator).ref,
              Calendar(allocator: allocator))
          ..insert(
              GUIDFromString(IID_IStorageItem, allocator: allocator).ref, true)
          ..insert(
              GUIDFromString(IID_IPhoneNumberFormatter, allocator: allocator)
                  .ref,
              DateTime(2022, 7, 11, 17, 30))
          ..insert(
              GUIDFromString(IID_ISpellChecker, allocator: allocator).ref, 0.5)
          ..insert(GUIDFromString(IID_IShellLink, allocator: allocator).ref,
              const Duration(seconds: 30))
          ..insert(GUIDFromString(IID_IShellService, allocator: allocator).ref,
              GUIDFromString(IID_ISpVoice, allocator: allocator).ref)
          ..insert(
              GUIDFromString(IID_IShellFolder, allocator: allocator).ref, 259)
          ..insert(GUIDFromString(IID_IShellItem, allocator: allocator).ref,
              pPoint.ref)
          ..insert(GUIDFromString(IID_IShellItem2, allocator: allocator).ref,
              pRect.ref)
          ..insert(
              GUIDFromString(IID_IShellItemArray, allocator: allocator).ref,
              pSize.ref)
          ..insert(
              GUIDFromString(IID_IShellItemFilter, allocator: allocator).ref,
              'strVal')
          ..insert(GUIDFromString(IID_IUnknown, allocator: allocator).ref,
              [true, false])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader, allocator: allocator).ref,
              [DateTime(2020, 7, 11, 17, 30), DateTime(2022, 7, 11, 17, 30)])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader2, allocator: allocator)
                  .ref,
              [2.5, 0.99])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader3, allocator: allocator)
                  .ref,
              const [Duration(hours: 1), Duration(minutes: 60)])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader4, allocator: allocator)
                  .ref,
              [GUIDFromString(IID_IShellItem, allocator: allocator).ref])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader5, allocator: allocator)
                  .ref,
              [
                Calendar(allocator: allocator),
              ])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader6, allocator: allocator)
                  .ref,
              [2022, -2022])
          ..insert(
              GUIDFromString(IID_IAppxManifestReader7, allocator: allocator)
                  .ref,
              [pPoint.ref])
          ..insert(
              GUIDFromString(IID_IAppxManifestProperties, allocator: allocator)
                  .ref,
              [pRect.ref])
          ..insert(
              GUIDFromString(IID_IAppxManifestPackageId, allocator: allocator)
                  .ref,
              [pSize.ref])
          ..insert(GUIDFromString(IID_IAppxFile, allocator: allocator).ref,
              ['str1', 'str2']);
      });

      test('fromMap', () {
        final calendarGuid =
            GUIDFromString(IID_ICalendar, allocator: allocator).ref;
        final pickerGuid =
            GUIDFromString(IID_IFileOpenPicker, allocator: allocator).ref;
        final storageItemGuid =
            GUIDFromString(IID_IStorageItem, allocator: allocator).ref;
        map = IMap.fromMap({
          calendarGuid: Calendar(allocator: allocator),
          pickerGuid: 259,
          storageItemGuid: 'strVal',
        });

        final calendarVal = map.lookup(calendarGuid);
        expect(calendarVal, isA<IInspectable>());
        final calendar =
            Calendar.fromRawPointer((calendarVal as IInspectable).ptr);
        expect(calendar.runtimeClassName,
            equals('Windows.Globalization.Calendar'));
        expect(map.lookup(pickerGuid), equals(259));
        expect(map.lookup(storageItemGuid), equals('strVal'));
      });

      test('lookup fails if the map is empty', () {
        map.clear();
        expect(
            () => map.lookup(
                GUIDFromString(IID_ICalendar, allocator: allocator).ref),
            throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(
            () => map.lookup(
                GUIDFromString(IID_IInspectable, allocator: allocator).ref),
            throwsException);
      });

      test('lookup returns items', () {
        expect(
            map.lookup(
                GUIDFromString(IID_IFileOpenPicker, allocator: allocator).ref),
            isNull);

        final calendarVal =
            map.lookup(GUIDFromString(IID_ICalendar, allocator: allocator).ref);
        expect(calendarVal, isA<IInspectable>());
        final calendar =
            Calendar.fromRawPointer((calendarVal as IInspectable).ptr);
        expect(calendar.runtimeClassName,
            equals('Windows.Globalization.Calendar'));

        expect(
            map.lookup(
                GUIDFromString(IID_IStorageItem, allocator: allocator).ref),
            isTrue);

        final dateTimeVal = map.lookup(
            GUIDFromString(IID_IPhoneNumberFormatter, allocator: allocator)
                .ref);
        expect(dateTimeVal, isA<DateTime>());
        final dateTime = dateTimeVal as DateTime;
        expect(dateTime.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(
            map.lookup(
                GUIDFromString(IID_ISpellChecker, allocator: allocator).ref),
            equals(0.5));
        expect(
            map.lookup(
                GUIDFromString(IID_IShellLink, allocator: allocator).ref),
            equals(const Duration(seconds: 30)));

        final guidVal = map.lookup(
            GUIDFromString(IID_IShellService, allocator: allocator).ref);
        expect(guidVal, isA<GUID>());
        final guid = guidVal as GUID;
        expect(guid.toString(), equals(IID_ISpVoice));

        expect(
            map.lookup(
                GUIDFromString(IID_IShellFolder, allocator: allocator).ref),
            equals(259));

        final pointVal = map
            .lookup(GUIDFromString(IID_IShellItem, allocator: allocator).ref);
        expect(pointVal, isA<Point>());
        final point = pointVal as Point;
        expect(point.X, equals(3));
        expect(point.Y, equals(-3));

        final rectVal = map
            .lookup(GUIDFromString(IID_IShellItem2, allocator: allocator).ref);
        expect(rectVal, isA<Rect>());
        final rect = rectVal as Rect;
        expect(rect.Height, equals(100));
        expect(rect.Width, equals(200));
        expect(rect.X, equals(2));
        expect(rect.Y, equals(-2));

        final sizeVal = map.lookup(
            GUIDFromString(IID_IShellItemArray, allocator: allocator).ref);
        expect(sizeVal, isA<Size>());
        final size = sizeVal as Size;
        expect(size.Height, equals(1500));
        expect(size.Width, equals(300));

        expect(map.lookup(GUIDFromString(IID_IShellItemFilter).ref),
            equals('strVal'));

        expect(
            map.lookup(GUIDFromString(IID_IUnknown, allocator: allocator).ref),
            equals([true, false]));

        final dateTimeListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestReader, allocator: allocator).ref);
        expect(dateTimeListVal, isA<List<DateTime>>());
        final dateTimeList = dateTimeListVal as List<DateTime>;
        expect(dateTimeList.first.millisecondsSinceEpoch,
            equals(DateTime(2020, 7, 11, 17, 30).millisecondsSinceEpoch));
        expect(dateTimeList.last.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(
            map.lookup(
                GUIDFromString(IID_IAppxManifestReader2, allocator: allocator)
                    .ref),
            equals([2.5, 0.99]));

        expect(
            map.lookup(
                GUIDFromString(IID_IAppxManifestReader3, allocator: allocator)
                    .ref),
            equals(const [Duration(hours: 1), Duration(minutes: 60)]));

        final guidListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestReader4, allocator: allocator).ref);
        expect(guidListVal, isA<List<GUID>>());
        final guidList = guidListVal as List<GUID>;
        expect(guidList.first.toString(), equals(IID_IShellItem));

        final calendarListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestReader5, allocator: allocator).ref);
        expect(calendarListVal, isA<List<IInspectable>>());
        final calendarList = calendarListVal as List<IInspectable>;
        final calendar_ = Calendar.fromRawPointer(calendarList.first.ptr);
        expect(calendar_.runtimeClassName,
            equals('Windows.Globalization.Calendar'));

        expect(
            map.lookup(
                GUIDFromString(IID_IAppxManifestReader6, allocator: allocator)
                    .ref),
            equals([2022, -2022]));

        final pointListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestReader7, allocator: allocator).ref);
        expect(pointListVal, isA<List<Point>>());
        final pointList = pointListVal as List<Point>;
        expect(pointList.first.X, equals(3));
        expect(pointList.first.Y, equals(-3));

        final rectListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestProperties, allocator: allocator)
                .ref);
        expect(rectListVal, isA<List<Rect>>());
        final rectList = rectListVal as List<Rect>;
        expect(rectList.first.Height, equals(100));
        expect(rectList.first.Width, equals(200));
        expect(rectList.first.X, equals(2));
        expect(rectList.first.Y, equals(-2));

        final sizeListVal = map.lookup(
            GUIDFromString(IID_IAppxManifestPackageId, allocator: allocator)
                .ref);
        expect(sizeListVal, isA<List<Size>>());
        final sizeList = sizeListVal as List<Size>;
        expect(sizeList.first.Height, equals(1500));
        expect(sizeList.first.Width, equals(300));

        expect(
            map.lookup(GUIDFromString(IID_IAppxFile, allocator: allocator).ref),
            equals(['str1', 'str2']));
      });

      test('hasKey finds items', () {
        expect(
            map.hasKey(GUIDFromString(IID_ICalendar, allocator: allocator).ref),
            isTrue);
        expect(
            map.hasKey(
                GUIDFromString(IID_IShellLink, allocator: allocator).ref),
            isTrue);
        expect(
            map.hasKey(
                GUIDFromString(IID_IShellItemFilter, allocator: allocator).ref),
            isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(
            map.hasKey(
                GUIDFromString(IID_IInspectable, allocator: allocator).ref),
            isFalse);
      });

      test('getView', () {
        final unmodifiableMap = map.getView();
        expect(unmodifiableMap.length, equals(23));
        expect(() => unmodifiableMap..clear(), throwsUnsupportedError);
      });

      test('insert replaces an existing item', () {
        final guid =
            GUIDFromString(IID_IShellItemFilter, allocator: allocator).ref;
        expect(map.size, equals(23));
        expect(map.insert(guid, 'strValNew'), isTrue);
        expect(map.size, equals(23));
        expect(map.lookup(guid), equals('strValNew'));
      });

      test('insert inserts a new item', () {
        final guid =
            GUIDFromString(IID_IDevicePicker, allocator: allocator).ref;
        expect(map.size, equals(23));
        expect(map.insert(guid, 'idevicepicker'), isFalse);
        expect(map.size, equals(24));
        expect(map.lookup(guid), equals('idevicepicker'));
      });

      test('remove throws exception if the map is empty', () {
        map.clear();
        final guid = GUIDFromString(IID_ICalendar, allocator: allocator).ref;
        expect(() => map.remove(guid), throwsException);
      });

      test('remove throws exception if the item does not exists', () {
        final guid = GUIDFromString(IID_IInspectable, allocator: allocator).ref;
        expect(() => map.remove(guid), throwsException);
      });

      test('remove', () {
        final guid1 =
            GUIDFromString(IID_IShellFolder, allocator: allocator).ref;
        final guid2 =
            GUIDFromString(IID_IShellItemFilter, allocator: allocator).ref;
        expect(map.size, equals(23));

        map.remove(guid1);
        expect(map.size, equals(22));
        expect(() => map.lookup(guid1), throwsException);

        map.remove(guid2);
        expect(map.size, equals(21));
        expect(() => map.lookup(guid2), throwsException);
      });

      test('clear', () {
        expect(map.size, equals(23));
        map.clear();
        expect(map.size, equals(0));
      });

      test('toMap', () {
        final guid1 =
            GUIDFromString(IID_IShellFolder, allocator: allocator).ref;
        final guid2 =
            GUIDFromString(IID_IShellItemFilter, allocator: allocator).ref;
        final guid3 =
            GUIDFromString(IID_IAppxManifestReader2, allocator: allocator).ref;
        final dartMap = map.toMap();
        expect(dartMap.length, equals(23));
        expect(dartMap[guid1], equals(259));
        expect(dartMap[guid2], equals('strVal'));
        expect(dartMap[guid3], equals([2.5, 0.99]));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final calendarGuid =
            GUIDFromString(IID_ICalendar, allocator: allocator).ref;
        final storageItemGuid =
            GUIDFromString(IID_IStorageItem, allocator: allocator).ref;
        map = IMap.fromMap({calendarGuid: 'icalendar', storageItemGuid: 259});

        final iterator = map.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals(calendarGuid));
        expect(iterator.current.value, equals('icalendar'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals(storageItemGuid));
        expect(iterator.current.value, equals(259));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IMap<String, Object?> (PropertySet)', () {
      late IMap<String, Object?> map;
      late Arena allocator;

      setUp(() {
        winrtInitialize();
        allocator = Arena();
        final guid = GUIDFromString(IID_ISpVoice, allocator: allocator).ref;
        final pPoint = allocator<Point>()
          ..ref.X = 3
          ..ref.Y = -3;
        final pRect = allocator<Rect>()
          ..ref.Height = 100
          ..ref.Width = 200
          ..ref.X = 2
          ..ref.Y = -2;
        final pSize = allocator<Size>()
          ..ref.Height = 1500
          ..ref.Width = 300;

        map = IMap()
          ..insert('key1', null)
          ..insert('key2', Calendar(allocator: allocator))
          ..insert('key3', true)
          ..insert('key4', DateTime(2022, 7, 11, 17, 30))
          ..insert('key5', 0.5)
          ..insert('key6', const Duration(seconds: 30))
          ..insert('key7', guid)
          ..insert('key8', 259)
          ..insert('key9', pPoint.ref)
          ..insert('key10', pRect.ref)
          ..insert('key11', pSize.ref)
          ..insert('key12', 'strVal')
          ..insert('key13', [true, false])
          ..insert('key14',
              [DateTime(2020, 7, 11, 17, 30), DateTime(2022, 7, 11, 17, 30)])
          ..insert('key15', [2.5, 0.99])
          ..insert('key16', const [Duration(hours: 1), Duration(minutes: 60)])
          ..insert('key17', [guid])
          ..insert('key18', [Calendar(allocator: allocator)])
          ..insert('key19', [2022, -2022])
          ..insert('key20', [pPoint.ref])
          ..insert('key21', [pRect.ref])
          ..insert('key22', [pSize.ref])
          ..insert('key23', ['str1', 'str2']);
      });

      test('fromMap', () {
        map = IMap.fromMap({
          'key1': Calendar(allocator: allocator),
          'key2': 259,
          'key3': 'strVal',
        });

        final calendarVal = map.lookup('key1');
        expect(calendarVal, isA<IInspectable>());
        final calendar =
            Calendar.fromRawPointer((calendarVal as IInspectable).ptr);
        expect(calendar.runtimeClassName,
            equals('Windows.Globalization.Calendar'));
        expect(map.lookup('key2'), equals(259));
        expect(map.lookup('key3'), equals('strVal'));
      });

      test('lookup fails if the map is empty', () {
        map.clear();
        expect(() => map.lookup('key1'), throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(() => map.lookup('key0'), throwsException);
      });

      test('lookup returns items', () {
        expect(map.lookup('key1'), isNull);

        final calendarVal = map.lookup('key2');
        expect(calendarVal, isA<IInspectable>());
        final calendar =
            Calendar.fromRawPointer((calendarVal as IInspectable).ptr);
        expect(calendar.runtimeClassName,
            equals('Windows.Globalization.Calendar'));

        expect(map.lookup('key3'), isTrue);

        final dateTimeVal = map.lookup('key4');
        expect(dateTimeVal, isA<DateTime>());
        final dateTime = dateTimeVal as DateTime;
        expect(dateTime.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(map.lookup('key5'), equals(0.5));
        expect(map.lookup('key6'), equals(const Duration(seconds: 30)));

        final guidVal = map.lookup('key7');
        expect(guidVal, isA<GUID>());
        final guid = guidVal as GUID;
        expect(guid.toString(), equals(IID_ISpVoice));

        expect(map.lookup('key8'), equals(259));

        final pointVal = map.lookup('key9');
        expect(pointVal, isA<Point>());
        final point = pointVal as Point;
        expect(point.X, equals(3));
        expect(point.Y, equals(-3));

        final rectVal = map.lookup('key10');
        expect(rectVal, isA<Rect>());
        final rect = rectVal as Rect;
        expect(rect.Height, equals(100));
        expect(rect.Width, equals(200));
        expect(rect.X, equals(2));
        expect(rect.Y, equals(-2));

        final sizeVal = map.lookup('key11');
        expect(sizeVal, isA<Size>());
        final size = sizeVal as Size;
        expect(size.Height, equals(1500));
        expect(size.Width, equals(300));

        expect(map.lookup('key12'), equals('strVal'));

        expect(map.lookup('key13'), equals([true, false]));

        final dateTimeListVal = map.lookup('key14');
        expect(dateTimeListVal, isA<List<DateTime>>());
        final dateTimeList = dateTimeListVal as List<DateTime>;
        expect(dateTimeList.first.millisecondsSinceEpoch,
            equals(DateTime(2020, 7, 11, 17, 30).millisecondsSinceEpoch));
        expect(dateTimeList.last.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(map.lookup('key15'), equals([2.5, 0.99]));

        expect(map.lookup('key16'),
            equals(const [Duration(hours: 1), Duration(minutes: 60)]));

        final guidListVal = map.lookup('key17');
        expect(guidListVal, isA<List<GUID>>());
        final guidList = guidListVal as List<GUID>;
        expect(guidList.first.toString(), equals(IID_ISpVoice));

        final calendarListVal = map.lookup('key18');
        expect(calendarListVal, isA<List<IInspectable>>());
        final calendarList = calendarListVal as List<IInspectable>;
        final calendar_ = Calendar.fromRawPointer(calendarList.first.ptr);
        expect(calendar_.runtimeClassName,
            equals('Windows.Globalization.Calendar'));

        expect(map.lookup('key19'), equals([2022, -2022]));

        final pointListVal = map.lookup('key20');
        expect(pointListVal, isA<List<Point>>());
        final pointList = pointListVal as List<Point>;
        expect(pointList.first.X, equals(3));
        expect(pointList.first.Y, equals(-3));

        final rectListVal = map.lookup('key21');
        expect(rectListVal, isA<List<Rect>>());
        final rectList = rectListVal as List<Rect>;
        expect(rectList.first.Height, equals(100));
        expect(rectList.first.Width, equals(200));
        expect(rectList.first.X, equals(2));
        expect(rectList.first.Y, equals(-2));

        final sizeListVal = map.lookup('key22');
        expect(sizeListVal, isA<List<Size>>());
        final sizeList = sizeListVal as List<Size>;
        expect(sizeList.first.Height, equals(1500));
        expect(sizeList.first.Width, equals(300));

        expect(map.lookup('key23'), equals(['str1', 'str2']));
      });

      test('hasKey finds items', () {
        expect(map.hasKey('key1'), isTrue);
        expect(map.hasKey('key11'), isTrue);
        expect(map.hasKey('key23'), isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(map.hasKey('key0'), isFalse);
      });

      test('getView', () {
        final unmodifiableMap = map.getView();
        expect(unmodifiableMap.length, equals(23));
        expect(() => unmodifiableMap..clear(), throwsUnsupportedError);
      });

      test('insert replaces an existing item', () {
        expect(map.size, equals(23));
        expect(map.insert('key12', 'strValNew'), isTrue);
        expect(map.size, equals(23));
        expect(map.lookup('key12'), equals('strValNew'));
      });

      test('insert inserts a new item', () {
        expect(map.size, equals(23));
        expect(map.insert('key24', null), isFalse);
        expect(map.size, equals(24));
        expect(map.lookup('key24'), isNull);
      });

      test('remove throws exception if the map is empty', () {
        map.clear();
        expect(() => map.remove('key1'), throwsException);
      });

      test('remove throws exception if the item does not exists', () {
        expect(() => map.remove('key0'), throwsException);
      });

      test('remove', () {
        expect(map.size, equals(23));

        map.remove('key1');
        expect(map.size, equals(22));
        expect(() => map.lookup('key1'), throwsException);

        map.remove('key6');
        expect(map.size, equals(21));
        expect(() => map.lookup('key6'), throwsException);
      });

      test('clear', () {
        expect(map.size, equals(23));
        map.clear();
        expect(map.size, equals(0));
      });

      test('toMap', () {
        final dartMap = map.toMap();
        expect(dartMap.length, equals(23));
        expect(dartMap['key8'], equals(259));
        expect(dartMap['key12'], equals('strVal'));
        expect(dartMap['key15'], equals([2.5, 0.99]));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        map = IMap.fromMap({'key1': 'icalendar', 'key2': 259});

        final iterator = map.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals('key2'));
        expect(iterator.current.value, equals(259));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key1'));
        expect(iterator.current.value, equals('icalendar'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IMap<String, Object?> (ValueSet)', () {
      late IMap<String, Object?> map;
      late Arena allocator;

      setUp(() {
        winrtInitialize();
        allocator = Arena();
        final guid = GUIDFromString(IID_ISpVoice, allocator: allocator).ref;
        final valueSet = ValueSet(allocator: allocator)
          ..insert('key1', null)
          ..insert('key2', 'strVal');
        final pPoint = allocator<Point>()
          ..ref.X = 3
          ..ref.Y = -3;
        final pRect = allocator<Rect>()
          ..ref.Height = 100
          ..ref.Width = 200
          ..ref.X = 2
          ..ref.Y = -2;
        final pSize = allocator<Size>()
          ..ref.Height = 1500
          ..ref.Width = 300;

        map = ValueSet(allocator: allocator)
          ..insert('key1', null)
          ..insert('key2', valueSet)
          ..insert('key3', true)
          ..insert('key4', DateTime(2022, 7, 11, 17, 30))
          ..insert('key5', 0.5)
          ..insert('key6', const Duration(seconds: 30))
          ..insert('key7', guid)
          ..insert('key8', 259)
          ..insert('key9', pPoint.ref)
          ..insert('key10', pRect.ref)
          ..insert('key11', pSize.ref)
          ..insert('key12', 'strVal')
          ..insert('key13', [true, false])
          ..insert('key14',
              [DateTime(2020, 7, 11, 17, 30), DateTime(2022, 7, 11, 17, 30)])
          ..insert('key15', [2.5, 0.99])
          ..insert('key16', const [Duration(hours: 1), Duration(minutes: 60)])
          ..insert('key17', [guid])
          ..insert('key18', [2022, -2022])
          ..insert('key19', [pPoint.ref])
          ..insert('key20', [pRect.ref])
          ..insert('key21', [pSize.ref])
          ..insert('key22', ['str1', 'str2']);
      });

      test('lookup fails if the map is empty', () {
        map.clear();
        expect(() => map.lookup('key1'), throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(() => map.lookup('key0'), throwsException);
      });

      test('lookup returns items', () {
        expect(map.lookup('key1'), isNull);

        final valueSetVal = map.lookup('key2');
        expect(valueSetVal, isA<IInspectable>());
        final valueSet =
            ValueSet.fromRawPointer((valueSetVal as IInspectable).ptr);
        expect(valueSet.runtimeClassName,
            equals('Windows.Foundation.Collections.ValueSet'));
        expect(valueSet.size, equals(2));
        expect(valueSet.lookup('key1'), isNull);
        expect(valueSet.lookup('key2'), equals('strVal'));

        expect(map.lookup('key3'), isTrue);

        final dateTimeVal = map.lookup('key4');
        expect(dateTimeVal, isA<DateTime>());
        final dateTime = dateTimeVal as DateTime;
        expect(dateTime.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(map.lookup('key5'), equals(0.5));
        expect(map.lookup('key6'), equals(const Duration(seconds: 30)));

        final guidVal = map.lookup('key7');
        expect(guidVal, isA<GUID>());
        final guid = guidVal as GUID;
        expect(guid.toString(), equals(IID_ISpVoice));

        expect(map.lookup('key8'), equals(259));

        final pointVal = map.lookup('key9');
        expect(pointVal, isA<Point>());
        final point = pointVal as Point;
        expect(point.X, equals(3));
        expect(point.Y, equals(-3));

        final rectVal = map.lookup('key10');
        expect(rectVal, isA<Rect>());
        final rect = rectVal as Rect;
        expect(rect.Height, equals(100));
        expect(rect.Width, equals(200));
        expect(rect.X, equals(2));
        expect(rect.Y, equals(-2));

        final sizeVal = map.lookup('key11');
        expect(sizeVal, isA<Size>());
        final size = sizeVal as Size;
        expect(size.Height, equals(1500));
        expect(size.Width, equals(300));

        expect(map.lookup('key12'), equals('strVal'));

        expect(map.lookup('key13'), equals([true, false]));

        final dateTimeListVal = map.lookup('key14');
        expect(dateTimeListVal, isA<List<DateTime>>());
        final dateTimeList = dateTimeListVal as List<DateTime>;
        expect(dateTimeList.first.millisecondsSinceEpoch,
            equals(DateTime(2020, 7, 11, 17, 30).millisecondsSinceEpoch));
        expect(dateTimeList.last.millisecondsSinceEpoch,
            equals(DateTime(2022, 7, 11, 17, 30).millisecondsSinceEpoch));

        expect(map.lookup('key15'), equals([2.5, 0.99]));

        expect(map.lookup('key16'),
            equals(const [Duration(hours: 1), Duration(minutes: 60)]));

        final guidListVal = map.lookup('key17');
        expect(guidListVal, isA<List<GUID>>());
        final guidList = guidListVal as List<GUID>;
        expect(guidList.first.toString(), equals(IID_ISpVoice));

        expect(map.lookup('key18'), equals([2022, -2022]));

        final pointListVal = map.lookup('key19');
        expect(pointListVal, isA<List<Point>>());
        final pointList = pointListVal as List<Point>;
        expect(pointList.first.X, equals(3));
        expect(pointList.first.Y, equals(-3));

        final rectListVal = map.lookup('key20');
        expect(rectListVal, isA<List<Rect>>());
        final rectList = rectListVal as List<Rect>;
        expect(rectList.first.Height, equals(100));
        expect(rectList.first.Width, equals(200));
        expect(rectList.first.X, equals(2));
        expect(rectList.first.Y, equals(-2));

        final sizeListVal = map.lookup('key21');
        expect(sizeListVal, isA<List<Size>>());
        final sizeList = sizeListVal as List<Size>;
        expect(sizeList.first.Height, equals(1500));
        expect(sizeList.first.Width, equals(300));

        expect(map.lookup('key22'), equals(['str1', 'str2']));
      });

      test('hasKey finds items', () {
        expect(map.hasKey('key1'), isTrue);
        expect(map.hasKey('key11'), isTrue);
        expect(map.hasKey('key22'), isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(map.hasKey('key0'), isFalse);
      });

      test('getView', () {
        final unmodifiableMap = map.getView();
        expect(unmodifiableMap.length, equals(22));
        expect(() => unmodifiableMap..clear(), throwsUnsupportedError);
      });

      test('insert replaces an existing item', () {
        expect(map.size, equals(22));
        expect(map.insert('key12', 'strValNew'), isTrue);
        expect(map.size, equals(22));
        expect(map.lookup('key12'), equals('strValNew'));
      });

      test('insert inserts a new item', () {
        expect(map.size, equals(22));
        expect(map.insert('key23', null), isFalse);
        expect(map.size, equals(23));
        expect(map.lookup('key23'), isNull);
      });

      test('remove throws exception if the map is empty', () {
        map.clear();
        expect(() => map.remove('key1'), throwsException);
      });

      test('remove throws exception if the item does not exists', () {
        expect(() => map.remove('key0'), throwsException);
      });

      test('remove', () {
        expect(map.size, equals(22));

        map.remove('key1');
        expect(map.size, equals(21));
        expect(() => map.lookup('key1'), throwsException);

        map.remove('key6');
        expect(map.size, equals(20));
        expect(() => map.lookup('key6'), throwsException);
      });

      test('clear', () {
        expect(map.size, equals(22));
        map.clear();
        expect(map.size, equals(0));
      });

      test('toMap', () {
        final dartMap = map.toMap();
        expect(dartMap.length, equals(22));
        expect(dartMap['key8'], equals(259));
        expect(dartMap['key12'], equals('strVal'));
        expect(dartMap['key15'], equals([2.5, 0.99]));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        map = ValueSet(allocator: allocator)
          ..insert('key1', 'icalendar')
          ..insert('key2', 259);

        final iterator = map.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals('key2'));
        expect(iterator.current.value, equals(259));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key1'));
        expect(iterator.current.value, equals('icalendar'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IMap<String, IJsonValue?>', () {
      late IMap<String, IJsonValue?> map;

      setUp(() {
        winrtInitialize();
        final jsonStr =
            '{"key1": "strVal", "key2": 97, "key3": false, "key4": [1, 2, 3], "key5": null}';
        map = JsonObject()
          ..insert('key1', JsonValue.parse(jsonStr))
          ..insert('key2', JsonValue.createBooleanValue(true))
          ..insert('key3', JsonValue.createNumberValue(2022))
          ..insert('key4', JsonValue.createStringValue('strVal'))
          ..insert('key5', null);
      });

      test('lookup fails if the map is empty', () {
        map.clear();
        expect(() => map.lookup('key1'), throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(() => map.lookup('key0'), throwsException);
      });

      test('lookup returns items', () {
        expect(
            map.lookup('key1')?.stringify(),
            equals(
                '{"key1":"strVal","key2":97,"key3":false,"key4":[1,2,3],"key5":null}'));
        expect(map.lookup('key2')?.getBoolean(), isTrue);
        expect(map.lookup('key3')?.getNumber(), equals(2022));
        expect(map.lookup('key4')?.getString(), equals('strVal'));
        expect(map.lookup('key5')?.valueType, equals(JsonValueType.null_));
      });

      test('hasKey finds items', () {
        expect(map.hasKey('key1'), isTrue);
        expect(map.hasKey('key2'), isTrue);
        expect(map.hasKey('key3'), isTrue);
        expect(map.hasKey('key4'), isTrue);
        expect(map.hasKey('key5'), isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(map.hasKey('key0'), isFalse);
      });

      test('getView', () {
        final unmodifiableMap = map.getView();
        expect(unmodifiableMap.length, equals(5));
        expect(() => unmodifiableMap..clear(), throwsUnsupportedError);
      });

      test('insert replaces an existing item', () {
        expect(map.size, equals(5));
        expect(map.insert('key4', JsonValue.createStringValue('strValNew')),
            isTrue);
        expect(map.size, equals(5));
        expect(map.lookup('key4')?.getString(), equals('strValNew'));
      });

      test('insert inserts a new item', () {
        expect(map.size, equals(5));
        expect(
            map.insert('key6', JsonValue.parse('{"hello": "world"}')), isFalse);
        expect(map.size, equals(6));
        expect(map.lookup('key6')?.stringify(), equals('{"hello":"world"}'));
      });

      test('remove returns normally if the map is empty', () {
        map.clear();
        expect(() => map.remove('key1'), returnsNormally);
      });

      test('remove returns normally if the item does not exists', () {
        expect(() => map.remove('key0'), returnsNormally);
      });

      test('remove', () {
        expect(map.size, equals(5));
        map.remove('key1');
        expect(map.size, equals(4));
        expect(() => map.lookup('key1'), throwsException);

        map.remove('key2');
        expect(map.size, equals(3));
        expect(() => map.lookup('key2'), throwsException);
      });

      test('clear', () {
        expect(map.size, equals(5));
        map.clear();
        expect(map.size, equals(0));
      });

      test('toMap', () {
        final dartMap = map.toMap();
        expect(dartMap.length, equals(5));
        expect(
            dartMap['key1']?.stringify(),
            equals(
                '{"key1":"strVal","key2":97,"key3":false,"key4":[1,2,3],"key5":null}'));
        expect(dartMap['key2']?.getBoolean(), isTrue);
        expect(dartMap['key3']?.getNumber(), equals(2022));
        expect(dartMap['key4']?.getString(), equals('strVal'));
        expect(dartMap['key5']?.valueType, equals(JsonValueType.null_));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final iterator = map.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals('key3'));
        expect(iterator.current.value?.getNumber(), equals(2022));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key5'));
        expect(iterator.current.value?.valueType, equals(JsonValueType.null_));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key2'));
        expect(iterator.current.value?.getBoolean(), isTrue);
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key1'));
        expect(
            iterator.current.value?.stringify(),
            equals(
                '{"key1":"strVal","key2":97,"key3":false,"key4":[1,2,3],"key5":null}'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key4'));
        expect(iterator.current.value?.getString(), equals('strVal'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(winrtUninitialize);
    });

    group('IMap<String, String?> (StringMap)', () {
      late IMap<String, String?> map;

      setUp(() {
        winrtInitialize();
        map = IMap()
          ..insert('key1', 'value1')
          ..insert('key2', null)
          ..insert('key3', 'value3');
      });

      test('fromMap', () {
        map = IMap.fromMap({'key1': 'value1', 'key2': null, 'key3': 'value3'});
        expect(map.lookup('key1'), equals('value1'));
        expect(map.lookup('key2'), isNull);
        expect(map.lookup('key3'), equals('value3'));
      });

      test('lookup fails if the map is empty', () {
        map.clear();
        expect(() => map.lookup('key1'), throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(() => map.lookup('key4'), throwsException);
      });

      test('lookup returns items', () {
        expect(map.lookup('key1'), equals('value1'));
        expect(map.lookup('key2'), isNull);
        expect(map.lookup('key3'), equals('value3'));
      });

      test('hasKey finds items', () {
        expect(map.hasKey('key1'), isTrue);
        expect(map.hasKey('key2'), isTrue);
        expect(map.hasKey('key3'), isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(map.hasKey('key4'), isFalse);
      });

      test('getView', () {
        final unmodifiableMap = map.getView();
        expect(unmodifiableMap.length, equals(3));
        expect(() => unmodifiableMap..clear(), throwsUnsupportedError);
      });

      test('insert replaces an existing item', () {
        expect(map.size, equals(3));
        expect(map.insert('key1', 'value1New'), isTrue);
        expect(map.size, equals(3));
        expect(map.lookup('key1'), equals('value1New'));
      });

      test('insert inserts a new item', () {
        expect(map.size, equals(3));
        expect(map.insert('key4', 'value4'), isFalse);
        expect(map.size, equals(4));
        expect(map.lookup('key4'), equals('value4'));
      });

      test('remove throws exception if the map is empty', () {
        map.clear();
        expect(() => map.remove('key0'), throwsException);
      });

      test('remove throws exception if the item does not exists', () {
        expect(() => map.remove('key4'), throwsException);
      });

      test('remove', () {
        expect(map.size, equals(3));
        map.remove('key1');
        expect(map.size, equals(2));
        expect(() => map.lookup('key1'), throwsException);

        map.remove('key2');
        expect(map.size, equals(1));
        expect(() => map.lookup('key2'), throwsException);
      });

      test('clear', () {
        expect(map.size, equals(3));
        map.clear();
        expect(map.size, equals(0));
      });

      test('toMap', () {
        final dartMap = map.toMap();
        expect(dartMap.length, equals(3));
        expect(dartMap['key1'], equals('value1'));
        expect(dartMap['key2'], isNull);
        expect(dartMap['key3'], equals('value3'));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final iterator = map.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals('key3'));
        expect(iterator.current.value, equals('value3'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key2'));
        expect(iterator.current.value, isNull);
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key1'));
        expect(iterator.current.value, equals('value1'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(winrtUninitialize);
    });

    group('IMapView<String, String?> (StringMap)', () {
      late IMapView<String, String?> mapView;

      IMapView<String, String?> getView(Pointer<COMObject> ptr) {
        final retValuePtr = calloc<COMObject>();

        final hr = ptr.ref.lpVtbl.value
                .elementAt(9)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, retValuePtr);

        if (FAILED(hr)) throw WindowsException(hr);

        return IMapView.fromRawPointer(retValuePtr);
      }

      setUp(() {
        winrtInitialize();
        final map = IMap<String, String?>()
          ..insert('key1', 'value1')
          ..insert('key2', null)
          ..insert('key3', 'value3');
        mapView = getView(map.ptr);
      });

      test('lookup fails if the map is empty', () {
        final map = IMap<String, String?>();
        mapView = getView(map.ptr);
        expect(() => mapView.lookup('key1'), throwsException);
      });

      test('lookup throws exception if the item does not exists', () {
        expect(() => mapView.lookup('key4'), throwsException);
      });

      test('lookup returns items', () {
        expect(mapView.lookup('key1'), equals('value1'));
        expect(mapView.lookup('key2'), isNull);
        expect(mapView.lookup('key3'), equals('value3'));
      });

      test('hasKey finds items', () {
        expect(mapView.hasKey('key1'), isTrue);
        expect(mapView.hasKey('key2'), isTrue);
        expect(mapView.hasKey('key3'), isTrue);
      });

      test('hasKey returns false if the item does not exists', () {
        expect(mapView.hasKey('key4'), isFalse);
      });

      test('toMap', () {
        final dartMap = mapView.toMap();
        expect(dartMap.length, equals(3));
        expect(dartMap['key1'], equals('value1'));
        expect(dartMap['key2'], isNull);
        expect(dartMap['key3'], equals('value3'));
        expect(() => dartMap..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final iterator = mapView.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current.key, equals('key3'));
        expect(iterator.current.value, equals('value3'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key2'));
        expect(iterator.current.value, isNull);
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current.key, equals('key1'));
        expect(iterator.current.value, equals('value1'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(winrtUninitialize);
    });

    group('IVector<DeviceClass>', () {
      late DevicePicker picker;
      late DevicePickerFilter pickerFilter;
      late IVector<DeviceClass> vector;
      late Arena allocator;

      setUp(() {
        winrtInitialize();

        allocator = Arena();
        picker = DevicePicker(allocator: allocator);
        pickerFilter = picker.filter;
        vector = pickerFilter.supportedDeviceClasses;
      });

      test('getAt fails if the vector is empty', () {
        expect(() => vector.getAt(0), throwsException);
      });

      test('getAt throws exception if the index is out of bounds', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(() => vector.getAt(2), throwsException);
      });

      test('getAt returns elements', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(vector.getAt(0), equals(DeviceClass.audioCapture));
        expect(vector.getAt(1), equals(DeviceClass.audioRender));
      });

      test('getView', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        final list = vector.getView();
        expect(list.length, equals(2));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('indexOf finds element', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        final containsElement = vector.indexOf(DeviceClass.audioRender, pIndex);
        expect(containsElement, isTrue);
        expect(pIndex.value, equals(1));
      });

      test('indexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        final containsElement =
            vector.indexOf(DeviceClass.imageScanner, pIndex);
        expect(containsElement, isFalse);
        expect(pIndex.value, equals(0));
      });

      test('setAt throws exception if the vector is empty', () {
        expect(
            () => vector.setAt(0, DeviceClass.audioCapture), throwsException);
      });

      test('setAt throws exception if the index is out of bounds', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(
            () => vector.setAt(3, DeviceClass.imageScanner), throwsException);
      });

      test('setAt', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(vector.size, equals(2));
        vector.setAt(0, DeviceClass.imageScanner);
        expect(vector.size, equals(2));
        vector.setAt(1, DeviceClass.location);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(DeviceClass.imageScanner));
        expect(vector.getAt(1), equals(DeviceClass.location));
      });

      test('insertAt throws exception if the index is out of bounds', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(() => vector.insertAt(3, DeviceClass.imageScanner),
            throwsException);
      });

      test('insertAt', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(vector.size, equals(2));
        vector.insertAt(0, DeviceClass.imageScanner);
        expect(vector.size, equals(3));
        vector.insertAt(2, DeviceClass.location);
        expect(vector.size, equals(4));
        expect(vector.getAt(0), equals(DeviceClass.imageScanner));
        expect(vector.getAt(1), equals(DeviceClass.audioCapture));
        expect(vector.getAt(2), equals(DeviceClass.location));
        expect(vector.getAt(3), equals(DeviceClass.audioRender));
      });

      test('removeAt throws exception if the vector is empty', () {
        expect(() => vector.removeAt(0), throwsException);
      });

      test('removeAt throws exception if the index is out of bounds', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(() => vector.removeAt(3), throwsException);
      });

      test('removeAt', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender)
          ..append(DeviceClass.imageScanner)
          ..append(DeviceClass.location);
        expect(vector.size, equals(4));
        vector.removeAt(2);
        expect(vector.size, equals(3));
        expect(vector.getAt(2), equals(DeviceClass.location));
        vector.removeAt(0);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(DeviceClass.audioRender));
        vector.removeAt(1);
        expect(vector.size, equals(1));
        expect(vector.getAt(0), equals(DeviceClass.audioRender));
        vector.removeAt(0);
        expect(vector.size, equals(0));
      });

      test('append', () {
        expect(vector.size, equals(0));
        vector.append(DeviceClass.audioCapture);
        expect(vector.size, equals(1));
        vector.append(DeviceClass.audioRender);
        expect(vector.size, equals(2));
      });

      test('removeAtEnd throws exception if the vector is empty', () {
        expect(() => vector.removeAtEnd(), throwsException);
      });

      test('removeAtEnd', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(vector.size, equals(2));
        vector.removeAtEnd();
        expect(vector.size, equals(1));
      });

      test('clear', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender);
        expect(vector.size, equals(2));
        vector.clear();
        expect(vector.size, equals(0));
      });

      test('getMany returns 0 if the vector is empty', () {
        final pInt32 = allocator<Int32>();

        expect(vector.getMany(0, 1, pInt32), equals(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pInt32 = allocator<Int32>(3);

        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender)
          ..append(DeviceClass.imageScanner);
        expect(vector.getMany(0, 3, pInt32), equals(3));
        final list = pInt32.asTypedList(3);
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals(DeviceClass.audioCapture.value));
        expect(list.elementAt(1), equals(DeviceClass.audioRender.value));
        expect(list.elementAt(2), equals(DeviceClass.imageScanner.value));
      });

      test('getMany returns elements starting from index 1', () {
        final pInt32 = allocator<Int32>(2);

        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender)
          ..append(DeviceClass.imageScanner);
        expect(vector.getMany(1, 2, pInt32), equals(2));
        final list = pInt32.asTypedList(2);
        expect(list.length, equals(2));
        expect(list.elementAt(0), equals(DeviceClass.audioRender.value));
        expect(list.elementAt(1), equals(DeviceClass.imageScanner.value));
      });

      test('replaceAll', () {
        expect(vector.size, equals(0));
        vector.replaceAll([DeviceClass.audioCapture, DeviceClass.audioRender]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(DeviceClass.audioCapture));
        expect(vector.getAt(1), equals(DeviceClass.audioRender));
        vector.replaceAll([DeviceClass.imageScanner, DeviceClass.location]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(DeviceClass.imageScanner));
        expect(vector.getAt(1), equals(DeviceClass.location));
      });

      test('toList', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender)
          ..append(DeviceClass.imageScanner);
        final list = vector.toList();
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals(DeviceClass.audioCapture));
        expect(list.elementAt(1), equals(DeviceClass.audioRender));
        expect(list.elementAt(2), equals(DeviceClass.imageScanner));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        vector
          ..append(DeviceClass.audioCapture)
          ..append(DeviceClass.audioRender)
          ..append(DeviceClass.imageScanner);
        final iterator = vector.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current, equals(DeviceClass.audioCapture));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals(DeviceClass.audioRender));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals(DeviceClass.imageScanner));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        free(pickerFilter.ptr);
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVector<int>', () {
      late Printing3DMultiplePropertyMaterial material;
      late IVector<int> vector;
      late Arena allocator;

      setUp(() {
        winrtInitialize();

        allocator = Arena();
        material = Printing3DMultiplePropertyMaterial(allocator: allocator);
        vector = material.materialIndices;
      });

      test('getAt fails if the vector is empty', () {
        expect(() => vector.getAt(0), throwsException);
      });

      test('getAt throws exception if the index is out of bounds', () {
        vector
          ..append(5)
          ..append(259);
        expect(() => vector.getAt(2), throwsException);
      });

      test('getAt returns elements', () {
        vector
          ..append(5)
          ..append(259);
        expect(vector.getAt(0), equals(5));
        expect(vector.getAt(1), equals(259));
      });

      test('getView', () {
        vector
          ..append(5)
          ..append(259);
        final list = vector.getView();
        expect(list.length, equals(2));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('indexOf finds element', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append(5)
          ..append(259);
        final containsElement = vector.indexOf(259, pIndex);
        expect(containsElement, isTrue);
        expect(pIndex.value, equals(1));
      });

      test('indexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append(5)
          ..append(259);
        final containsElement = vector.indexOf(666, pIndex);
        expect(containsElement, isFalse);
        expect(pIndex.value, equals(0));
      });

      test('setAt throws exception if the vector is empty', () {
        expect(() => vector.setAt(0, 5), throwsException);
      });

      test('setAt throws exception if the index is out of bounds', () {
        vector
          ..append(5)
          ..append(259);
        expect(() => vector.setAt(3, 666), throwsException);
      });

      test('setAt', () {
        vector
          ..append(5)
          ..append(259);
        expect(vector.size, equals(2));
        vector.setAt(0, 666);
        expect(vector.size, equals(2));
        vector.setAt(1, 4294967295); // 2 ^ 32 - 1
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(666));
        expect(vector.getAt(1), equals(4294967295));
      });

      test('insertAt throws exception if the index is out of bounds', () {
        vector
          ..append(5)
          ..append(259);
        expect(() => vector.insertAt(3, 666), throwsException);
      });

      test('insertAt', () {
        vector
          ..append(5)
          ..append(259);
        expect(vector.size, equals(2));
        vector.insertAt(0, 666);
        expect(vector.size, equals(3));
        vector.insertAt(2, 4294967295);
        expect(vector.size, equals(4));
        expect(vector.getAt(0), equals(666));
        expect(vector.getAt(1), equals(5));
        expect(vector.getAt(2), equals(4294967295));
        expect(vector.getAt(3), equals(259));
      });

      test('removeAt throws exception if the vector is empty', () {
        expect(() => vector.removeAt(0), throwsException);
      });

      test('removeAt throws exception if the index is out of bounds', () {
        vector
          ..append(5)
          ..append(259);
        expect(() => vector.removeAt(3), throwsException);
      });

      test('removeAt', () {
        vector
          ..append(5)
          ..append(259)
          ..append(666)
          ..append(4294967295);
        expect(vector.size, equals(4));
        vector.removeAt(2);
        expect(vector.size, equals(3));
        expect(vector.getAt(2), equals(4294967295));
        vector.removeAt(0);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(259));
        vector.removeAt(1);
        expect(vector.size, equals(1));
        expect(vector.getAt(0), equals(259));
        vector.removeAt(0);
        expect(vector.size, equals(0));
      });

      test('append', () {
        expect(vector.size, equals(0));
        vector.append(5);
        expect(vector.size, equals(1));
        vector.append(259);
        expect(vector.size, equals(2));
      });

      test('removeAtEnd throws exception if the vector is empty', () {
        expect(() => vector.removeAtEnd(), throwsException);
      });

      test('removeAtEnd', () {
        vector
          ..append(5)
          ..append(259);
        expect(vector.size, equals(2));
        vector.removeAtEnd();
        expect(vector.size, equals(1));
      });

      test('clear', () {
        vector
          ..append(5)
          ..append(259);
        expect(vector.size, equals(2));
        vector.clear();
        expect(vector.size, equals(0));
      });

      test('getMany returns 0 if the vector is empty', () {
        final pUint32 = allocator<Uint32>();

        expect(vector.getMany(0, 1, pUint32), equals(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pUint32 = allocator<Uint32>(3);

        vector
          ..append(5)
          ..append(259)
          ..append(666);
        expect(vector.getMany(0, 3, pUint32), equals(3));
        final list = pUint32.asTypedList(vector.size);
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals(5));
        expect(list.elementAt(1), equals(259));
        expect(list.elementAt(2), equals(666));
      });

      test('getMany returns elements starting from index 1', () {
        final pUint32 = allocator<Uint32>(2);

        vector
          ..append(5)
          ..append(259)
          ..append(666);
        expect(vector.getMany(1, 2, pUint32), equals(2));
        final list = pUint32.asTypedList(2);
        expect(list.length, equals(2));
        expect(list.elementAt(0), equals(259));
        expect(list.elementAt(1), equals(666));
      });

      test('replaceAll', () {
        expect(vector.size, equals(0));
        vector.replaceAll([5, 259]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(5));
        expect(vector.getAt(1), equals(259));
        vector.replaceAll([666, 4294967295]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(666));
        expect(vector.getAt(1), equals(4294967295));
      });

      test('toList', () {
        vector
          ..append(5)
          ..append(259)
          ..append(666);
        final list = vector.toList();
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals(5));
        expect(list.elementAt(1), equals(259));
        expect(list.elementAt(2), equals(666));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        vector
          ..append(5)
          ..append(259)
          ..append(666);
        final iterator = vector.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current, equals(5));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals(259));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals(666));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVector<String>', () {
      late IFileOpenPicker picker;
      late IVector<String> vector;
      late Arena allocator;

      setUp(() {
        winrtInitialize();

        final object = CreateObject(
            'Windows.Storage.Pickers.FileOpenPicker', IID_IFileOpenPicker);
        picker = IFileOpenPicker.fromRawPointer(object);
        allocator = Arena();
        vector = picker.fileTypeFilter;
      });

      test('getAt fails if the vector is empty', () {
        expect(() => vector.getAt(0), throwsException);
      });

      test('getAt throws exception if the index is out of bounds', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(() => vector.getAt(2), throwsException);
      });

      test('getAt returns elements', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(vector.getAt(0), equals('.jpg'));
        expect(vector.getAt(1), equals('.jpeg'));
      });

      test('getView', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        final list = vector.getView();
        expect(list.length, equals(2));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('indexOf finds element', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append('.jpg')
          ..append('.jpeg');
        final containsElement = vector.indexOf('.jpeg', pIndex);
        expect(containsElement, isTrue);
        expect(pIndex.value, equals(1));
      });

      test('indexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();

        vector
          ..append('.jpg')
          ..append('.jpeg');
        final containsElement = vector.indexOf('.png', pIndex);
        expect(containsElement, isFalse);
        expect(pIndex.value, equals(0));
      });

      test('setAt throws exception if the vector is empty', () {
        expect(() => vector.setAt(0, '.jpg'), throwsException);
      });

      test('setAt throws exception if the index is out of bounds', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(() => vector.setAt(3, '.png'), throwsException);
      });

      test('setAt', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(vector.size, equals(2));
        vector.setAt(0, '.png');
        expect(vector.size, equals(2));
        vector.setAt(1, '.gif');
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals('.png'));
        expect(vector.getAt(1), equals('.gif'));
      });

      test('insertAt throws exception if the index is out of bounds', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(() => vector.insertAt(3, '.png'), throwsException);
      });

      test('insertAt', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(vector.size, equals(2));
        vector.insertAt(0, '.png');
        expect(vector.size, equals(3));
        vector.insertAt(2, '.gif');
        expect(vector.size, equals(4));
        expect(vector.getAt(0), equals('.png'));
        expect(vector.getAt(1), equals('.jpg'));
        expect(vector.getAt(2), equals('.gif'));
        expect(vector.getAt(3), equals('.jpeg'));
      });

      test('removeAt throws exception if the vector is empty', () {
        expect(() => vector.removeAt(0), throwsException);
      });

      test('removeAt throws exception if the index is out of bounds', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(() => vector.removeAt(3), throwsException);
      });

      test('removeAt', () {
        vector
          ..append('.jpg')
          ..append('.jpeg')
          ..append('.png')
          ..append('.gif');
        expect(vector.size, equals(4));
        vector.removeAt(2);
        expect(vector.size, equals(3));
        expect(vector.getAt(2), equals('.gif'));
        vector.removeAt(0);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals('.jpeg'));
        vector.removeAt(1);
        expect(vector.size, equals(1));
        expect(vector.getAt(0), equals('.jpeg'));
        vector.removeAt(0);
        expect(vector.size, equals(0));
      });

      test('append', () {
        expect(vector.size, equals(0));
        vector.append('.jpg');
        expect(vector.size, equals(1));
        vector.append('.jpeg');
        expect(vector.size, equals(2));
      });

      test('removeAtEnd throws exception if the vector is empty', () {
        expect(() => vector.removeAtEnd(), throwsException);
      });

      test('removeAtEnd', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(vector.size, equals(2));
        vector.removeAtEnd();
        expect(vector.size, equals(1));
      });

      test('clear', () {
        vector
          ..append('.jpg')
          ..append('.jpeg');
        expect(vector.size, equals(2));
        vector.clear();
        expect(vector.size, equals(0));
      });

      test('getMany returns 0 if the vector is empty', () {
        final pHString = allocator<HSTRING>();

        expect(vector.getMany(0, 1, pHString), equals(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pHString = allocator<HSTRING>(3);

        vector
          ..append('.jpg')
          ..append('.jpeg')
          ..append('.png');
        expect(vector.getMany(0, 3, pHString), equals(3));
        expect(convertFromHString(pHString[0]), equals('.jpg'));
        expect(convertFromHString(pHString[1]), equals('.jpeg'));
        expect(convertFromHString(pHString[2]), equals('.png'));
      });

      test('getMany returns elements starting from index 1', () {
        final pHString = allocator<HSTRING>(2);

        vector
          ..append('.jpg')
          ..append('.jpeg')
          ..append('.png');
        expect(vector.getMany(1, 2, pHString), equals(2));
        expect(convertFromHString(pHString[0]), equals('.jpeg'));
        expect(convertFromHString(pHString[1]), equals('.png'));
      });

      test('replaceAll', () {
        expect(vector.size, equals(0));
        vector.replaceAll(['.jpg', '.jpeg']);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals('.jpg'));
        expect(vector.getAt(1), equals('.jpeg'));
        vector.replaceAll(['.png', '.gif']);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals('.png'));
        expect(vector.getAt(1), equals('.gif'));
      });

      test('toList', () {
        vector
          ..append('.jpg')
          ..append('.jpeg')
          ..append('.png');
        final list = vector.toList();
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals('.jpg'));
        expect(list.elementAt(1), equals('.jpeg'));
        expect(list.elementAt(2), equals('.png'));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        vector
          ..append('.jpg')
          ..append('.jpeg')
          ..append('.png');
        final iterator = vector.first();
        expect(iterator.hasCurrent, isTrue);
        expect(iterator.current, equals('.jpg'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals('.jpeg'));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals('.png'));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        free(picker.ptr);
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVector<Uri>', () {
      late IVector<Uri> vector;
      late Arena allocator;

      IVector<Uri> getServerUris(Pointer<COMObject> ptr, Allocator allocator) {
        final retValuePtr = allocator<COMObject>();

        final hr = ptr.ref.vtable
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, retValuePtr);

        if (FAILED(hr)) throw WindowsException(hr);

        return IVector.fromRawPointer(retValuePtr);
      }

      setUp(() {
        winrtInitialize();
        // ignore: constant_identifier_names
        const IID_IVpnPlugInProfile = '{0EDF0DA4-4F00-4589-8D7B-4BF988F6542C}';
        final object = CreateObject(
            'Windows.Networking.Vpn.VpnPlugInProfile', IID_IVpnPlugInProfile);
        allocator = Arena();
        vector = getServerUris(object, allocator);
      });

      test('getAt fails if the vector is empty', () {
        expect(() => vector.getAt(0), throwsException);
      });

      test('getAt throws exception if the index is out of bounds', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(() => vector.getAt(2), throwsException);
      });

      test('getAt returns elements', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(vector.getAt(0), equals(Uri.parse('https://dart.dev/overview')));
        expect(vector.getAt(1), equals(Uri.parse('https://dart.dev/docs')));
      });

      test('getView', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        final list = vector.getView();
        expect(list.length, equals(2));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('setAt throws exception if the vector is empty', () {
        expect(() => vector.setAt(0, Uri.parse('https://dart.dev/overview')),
            throwsException);
      });

      test('setAt throws exception if the index is out of bounds', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(
            () => vector.setAt(3, Uri.parse('https://flutter.dev/development')),
            throwsException);
      });

      test('setAt', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(vector.size, equals(2));
        vector.setAt(0, Uri.parse('https://flutter.dev/development'));
        expect(vector.size, equals(2));
        vector.setAt(1, Uri.parse('https://flutter.dev/multi-platform'));
        expect(vector.size, equals(2));
        expect(vector.getAt(0),
            equals(Uri.parse('https://flutter.dev/development')));
        expect(vector.getAt(1),
            equals(Uri.parse('https://flutter.dev/multi-platform')));
      });

      test('insertAt throws exception if the index is out of bounds', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(
            () => vector.insertAt(
                3, Uri.parse('https://flutter.dev/development')),
            throwsException);
      });

      test('insertAt', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(vector.size, equals(2));
        vector.insertAt(0, Uri.parse('https://flutter.dev/development'));
        expect(vector.size, equals(3));
        vector.insertAt(2, Uri.parse('https://flutter.dev/multi-platform'));
        expect(vector.size, equals(4));
        expect(vector.getAt(0),
            equals(Uri.parse('https://flutter.dev/development')));
        expect(vector.getAt(1), equals(Uri.parse('https://dart.dev/overview')));
        expect(vector.getAt(2),
            equals(Uri.parse('https://flutter.dev/multi-platform')));
        expect(vector.getAt(3), equals(Uri.parse('https://dart.dev/docs')));
      });

      test('removeAt throws exception if the vector is empty', () {
        expect(() => vector.removeAt(0), throwsException);
      });

      test('removeAt throws exception if the index is out of bounds', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(() => vector.removeAt(3), throwsException);
      });

      test('removeAt', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'))
          ..append(Uri.parse('https://flutter.dev/development'))
          ..append(Uri.parse('https://flutter.dev/multi-platform'));
        expect(vector.size, equals(4));
        vector.removeAt(2);
        expect(vector.size, equals(3));
        expect(vector.getAt(2),
            equals(Uri.parse('https://flutter.dev/multi-platform')));
        vector.removeAt(0);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(Uri.parse('https://dart.dev/docs')));
        vector.removeAt(1);
        expect(vector.size, equals(1));
        expect(vector.getAt(0), equals(Uri.parse('https://dart.dev/docs')));
        vector.removeAt(0);
        expect(vector.size, equals(0));
      });

      test('append', () {
        expect(vector.size, equals(0));
        vector.append(Uri.parse('https://dart.dev/overview'));
        expect(vector.size, equals(1));
        vector.append(Uri.parse('https://dart.dev/docs'));
        expect(vector.size, equals(2));
      });

      test('removeAtEnd throws exception if the vector is empty', () {
        expect(() => vector.removeAtEnd(), throwsException);
      });

      test('removeAtEnd', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(vector.size, equals(2));
        vector.removeAtEnd();
        expect(vector.size, equals(1));
      });

      test('clear', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'));
        expect(vector.size, equals(2));
        vector.clear();
        expect(vector.size, equals(0));
      });

      test('getMany returns 0 if the vector is empty', () {
        final pCOMObject = allocator<COMObject>();

        expect(vector.getMany(0, 1, pCOMObject), equals(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pCOMObject = allocator<COMObject>(2);

        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'))
          ..append(Uri.parse('https://flutter.dev/development'));
        expect(vector.getMany(0, 3, pCOMObject), equals(3));
        expect(winrt_uri.Uri.fromRawPointer(pCOMObject.elementAt(0)).toString(),
            equals('https://dart.dev/overview'));
        expect(winrt_uri.Uri.fromRawPointer(pCOMObject.elementAt(1)).toString(),
            equals('https://dart.dev/docs'));
        expect(winrt_uri.Uri.fromRawPointer(pCOMObject.elementAt(2)).toString(),
            equals('https://flutter.dev/development'));
      });

      test('getMany returns elements starting from index 1', () {
        final pCOMObject = allocator<COMObject>(2);

        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'))
          ..append(Uri.parse('https://flutter.dev/development'));
        expect(vector.getMany(1, 2, pCOMObject), equals(2));
        expect(winrt_uri.Uri.fromRawPointer(pCOMObject.elementAt(0)).toString(),
            equals('https://dart.dev/docs'));
        expect(winrt_uri.Uri.fromRawPointer(pCOMObject.elementAt(1)).toString(),
            equals('https://flutter.dev/development'));
      });

      test('replaceAll', () {
        expect(vector.size, equals(0));
        vector.replaceAll([
          Uri.parse('https://dart.dev/overview'),
          Uri.parse('https://dart.dev/docs')
        ]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0), equals(Uri.parse('https://dart.dev/overview')));
        expect(vector.getAt(1), equals(Uri.parse('https://dart.dev/docs')));
        vector.replaceAll([
          Uri.parse('https://flutter.dev/development'),
          Uri.parse('https://flutter.dev/multi-platform')
        ]);
        expect(vector.size, equals(2));
        expect(vector.getAt(0),
            equals(Uri.parse('https://flutter.dev/development')));
        expect(vector.getAt(1),
            equals(Uri.parse('https://flutter.dev/multi-platform')));
      });

      test('toList', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'))
          ..append(Uri.parse('https://flutter.dev/development'));
        final list = vector.toList();
        expect(list.length, equals(3));
        expect(
            list.elementAt(0), equals(Uri.parse('https://dart.dev/overview')));
        expect(list.elementAt(1), equals(Uri.parse('https://dart.dev/docs')));
        expect(list.elementAt(2),
            equals(Uri.parse('https://flutter.dev/development')));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        vector
          ..append(Uri.parse('https://dart.dev/overview'))
          ..append(Uri.parse('https://dart.dev/docs'))
          ..append(Uri.parse('https://flutter.dev/development'));
        final iterator = vector.first();
        expect(iterator.hasCurrent, isTrue);
        expect(
            iterator.current, equals(Uri.parse('https://dart.dev/overview')));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, equals(Uri.parse('https://dart.dev/docs')));
        expect(iterator.moveNext(), isTrue);
        expect(iterator.current,
            equals(Uri.parse('https://flutter.dev/development')));
        expect(iterator.moveNext(), isFalse);
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVectorView<String>', () {
      late Arena allocator;
      late IVectorView<String> vectorView;

      IVectorView<String> getLanguages(
          Pointer<COMObject> ptr, Allocator allocator) {
        final retValuePtr = allocator<COMObject>();

        final hr = ptr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
              Pointer,
              Pointer<COMObject>,
            )>>>()
            .value
            .asFunction<
                int Function(
              Pointer,
              Pointer<COMObject>,
            )>()(ptr.ref.lpVtbl, retValuePtr);

        if (FAILED(hr)) throw WindowsException(hr);

        return IVectorView.fromRawPointer(retValuePtr);
      }

      setUp(() {
        winrtInitialize();

        allocator = Arena();
        final object = ActivateClass('Windows.Globalization.Calendar',
            allocator: allocator);
        allocator = Arena();
        vectorView = getLanguages(object, allocator);
      });

      test('getAt throws exception if the index is out of bounds', () {
        expect(() => vectorView.getAt(20), throwsException);
      });

      test('getAt returns elements', () {
        final element = vectorView.getAt(0);
        // Should be something like en-US
        expect(element[2], equals('-'));
        expect(element.length, equals(5));
      });

      test('indexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();
        final containsElement = vectorView.indexOf('xx-xx', pIndex);
        expect(containsElement, isFalse);
        expect(pIndex.value, equals(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pHString = allocator<HSTRING>(vectorView.size);

        expect(vectorView.getMany(0, vectorView.size, pHString),
            greaterThanOrEqualTo(1));
        // Should be something like en-US
        expect(convertFromHString(pHString[0])[2], equals('-'));
        expect(convertFromHString(pHString[0]).length, equals(5));
      });

      test('toList', () {
        final list = vectorView.toList();
        expect(list.length, greaterThanOrEqualTo(1));
        // Should be something like en-US
        expect(list.first[2], equals('-'));
        expect(list.first.length, equals(5));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final list = vectorView.toList();
        final iterator = vectorView.first();

        for (var i = 0; i < list.length; i++) {
          expect(iterator.hasCurrent, isTrue);
          // Should be something like en-US
          expect(iterator.current[2], equals('-'));
          // MoveNext() should return true except for the last iteration
          expect(iterator.moveNext(), i < list.length - 1);
        }
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVectorView<IHostName>', () {
      late Arena allocator;
      late IVectorView<IHostName> vectorView;

      IVectorView<IHostName> getHostNames(
          Pointer<COMObject> ptr, Allocator allocator) {
        final retValuePtr = allocator<COMObject>();

        final hr = ptr.ref.vtable
                .elementAt(9)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, retValuePtr);

        if (FAILED(hr)) throw WindowsException(hr);

        return IVectorView.fromRawPointer(retValuePtr,
            creator: IHostName.fromRawPointer);
      }

      setUp(() {
        winrtInitialize();

        allocator = Arena();
        final object = CreateActivationFactory(
            'Windows.Networking.Connectivity.NetworkInformation',
            IID_INetworkInformationStatics,
            allocator: allocator);
        vectorView = getHostNames(object, allocator);
      });

      test('getAt throws exception if the index is out of bounds', () {
        expect(() => vectorView.getAt(20), throwsException);
      });

      test('getAt returns elements', () {
        final element = vectorView.getAt(0);
        expect(element.displayName, isNotEmpty);
      });

      test('indexOf finds element', () {
        final pIndex = allocator<Uint32>();
        final hostName = vectorView.getAt(0);
        final containsElement = vectorView.indexOf(hostName, pIndex);
        expect(containsElement, isTrue);
        expect(pIndex.value, greaterThanOrEqualTo(0));
      });

      test('getMany returns elements starting from index 0', () {
        final pCOMObject = allocator<COMObject>(vectorView.size);
        expect(vectorView.getMany(0, vectorView.size, pCOMObject),
            greaterThanOrEqualTo(1));
      });

      test('toList', () {
        final list = vectorView.toList();
        expect(list.length, greaterThanOrEqualTo(1));
        expect(() => list..clear(), throwsUnsupportedError);
      });

      test('first', () {
        final list = vectorView.toList();
        final iterator = vectorView.first();

        for (var i = 0; i < list.length; i++) {
          expect(iterator.hasCurrent, isTrue);
          expect(iterator.current.rawName, equals(list[i].rawName));
          // moveNext() should return true except for the last iteration
          expect(iterator.moveNext(), i < list.length - 1);
        }
      });

      tearDown(() {
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });
  }
}
