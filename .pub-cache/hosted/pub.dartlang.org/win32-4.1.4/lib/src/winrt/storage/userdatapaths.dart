// userdatapaths.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';
import '../system/user.dart';
import 'iuserdatapaths.dart';
import 'iuserdatapathsstatics.dart';

/// Returns full paths for common user data folders. User data folders are
/// based on the KNOWNFOLDERID naming pattern.
///
/// {@category Class}
/// {@category winrt}
class UserDataPaths extends IInspectable implements IUserDataPaths {
  UserDataPaths.fromRawPointer(super.ptr);

  static const _className = 'Windows.Storage.UserDataPaths';

  // IUserDataPathsStatics methods
  static UserDataPaths? getForUser(User? user) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUserDataPathsStatics);
    final object = IUserDataPathsStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getForUser(user);
    } finally {
      object.release();
    }
  }

  static UserDataPaths? getDefault() {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUserDataPathsStatics);
    final object = IUserDataPathsStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getDefault();
    } finally {
      object.release();
    }
  }

  // IUserDataPaths methods
  late final _iUserDataPaths = IUserDataPaths.from(this);

  @override
  String get cameraRoll => _iUserDataPaths.cameraRoll;

  @override
  String get cookies => _iUserDataPaths.cookies;

  @override
  String get desktop => _iUserDataPaths.desktop;

  @override
  String get documents => _iUserDataPaths.documents;

  @override
  String get downloads => _iUserDataPaths.downloads;

  @override
  String get favorites => _iUserDataPaths.favorites;

  @override
  String get history => _iUserDataPaths.history;

  @override
  String get internetCache => _iUserDataPaths.internetCache;

  @override
  String get localAppData => _iUserDataPaths.localAppData;

  @override
  String get localAppDataLow => _iUserDataPaths.localAppDataLow;

  @override
  String get music => _iUserDataPaths.music;

  @override
  String get pictures => _iUserDataPaths.pictures;

  @override
  String get profile => _iUserDataPaths.profile;

  @override
  String get recent => _iUserDataPaths.recent;

  @override
  String get roamingAppData => _iUserDataPaths.roamingAppData;

  @override
  String get savedPictures => _iUserDataPaths.savedPictures;

  @override
  String get screenshots => _iUserDataPaths.screenshots;

  @override
  String get templates => _iUserDataPaths.templates;

  @override
  String get videos => _iUserDataPaths.videos;
}
