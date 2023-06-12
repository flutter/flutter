// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

// Keep dart:ui for retrocompatiblity with Flutter <3.3.0
// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:mime/mime.dart' show extensionFromMime, lookupMimeType;
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Plugin for summoning a platform share sheet.
class MethodChannelShare extends SharePlatform {
  /// [MethodChannel] used to communicate with the platform side.
  @visibleForTesting
  static const MethodChannel channel =
      MethodChannel('dev.fluttercommunity.plus/share');

  /// Summons the platform's share sheet to share text.
  @override
  Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    assert(text.isNotEmpty);
    final params = <String, dynamic>{
      'text': text,
      'subject': subject,
    };

    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }

    return channel.invokeMethod<void>('share', params);
  }

  /// Summons the platform's share sheet to share multiple files.
  @override
  Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    assert(paths.isNotEmpty);
    assert(paths.every((element) => element.isNotEmpty));
    final params = <String, dynamic>{
      'paths': paths,
      'mimeTypes': mimeTypes ??
          paths.map((String path) => _mimeTypeForPath(path)).toList(),
    };

    if (subject != null) params['subject'] = subject;
    if (text != null) params['text'] = text;

    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }

    return channel.invokeMethod('shareFiles', params);
  }

  /// Summons the platform's share sheet to share text and returns the result.
  @override
  Future<ShareResult> shareWithResult(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    assert(text.isNotEmpty);
    final params = <String, dynamic>{
      'text': text,
      'subject': subject,
    };

    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }

    final result =
        await channel.invokeMethod<String>('shareWithResult', params) ??
            'dev.fluttercommunity.plus/share/unavailable';

    return ShareResult(result, _statusFromResult(result));
  }

  /// Summons the platform's share sheet to share multiple files and returns the result.
  @override
  Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    assert(paths.isNotEmpty);
    assert(paths.every((element) => element.isNotEmpty));
    final params = <String, dynamic>{
      'paths': paths,
      'mimeTypes': mimeTypes ??
          paths.map((String path) => _mimeTypeForPath(path)).toList(),
    };

    if (subject != null) params['subject'] = subject;
    if (text != null) params['text'] = text;

    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }

    final result =
        await channel.invokeMethod<String>('shareFilesWithResult', params) ??
            'dev.fluttercommunity.plus/share/unavailable';

    return ShareResult(result, _statusFromResult(result));
  }

  /// Summons the platform's share sheet to share multiple files.
  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    final filesWithPath = await _getFiles(files);

    final mimeTypes = filesWithPath
        .map((e) => e.mimeType ?? _mimeTypeForPath(e.path))
        .toList();

    return shareFilesWithResult(
      filesWithPath.map((e) => e.path).toList(),
      mimeTypes: mimeTypes,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// if file doesn't contain path
  /// then make new file in TemporaryDirectory and return with path
  ///
  /// the system will automatically delete files in this
  /// TemporaryDirectory as disk space is needed elsewhere on the device
  Future<List<XFile>> _getFiles(List<XFile> files) async {
    if (files.any((element) => element.path.isEmpty)) {
      final newFiles = <XFile>[];

      final String tempPath = (await getTemporaryDirectory()).path;

      const uuid = Uuid();
      for (final XFile element in files) {
        if (element.path.isEmpty) {
          final name = uuid.v4();

          final extension =
              extensionFromMime(element.mimeType ?? 'octet-stream');

          final path = '$tempPath/$name.$extension';
          final file = File(path);

          await file.writeAsBytes(await element.readAsBytes());

          newFiles.add(XFile(path));
        } else {
          newFiles.add(element);
        }
      }

      return newFiles;
    } else {
      return files;
    }
  }

  static String _mimeTypeForPath(String path) {
    return lookupMimeType(path) ?? 'application/octet-stream';
  }

  static ShareResultStatus _statusFromResult(String result) {
    switch (result) {
      case '':
        return ShareResultStatus.dismissed;
      case 'dev.fluttercommunity.plus/share/unavailable':
        return ShareResultStatus.unavailable;
      default:
        return ShareResultStatus.success;
    }
  }
}
