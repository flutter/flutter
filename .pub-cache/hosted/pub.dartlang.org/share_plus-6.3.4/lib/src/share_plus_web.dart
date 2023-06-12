import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

/// The web implementation of [SharePlatform].
class SharePlusWebPlugin extends SharePlatform {
  final UrlLauncherPlatform urlLauncher;

  /// Registers this class as the default instance of [SharePlatform].
  static void registerWith(Registrar registrar) {
    SharePlatform.instance = SharePlusWebPlugin(UrlLauncherPlugin());
  }

  final html.Navigator _navigator;

  /// A constructor that allows tests to override the window object used by the plugin.
  SharePlusWebPlugin(
    this.urlLauncher, {
    @visibleForTesting html.Navigator? debugNavigator,
  }) : _navigator = debugNavigator ?? html.window.navigator;

  /// Share text
  @override
  Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      await _navigator.share({'title': subject, 'text': text});
    } on NoSuchMethodError catch (_) {
      //Navigator is not available or the webPage is not served on https
      final queryParameters = {
        if (subject != null) 'subject': subject,
        'body': text,
      };

      // see https://github.com/dart-lang/sdk/issues/43838#issuecomment-823551891
      final uri = Uri(
        scheme: 'mailto',
        query: queryParameters.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );

      final launchResult = await urlLauncher.launchUrl(
        uri.toString(),
        const LaunchOptions(),
      );
      if (!launchResult) {
        throw Exception('Failed to launch $uri');
      }
    }
  }

  /// Share files
  @override
  Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    final files = <XFile>[];
    for (var i = 0; i < paths.length; i++) {
      files.add(XFile(paths[i], mimeType: mimeTypes?[i]));
    }
    return shareXFiles(
      files,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share [XFile] objects.
  ///
  /// Remarks for the web implementation:
  /// This uses the [Web Share API](https://web.dev/web-share/) if it's
  /// available. Otherwise, uncaught Errors will be thrown.
  /// See [Can I Use - Web Share API](https://caniuse.com/web-share) to
  /// understand which browsers are supported. This builds on the
  /// [`cross_file`](https://pub.dev/packages/cross_file) package.
  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    // See https://developer.mozilla.org/en-US/docs/Web/API/Navigator/share

    final webFiles = <html.File>[];
    for (final xFile in files) {
      webFiles.add(await _fromXFile(xFile));
    }
    await _navigator.share({
      if (subject?.isNotEmpty ?? false) 'title': subject,
      if (text?.isNotEmpty ?? false) 'text': text,
      if (webFiles.isNotEmpty) 'files': webFiles,
    });

    return _resultUnavailable;
  }

  static Future<html.File> _fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return html.File(
      [ByteData.sublistView(bytes)],
      file.name,
      {
        'type': file.mimeType ?? _mimeTypeForPath(file, bytes),
      },
    );
  }

  static String _mimeTypeForPath(XFile file, Uint8List bytes) {
    return lookupMimeType(file.name, headerBytes: bytes) ??
        'application/octet-stream';
  }
}

const _resultUnavailable = ShareResult(
  'dev.fluttercommunity.plus/share/unavailable',
  ShareResultStatus.unavailable,
);
