// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as system;

import 'cache.dart';
import 'patterns.dart';
import 'limits.dart';

class FetchedContentsOf extends Key { FetchedContentsOf(dynamic value) : super(value); }

enum LicenseType { unknown, bsd, gpl, lgpl, mpl, afl, mit, freetype, apache, apacheNotice, eclipse, ijg, zlib, icu, apsl, libpng, openssl }

LicenseType convertLicenseNameToType(String name) {
  switch (name) {
    case 'Apache':
    case 'apache-license-2.0':
    case 'LICENSE-APACHE-2.0.txt':
      return LicenseType.apache;
    case 'BSD':
    case 'BSD.txt':
      return LicenseType.bsd;
    case 'LICENSE-LGPL-2':
    case 'LICENSE-LGPL-2.1':
    case 'COPYING-LGPL-2.1':
      return LicenseType.lgpl;
    case 'COPYING-GPL-3':
      return LicenseType.gpl;
    case 'FTL.TXT':
      return LicenseType.freetype;
    case 'zlib.h':
      return LicenseType.zlib;
    case 'png.h':
      return LicenseType.libpng;
    case 'ICU':
      return LicenseType.icu;
    case 'Apple Public Source License':
      return LicenseType.apsl;
    case 'OpenSSL':
      return LicenseType.openssl;
    case 'LICENSE.MPLv2':
    case 'COPYING-MPL-1.1':
      return LicenseType.mpl;
    // common file names that don't say what the type is
    case 'COPYING':
    case 'COPYING.txt':
    case 'COPYING.LIB': // lgpl usually
    case 'COPYING.RUNTIME': // gcc exception usually
    case 'LICENSE':
    case 'LICENSE.md':
    case 'license.html':
    case 'LICENSE.txt':
    case 'LICENSE.TXT':
    case 'LICENSE.cssmin':
    case 'NOTICE':
    case 'NOTICE.txt':
    case 'Copyright':
    case 'copyright':
    case 'license.txt':
      return LicenseType.unknown;
    // particularly weird file names
    case 'LICENSE-APPLE':
    case 'extreme.indiana.edu.license.TXT':
    case 'extreme.indiana.edu.license.txt':
    case 'javolution.license.TXT':
    case 'javolution.license.txt':
    case 'libyaml-license.txt':
    case 'license.patch':
    case 'license.rst':
    case 'LICENSE.rst':
    case 'mh-bsd-gcc':
    case 'pivotal.labs.license.txt':
      return LicenseType.unknown;
  }
  throw 'unknown license type: $name';
}

LicenseType convertBodyToType(String body) {
  if (body.startsWith(lrApache))
    return LicenseType.apache;
  if (body.startsWith(lrMPL))
    return LicenseType.mpl;
  if (body.startsWith(lrGPL))
    return LicenseType.gpl;
  if (body.startsWith(lrAPSL))
    return LicenseType.apsl;
  if (body.contains(lrOpenSSL))
    return LicenseType.openssl;
  if (body.contains(lrBSD))
    return LicenseType.bsd;
  if (body.contains(lrMIT))
    return LicenseType.mit;
  if (body.contains(lrZlib))
    return LicenseType.zlib;
  if (body.contains(lrPNG))
    return LicenseType.libpng;
  return LicenseType.unknown;
}

abstract class LicenseSource {
  List<License> nearestLicensesFor(String name);
  License nearestLicenseOfType(LicenseType type);
  License nearestLicenseWithName(String name, { String authors });
}

abstract class License implements Comparable<License> {
  factory License.unique(String body, LicenseType type, { bool reformatted: false, String origin, bool yesWeKnowWhatItLooksLikeButItIsNot: false }) {
    if (!reformatted)
      body = _reformat(body);
    final License result = _registry.putIfAbsent(body, () => UniqueLicense._(body, type, origin: origin, yesWeKnowWhatItLooksLikeButItIsNot: yesWeKnowWhatItLooksLikeButItIsNot));
    assert(() {
      if (result is! UniqueLicense || result.type != type)
        throw 'tried to add a UniqueLicense $type, but it was a duplicate of a ${result.runtimeType} ${result.type}';
      return true;
    }());
    return result;
  }

  factory License.template(String body, LicenseType type, { bool reformatted: false, String origin }) {
    if (!reformatted)
      body = _reformat(body);
    final License result = _registry.putIfAbsent(body, () => TemplateLicense._(body, type, origin: origin));
    assert(() {
      if (result is! TemplateLicense || result.type != type)
        throw 'tried to add a TemplateLicense $type, but it was a duplicate of a ${result.runtimeType} ${result.type}';
      return true;
    }());
    return result;
  }

  factory License.message(String body, LicenseType type, { bool reformatted: false, String origin }) {
    if (!reformatted)
      body = _reformat(body);
    final License result = _registry.putIfAbsent(body, () => MessageLicense._(body, type, origin: origin));
    assert(() {
      if (result is! MessageLicense || result.type != type)
        throw 'tried to add a MessageLicense $type, but it was a duplicate of a ${result.runtimeType} ${result.type}';
      return true;
    }());
    return result;
  }

