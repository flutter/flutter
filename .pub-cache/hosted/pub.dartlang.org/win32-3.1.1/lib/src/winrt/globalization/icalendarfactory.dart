// icalendarfactory.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import '../foundation/collections/iiterable.dart';
import 'calendar.dart';
import '../../com/iinspectable.dart';

/// @nodoc
const IID_ICalendarFactory = '{83F58412-E56B-4C75-A66E-0F63D57758A6}';

/// {@category Interface}
/// {@category winrt}
class ICalendarFactory extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  ICalendarFactory.fromRawPointer(super.ptr);

  factory ICalendarFactory.from(IInspectable interface) =>
      ICalendarFactory.fromRawPointer(
          interface.toInterface(IID_ICalendarFactory));

  Calendar createCalendarDefaultCalendarAndClock(IIterable<String> languages) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> languages,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<COMObject> languages,
                    Pointer<COMObject>)>()(ptr.ref.lpVtbl,
        languages.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return Calendar.fromRawPointer(retValuePtr);
  }

  Calendar createCalendar(
      IIterable<String> languages, String calendar, String clock) {
    final retValuePtr = calloc<COMObject>();

    final calendarHstring = convertToHString(calendar);
    final clockHstring = convertToHString(clock);
    final hr =
        ptr.ref.vtable
                .elementAt(7)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> languages,
                                IntPtr calendar,
                                IntPtr clock,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> languages,
                        int calendar, int clock, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl,
            languages.ptr.cast<Pointer<COMObject>>().value,
            calendarHstring,
            clockHstring,
            retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    WindowsDeleteString(calendarHstring);
    WindowsDeleteString(clockHstring);
    return Calendar.fromRawPointer(retValuePtr);
  }
}
