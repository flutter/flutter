// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';

import 'types.dart';

/// The response object of [ImagePicker.getLostData].
///
/// Only applies to Android.
/// See also:
/// * [ImagePicker.getLostData] for more details on retrieving lost data.
class LostDataResponse {
  /// Creates an instance with the given [file], [exception], and [type]. Any of
  /// the params may be null, but this is never considered to be empty.
  LostDataResponse({
    this.file,
    this.exception,
    this.type,
    this.files,
  });

  /// Initializes an instance with all member params set to null and considered
  /// to be empty.
  LostDataResponse.empty()
      : file = null,
        exception = null,
        type = null,
        _empty = true,
        files = null;

  /// Whether it is an empty response.
  ///
  /// An empty response should have [file], [exception] and [type] to be null.
  bool get isEmpty => _empty;

  /// The file that was lost in a previous [getImage], [getMultiImage] or [getVideo] call due to MainActivity being destroyed.
  ///
  /// Can be null if [exception] exists.
  final XFile? file;

  /// The exception of the last [getImage], [getMultiImage] or [getVideo].
  ///
  /// If the last [getImage], [getMultiImage] or [getVideo] threw some exception before the MainActivity destruction,
  /// this variable keeps that exception.
  /// You should handle this exception as if the [getImage], [getMultiImage] or [getVideo] got an exception when
  /// the MainActivity was not destroyed.
  ///
  /// Note that it is not the exception that caused the destruction of the MainActivity.
  final PlatformException? exception;

  /// Can either be [RetrieveType.image] or [RetrieveType.video];
  ///
  /// If the lost data is empty, this will be null.
  final RetrieveType? type;

  bool _empty = false;

  /// The list of files that were lost in a previous [getMultiImage] call due to MainActivity being destroyed.
  ///
  /// When [files] is populated, [file] will refer to the last item in the [files] list.
  ///
  /// Can be null if [exception] exists.
  final List<XFile>? files;
}
