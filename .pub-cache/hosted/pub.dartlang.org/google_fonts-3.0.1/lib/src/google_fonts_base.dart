// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../google_fonts.dart';
import 'asset_manifest.dart';
import 'file_io.dart' // Stubbed implementation by default.
    // Concrete implementation if File IO is available.
    if (dart.library.io) 'file_io_desktop_and_mobile.dart' as file_io;
import 'google_fonts_descriptor.dart';
import 'google_fonts_family_with_variant.dart';
import 'google_fonts_variant.dart';

// Keep track of the fonts that are loaded or currently loading in FontLoader
// for the life of the app instance. Once a font is attempted to load, it does
// not need to be attempted to load again, unless the attempted load resulted
// in an error.
final Set<String> _loadedFonts = {};

@visibleForTesting
http.Client httpClient = http.Client();

@visibleForTesting
AssetManifest assetManifest = AssetManifest();

@visibleForTesting
void clearCache() => _loadedFonts.clear();

/// Creates a [TextStyle] that either uses the [fontFamily] for the requested
/// GoogleFont, or falls back to the pre-bundled [fontFamily].
///
/// This function has a side effect of loading the font into the [FontLoader],
/// either by network or from the device file system.
TextStyle googleFontsTextStyle({
  required String fontFamily,
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  required Map<GoogleFontsVariant, GoogleFontsFile> fonts,
}) {
  textStyle ??= const TextStyle();
  textStyle = textStyle.copyWith(
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );

  final variant = GoogleFontsVariant(
    fontWeight: textStyle.fontWeight ?? FontWeight.w400,
    fontStyle: textStyle.fontStyle ?? FontStyle.normal,
  );
  final matchedVariant = _closestMatch(variant, fonts.keys);
  final familyWithVariant = GoogleFontsFamilyWithVariant(
    family: fontFamily,
    googleFontsVariant: matchedVariant,
  );

  final descriptor = GoogleFontsDescriptor(
    familyWithVariant: familyWithVariant,
    file: fonts[matchedVariant]!,
  );

  loadFontIfNecessary(descriptor);

  return textStyle.copyWith(
    fontFamily: familyWithVariant.toString(),
    fontFamilyFallback: [fontFamily],
  );
}

/// Loads a font into the [FontLoader] with [googleFontsFamilyName] for the
/// matching [expectedFileHash].
///
/// If a font with the [fontName] has already been loaded into memory, then
/// this method does nothing as there is no need to load it a second time.
///
/// Otherwise, this method will first check to see if the font is available
/// as an asset, then on the device file system. If it isn't, it is fetched via
/// the [fontUrl] and stored on device. In all cases, the font is loaded into
/// the [FontLoader].
Future<void> loadFontIfNecessary(GoogleFontsDescriptor descriptor) async {
  final familyWithVariantString = descriptor.familyWithVariant.toString();
  final fontName = descriptor.familyWithVariant.toApiFilenamePrefix();
  final fileHash = descriptor.file.expectedFileHash;
  // If this font has already already loaded or is loading, then there is no
  // need to attempt to load it again, unless the attempted load results in an
  // error.
  if (_loadedFonts.contains(familyWithVariantString)) {
    return;
  } else {
    _loadedFonts.add(familyWithVariantString);
  }

  try {
    Future<ByteData?>? byteData;

    // Check if this font can be loaded by the pre-bundled assets.
    final assetManifestJson = await assetManifest.json();
    final assetPath = _findFamilyWithVariantAssetPath(
      descriptor.familyWithVariant,
      assetManifestJson,
    );
    if (assetPath != null) {
      byteData = rootBundle.load(assetPath);
    }
    if (await byteData != null) {
      return loadFontByteData(familyWithVariantString, byteData);
    }

    // Check if this font can be loaded from the device file system.
    byteData = file_io.loadFontFromDeviceFileSystem(
      name: familyWithVariantString,
      fileHash: fileHash,
    );

    if (await byteData != null) {
      return loadFontByteData(familyWithVariantString, byteData);
    }

    // Attempt to load this font via http, unless disallowed.
    if (GoogleFonts.config.allowRuntimeFetching) {
      byteData = _httpFetchFontAndSaveToDevice(
        familyWithVariantString,
        descriptor.file,
      );
      if (await byteData != null) {
        return loadFontByteData(familyWithVariantString, byteData);
      }
    } else {
      throw Exception(
        'GoogleFonts.config.allowRuntimeFetching is false but font $fontName was not '
        'found in the application assets. Ensure $fontName.ttf exists in a '
        "folder that is included in your pubspec's assets.",
      );
    }
  } catch (e) {
    _loadedFonts.remove(familyWithVariantString);
    print('Error: google_fonts was unable to load font $fontName because the '
        'following exception occurred:\n$e');
    if (file_io.isTest) {
      print('\nThere is likely something wrong with your test. Please see '
          'https://github.com/material-foundation/google-fonts-flutter/blob/main/example/test '
          'for examples of how to test with google_fonts.');
    } else if (file_io.isMacOS || file_io.isAndroid) {
      print(
        '\nSee https://docs.flutter.dev/development/data-and-backend/networking#platform-notes.',
      );
    }
    print('If troubleshooting doesn\'t solve the problem, please file an issue '
        'at https://github.com/material-foundation/google-fonts-flutter/issues/new .\n');
  }
}