  factory License.blank(String body, LicenseType type, { String origin }) {
    final License result = _registry.putIfAbsent(body, () => BlankLicense._(_reformat(body), type, origin: origin));
    assert(() {
      if (result is! BlankLicense || result.type != type)
        throw 'tried to add a BlankLicense $type, but it was a duplicate of a ${result.runtimeType} ${result.type}';
      return true;
    }());
    return result;
  }

  factory License.fromMultipleBlocks(List<String> bodies, LicenseType type) {
    final String body = bodies.map((String s) => _reformat(s)).join('\n\n');
    return _registry.putIfAbsent(body, () => UniqueLicense._(body, type));
  }

  factory License.fromBodyAndType(String body, LicenseType type, { bool reformatted: false, String origin }) {
    if (!reformatted)
      body = _reformat(body);
    final License result = _registry.putIfAbsent(body, () {
      switch (type) {
        case LicenseType.bsd:
        case LicenseType.mit:
        case LicenseType.zlib:
        case LicenseType.icu:
          return TemplateLicense._(body, type, origin: origin);
        case LicenseType.unknown:
        case LicenseType.apacheNotice:
          return UniqueLicense._(body, type, origin: origin);
        case LicenseType.afl:
        case LicenseType.mpl:
        case LicenseType.gpl:
        case LicenseType.lgpl:
        case LicenseType.freetype:
        case LicenseType.apache:
        case LicenseType.eclipse:
        case LicenseType.ijg:
        case LicenseType.apsl:
          return MessageLicense._(body, type, origin: origin);
        case LicenseType.openssl:
          return MultiLicense._(body, type, origin: origin);
        case LicenseType.libpng:
          return BlankLicense._(body, type, origin: origin);
      }
    });
    assert(result.type == type);
    return result;
  }

  factory License.fromBodyAndName(String body, String name, { String origin }) {
    body = _reformat(body);
    LicenseType type = convertLicenseNameToType(name);
    if (type == LicenseType.unknown)
      type = convertBodyToType(body);
    return License.fromBodyAndType(body, type, origin: origin);
  }

  factory License.fromBody(String body, { String origin }) {
    body = _reformat(body);
    final LicenseType type = convertBodyToType(body);
    return License.fromBodyAndType(body, type, reformatted: true, origin: origin);
  }

  factory License.fromCopyrightAndLicense(String copyright, String template, LicenseType type, { String origin }) {
    final String body = '$copyright\n\n$template';
    return _registry.putIfAbsent(body, () => TemplateLicense._(body, type, origin: origin));
  }

  factory License.fromUrl(String url, { String origin }) {
    String body;
    LicenseType type = LicenseType.unknown;
    switch (url) {
      case 'Apache:2.0':
      case 'http://www.apache.org/licenses/LICENSE-2.0':
        body = system.File('data/apache-license-2.0').readAsStringSync();
        type = LicenseType.apache;
        break;
      case 'https://developers.google.com/open-source/licenses/bsd':
        body = system.File('data/google-bsd').readAsStringSync();
        type = LicenseType.bsd;
        break;
      case 'http://polymer.github.io/LICENSE.txt':
        body = system.File('data/polymer-bsd').readAsStringSync();
        type = LicenseType.bsd;
        break;
      case 'http://www.eclipse.org/legal/epl-v10.html':
        body = system.File('data/eclipse-1.0').readAsStringSync();
        type = LicenseType.eclipse;
        break;
      case 'COPYING3:3':
        body = system.File('data/gpl-3.0').readAsStringSync();
        type = LicenseType.gpl;
        break;
      case 'COPYING.LIB:2':
      case 'COPYING.LIother.m_:2': // blame hyatt
        body = system.File('data/library-gpl-2.0').readAsStringSync();
        type = LicenseType.lgpl;
        break;
      case 'GNU Lesser:2':
        // there has never been such a license, but the authors said they meant the LGPL2.1
      case 'GNU Lesser:2.1':
        body = system.File('data/lesser-gpl-2.1').readAsStringSync();
        type = LicenseType.lgpl;
        break;
      case 'COPYING.RUNTIME:3.1':
      case 'GCC Runtime Library Exception:3.1':
        body = system.File('data/gpl-gcc-exception-3.1').readAsStringSync();
        break;
      case 'Academic Free License:3.0':
        body = system.File('data/academic-3.0').readAsStringSync();
        type = LicenseType.afl;
        break;
      case 'http://mozilla.org/MPL/2.0/:2.0':
        body = system.File('data/mozilla-2.0').readAsStringSync();
        type = LicenseType.mpl;
        break;
      case 'http://opensource.org/licenses/MIT':
      case 'http://opensource->org/licenses/MIT': // i don't even
        body = system.File('data/mit').readAsStringSync();
        type = LicenseType.mit;
        break;
      case 'http://www.unicode.org/copyright.html':
        body = system.File('data/unicode').readAsStringSync();
        type = LicenseType.icu;
        break;
      default: throw 'unknown url $url';
    }
    return _registry.putIfAbsent(body, () => License.fromBodyAndType(body, type, origin: origin));
  }

