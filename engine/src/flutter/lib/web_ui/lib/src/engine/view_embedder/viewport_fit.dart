// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The `viewport-fit` descriptor of a viewport meta tag.
///
/// The values are the ones defined by the CSS Round Display specification,
/// <https://www.w3.org/TR/css-round-display-1/#viewport-fit-descriptor>.
/// Only [cover] lays the page out underneath the parts of the screen that the
/// device obstructs, and so makes `env(safe-area-inset-*)` meaningful.
enum ViewportFit {
  auto,
  contain,
  cover;

  /// The descriptor, as it is spelled in the `content` of a viewport meta tag.
  String get descriptor => 'viewport-fit=$name';
}

/// Matches a `viewport-fit` descriptor within the `content` of a viewport meta
/// tag, and captures its value.
///
/// Browsers accept commas, semicolons and whitespace as separators between the
/// descriptors of a viewport meta tag, and the descriptors themselves are
/// case-insensitive, so all of that has to be tolerated here. The value is
/// restricted to the ones of [ViewportFit], so that only well-known descriptors
/// can ever make it into the meta tag that the engine writes.
final RegExp _viewportFitPattern = RegExp(
  r'(?:^|[,;\s])viewport-fit\s*=\s*(auto|contain|cover)(?=$|[,;\s])',
  caseSensitive: false,
);

/// Reads the [ViewportFit] declared by [content], the `content` attribute of a
/// viewport meta tag, or null if it declares none that the engine knows about.
///
/// Both the engine and the app it embeds declare their `viewport-fit` this way,
/// and both are read back with this function, so that whatever one of them can
/// write, the other can read.
ViewportFit? readViewportFit(String? content) {
  if (content == null) {
    return null;
  }
  // The last declaration wins, as it does in the browser.
  final String? value = _viewportFitPattern.allMatches(content).lastOrNull?.group(1);
  if (value == null) {
    return null;
  }
  final String lowerCased = value.toLowerCase();
  return ViewportFit.values.firstWhere((ViewportFit fit) => fit.name == lowerCased);
}

/// Splits [content], the `content` attribute of a viewport meta tag, into its
/// descriptors, keyed by a lower-cased name.
///
/// Used to work out whether the tag the engine is about to write says
/// everything an existing tag on the page said, and so whether replacing it
/// loses anything worth warning about.
Map<String, String> parseViewportContent(String? content) {
  if (content == null) {
    return const <String, String>{};
  }
  final descriptors = <String, String>{};
  // Close up the spacing around the separators first: whitespace is itself a
  // separator between descriptors, so `width = device-width` would otherwise
  // split into three tokens and be dropped. `readViewportFit` tolerates the
  // same spacing, and the two have to agree.
  final String closedUp = content.replaceAll(RegExp(r'\s*=\s*'), '=');
  for (final String descriptor in closedUp.split(RegExp(r'[,;\s]+'))) {
    final int separator = descriptor.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    final String name = descriptor.substring(0, separator).trim().toLowerCase();
    final String value = descriptor.substring(separator + 1).trim().toLowerCase();
    if (name.isNotEmpty && value.isNotEmpty) {
      descriptors[name] = value;
    }
  }
  return descriptors;
}