/// Loads a font with [FontLoader], given its name and byte-representation.
@visibleForTesting
Future<void> loadFontByteData(
  String familyWithVariantString,
  Future<ByteData?>? byteData,
) async {
  if (byteData == null) return;
  final fontData = await byteData;
  if (fontData == null) return;

  final fontLoader = FontLoader(familyWithVariantString);
  fontLoader.addFont(Future.value(fontData));
  await fontLoader.load();
}

/// Returns [GoogleFontsVariant] from [variantsToCompare] that most closely
/// matches [sourceVariant] according to the [_computeMatch] scoring function.
///
/// This logic is derived from the following section of the minikin library,
/// which is ultimately how flutter handles matching fonts.
/// https://github.com/flutter/engine/blob/master/third_party/txt/src/minikin/FontFamily.cpp#L149
GoogleFontsVariant _closestMatch(
  GoogleFontsVariant sourceVariant,
  Iterable<GoogleFontsVariant> variantsToCompare,
) {
  int? bestScore;
  late GoogleFontsVariant bestMatch;
  for (final variantToCompare in variantsToCompare) {
    final score = _computeMatch(sourceVariant, variantToCompare);
    if (bestScore == null || score < bestScore) {
      bestScore = score;
      bestMatch = variantToCompare;
    }
  }
  return bestMatch;
}

/// Fetches a font with [fontName] from the [fontUrl] and saves it locally if
/// it is the first time it is being loaded.
///
/// This function can return `null` if the font fails to load from the URL.
Future<ByteData> _httpFetchFontAndSaveToDevice(
  String fontName,
  GoogleFontsFile file,
) async {
  final uri = Uri.tryParse(file.url);
  if (uri == null) {
    throw Exception('Invalid fontUrl: ${file.url}');
  }

  http.Response response;
  try {
    response = await httpClient.get(uri);
  } catch (e) {
    throw Exception('Failed to load font with url: ${file.url}');
  }
  if (response.statusCode == 200) {
    if (!_isFileSecure(file, response.bodyBytes)) {
      throw Exception(
        'File from ${file.url} did not match expected length and checksum.',
      );
    }

    _unawaited(file_io.saveFontToDeviceFileSystem(
      name: fontName,
      fileHash: file.expectedFileHash,
      bytes: response.bodyBytes,
    ));

    return ByteData.view(response.bodyBytes.buffer);
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load font with url: ${file.url}');
  }
}

// This logic is taken from the following section of the minikin library, which
// is ultimately how flutter handles matching fonts.
// * https://github.com/flutter/engine/blob/master/third_party/txt/src/minikin/FontFamily.cpp#L128
int _computeMatch(GoogleFontsVariant a, GoogleFontsVariant b) {
  if (a == b) {
    return 0;
  }
  int score = (a.fontWeight.index - b.fontWeight.index).abs();
  if (a.fontStyle != b.fontStyle) {
    score += 2;
  }
  return score;
}

/// Looks for a matching [familyWithVariant] font, provided the asset manifest.
/// Returns the path of the font asset if found, otherwise an empty string.
String? _findFamilyWithVariantAssetPath(
  GoogleFontsFamilyWithVariant familyWithVariant,
  Map<String, List<String>>? manifestJson,
) {
  if (manifestJson == null) return null;

  final apiFilenamePrefix = familyWithVariant.toApiFilenamePrefix();

  for (final assetList in manifestJson.values) {
    for (final String asset in assetList) {
      for (final matchingSuffix in ['.ttf', '.otf'].where(asset.endsWith)) {
        final assetWithoutExtension =
            asset.substring(0, asset.length - matchingSuffix.length);
        if (assetWithoutExtension.endsWith(apiFilenamePrefix)) {
          return asset;
        }
      }
    }
  }

  return null;
}

bool _isFileSecure(GoogleFontsFile file, Uint8List bytes) {
  final actualFileLength = bytes.length;
  final actualFileHash = sha256.convert(bytes).toString();
  return file.expectedLength == actualFileLength &&
      file.expectedFileHash == actualFileHash;
}

void _unawaited(Future<void> future) {}
