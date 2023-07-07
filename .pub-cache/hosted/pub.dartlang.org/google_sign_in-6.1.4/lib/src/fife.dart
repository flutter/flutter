// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A regular expression that matches against the "size directive" path
/// segment of Google profile image URLs.
///
/// The format is is "`/sNN-c/`", where `NN` is the max width/height of the
/// image, and "`c`" indicates we want the image cropped.
final RegExp sizeDirective = RegExp(r'^s[0-9]{1,5}(-c)?$');

/// Adds [size] (and crop) directive to [photoUrl].
///
/// There are two formats for photoUrls coming from the Sign In backend.
///
/// The two formats can be told apart by the number of path segments in the
/// URL (path segments: parts of the URL separated by slashes "/"):
///
///  * If the URL has 2 or less path segments, it is a *new* style URL.
///  * If the URL has more than 2 path segments, it is an old style URL.
///
/// Old style URLs encode the image transformation directives as the last
/// path segment. Look at the [sizeDirective] Regular Expression for more
/// information about these URLs.
///
/// New style URLs carry the same directives at the end of the URL,
/// after an = sign, like: "`=s120-c-fSoften=1,50,0`".
///
/// Directives may contain the "=" sign (`fSoften=1,50,0`), but it seems the
/// base URL of the images don't. "Everything after the first = sign" is a
/// good heuristic to split new style URLs.
///
/// Each directive is separated from others by dashes. Directives are the same
/// as described in the [sizeDirective] RegExp.
///
/// Modified image URLs are recomposed by performing the parsing steps in reverse.
String addSizeDirectiveToUrl(String photoUrl, double size) {
  final Uri profileUri = Uri.parse(photoUrl);
  final List<String> pathSegments = List<String>.from(profileUri.pathSegments);
  if (pathSegments.length <= 2) {
    final String imagePath = pathSegments.last;
    // Does this have any existing transformation directives?
    final int directiveSeparator = imagePath.indexOf('=');
    if (directiveSeparator >= 0) {
      // Split the baseUrl from the sizing directive by the first "="
      final String baseUrl = imagePath.substring(0, directiveSeparator);
      final String directive = imagePath.substring(directiveSeparator + 1);
      // Split the directive by "-"
      final Set<String> directives = Set<String>.from(directive.split('-'))
        // Remove the size directive, if present, and any empty values
        ..removeWhere((String s) => s.isEmpty || sizeDirective.hasMatch(s))
        // Add the size and crop directives
        ..addAll(<String>['c', 's${size.round()}']);
      // Recompose the URL by performing the reverse of the parsing
      pathSegments.last = '$baseUrl=${directives.join("-")}';
    } else {
      pathSegments.last = '${pathSegments.last}=c-s${size.round()}';
    }
  } else {
    // Old style URLs
    pathSegments
      ..removeWhere(sizeDirective.hasMatch)
      ..insert(pathSegments.length - 1, 's${size.round()}-c');
  }
  return Uri(
    scheme: profileUri.scheme,
    host: profileUri.host,
    pathSegments: pathSegments,
  ).toString();
}
