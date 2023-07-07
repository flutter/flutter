/// Tests for ICU compact format numbers (e.g. 1.2M instead of 1200000).
///
/// These tests check that the test cases match what ICU produces. They are not
/// testing the package:intl implementation, they only help verify consistent
/// behaviour across platforms.

@TestOn("!browser")
@Tags(['ffi'])
@Skip(
    "currently failing (see issue https://github.com/dart-lang/intl/issues/240)")
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'compact_number_test_data.dart' as testdata35;
import 'more_compact_number_test_data.dart' as more_testdata;

main() {
  var problemLocales = [
    // ICU produces numerals in Arabic script, package:intl uses Latin script.
    'ar',
    // package:intl includes some tweaks to compact numbers for Bengali.
    'bn',
  ];

  runICUTests(systemIcuVersion: 63, skipLocales: problemLocales);
}

void runICUTests(
    {int? systemIcuVersion, String? specialIcuLib, List<String>? skipLocales}) {
  if (!setupICU(
      systemIcuVersion: systemIcuVersion, specialIcuLibPath: specialIcuLib)) {
    return;
  }

  print("Skipping problem locales $skipLocales.");
  testdata35.compactNumberTestData
      .removeWhere((k, v) => skipLocales!.contains(k));
  testdata35.compactNumberTestData.forEach(validate);
  more_testdata.cldr35CompactNumTests.forEach(validateFancy);

  test('UNumberFormatter simple integer formatting', () {
    expect(FormatWithUnumf('en', 'precision-integer', 5142.3), '5,142');
  });
}

void validate(String locale, List<List<String>> expected) {
  validateShort(locale, expected);
  validateLong(locale, expected);
}

void validateShort(String locale, List<List<String>> expected) {
  test('Validate $locale SHORT', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      expect(FormatWithUnumf(locale, 'compact-short', number), data[1]);
    }
  });
}

void validateLong(String locale, List<List<String>> expected) {
  test('Validate $locale LONG', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      expect(FormatWithUnumf(locale, 'compact-long', number), data[2]);
    }
  });
}

void validateFancy(more_testdata.CompactRoundingTestCase t) {
  var locale = 'en';
  var skel = 'compact-short';
  if (t.minimumIntegerDigits != null) {
    skel += ' integer-width/+' + '0' * t.minimumIntegerDigits!;
  }
  if (t.significantDigits != null) {
    skel += ' ' + '@' * t.significantDigits!;
  }
  if (t.minimumFractionDigits != null) {
    skel += ' .' + '0' * t.minimumFractionDigits!;
    var maxFD = t.maximumFractionDigits ?? 3;
    skel += '#' * (maxFD - t.minimumFractionDigits!);
  } else if (t.maximumFractionDigits != null) {
    skel += ' .' + '#' * t.maximumFractionDigits!;
  }
  test(t.toString(), () {
    expect(FormatWithUnumf(locale, skel, t.number), t.expected,
        reason: 'Skeleton: $skel');
  });
}

UErrorNameOp? u_errorName;
UnumfOpenForSkeletonAndLocaleOp? unumf_openForSkeletonAndLocale;
UnumfOpenResultOp? unumf_openResult;
UnumfFormatDoubleOp? unumf_formatDouble;
UnumfFormatIntOp? unumf_formatInt;
UnumfResultToStringOp? unumf_resultToString;
UnumfCloseOp? unumf_close;
UnumfCloseResultOp? unumf_closeResult;