  License._(String body, this.type, { this.origin, bool yesWeKnowWhatItLooksLikeButItIsNot: false }) : body = body, authors = _readAuthors(body) {
    assert(_reformat(body) == body);
    assert(() {
      try {
        switch (type) {
          case LicenseType.bsd:
          case LicenseType.mit:
          case LicenseType.zlib:
          case LicenseType.icu:
            assert(this is TemplateLicense);
            break;
          case LicenseType.unknown:
            assert(this is UniqueLicense || this is BlankLicense);
            break;
          case LicenseType.apacheNotice:
            assert(this is UniqueLicense);
            break;
          case LicenseType.afl:
          case LicenseType.mpl:
          case LicenseType.gpl:
          case LicenseType.lgpl:
          case LicenseType.freetype:
          case LicenseType.apache:
          case LicenseType.eclipse:
          case LicenseType.ijg:
          case LicenseType.apsl:
            assert(this is MessageLicense);
            break;
          case LicenseType.libpng:
            assert(this is BlankLicense);
            break;
          case LicenseType.openssl:
            assert(this is MultiLicense);
            break;
        }
      } on AssertionError {
        throw 'incorrectly created a $runtimeType for a $type';
      }
      return true;
    }());
    final LicenseType detectedType = convertBodyToType(body);
    if (detectedType != LicenseType.unknown && detectedType != type && !yesWeKnowWhatItLooksLikeButItIsNot)
      throw 'Created a license of type $type but it looks like $detectedType\.';
    if (type != LicenseType.apache && type != LicenseType.apacheNotice) {
      if (!yesWeKnowWhatItLooksLikeButItIsNot && body.contains('Apache'))
        throw 'Non-Apache license (type=$type, detectedType=$detectedType) contains the word "Apache"; maybe it\'s a notice?:\n---\n$body\n---';
    }
    if (body.contains(trailingColon))
      throw 'incomplete license detected:\n---\n$body\n---';
    // if (type == LicenseType.unknown)
    //   print('need detector for:\n----\n$body\n----');
    bool isUTF8 = true;
    List<int> latin1Encoded;
    try {
      latin1Encoded = latin1.encode(body);
      isUTF8 = false;
    } on ArgumentError { }
    if (!isUTF8) {
      bool isAscii = false;
      try {
        ascii.decode(latin1Encoded);
        isAscii = true;
      } on FormatException { }
      if (isAscii)
        return;
      try {
        utf8.decode(latin1Encoded);
        isUTF8 = true;
      } on FormatException { }
      if (isUTF8)
        throw 'tried to create a License object with text that appears to have been misdecoded as Latin1 instead of as UTF-8:\n$body';
    }
  }

  final String body;
  final String authors;
  final String origin;
  final LicenseType type;

  Iterable<String> get licensees => _licensees;
  List<String> _licensees = <String>[];
  Set<String> _libraries = Set<String>();

  bool get isUsed => _licensees.isNotEmpty;

  void markUsed(String filename, String libraryName) {
    assert(libraryName != null);
    assert(libraryName != '');
    filename != null;
    _licensees.add(filename);
    _libraries.add(libraryName);
  }

  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin });

  @override
  int compareTo(License other) => toString().compareTo(other.toString());

  @override
  String toString() {
    final List<String> prefixes = _libraries.toList();
    prefixes.sort();
    _licensees.sort();
    final List<String> header = <String>[];
    header.addAll(prefixes.map((String s) => 'LIBRARY: $s'));
    header.add('ORIGIN: $origin');
    header.add('TYPE: $type');
    header.addAll(licensees.map((String s) => 'FILE: $s'));
    return ('=' * 100) + '\n' +
           header.join('\n') +
           '\n' +
           ('-' * 100) + '\n' +
           toStringBody() + '\n' +
           ('=' * 100);
  }

  String toStringBody() => body;

  String toStringFormal() {
    final List<String> prefixes = _libraries.toList();
    prefixes.sort();
    return prefixes.join('\n') + '\n\n' + body;
  }

  static final RegExp _copyrightForAuthors = RegExp(
    r'Copyright [-0-9 ,(cC)©]+\b(The .+ Authors)\.',
    caseSensitive: false
  );

  static String _readAuthors(String body) {
    final List<Match> matches = _copyrightForAuthors.allMatches(body).toList();
    if (matches.isEmpty)
      return null;
    if (matches.length > 1)
      throw 'found too many authors for this copyright:\n$body';
    return matches[0].group(1);
  }
}


final Map<String, License> _registry = <String, License>{};

void clearLicenseRegistry() {
  _registry.clear();
}

final License missingLicense = UniqueLicense._('<missing>', LicenseType.unknown);

