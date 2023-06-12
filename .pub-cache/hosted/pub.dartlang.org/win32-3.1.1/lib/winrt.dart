// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: directives_ordering

/// Support for programming against the WinRT API on Windows operating systems.
///
/// The Windows Runtime (WinRT) is a suite of APIs and architectural model,
/// introduced in Windows 8, that powers the latest generation of Windows APIs.
/// It is an evolution of the COM API that is designed for access from a variety
/// of languages. WinRT introduces standardized interfaces for collections (e.g.
/// `IVectorView`), as well as support for generic types and asynchronous
/// programming models.
///
/// Warning: The WinRT API projection in Dart is unstable, experimental and
/// under active development. Updates to the win32 package may introduce
/// breaking changes.
///
/// ## Initializing the Windows Runtime
///
/// All threads that activate and interact with Windows Runtime objects must be
/// initialized prior to calling into the Windows Runtime. This package provides
/// the [winrtInitialize] helper function to do this. Call the matching
/// [winrtUninitialize] function to close the Windows Runtime on the current
/// thread. A successful call to `winrtInitialize` should be balanced with a
/// corresponding call to `winrtUninitialize`.
///
/// ## Instantiating Windows Runtime objects
///
/// The [CreateObject] function provides a convenient way to create a new
/// Windows Runtime object. This returns a generic `Pointer<COMObject>`, which
/// can be cast to the object type desired. For example:
///
/// ```dart
/// final comObject = CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
/// final calendar = ICalendar.fromRawPointer(comObject);
/// ```
///
/// The object should be disposed of when it is no longer in use, for example:
///
/// ```dart
/// free(calendar.ptr);
/// ```
///
/// ## Strings in the Windows Runtime
///
/// Windows Runtime APIs use `HSTRING` as their native type. An `HSTRING` is an
/// immutable string object, which is created with the [WindowsCreateString] API
/// and deleted with the [WindowsDeleteString] API. The `HSTRING` itself is an
/// integer value, just like other `HANDLE` objects in the Win32 programming
/// interface.
///
/// Helper functions exist to easily convert between the Dart `String` type and
/// Windows Runtime strings: specifically, [convertToHString] and
/// [convertFromHString].
///
/// Make sure you dispose of `HSTRING`s by calling `WindowsDeleteString`; you do
/// not need to free the pointer itself, since Windows reference counts the
/// backing store and frees the memory when the reference count reaches 0.

library winrt;

// The WinRT API builds on the underlying Win32 API, and so it is also exported
// here.
export 'win32.dart';

// WinRT foundational exports
export 'src/winrt_callbacks.dart';
export 'src/winrt_constants.dart';
export 'src/winrt_helpers.dart';
export 'src/winrt/foundation/winrt_enum.dart';
export 'src/winrt/internal/map_helpers.dart';

