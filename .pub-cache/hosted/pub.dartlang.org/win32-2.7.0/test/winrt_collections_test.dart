// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

// Exhaustively test the WinRT Collections to make sure constructors,
// properties and methods are working correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    group('IVector<String>', () {
      late IFileOpenPicker picker;
      late IVector<String> vector;
      late Arena allocator;

      setUp(() {
        winrtInitialize();

        final object = CreateObject(
            'Windows.Storage.Pickers.FileOpenPicker', IID_IFileOpenPicker);
        picker = IFileOpenPicker(object);
        allocator = Arena();
        vector = picker.FileTypeFilter;
      });

      test('GetAt fails if the vector is empty', () {
        expect(() => vector.GetAt(0), throwsException);
      });

      test('GetAt throws exception if the index is out of bounds', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(() => vector.GetAt(2), throwsException);
      });

      test('GetAt returns elements', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(vector.GetAt(0), equals('.jpg'));
        expect(vector.GetAt(1), equals('.jpeg'));
      });

      test('GetView', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        final list = vector.GetView;
        expect(list.length, equals(2));
      });

      test('IndexOf finds element', () {
        final pIndex = allocator<Uint32>();

        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        final containsElement = vector.IndexOf('.jpeg', pIndex);
        expect(containsElement, true);
        expect(pIndex.value, equals(1));
      });

      test('IndexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();

        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        final containsElement = vector.IndexOf('.png', pIndex);
        expect(containsElement, false);
        expect(pIndex.value, equals(0));
      });

      test('SetAt throws exception if the vector is empty', () {
        expect(() => vector.SetAt(0, '.jpg'), throwsException);
      });

      test('SetAt throws exception if the index is out of bounds', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(() => vector.SetAt(3, '.png'), throwsException);
      });

      test('SetAt', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(vector.Size, equals(2));
        vector.SetAt(0, '.png');
        expect(vector.Size, equals(2));
        vector.SetAt(1, '.gif');
        expect(vector.Size, equals(2));
        expect(vector.GetAt(0), equals('.png'));
        expect(vector.GetAt(1), equals('.gif'));
      });

      test('InsertAt throws exception if the index is out of bounds', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(() => vector.InsertAt(3, '.png'), throwsException);
      });

      test('InsertAt', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(vector.Size, equals(2));
        vector.InsertAt(0, '.png');
        expect(vector.Size, equals(3));
        vector.InsertAt(2, '.gif');
        expect(vector.Size, equals(4));
        expect(vector.GetAt(0), equals('.png'));
        expect(vector.GetAt(1), equals('.jpg'));
        expect(vector.GetAt(2), equals('.gif'));
        expect(vector.GetAt(3), equals('.jpeg'));
      });

      test('RemoveAt throws exception if the vector is empty', () {
        expect(() => vector.RemoveAt(0), throwsException);
      });

      test('RemoveAt throws exception if the index is out of bounds', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(() => vector.RemoveAt(3), throwsException);
      });

      test('RemoveAt', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg')
          ..Append('.png')
          ..Append('.gif');
        expect(vector.Size, equals(4));
        vector.RemoveAt(2);
        expect(vector.Size, equals(3));
        expect(vector.GetAt(2), equals('.gif'));
        vector.RemoveAt(0);
        expect(vector.Size, equals(2));
        expect(vector.GetAt(0), equals('.jpeg'));
        vector.RemoveAt(1);
        expect(vector.Size, equals(1));
        expect(vector.GetAt(0), equals('.jpeg'));
        vector.RemoveAt(0);
        expect(vector.Size, equals(0));
      });

      test('Append', () {
        expect(vector.Size, equals(0));
        vector.Append('.jpg');
        expect(vector.Size, equals(1));
        vector.Append('.jpeg');
        expect(vector.Size, equals(2));
      });

      test('RemoveAtEnd throws exception if the vector is empty', () {
        expect(() => vector.RemoveAtEnd(), throwsException);
      });

      test('RemoveAtEnd', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(vector.Size, equals(2));
        vector.RemoveAtEnd();
        expect(vector.Size, equals(1));
      });

      test('Clear', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg');
        expect(vector.Size, equals(2));
        vector.Clear();
        expect(vector.Size, equals(0));
      });

      test('GetMany returns 0 if the vector is empty', () {
        final pHString = allocator<HSTRING>(1);

        expect(vector.GetMany(0, pHString), equals(0));
      });

      test('GetMany returns elements starting from index 0', () {
        final pHString = allocator<HSTRING>(3);

        vector
          ..Append('.jpg')
          ..Append('.jpeg')
          ..Append('.png');
        expect(vector.GetMany(0, pHString), equals(3));
        final list = pHString.toList(length: vector.Size);
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals('.jpg'));
        expect(list.elementAt(1), equals('.jpeg'));
        expect(list.elementAt(2), equals('.png'));
      });

      test('GetMany returns elements starting from index 1', () {
        final pHString = allocator<HSTRING>(2);

        vector
          ..Append('.jpg')
          ..Append('.jpeg')
          ..Append('.png');
        expect(vector.GetMany(1, pHString), equals(2));
        final list = pHString.toList(length: 2);
        expect(list.length, equals(2));
        expect(list.elementAt(0), equals('.jpeg'));
        expect(list.elementAt(1), equals('.png'));
      });

      test('ReplaceAll', () {
        expect(vector.Size, equals(0));
        vector.ReplaceAll(['.jpg', '.jpeg']);
        expect(vector.Size, equals(2));
        expect(vector.GetAt(0), equals('.jpg'));
        expect(vector.GetAt(1), equals('.jpeg'));
        vector.ReplaceAll(['.png', '.gif']);
        expect(vector.Size, equals(2));
        expect(vector.GetAt(0), equals('.png'));
        expect(vector.GetAt(1), equals('.gif'));
      });

      test('toList', () {
        vector
          ..Append('.jpg')
          ..Append('.jpeg')
          ..Append('.png');
        final list = vector.toList();
        expect(list.length, equals(3));
        expect(list.elementAt(0), equals('.jpg'));
        expect(list.elementAt(1), equals('.jpeg'));
        expect(list.elementAt(2), equals('.png'));
      });

      tearDown(() {
        free(picker.ptr);
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVectorView<String>', () {
      late ICalendar calendar;
      late IVectorView<String> vectorView;
      late Arena allocator;

      IVectorView<String> Languages(
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

        return IVectorView(retValuePtr, allocator: allocator);
      }

      setUp(() {
        winrtInitialize();

        calendar = Calendar();
        allocator = Arena();
        vectorView = Languages(calendar.ptr, allocator);
      });

      test('GetAt throws exception if the index is out of bounds', () {
        expect(() => vectorView.GetAt(20), throwsException);
      });

      test('GetAt returns elements', () {
        final element = vectorView.GetAt(0);
        // Should be something like en-US
        expect(element[2], equals('-'));
        expect(element.length, equals(5));
      });

      test('IndexOf returns 0 if the element is not found', () {
        final pIndex = allocator<Uint32>();
        final containsElement = vectorView.IndexOf('xx-xx', pIndex);
        expect(containsElement, false);
        expect(pIndex.value, equals(0));
      });

      test('GetMany returns elements starting from index 0', () {
        final pHString = allocator<HSTRING>(vectorView.Size);

        expect(vectorView.GetMany(0, pHString), greaterThanOrEqualTo(1));
        final list = pHString.toList(length: vectorView.Size);
        expect(list.length, greaterThanOrEqualTo(1));
        // Should be something like en-US
        expect(list.first[2], equals('-'));
        expect(list.first.length, equals(5));
      });

      test('toList', () {
        final list = vectorView.toList();
        expect(list.length, greaterThanOrEqualTo(1));
        // Should be something like en-US
        expect(list.first[2], equals('-'));
        expect(list.first.length, equals(5));
      });

      tearDown(() {
        free(calendar.ptr);
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });

    group('IVectorView<IHostName>', () {
      late INetworkInformationStatics networkInformation;
      late IVectorView<IHostName> vectorView;
      late Arena allocator;

      IVectorView<IHostName> GetHostNames(
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
            )>()(
          ptr.ref.lpVtbl,
          retValuePtr,
        );

        if (FAILED(hr)) throw WindowsException(hr);

        return IVectorView(retValuePtr,
            creator: IHostName.new, allocator: allocator);
      }

      setUp(() {
        winrtInitialize();

        final object = CreateActivationFactory(
            'Windows.Networking.Connectivity.NetworkInformation',
            IID_INetworkInformationStatics);
        networkInformation = INetworkInformationStatics(object);
        allocator = Arena();
        vectorView = GetHostNames(object, allocator);
      });

      test('GetAt throws exception if the index is out of bounds', () {
        expect(() => vectorView.GetAt(20), throwsException);
      });

      test('GetAt returns elements', () {
        final element = vectorView.GetAt(0);
        expect(element.DisplayName, isNotEmpty);
      });

      test('IndexOf finds element', () {
        final pIndex = allocator<Uint32>();
        final hostName = vectorView.GetAt(0);
        final containsElement = vectorView.IndexOf(hostName, pIndex);
        expect(containsElement, true);
        expect(pIndex.value, greaterThanOrEqualTo(0));
      });

      test('GetMany returns elements starting from index 0', () {
        final pCOMObject = allocator<COMObject>(vectorView.Size);
        expect(vectorView.GetMany(0, pCOMObject), greaterThanOrEqualTo(1));
        final list = pCOMObject.toList<IHostName>(IHostName.new,
            length: vectorView.Size);
        expect(list.length, greaterThanOrEqualTo(1));
      });

      test('toList', () {
        final list = vectorView.toList();
        expect(list.length, greaterThanOrEqualTo(1));
      });

      tearDown(() {
        free(networkInformation.ptr);
        allocator.releaseAll(reuse: true);
        winrtUninitialize();
      });
    });
  }
}