String _reformat(String body) {
  // TODO(ianh): ensure that we're stripping the same amount of leading text on each line
  final List<String> lines = body.split('\n');
  while (lines.isNotEmpty && lines.first == '')
    lines.removeAt(0);
  while (lines.isNotEmpty && lines.last == '')
    lines.removeLast();
  if (lines.length > 2) {
    if (lines[0].startsWith(beginLicenseBlock) && lines.last.startsWith(endLicenseBlock)) {
      lines.removeAt(0);
      lines.removeLast();
    }
  } else if (lines.isEmpty) {
    return '';
  }
  final List<String> output = <String>[];
  int lastGood;
  String previousPrefix;
  bool lastWasEmpty = true;
  for (String line in lines) {
    final Match match = stripDecorations.firstMatch(line);
    final String prefix = match.group(1);
    String s = match.group(2);
    if (!lastWasEmpty || s != '') {
      if (s != '') {
        if (previousPrefix != null) {
          if (previousPrefix.length > prefix.length) {
            // TODO(ianh): Spot check files that hit this. At least one just
            // has a corrupt license block, which is why this is commented out.
            //if (previousPrefix.substring(prefix.length).contains(nonSpace))
            //  throw 'inconsistent line prefix: was "$previousPrefix", now "$prefix"\nfull body was:\n---8<---\n$body\n---8<---';
            previousPrefix = prefix;
          } else if (previousPrefix.length < prefix.length) {
            s = '${prefix.substring(previousPrefix.length)}$s';
          }
        } else {
          previousPrefix = prefix;
        }
        lastWasEmpty = false;
        lastGood = output.length + 1;
      } else {
        lastWasEmpty = true;
      }
      output.add(s);
    }
  }
  if (lastGood == null) {
    print('_reformatted to nothing:\n----\n|${body.split("\n").join("|\n|")}|\n----');
    assert(lastGood != null);
    throw 'reformatted to nothing:\n$body';
  }
  return output.take(lastGood).join('\n');
}

class _LineRange {
  _LineRange(this.start, this.end, this._body);
  final int start;
  final int end;
  final String _body;
  String _value;
  String get value {
    _value ??= _body.substring(start, end);
    return _value;
  }
}

Iterable<_LineRange> _walkLinesBackwards(String body, int start) sync* {
  int end;
  while (start > 0) {
    start -= 1;
    if (body[start] == '\n') {
      if (end != null)
        yield _LineRange(start + 1, end, body);
      end = start;
    }
  }
  if (end != null)
    yield _LineRange(start, end, body);
}

Iterable<_LineRange> _walkLinesForwards(String body, { int start: 0, int end }) sync* {
  int startIndex = start == 0 || body[start-1] == '\n' ? start : null;
  int endIndex = startIndex ?? start;
  end ??= body.length;
  while (endIndex < end) {
    if (body[endIndex] == '\n') {
      if (startIndex != null)
        yield _LineRange(startIndex, endIndex, body);
      startIndex = endIndex + 1;
    }
    endIndex += 1;
  }
  if (startIndex != null)
    yield _LineRange(startIndex, endIndex, body);
}

class _SplitLicense {
  _SplitLicense(this._body, this._split) {
    assert(this._split == 0 || this._split == this._body.length || this._body[this._split] == '\n');
  }
  final String _body;
  final int _split;
  String getCopyright() => _body.substring(0, _split);
  String getConditions() => _split >= _body.length ? '' : _body.substring(_split == 0 ? 0 : _split + 1);
}

_SplitLicense _splitLicense(String body, { bool verifyResults: true }) {
  final Iterator<_LineRange> lines = _walkLinesForwards(body).iterator;
  if (!lines.moveNext())
    throw 'tried to split empty license';
  int end = 0;
  while (true) { // ignore: literal_only_boolean_expressions
    final String line = lines.current.value;
    if (line == 'Author:' ||
        line == 'This code is derived from software contributed to Berkeley by' ||
        line == 'The Initial Developer of the Original Code is') {
      if (!lines.moveNext())
        throw 'unexpected end of block instead of author when looking for copyright';
      if (lines.current.value.trim() == '')
        throw 'unexpectedly blank line instead of author when looking for copyright';
      end = lines.current.end;
      if (!lines.moveNext())
        break;
    } else if (line.startsWith('Authors:') || line == 'Other contributors:') {
      if (line != 'Authors:') {
        // assume this line contained an author as well
        end = lines.current.end;
      }
      if (!lines.moveNext())
        throw 'unexpected end of license when reading list of authors while looking for copyright';
      final String firstAuthor = lines.current.value;
      int subindex = 0;
      while (subindex < firstAuthor.length && (firstAuthor[subindex] == ' ' ||
                                               firstAuthor[subindex] == '\t'))
        subindex += 1;
      if (subindex == 0 || subindex > firstAuthor.length)
        throw 'unexpected blank line instead of authors found when looking for copyright';
      end = lines.current.end;
      final String prefix = firstAuthor.substring(0, subindex);
      while (lines.moveNext() && lines.current.value.startsWith(prefix)) {
        final String nextAuthor = lines.current.value.substring(prefix.length);
        if (nextAuthor == '' || nextAuthor[0] == ' ' || nextAuthor[0] == '\t')
          throw 'unexpectedly ragged author list when looking for copyright';
        end = lines.current.end;
      }
      if (lines.current == null)
        break;
    } else if (line.contains(halfCopyrightPattern)) {
      do {
        if (!lines.moveNext())
          throw 'unexpected end of block instead of copyright holder when looking for copyright';
        if (lines.current.value.trim() == '')
          throw 'unexpectedly blank line instead of copyright holder when looking for copyright';
        end = lines.current.end;
      } while (lines.current.value.contains(trailingComma));
      if (!lines.moveNext())
        break;
    } else if (copyrightStatementPatterns.every((RegExp pattern) => !line.contains(pattern))) {
      break;
    } else {
      end = lines.current.end;
      if (!lines.moveNext())
        break;
    }
  }
  if (verifyResults && 'Copyright ('.allMatches(body, end).isNotEmpty && !body.startsWith('If you modify libpng'))
    throw 'the license seems to contain a copyright:\n===copyright===\n${body.substring(0, end)}\n===license===\n${body.substring(end)}\n=========';
  return _SplitLicense(body, end);
}