// Windows Runtime classes and interfaces
export 'src/winrt/data/json/ijsonarray.dart';
export 'src/winrt/data/json/ijsonobject.dart';
export 'src/winrt/data/json/ijsonobjectwithdefaultvalues.dart';
export 'src/winrt/data/json/ijsonvalue.dart';
export 'src/winrt/data/json/jsonarray.dart';
export 'src/winrt/data/json/jsonobject.dart';
export 'src/winrt/data/json/jsonvalue.dart';
export 'src/winrt/devices/enumeration/devicepicker.dart';
export 'src/winrt/devices/enumeration/devicepickerfilter.dart';
export 'src/winrt/devices/enumeration/idevicepicker.dart';
export 'src/winrt/devices/enumeration/idevicepickerfilter.dart';
export 'src/winrt/devices/power/batteryreport.dart';
export 'src/winrt/devices/power/ibatteryreport.dart';
export 'src/winrt/devices/sensors/ipedometerreading.dart';
export 'src/winrt/devices/sensors/pedometerreading.dart';
export 'src/winrt/foundation/iasyncaction.dart';
export 'src/winrt/foundation/iasyncinfo.dart';
export 'src/winrt/foundation/iasyncoperation.dart';
export 'src/winrt/foundation/ipropertyvalue.dart';
export 'src/winrt/foundation/ireference.dart';
export 'src/winrt/foundation/propertyvalue.dart';
export 'src/winrt/foundation/collections/iiterable.dart';
export 'src/winrt/foundation/collections/iiterator.dart';
export 'src/winrt/foundation/collections/ikeyvaluepair.dart';
export 'src/winrt/foundation/collections/imap.dart';
export 'src/winrt/foundation/collections/imapview.dart';
export 'src/winrt/foundation/collections/ivector.dart';
export 'src/winrt/foundation/collections/ivectorview.dart';
export 'src/winrt/foundation/collections/propertyset.dart';
export 'src/winrt/foundation/collections/stringmap.dart';
export 'src/winrt/foundation/collections/valueset.dart';
export 'src/winrt/gaming/input/gamepad.dart';
export 'src/winrt/gaming/input/headset.dart';
export 'src/winrt/gaming/input/igamecontroller.dart';
export 'src/winrt/gaming/input/igamecontrollerbatteryinfo.dart';
export 'src/winrt/gaming/input/igamepad.dart';
export 'src/winrt/gaming/input/iheadset.dart';
export 'src/winrt/globalization/calendar.dart';
export 'src/winrt/globalization/icalendar.dart';
export 'src/winrt/globalization/phonenumberformatting/iphonenumberformatter.dart';
export 'src/winrt/globalization/phonenumberformatting/phonenumberformatter.dart';
export 'src/winrt/graphics/printing3d/iprinting3dmultiplepropertymaterial.dart';
export 'src/winrt/graphics/printing3d/printing3dmultiplepropertymaterial.dart';
export 'src/winrt/media/mediaproperties/mediapropertyset.dart';
export 'src/winrt/networking/hostname.dart';
export 'src/winrt/networking/ihostname.dart';
export 'src/winrt/networking/connectivity/inetworkadapter.dart';
export 'src/winrt/networking/connectivity/inetworkinformationstatics.dart';
export 'src/winrt/networking/connectivity/inetworkitem.dart';
export 'src/winrt/networking/connectivity/ipinformation.dart';
export 'src/winrt/networking/connectivity/networkadapter.dart';
export 'src/winrt/networking/connectivity/networkitem.dart';
export 'src/winrt/storage/istorageitem.dart';
export 'src/winrt/storage/iuserdatapathsstatics.dart';
export 'src/winrt/storage/userdatapaths.dart';
export 'src/winrt/storage/pickers/fileopenpicker.dart';
export 'src/winrt/storage/pickers/ifileopenpicker.dart';
export 'src/winrt/ui/notifications/itoastnotificationfactory.dart';
export 'src/winrt/ui/notifications/itoastnotificationmanagerstatics.dart';
export 'src/winrt/ui/notifications/toastnotification.dart';

// Windows Runtime enumerations
export 'src/winrt/data/json/enums.g.dart';
export 'src/winrt/devices/enumeration/enums.g.dart';
export 'src/winrt/devices/sensors/enums.g.dart';
export 'src/winrt/foundation/enums.g.dart';
export 'src/winrt/gaming/input/enums.g.dart';
export 'src/winrt/globalization/enums.g.dart';
export 'src/winrt/globalization/phonenumberformatting/enums.g.dart';
export 'src/winrt/networking/enums.g.dart';
export 'src/winrt/networking/connectivity/enums.g.dart';
export 'src/winrt/storage/enums.g.dart';
export 'src/winrt/storage/pickers/enums.g.dart';
export 'src/winrt/system/power/enums.g.dart';
export 'src/winrt/ui/notifications/enums.g.dart';
export 'src/winrt/ui/popups/enums.g.dart';

// Windows Runtime structs
export 'src/winrt/foundation/structs.g.dart';
export 'src/winrt/foundation/numerics/structs.g.dart';
export 'src/winrt/gaming/input/structs.g.dart';
