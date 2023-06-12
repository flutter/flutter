// icalendarfactory2.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import '../com/iinspectable.dart';

/// @nodoc
const IID_ICalendarFactory2 = '{B44B378C-CA7E-4590-9E72-EA2BEC1A5115}';

/// {@category Interface}
/// {@category winrt}
class ICalendarFactory2 extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  ICalendarFactory2(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_ICalendarFactory2);

  Pointer<COMObject> CreateCalendarWithTimeZone(Pointer<COMObject> languages,
      String calendar, String clock, String timeZoneId) {
    final retValuePtr = calloc<COMObject>();

    final calendarHstring = convertToHString(calendar);
    final clockHstring = convertToHString(clock);
    final timeZoneIdHstring = convertToHString(timeZoneId);
    final hr = _thisPtr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            Pointer<COMObject> languages,
                            IntPtr calendar,
                            IntPtr clock,
                            IntPtr timeZoneId,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer,
                    Pointer<COMObject> languages,
                    int calendar,
                    int clock,
                    int timeZoneId,
                    Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl,
        languages.cast<Pointer<COMObject>>().value,
        calendarHstring,
        clockHstring,
        timeZoneIdHstring,
        retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(calendarHstring);
    WindowsDeleteString(clockHstring);
    WindowsDeleteString(timeZoneIdHstring);
    return retValuePtr;
  }
}