class _PartialLicenseMatch {
  _PartialLicenseMatch(this._body, this.start, this.split, this.end, this._match, { this.hasCopyrights }) {
    assert(split >= start);
    assert(split == start || _body[split] == '\n');
  }
  final String _body;
  final int start;
  final int split;
  final int end;
  final Match _match;
  String group(int index) => _match.group(index);
  String getAuthors() {
    final Match match = authorPattern.firstMatch(getCopyrights());
    if (match != null)
      return match.group(1);
    return null;
  }
  String getCopyrights() => _body.substring(start, split);
  String getConditions() => _body.substring(split + 1, end);
  String getEntireLicense() => _body.substring(start, end);
  final bool hasCopyrights;
}

Iterable<_PartialLicenseMatch> _findLicenseBlocks(String body, RegExp pattern, int firstPrefixIndex, int indentPrefixIndex, { bool needsCopyright: true }) sync* {
  // I tried doing this with one big RegExp initially, but that way lay madness.
  for (Match match in pattern.allMatches(body)) {
    assert(match.groupCount >= firstPrefixIndex);
    assert(match.groupCount >= indentPrefixIndex);
    int start = match.start;
    final String fullPrefix = '${match.group(firstPrefixIndex)}${match.group(indentPrefixIndex)}';
    // first we walk back to the start of the block that has the same prefix (e.g.
    // the start of this comment block)
    bool firstLineSpecialComment = false;
    bool lastWasBlank = false;
    bool foundNonBlank = false;
    for (_LineRange range in _walkLinesBackwards(body, start)) {
      String line = range.value;
      bool isBlockCommentLine;
      if (line.length > 3 && line.endsWith('*/')) {
        int index = line.length - 3;
        while (line[index] == ' ')
          index -= 1;
        line = line.substring(0, index + 1);
        isBlockCommentLine = true;
      } else {
        isBlockCommentLine = false;
      }
      if (line.isEmpty || fullPrefix.startsWith(line)) {
        // this is blank line
        if (lastWasBlank && (foundNonBlank || !needsCopyright))
          break;
        lastWasBlank = true;
      } else if (((!isBlockCommentLine && line.startsWith('/*')) ||
                 line.startsWith('<!--') ||
                 (range.start == 0 && line.startsWith('  $fullPrefix')))) {
        start = range.start;
        firstLineSpecialComment = true;
        break;
      } else if (fullPrefix.isNotEmpty && !line.startsWith(fullPrefix)) {
        break;
      } else if (licenseFragments.any((RegExp pattern) => line.contains(pattern))) {
        // we're running into another license, abort, abort!
        break;
      } else {
        lastWasBlank = false;
        foundNonBlank = true;
      }
      start = range.start;
    }
    // then we walk forward dropping anything until the first line that matches what
    // we think might be part of a copyright statement
    bool foundAny = false;
    for (_LineRange range in _walkLinesForwards(body, start: start, end: match.start)) {
      final String line = range.value;
      if (firstLineSpecialComment || line.startsWith(fullPrefix)) {
        String data;
        if (firstLineSpecialComment) {
          data = stripDecorations.firstMatch(line).group(2);
        } else {
          data = line.substring(fullPrefix.length);
        }
        if (copyrightStatementLeadingPatterns.any((RegExp pattern) => data.contains(pattern))) {
          start = range.start;
          foundAny = true;
          break;
        }
      }
      firstLineSpecialComment = false;
    }
    // At this point we have figured out what might be copyright text before the license.
    int split;
    if (!foundAny) {
      if (needsCopyright)
        throw 'could not find copyright before license\nlicense body was:\n---\n${body.substring(match.start, match.end)}\n---\nfile was:\n---\n$body\n---';
      start = match.start;
      split = match.start;
    } else {
      final String copyrights = body.substring(start, match.start);
      final String undecoratedCopyrights = _reformat(copyrights);
      // Let's try splitting the copyright block as if it was a license.
      // This will tell us if we collected something in the copyright block
      // that was more license than copyright and that therefore should be
      // examined closer.
      final _SplitLicense sanityCheck = _splitLicense(undecoratedCopyrights, verifyResults: false);
      final String conditions = sanityCheck.getConditions();
      if (conditions != '')
        throw 'potential license text caught in _findLicenseBlocks copyright dragnet:\n---\n$conditions\n---\nundecorated copyrights was:\n---\n$undecoratedCopyrights\n---\ncopyrights was:\n---\n$copyrights\n---\nblock was:\n---\n${body.substring(start, match.end)}\n---';
      if (!copyrights.contains(copyrightMentionPattern))
        throw 'could not find copyright before license block:\n---\ncopyrights was:\n---\n$copyrights\n---\nblock was:\n---\n${body.substring(start, match.end)}\n---';
      if (body[match.start - 1] != '\n')
        print('about to assert; match.start = ${match.start}, match.end = ${match.end}, split at: "${body[match.start - 1]}"');
      assert(body[match.start - 1] == '\n');
      split = match.start - 1;
    }
    yield _PartialLicenseMatch(body, start, split, match.end, match, hasCopyrights: foundAny);
  }
}