/// Sets up dart:ffi functions.
///
/// If [systemIcuVersion] is specified, and set to 63 for example, we load the
/// functions from libicuuc.so.63 and libicui18n.so.63 if available. If
/// libraries are lacking, function returns [false].
///
/// If [systemIcuVersion] is unspecified, we expect to find all functions in a
/// library with filename [specialIcuLibPath].
bool setupICU({int? systemIcuVersion, String? specialIcuLibPath}) {
  DynamicLibrary libicui18n;
  String icuVersionSuffix;
  if (systemIcuVersion != null) {
    icuVersionSuffix = '_$systemIcuVersion';
    try {
      DynamicLibrary libicuuc =
          DynamicLibrary.open('libicuuc.so.$systemIcuVersion');
      u_errorName = libicuuc.lookupFunction<NativeUErrorNameOp, UErrorNameOp>(
          "u_errorName$icuVersionSuffix");
      libicui18n = DynamicLibrary.open('libicui18n.so.$systemIcuVersion');
    } on ArgumentError catch (e) {
      print('Unable to test against ICU version $systemIcuVersion: $e');
      return false;
    }
  } else {
    icuVersionSuffix = '';
    libicui18n = DynamicLibrary.open(specialIcuLibPath!);
    u_errorName = libicui18n.lookupFunction<NativeUErrorNameOp, UErrorNameOp>(
        "u_errorName$icuVersionSuffix");
  }

  unumf_openForSkeletonAndLocale = libicui18n.lookupFunction<
          NativeUnumfOpenForSkeletonAndLocaleOp,
          UnumfOpenForSkeletonAndLocaleOp>(
      "unumf_openForSkeletonAndLocale$icuVersionSuffix");
  unumf_openResult =
      libicui18n.lookupFunction<NativeUnumfOpenResultOp, UnumfOpenResultOp>(
          "unumf_openResult$icuVersionSuffix");
  unumf_formatDouble =
      libicui18n.lookupFunction<NativeUnumfFormatDoubleOp, UnumfFormatDoubleOp>(
          "unumf_formatDouble$icuVersionSuffix");
  unumf_formatInt =
      libicui18n.lookupFunction<NativeUnumfFormatIntOp, UnumfFormatIntOp>(
          "unumf_formatInt$icuVersionSuffix");
  unumf_resultToString = libicui18n.lookupFunction<NativeUnumfResultToStringOp,
      UnumfResultToStringOp>("unumf_resultToString$icuVersionSuffix");
  unumf_close = libicui18n.lookupFunction<NativeUnumfCloseOp, UnumfCloseOp>(
      "unumf_close$icuVersionSuffix");
  unumf_closeResult =
      libicui18n.lookupFunction<NativeUnumfCloseResultOp, UnumfCloseResultOp>(
          "unumf_closeResult$icuVersionSuffix");

  return true;
}

String FormatWithUnumf(String locale, String skeleton, num number) {
  // // Setup:
  // UErrorCode ec = U_ZERO_ERROR;
  // UNumberFormatter* uformatter =
  //     unumf_openForSkeletonAndLocale(u"precision-integer", -1, "en", &ec);
  // UFormattedNumber* uresult = unumf_openResult(&ec);
  // if (U_FAILURE(ec)) { return; }
  final cLocale = Utf8.toUtf8(locale);
  final cSkeleton = Utf16.toUtf16(skeleton);
  final cErrorCode = allocate<Int32>(count: 1);
  cErrorCode.value = 0;
  final uformatter =
      unumf_openForSkeletonAndLocale!(cSkeleton, -1, cLocale, cErrorCode);
  free(cSkeleton);
  free(cLocale);
  var errorCode = cErrorCode.value;
  expect(errorCode, lessThanOrEqualTo(0),
      reason: u_errorName!(errorCode).toString());
  final uresult = unumf_openResult!(cErrorCode);
  errorCode = cErrorCode.value;
  // Try to improve this once dart:ffi has extension methods:
  expect(errorCode, lessThanOrEqualTo(0),
      reason: u_errorName!(errorCode).toString());

  // // Format a double:
  // unumf_formatDouble(uformatter, 5142.3, uresult, &ec);
  // if (U_FAILURE(ec)) { return; }
  if (number is double) {
    unumf_formatDouble!(uformatter, number, uresult, cErrorCode);
  } else {
    unumf_formatInt!(uformatter, number as int, uresult, cErrorCode);
  }
  errorCode = cErrorCode.value;
  expect(errorCode, lessThanOrEqualTo(0),
      reason: u_errorName!(errorCode).toString());

  // // Export the string to a malloc'd buffer:
  // int32_t len = unumf_resultToString(uresult, NULL, 0, &ec);
  // // at this point, ec == U_BUFFER_OVERFLOW_ERROR
  // ec = U_ZERO_ERROR;
  // UChar* buffer = (UChar*) malloc((len+1)*sizeof(UChar));
  // unumf_resultToString(uresult, buffer, len+1, &ec);
  // if (U_FAILURE(ec)) { return; }
  // // buffer should equal "5,142"
  final reqLen = unumf_resultToString!(uresult, nullptr.cast(), 0, cErrorCode);
  errorCode = cErrorCode.value;
  expect(errorCode, equals(15), // U_BUFFER_OVERFLOW_ERROR
      reason: u_errorName!(errorCode).toString());
  cErrorCode.value = 0;
  final buffer = allocate<Utf16>(count: reqLen + 1);
  unumf_resultToString!(uresult, buffer, reqLen + 1, cErrorCode);
  errorCode = cErrorCode.value;
  expect(errorCode, lessThanOrEqualTo(0),
      reason: u_errorName!(errorCode).toString());
  final result = buffer.toString();

  // // Cleanup:
  // unumf_close(uformatter);
  // unumf_closeResult(uresult);
  // free(buffer);
  unumf_close!(uformatter);
  unumf_closeResult!(uresult);
  free(buffer);
  free(cErrorCode);

  return result;
}

