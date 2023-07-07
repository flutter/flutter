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
/// This package ensures that threads are implicitly assigned to the
/// multi-threaded apartment (MTA) so most of the time you don't need to do
/// anything. However, if you need to use APIs that only work in a
/// single-threaded apartment (STA), you need to call
/// `RoInitialize(RO_INIT_TYPE.RO_INIT_SINGLETHREADED)` to initialize the
/// Windows Runtime with a single-threaded apartment.
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
/// When you have finished using a Windows Runtime interface, you should release
/// it with the `release` method:
///
/// ```dart
/// calendar.release(); // Release the interface
/// ```
library winrt;

// The WinRT API builds on the underlying Win32 API, and so it is also exported
// here.
export 'win32.dart';

// WinRT foundational exports
export 'src/winrt_callbacks.dart';
export 'src/winrt_com_interop_helpers.dart';
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
export 'src/winrt/devices/geolocation/enums.g.dart';
export 'src/winrt/devices/geolocation/geocoordinate.dart';
export 'src/winrt/devices/geolocation/geolocator.dart';
export 'src/winrt/devices/geolocation/geopoint.dart';
export 'src/winrt/devices/geolocation/geoposition.dart';
export 'src/winrt/devices/geolocation/igeolocator.dart';
export 'src/winrt/devices/geolocation/igeolocator2.dart';
export 'src/winrt/devices/geolocation/igeolocatorstatics.dart';
export 'src/winrt/devices/geolocation/igeolocatorstatics2.dart';
export 'src/winrt/devices/geolocation/igeolocatorwithscalaraccuracy.dart';
export 'src/winrt/devices/geolocation/igeopoint.dart';
export 'src/winrt/devices/geolocation/igeopointfactory.dart';
export 'src/winrt/devices/geolocation/igeoposition.dart';
export 'src/winrt/devices/geolocation/igeoposition2.dart';
export 'src/winrt/devices/geolocation/igeoshape.dart';
export 'src/winrt/devices/geolocation/structs.g.dart';
export 'src/winrt/devices/geolocation/venuedata.dart';
export 'src/winrt/devices/power/batteryreport.dart';
export 'src/winrt/devices/power/ibatteryreport.dart';
export 'src/winrt/devices/sensors/ipedometerreading.dart';
export 'src/winrt/devices/sensors/pedometerreading.dart';
export 'src/winrt/foundation/ipropertyvalue.dart';
export 'src/winrt/foundation/ireference.dart';
export 'src/winrt/foundation/propertyvalue.dart';
export 'src/winrt/foundation/collections/iiterable.dart';
export 'src/winrt/foundation/collections/iiterator.dart';
export 'src/winrt/foundation/collections/ikeyvaluepair.dart';
export 'src/winrt/foundation/collections/imap.dart';
export 'src/winrt/foundation/collections/imapview.dart';
export 'src/winrt/foundation/collections/ipropertyset.dart';
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
export 'src/winrt/storage/fileproperties/basicproperties.dart';
export 'src/winrt/storage/fileproperties/ibasicproperties.dart';
export 'src/winrt/storage/istoragefile.dart';
export 'src/winrt/storage/istorageitem.dart';
export 'src/winrt/storage/iuserdatapathsstatics.dart';
export 'src/winrt/storage/storagefile.dart';
export 'src/winrt/storage/userdatapaths.dart';
export 'src/winrt/storage/pickers/fileopenpicker.dart';
export 'src/winrt/storage/pickers/ifileopenpicker.dart';
export 'src/winrt/ui/notifications/itoastnotificationfactory.dart';
export 'src/winrt/ui/notifications/itoastnotificationmanagerstatics.dart';
export 'src/winrt/ui/notifications/toastnotification.dart';
export 'src/winrt/ui/viewmanagement/iuisettings.dart';
export 'src/winrt/ui/viewmanagement/uisettings.dart';

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
export 'src/winrt/ui/viewmanagement/enums.g.dart';

// Windows Runtime structs
export 'src/winrt/foundation/structs.g.dart';
export 'src/winrt/foundation/numerics/structs.g.dart';
export 'src/winrt/gaming/input/structs.g.dart';
export 'src/winrt/ui/structs.g.dart';