class _LicenseMatch {
  _LicenseMatch(this.license, this.start, this.end, { this.debug: '', this.isDuplicate: false, this.missingCopyrights: false });
  final License license;
  final int start;
  final int end;
  final String debug;
  final bool isDuplicate;
  final bool missingCopyrights;
}

Iterable<_LicenseMatch> _expand(License template, String copyright, String body, int start, int end, { String debug: '', String origin }) sync* {
  final List<License> results = template.expandTemplate(_reformat(copyright), body, origin: origin).toList();
  if (results.isEmpty)
    throw 'license could not be expanded';
  yield _LicenseMatch(results.first, start, end, debug: 'expanding template for $debug');
  if (results.length > 1)
    yield* results.skip(1).map((License license) => _LicenseMatch(license, start, end, isDuplicate: true, debug: 'expanding subsequent template for $debug'));
}

Iterable<_LicenseMatch> _tryNone(String body, String filename, RegExp pattern, LicenseSource parentDirectory) sync* {
  for (Match match in pattern.allMatches(body)) {
    final List<License> results = parentDirectory.nearestLicensesFor(filename);
    if (results == null || results.isEmpty)
      throw 'no default license file found';
    // TODO(ianh): use _expand if the license asks for the copyright to be included (e.g. BSD)
    yield _LicenseMatch(results.first, match.start, match.end, debug: '_tryNone');
    if (results.length > 1)
      yield* results.skip(1).map((License license) => _LicenseMatch(license, match.start, match.end, isDuplicate: true, debug: 'subsequent _tryNone'));
  }
}

Iterable<_LicenseMatch> _tryAttribution(String body, RegExp pattern, { String origin }) sync* {
  for (Match match in pattern.allMatches(body)) {
    assert(match.groupCount == 2);
    yield _LicenseMatch(License.unique('Thanks to ${match.group(2)}.', LicenseType.unknown, origin: origin), match.start, match.end, debug: '_tryAttribution');
  }
}

Iterable<_LicenseMatch> _tryReferenceByFilename(String body, LicenseFileReferencePattern pattern, LicenseSource parentDirectory, { String origin }) sync* {
  if (pattern.copyrightIndex != null) {
    for (Match match in pattern.pattern.allMatches(body)) {
      final String copyright = match.group(pattern.copyrightIndex);
      final String authors = pattern.authorIndex != null ? match.group(pattern.authorIndex) : null;
      final String filename = match.group(pattern.fileIndex);
      final License template = parentDirectory.nearestLicenseWithName(filename, authors: authors);
      if (template == null)
        throw 'failed to find template $filename in $parentDirectory (authors=$authors)';
      assert(_reformat(copyright) != '');
      final String entireLicense = body.substring(match.start, match.end);
      yield* _expand(template, copyright, entireLicense, match.start, match.end, debug: '_tryReferenceByFilename (with explicit copyright) looking for $filename', origin: origin);
    }
  } else {
    for (_PartialLicenseMatch match in _findLicenseBlocks(body, pattern.pattern, pattern.firstPrefixIndex, pattern.indentPrefixIndex, needsCopyright: pattern.needsCopyright)) {
      final String authors = match.getAuthors();
      String filename = match.group(pattern.fileIndex);
      if (filename == 'modp_b64.c')
        filename = 'modp_b64.cc'; // it was renamed but other files reference the old name
      final License template = parentDirectory.nearestLicenseWithName(filename, authors: authors);
      if (template == null) {
        throw
          'failed to find accompanying "$filename" in $parentDirectory\n'
          'block:\n---\n${match.getEntireLicense()}\n---';
      }
      if (match.getCopyrights() == '') {
        yield _LicenseMatch(template, match.start, match.end, debug: '_tryReferenceByFilename (with failed copyright search) looking for $filename');
      } else {
        yield* _expand(template, match.getCopyrights(), match.getEntireLicense(), match.start, match.end, debug: '_tryReferenceByFilename (with successful copyright search) looking for $filename', origin: origin);
      }
    }
  }
}

Iterable<_LicenseMatch> _tryReferenceByType(String body, RegExp pattern, LicenseSource parentDirectory, { String origin, bool needsCopyright: true }) sync* {
  for (_PartialLicenseMatch match in _findLicenseBlocks(body, pattern, 1, 2, needsCopyright: needsCopyright)) {
    final LicenseType type = convertLicenseNameToType(match.group(3));
    final License template = parentDirectory.nearestLicenseOfType(type);
    if (template == null)
      throw 'failed to find accompanying $type license in $parentDirectory';
    assert(() {
      final String copyrights = _reformat(match.getCopyrights());
      assert(needsCopyright && copyrights.isNotEmpty || !needsCopyright && copyrights.isEmpty);
      return true;
    }());
    if (needsCopyright)
      yield* _expand(template, match.getCopyrights(), match.getEntireLicense(), match.start, match.end, debug: '_tryReferenceByType', origin: origin);
    else
      yield _LicenseMatch(template, match.start, match.end, debug: '_tryReferenceByType (without copyrights) for type $type');
  }
}