/// C signature for
/// [u_errorName()](http://icu-project.org/apiref/icu4c/utypes_8h.html#a89eb455526bb29bf5350ee861d81df92)
typedef NativeUErrorNameOp = Pointer<Utf8> Function(Int32 code);

/// Dart signature for
/// [u_errorName()](http://icu-project.org/apiref/icu4c/utypes_8h.html#a89eb455526bb29bf5350ee861d81df92)
typedef UErrorNameOp = Pointer<Utf8> Function(int code);

/// [UNumberFormatter](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a7c1238b2dd08f32f1ea245ece41e71bd)
class UNumberFormatter extends Struct {}

/// [UFormattedNumber](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a9d4030bdc4dd1ec4de828bf1bcf4b1b6)
class UFormattedNumber extends Struct {}

/// C signature for
/// [unumf_openForSkeletonAndLocale()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a29339e144833880bda36fb7c17032698)
typedef NativeUnumfOpenForSkeletonAndLocaleOp
    = Pointer<UNumberFormatter> Function(Pointer<Utf16> skeleton,
        Int32 skeletonLen, Pointer<Utf8> locale, Pointer<Int32> ec);

/// Dart signature for
/// [unumf_openForSkeletonAndLocale()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a29339e144833880bda36fb7c17032698)
typedef UnumfOpenForSkeletonAndLocaleOp = Pointer<UNumberFormatter> Function(
    Pointer<Utf16> skeleton,
    int skeletonLen,
    Pointer<Utf8> locale,
    Pointer<Int32> ec);

/// C signature for
/// [unumf_openResult()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a5bd2d297cb2664b4964d25fd41671dad)
typedef NativeUnumfOpenResultOp = Pointer<UFormattedNumber> Function(
    Pointer<Int32> ec);

/// Dart signature for
/// [unumf_openResult()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a5bd2d297cb2664b4964d25fd41671dad)
typedef UnumfOpenResultOp = Pointer<UFormattedNumber> Function(
    Pointer<Int32> ec);

/// C signature for
/// [unumf_formatDouble()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#af5f79e43adc900f07b3ba90b6315944e)
typedef NativeUnumfFormatDoubleOp = Void Function(
    Pointer<UNumberFormatter> uformatter,
    Double value,
    Pointer<UFormattedNumber> uresult,
    Pointer<Int32> ec);

/// Dart signature for
/// [unumf_formatDouble()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#af5f79e43adc900f07b3ba90b6315944e)
typedef UnumfFormatDoubleOp = void Function(
    Pointer<UNumberFormatter> uformatter,
    double value,
    Pointer<UFormattedNumber> uresult,
    Pointer<Int32> ec);

/// C signature for
/// [unumf_formatInt()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a459b9313ed05fc98c9cd125eb9c1a625)
typedef NativeUnumfFormatIntOp = Void Function(
    Pointer<UNumberFormatter> uformatter,
    Int32 value,
    Pointer<UFormattedNumber> uresult,
    Pointer<Int32> ec);

/// Dart signature for
/// [unumf_formatInt()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a459b9313ed05fc98c9cd125eb9c1a625)
typedef UnumfFormatIntOp = void Function(Pointer<UNumberFormatter> uformatter,
    int value, Pointer<UFormattedNumber> uresult, Pointer<Int32> ec);

/// C signature for
/// [unumf_resultToString()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a72131183633fda6851c35e37ffd821a1)
typedef NativeUnumfResultToStringOp = Int32 Function(
    Pointer<UFormattedNumber> uresult,
    Pointer<Utf16> buffer,
    Int32 bufferCapacity,
    Pointer<Int32> ec);

/// Dart signature for
/// [unumf_resultToString()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a72131183633fda6851c35e37ffd821a1)
typedef UnumfResultToStringOp = int Function(Pointer<UFormattedNumber> uresult,
    Pointer<Utf16> buffer, int bufferCapacity, Pointer<Int32> ec);

/// C signature for
/// [unumf_close()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a6f47836ca05077fc912ad24e462312c6)
typedef NativeUnumfCloseOp = Void Function(
    Pointer<UNumberFormatter> uformatter);

/// Dart signature for
/// [unumf_close()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a6f47836ca05077fc912ad24e462312c6)
typedef UnumfCloseOp = void Function(Pointer<UNumberFormatter> uformatter);

/// C signature for
/// [unumf_closeResult()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a78f19cef14a2db1a0eb62a8b724eb123)
typedef NativeUnumfCloseResultOp = Void Function(
    Pointer<UFormattedNumber> uresult);

/// Dart signature for
/// [unumf_closeResult()](http://icu-project.org/apiref/icu4c/unumberformatter_8h.html#a78f19cef14a2db1a0eb62a8b724eb123)
typedef UnumfCloseResultOp = void Function(Pointer<UFormattedNumber> uresult);
