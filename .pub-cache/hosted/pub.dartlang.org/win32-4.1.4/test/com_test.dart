@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

void main() {
  test('GUID creation', () {
    final guid = calloc<GUID>();
    final hr = CoCreateGuid(guid);
    expect(hr, equals(S_OK));

    final guid2 = calloc<GUID>()..ref.setGUID(guid.ref.toString());
    expect(guid.ref.toString(), equals(guid2.ref.toString()));

    free(guid2);
    free(guid);
  });

  test('GUID creation failure', () {
    final guid = calloc<GUID>();
    try {
      // Note the rogue 'X' here
      expect(() => guid.ref.setGUID('{X161CA9B-9409-4A77-7327-8B8D3363C6B9}'),
          throwsA(anyOf(isA<FormatException>(), isA<AssertionError>())));
    } finally {
      free(guid);
    }
  });

  test('CLSIDFromString', () {
    final guid = calloc<GUID>();
    final pCLSID = CLSID_FileSaveDialog.toNativeUtf16();

    final hr = CLSIDFromString(pCLSID, guid);
    expect(hr, equals(S_OK));

    expect(guid.ref.toString(), equalsIgnoringCase(CLSID_FileSaveDialog));

    free(pCLSID);
    free(guid);
  });

  test('IIDFromString', () {
    final guid = calloc<GUID>();
    final pIID = IID_IShellItem2.toNativeUtf16();

    final hr = IIDFromString(pIID, guid);
    expect(hr, equals(S_OK));

    expect(guid.ref.toString(), equalsIgnoringCase(IID_IShellItem2));

    free(pIID);
    free(guid);
  });

  test('Create COM object without calling CoInitialize should fail', () {
    expect(
        FileOpenDialog.createInstance,
        throwsA(isA<WindowsException>()
            .having((e) => e.hr, 'hr', equals(CO_E_NOTINITIALIZED))
            .having((e) => e.toString(), 'message',
                contains('CoInitialize has not been called.'))));
  });

  test('Create COM object with CoCreateInstance', () {
    var hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    expect(hr, equals(S_OK));

    final ptr = calloc<Pointer>();
    final clsid = GUIDFromString(CLSID_FileSaveDialog);
    final iid = GUIDFromString(IID_IFileSaveDialog);

    hr = CoCreateInstance(clsid, nullptr, CLSCTX_ALL, iid, ptr);
    expect(hr, equals(S_OK));
    expect(ptr.address, isNonZero);

    free(iid);
    free(clsid);
    free(ptr);

    CoUninitialize();
  });

  test('Create COM object with CoGetClassObject', () {
    var hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    expect(hr, equals(S_OK));

    final ptrFactory = calloc<COMObject>();
    final ptrSaveDialog = calloc<COMObject>();
    final clsid = GUIDFromString(CLSID_FileSaveDialog);
    final iidClassFactory = GUIDFromString(IID_IClassFactory);
    final iidFileSaveDialog = GUIDFromString(IID_IFileSaveDialog);

    hr = CoGetClassObject(
        clsid, CLSCTX_ALL, nullptr, iidClassFactory, ptrFactory.cast());
    expect(hr, equals(S_OK));
    expect(ptrFactory.address, isNonZero);

    final classFactory = IClassFactory(ptrFactory);
    hr = classFactory.createInstance(
        nullptr, iidFileSaveDialog, ptrSaveDialog.cast());
    expect(hr, equals(S_OK));
    expect(ptrSaveDialog.address, isNonZero);

    free(iidFileSaveDialog);
    free(iidClassFactory);
    free(clsid);
    free(ptrSaveDialog);
    classFactory.release();

    CoUninitialize();
  });

  test('Create COM object through class method', () {
    final hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    expect(hr, equals(S_OK));

    expect(FileOpenDialog.createInstance, returnsNormally);

    CoUninitialize();
  });

  group('COM object tests', () {
    late FileOpenDialog dialog;

    setUp(() {
      final hr = CoInitializeEx(
          nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
      if (FAILED(hr)) throw WindowsException(hr);

      dialog = FileOpenDialog.createInstance();
    });

    test('Dialog object exists', () {
      expect(dialog.ptr.address, isNonZero);
    });

    test('Can cast to IUnknown', () {
      final unk = IUnknown.from(dialog);
      expect(unk.ptr.address, isNonZero);

      unk.release();
    });

    test('Cast to random interface fails', () {
      expect(
          () => dialog.toInterface(IID_IDesktopWallpaper),
          throwsA(isA<WindowsException>()
              .having((e) => e.hr, 'hr', equals(E_NOINTERFACE))
              .having((e) => e.toString(), 'message',
                  contains('No such interface supported'))));
    });

    test('AddRef / Release', () {
      var refs = dialog.addRef();
      expect(refs, equals(2));

      refs = dialog.addRef();
      expect(refs, equals(3));

      refs = dialog.release();
      expect(refs, equals(2));

      refs = dialog.release();
      expect(refs, equals(1));
    });

    tearDown(() {
      dialog.release();
      CoUninitialize();
    });
  });

  group('COM object casting using methods', () {
    late FileOpenDialog dialog;

    setUp(() {
      final hr = CoInitializeEx(
          nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
      if (FAILED(hr)) throw WindowsException(hr);

      dialog = FileOpenDialog.createInstance();
    });

    test('Can cast to various supported interfaces', () {
      expect(() => IUnknown.from(dialog), returnsNormally);
      expect(() => IModalWindow.from(dialog), returnsNormally);
      expect(() => IFileOpenDialog.from(dialog), returnsNormally);
      expect(() => IFileDialog.from(dialog), returnsNormally);
      expect(() => IFileDialog2.from(dialog), returnsNormally);
    });

    test('Cannot cast to various unsupported interfaces', () {
      expect(
          () => IShellItem.from(dialog),
          throwsA(isA<WindowsException>()
              .having((e) => e.hr, 'hr', equals(E_NOINTERFACE))));
      expect(
          () => ISpeechObjectToken.from(dialog),
          throwsA(isA<WindowsException>()
              .having((e) => e.hr, 'hr', equals(E_NOINTERFACE))));
    });

    tearDown(() {
      dialog.release();
      CoUninitialize();
    });
  });
}