License _dereferenceLicense(int groupIndex, String group(int index), MultipleVersionedLicenseReferencePattern pattern, LicenseSource parentDirectory, { String origin }) {
  License result = pattern.checkLocalFirst ? parentDirectory.nearestLicenseWithName(group(groupIndex)) : null;
  if (result == null) {
    String suffix = '';
    if (pattern.versionIndicies != null && pattern.versionIndicies.containsKey(groupIndex))
      suffix = ':${group(pattern.versionIndicies[groupIndex])}';
    result = License.fromUrl('${group(groupIndex)}$suffix', origin: origin);
  }
  return result;
}

Iterable<_LicenseMatch> _tryReferenceByUrl(String body, MultipleVersionedLicenseReferencePattern pattern, LicenseSource parentDirectory, { String origin }) sync* {
  for (_PartialLicenseMatch match in _findLicenseBlocks(body, pattern.pattern, 1, 2, needsCopyright: false)) {
    bool isDuplicate = false;
    for (int index in pattern.licenseIndices) {
      final License result = _dereferenceLicense(index, match.group, pattern, parentDirectory, origin: origin);
      yield _LicenseMatch(result, match.start, match.end, isDuplicate: isDuplicate, debug: '_tryReferenceByUrl');
      isDuplicate = true;
    }
  }
}

Iterable<_LicenseMatch> _tryInline(String body, RegExp pattern, { bool needsCopyright, String origin }) sync* {
  assert(needsCopyright != null);
  for (_PartialLicenseMatch match in _findLicenseBlocks(body, pattern, 1, 2, needsCopyright: false)) {
    // We search with "needsCopyright: false" but then create a _LicenseMatch with
    // "missingCopyrights: true" if our own "needsCopyright" argument is true.
    // We use a template license here (not unique) because it's not uncommon for files
    // to reference license blocks in other files, but with their own copyrights.
    yield _LicenseMatch(License.fromBody(match.getEntireLicense(), origin: origin), match.start, match.end, debug: '_tryInline', missingCopyrights: needsCopyright && !match.hasCopyrights);
  }
}

Iterable<_LicenseMatch> _tryForwardReferencePattern(String fileContents, ForwardReferencePattern pattern, License template, { String origin }) sync* {
  for (_PartialLicenseMatch match in _findLicenseBlocks(fileContents, pattern.pattern, pattern.firstPrefixIndex, pattern.indentPrefixIndex)) {
    if (!template.body.contains(pattern.targetPattern)) {
      throw
        'forward license reference to unexpected license\n'
        'license:\n---\n${template.body}\n---\nexpected pattern:\n---\n${pattern.targetPattern}\n---';
    }
    yield* _expand(template, match.getCopyrights(), match.getEntireLicense(), match.start, match.end, debug: '_tryForwardReferencePattern', origin: origin);
  }
}

List<License> determineLicensesFor(String fileContents, String filename, LicenseSource parentDirectory, { String origin }) {
  if (fileContents.length > kMaxSize)
    fileContents = fileContents.substring(0, kMaxSize);
  final List<_LicenseMatch> results = <_LicenseMatch>[];
  fileContents = fileContents.replaceAll('\t', ' ');
  fileContents = fileContents.replaceAll(newlinePattern, '\n');
  results.addAll(csNoCopyrights.expand((RegExp pattern) => _tryNone(fileContents, filename, pattern, parentDirectory)));
  results.addAll(csAttribution.expand((RegExp pattern) => _tryAttribution(fileContents, pattern, origin: origin)));
  results.addAll(csReferencesByFilename.expand((LicenseFileReferencePattern pattern) => _tryReferenceByFilename(fileContents, pattern, parentDirectory, origin: origin)));
  results.addAll(csReferencesByType.expand((RegExp pattern) => _tryReferenceByType(fileContents, pattern, parentDirectory, origin: origin)));
  results.addAll(csReferencesByTypeNoCopyright.expand((RegExp pattern) => _tryReferenceByType(fileContents, pattern, parentDirectory, origin: origin, needsCopyright: false)));
  results.addAll(csReferencesByUrl.expand((MultipleVersionedLicenseReferencePattern pattern) => _tryReferenceByUrl(fileContents, pattern, parentDirectory, origin: origin)));
  results.addAll(csLicenses.expand((RegExp pattern) => _tryInline(fileContents, pattern, needsCopyright: true, origin: origin)));
  results.addAll(csNotices.expand((RegExp pattern) => _tryInline(fileContents, pattern, needsCopyright: false, origin: origin)));
  _LicenseMatch usedTemplate;
  if (results.length == 1) {
    final _LicenseMatch target = results.single;
    results.addAll(csForwardReferenceLicenses.expand((ForwardReferencePattern pattern) => _tryForwardReferencePattern(fileContents, pattern, target.license, origin: origin)));
    if (results.length > 1)
      usedTemplate = target;
  }
  // It's good to manually sanity check that these are all being correctly used
  // to expand later licenses every now and then:
  // for (_LicenseMatch match in results.where((_LicenseMatch match) => match.missingCopyrights)) {
  //   print('Found a license for $filename but it was missing a copyright, so ignoring it:\n----8<----\n${match.license}\n----8<----');
  // }
  results.removeWhere((_LicenseMatch match) => match.missingCopyrights);
  if (results.isEmpty) {
    // we failed to find a license, so let's look for some corner cases
    results.addAll(csFallbacks.expand((RegExp pattern) => _tryNone(fileContents, filename, pattern, parentDirectory)));
    if (results.isEmpty) {
      if ((fileContents.contains(copyrightMentionPattern) && fileContents.contains(licenseMentionPattern)) && !fileContents.contains(copyrightMentionOkPattern))
        throw 'unmatched potential copyright and license statements; first twenty lines:\n----8<----\n${fileContents.split("\n").take(20).join("\n")}\n----8<----';
    }
  }
  final List<_LicenseMatch> verificationList = results.toList();
  if (usedTemplate != null && !verificationList.contains(usedTemplate))
    verificationList.add(usedTemplate);
  verificationList.sort((_LicenseMatch a, _LicenseMatch b) {
    final int result = a.start - b.start;
    if (result != 0)
      return result;
    return a.end - b.end;
  });
  int position = 0;
  for (_LicenseMatch m in verificationList) {
    if (m.isDuplicate)
      continue; // some text expanded into multiple licenses, so overlapping is expected
    if (position > m.start) {
      for (_LicenseMatch n in results)
        print('license match: ${n.start}..${n.end}, ${n.debug}, first line: ${n.license.body.split("\n").first}');
      throw 'overlapping licenses in $filename (one ends at $position, another starts at ${m.start})';
    }
    if (position < m.start) {
      final String substring = fileContents.substring(position, m.start);
      if (substring.contains(copyrightMentionPattern) && !substring.contains(copyrightMentionOkPattern))
        throw 'there is another unmatched potential copyright statement in $filename:\n  $position..${m.start}: "$substring"';
    }
    position = m.end;
  }
  return results.map((_LicenseMatch entry) => entry.license).toList();
}

