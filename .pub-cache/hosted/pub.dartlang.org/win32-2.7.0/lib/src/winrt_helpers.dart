// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions to minimize ceremony when calling WinRT APIs.

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'api_ms_win_core_winrt_l1_1_0.dart';
import 'api_ms_win_core_winrt_string_l1_1_0.dart';
import 'com/iinspectable.dart';
import 'combase.dart';
import 'constants.dart';
import 'exceptions.dart';
import 'guid.dart';
import 'macros.dart';
import 'ole32.dart';
import 'types.dart';
import 'utils.dart';

/// Initializes the Windows Runtime on the current thread with a single-threaded
/// concurrency model.
///
/// {@category winrt}
void winrtInitialize() => RoInitialize(RO_INIT_TYPE.RO_INIT_SINGLETHREADED);

/// Closes the Windows Runtime on the current thread.
///
/// {@category winrt}
void winrtUninitialize() => RoUninitialize();

extension WinRTStringConversion on Pointer<HSTRING> {
  /// Gets the Dart string at the handle pointed to by this object.
  String toDartString() => convertFromHString(value);
}

/// Takes a `HSTRING` (a WinRT String handle), and converts it to a Dart
/// `String`.
///
/// {@category winrt}
String convertFromHString(int hstring) =>
    WindowsGetStringRawBuffer(hstring, nullptr).toDartString();

/// Takes a Dart String and converts it to an `HSTRING` (a WinRT String),
/// returning an integer handle.
///
/// The caller is responsible for deleting the `HSTRING` when it is no longer
/// used, through a call to `WindowsDeleteString(HSTRING hstr)`, which
/// decrements the reference count of that string. If the reference count
/// reaches 0, the Windows Runtime deallocates the buffer.
///
/// {@category winrt}
int convertToHString(String string) {
  final hString = calloc<HSTRING>();
  final stringPtr = string.toNativeUtf16();
  // Create a HSTRING representing the object
  try {
    final hr = WindowsCreateString(stringPtr, string.length, hString);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    } else {
      return hString.value;
    }
  } finally {
    free(stringPtr);
  }
}

/// Creates a WinRT object.
///
/// ```dart
/// final object = CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
/// final calendar = ICalendar(object);
/// ```
///
/// {@category winrt}
Pointer<COMObject> CreateObject(String className, String iid) {
  final hstrClass = calloc<HSTRING>();
  final lpClassName = className.toNativeUtf16();
  final inspectablePtr = calloc<COMObject>();
  final riid = calloc<GUID>();
  final classPtr = calloc<Pointer>();
  final iidPtr = iid.toNativeUtf16();
  final classNamePtr = className.toNativeUtf16();

  try {
    // Create a HSTRING representing the object
    var hr = WindowsCreateString(classNamePtr, className.length, hstrClass);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }
    // Activates the specified Windows Runtime class. This returns the WinRT
    // IInspectable interface, which is a subclass of IUnknown.
    hr = RoActivateInstance(hstrClass.value, inspectablePtr.cast());
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    // Create an IID for the interface required
    hr = IIDFromString(iidPtr, riid);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    // Now use IInspectable to navigate to the relevant interface
    final inspectable = IInspectable(inspectablePtr);
    hr = inspectable.QueryInterface(riid, classPtr);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    // Return a pointer to the relevant class
    return classPtr.cast();
  } finally {
    free(classNamePtr);
    free(iidPtr);
    free(riid);
    free(inspectablePtr);
    free(lpClassName);
    free(hstrClass);
  }
}

Pointer<COMObject> ActivateClass(String className,
    {Allocator allocator = calloc}) {
  final inspectablePtr = allocator<COMObject>();

  final hClassName = convertToHString(className);
  try {
    // Create a HSTRING representing the object
    // Activates the specified Windows Runtime class. This returns the WinRT
    // IInspectable interface, which is a subclass of IUnknown.
    final hr = RoActivateInstance(hClassName, inspectablePtr.cast());
    if (FAILED(hr)) throw WindowsException(hr);

    // Return a pointer to the relevant class
    return inspectablePtr;
  } finally {
    WindowsDeleteString(hClassName);
  }
}

/// Creates the activation factory for the specified runtime class using the
/// `className` and `iid`.
///
/// ```dart
/// final object = CreateActivationFactory(
///     'Windows.Globalization.PhoneNumberFormatting.PhoneNumberFormatter',
///     IID_IPhoneNumberFormatterStatics);
/// final phoneNumberFormatter = IPhoneNumberFormatterStatics(object);
/// ```
///
/// It is the caller's responsibility to deallocate the returned pointer when
/// they are finished with it. A FFI `Arena` may be passed as a custom allocator
/// for ease of memory management.
///
/// {@category winrt}
Pointer<COMObject> CreateActivationFactory(String className, String iid,
    {Allocator allocator = calloc}) {
  final hClassName = convertToHString(className);
  final pIID = calloc<GUID>()..ref.setGUID(iid);
  final pActivationFactory = allocator<COMObject>();

  try {
    final hr =
        RoGetActivationFactory(hClassName, pIID, pActivationFactory.cast());
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    return pActivationFactory;
  } finally {
    WindowsDeleteString(hClassName);
    free(pIID);
  }
}

/// Represents the trust level of an activatable class.
///
/// {@category Enum}
enum TrustLevel {
  /// The component has access to resources that are not protected.
  baseTrust,

  /// The component has access to resources requested in the app manifest and
  /// approved by the user.
  partialTrust,

  /// The component requires the full privileges of the user.
  fullTrust
}

extension IInspectableExtension on IInspectable {
  /// Returns the interface IIDs that are implemented by the current Windows
  /// Runtime class.
  ///
  /// The `IUnknown` and `IInspectable` interfaces are excluded.
  List<String> get iids {
    final pIIDCount = calloc<Uint32>();
    final pIIDs = calloc<Pointer<GUID>>();

    try {
      final hr = GetIids(pIIDCount, pIIDs);
      if (SUCCEEDED(hr)) {
        return [
          for (var i = 0; i < pIIDCount.value; i++) pIIDs.value[i].toString()
        ];
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(pIIDCount);
      free(pIIDs);
    }
  }

  /// Gets the fully qualified name of the current Windows Runtime object.
  String get runtimeClassName {
    final hstr = calloc<HSTRING>();

    try {
      final hr = GetRuntimeClassName(hstr);
      if (SUCCEEDED(hr)) {
        return convertFromHString(hstr.value);
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(hstr);
    }
  }

  /// Gets the trust level of the current Windows Runtime object.
  TrustLevel get trustLevel {
    final pTrustLevel = calloc<Int32>();

    try {
      final hr = GetTrustLevel(pTrustLevel);
      if (SUCCEEDED(hr)) {
        switch (pTrustLevel.value) {
          case 0:
            return TrustLevel.baseTrust;
          case 1:
            return TrustLevel.partialTrust;
          case 2:
            return TrustLevel.fullTrust;
          default:
            throw ArgumentError('GetTrustLevel returned an unexpected value.');
        }
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(pTrustLevel);
    }
  }
}
