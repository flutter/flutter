// ApplicationData.dart

// ignore_for_file: unused_import
// ignore_for_file: directives_ordering, non_constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../com/iinspectable.dart';
import '../utils.dart';
import '../winrt_helpers.dart';

import 'iapplicationdata.dart';
import 'iapplicationdatastatics.dart';

/// {@category winrt}
class ApplicationData extends IInspectable with IApplicationData {
  ApplicationData(super.ptr);

  static const _className = 'Windows.Storage.ApplicationData';

  static ApplicationData Current() {
    final activationFactory =
        CreateActivationFactory(_className, IID_IApplicationDataStatics);
    try {
      return ApplicationData(
          IApplicationDataStatics(activationFactory).Current);
    } finally {
      free(activationFactory);
    }
  }
}