License interpretAsRedirectLicense(String fileContents, LicenseSource parentDirectory, { String origin }) {
  _SplitLicense split;
  try {
    split = _splitLicense(fileContents);
  } on String {
    return null;
  }
  final String body = split.getConditions().trim();
  License result;
  for (MultipleVersionedLicenseReferencePattern pattern in csReferencesByUrl) {
    final Match match = pattern.pattern.matchAsPrefix(body);
    if (match != null && match.start == 0 && match.end == body.length) {
      for (int index in pattern.licenseIndices) {
        final License candidate = _dereferenceLicense(index, match.group, pattern, parentDirectory, origin: origin);
        if (result != null && candidate != null)
          throw 'Multiple potential matches in interpretAsRedirectLicense in $parentDirectory; body was:\n------8<------\n$fileContents\n------8<------';
        result = candidate;
      }
    }
  }
  return result;
}

// the kind of license that just wants to show a message (e.g. the JPEG one)
class MessageLicense extends License {
  MessageLicense._(String body, LicenseType type, { String origin }) : super._(body, type, origin: origin);
  @override
  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin }) sync* {
    yield this;
  }
}

// the kind of license that says to include the copyright and the license text (e.g. BSD)
class TemplateLicense extends License {
  TemplateLicense._(String body, LicenseType type, { String origin }) : super._(body, type, origin: origin) {
    assert(!body.startsWith('Apache License'));
  }

  String _conditions;

  @override
  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin }) sync* {
    _conditions ??= _splitLicense(body).getConditions();
    yield License.fromCopyrightAndLicense(copyright, _conditions, type, origin: '$origin + ${this.origin}');
  }
}

// the kind of license that expands to two license blocks a main license and the referring block (e.g. OpenSSL)
class MultiLicense extends License {
  MultiLicense._(String body, LicenseType type, { String origin }) : super._(body, type, origin: origin);

  @override
  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin }) sync* {
    yield License.fromBody(body, origin: '$origin + ${this.origin}');
    yield License.fromBody(licenseBody, origin: '$origin + ${this.origin}');
  }
}

// the kind of license that should not be combined with separate copyright notices
class UniqueLicense extends License {
  UniqueLicense._(String body, LicenseType type, { String origin, bool yesWeKnowWhatItLooksLikeButItIsNot: false })
    : super._(body, type, origin: origin, yesWeKnowWhatItLooksLikeButItIsNot: yesWeKnowWhatItLooksLikeButItIsNot);
  @override
  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin }) sync* {
    throw 'attempted to expand non-template license with "$copyright"\ntemplate was: $this';
  }
}

// the kind of license that doesn't need to be reported anywhere
class BlankLicense extends License {
  BlankLicense._(String body, LicenseType type, { String origin }) : super._(body, type, origin: origin);
  @override
  Iterable<License> expandTemplate(String copyright, String licenseBody, { String origin }) sync* {
    yield this;
  }
  @override
  String toStringBody() => '<THIS BLOCK INTENTIONALLY LEFT BLANK>';
  @override
  String toStringFormal() => null;
}
