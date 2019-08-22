// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See README in this directory for information on how this code is organized.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as system;
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:licenses/patterns.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'filesystem.dart' as fs;
import 'licenses.dart';


// REPOSITORY OBJECTS

abstract class _RepositoryEntry implements Comparable<_RepositoryEntry> {
  _RepositoryEntry(this.parent, this.io);
  final _RepositoryDirectory parent;
  final fs.IoNode io;
  String get name => io.name;
  String get libraryName;

  @override
  int compareTo(_RepositoryEntry other) => toString().compareTo(other.toString());

  @override
  String toString() => io.fullName;
}

abstract class _RepositoryFile extends _RepositoryEntry {
  _RepositoryFile(_RepositoryDirectory parent, fs.File io) : super(parent, io);

  Iterable<License> get licenses;

  @override
  String get libraryName => parent.libraryName;

  @override
  fs.File get io => super.io;
}

abstract class _RepositoryLicensedFile extends _RepositoryFile {
  _RepositoryLicensedFile(_RepositoryDirectory parent, fs.File io) : super(parent, io);

  // file names that we are confident won't be included in the final build product
  static final RegExp _readmeNamePattern = RegExp(r'\b_*(?:readme|contributing|patents)_*\b', caseSensitive: false);
  static final RegExp _buildTimePattern = RegExp(r'^(?!.*gen$)(?:CMakeLists\.txt|(?:pkgdata)?Makefile(?:\.inc)?(?:\.am|\.in|)|configure(?:\.ac|\.in)?|config\.(?:sub|guess)|.+\.m4|install-sh|.+\.sh|.+\.bat|.+\.pyc?|.+\.pl|icu-configure|.+\.gypi?|.*\.gni?|.+\.mk|.+\.cmake|.+\.gradle|.+\.yaml|pubspec\.lock|\.packages|vms_make\.com|pom\.xml|\.project|source\.properties)$', caseSensitive: false);
  static final RegExp _docsPattern = RegExp(r'^(?:INSTALL|NEWS|OWNERS|AUTHORS|ChangeLog(?:\.rst|\.[0-9]+)?|.+\.txt|.+\.md|.+\.log|.+\.css|.+\.1|doxygen\.config|Doxyfile|.+\.spec(?:\.in)?)$', caseSensitive: false);
  static final RegExp _devPattern = RegExp(r'^(?:codereview\.settings|.+\.~|.+\.~[0-9]+~|\.clang-format|\.gitattributes|\.landmines|\.DS_Store|\.travis\.yml|\.cirrus\.yml)$', caseSensitive: false);
  static final RegExp _testsPattern = RegExp(r'^(?:tj(?:bench|example)test\.(?:java\.)?in|example\.c)$', caseSensitive: false);

  bool get isIncludedInBuildProducts {
    return !io.name.contains(_readmeNamePattern)
        && !io.name.contains(_buildTimePattern)
        && !io.name.contains(_docsPattern)
        && !io.name.contains(_devPattern)
        && !io.name.contains(_testsPattern)
        && !isShellScript;
  }

  bool get isShellScript => false;
}

class _RepositorySourceFile extends _RepositoryLicensedFile {
  _RepositorySourceFile(_RepositoryDirectory parent, fs.TextFile io) : super(parent, io);

  @override
  fs.TextFile get io => super.io;

  static final RegExp _hashBangPattern = RegExp(r'^#! *(?:/bin/sh|/bin/bash|/usr/bin/env +(?:python|bash))\b');

  @override
  bool get isShellScript {
    return io.readString().startsWith(_hashBangPattern);
  }

  List<License> _licenses;

  @override
  Iterable<License> get licenses {
    if (_licenses != null)
      return _licenses;
    String contents;
    try {
      contents = io.readString();
    } on FormatException {
      print('non-UTF8 data in $io');
      system.exit(2);
    }
    _licenses = determineLicensesFor(contents, name, parent, origin: '$this');
    if (_licenses == null || _licenses.isEmpty) {
      _licenses = parent.nearestLicensesFor(name);
      if (_licenses == null || _licenses.isEmpty)
        throw 'file has no detectable license and no in-scope default license file';
    }
    _licenses.sort();
    for (License license in licenses)
      license.markUsed(io.fullName, libraryName);
    assert(_licenses != null && _licenses.isNotEmpty);
    return _licenses;
  }
}

class _RepositoryBinaryFile extends _RepositoryLicensedFile {
  _RepositoryBinaryFile(_RepositoryDirectory parent, fs.File io) : super(parent, io);

  List<License> _licenses;

  @override
  List<License> get licenses {
    if (_licenses == null) {
      _licenses = parent.nearestLicensesFor(name);
      if (_licenses == null || _licenses.isEmpty)
        throw 'no license file found in scope for ${io.fullName}';
      for (License license in licenses)
        license.markUsed(io.fullName, libraryName);
    }
    return _licenses;
  }
}


// LICENSES

abstract class _RepositoryLicenseFile extends _RepositoryFile {
  _RepositoryLicenseFile(_RepositoryDirectory parent, fs.File io) : super(parent, io);

  List<License> licensesFor(String name);
  License licenseOfType(LicenseType type);
  License licenseWithName(String name);

  License get defaultLicense;
}

abstract class _RepositorySingleLicenseFile extends _RepositoryLicenseFile {
  _RepositorySingleLicenseFile(_RepositoryDirectory parent, fs.TextFile io, this.license)
    : super(parent, io);

  final License license;

  @override
  List<License> licensesFor(String name) {
    if (license != null)
      return <License>[license];
    return null;
  }

  @override
  License licenseWithName(String name) {
    if (this.name == name)
      return license;
    return null;
  }

  @override
  License get defaultLicense => license;

  @override
  Iterable<License> get licenses sync* { yield license; }
}

class _RepositoryGeneralSingleLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryGeneralSingleLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, License.fromBodyAndName(io.readString(), io.name, origin: io.fullName));

  _RepositoryGeneralSingleLicenseFile.fromLicense(_RepositoryDirectory parent, fs.TextFile io, License license)
    : super(parent, io, license);

  @override
  License licenseOfType(LicenseType type) {
    if (type == license.type)
      return license;
    return null;
  }
}

class _RepositoryApache4DNoticeFile extends _RepositorySingleLicenseFile {
  _RepositoryApache4DNoticeFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  @override
  License licenseOfType(LicenseType type) => null;

  static final RegExp _pattern = RegExp(
    r'^(// ------------------------------------------------------------------\n'
    r'// NOTICE file corresponding to the section 4d of The Apache License,\n'
    r'// Version 2\.0, in this case for (?:.+)\n'
    r'// ------------------------------------------------------------------\n)'
    r'((?:.|\n)+)$',
    multiLine: false,
    caseSensitive: false
  );

  static bool consider(fs.TextFile io) {
    return io.readString().contains(_pattern);
  }

  static License _parseLicense(fs.TextFile io) {
    final Match match = _pattern.allMatches(io.readString()).single;
    assert(match.groupCount == 2);
    return License.unique(match.group(2), LicenseType.apacheNotice, origin: io.fullName);
  }
}

class _RepositoryLicenseRedirectFile extends _RepositorySingleLicenseFile {
  _RepositoryLicenseRedirectFile(_RepositoryDirectory parent, fs.TextFile io, License license)
    : super(parent, io, license);

  @override
  License licenseOfType(LicenseType type) {
    if (type == license.type)
      return license;
    return null;
  }

  static _RepositoryLicenseRedirectFile maybeCreateFrom(_RepositoryDirectory parent, fs.TextFile io) {
    final String contents = io.readString();
    final License license = interpretAsRedirectLicense(contents, parent, origin: io.fullName);
    if (license != null)
      return _RepositoryLicenseRedirectFile(parent, io, license);
    return null;
  }
}

class _RepositoryLicenseFileWithLeader extends _RepositorySingleLicenseFile {
  _RepositoryLicenseFileWithLeader(_RepositoryDirectory parent, fs.TextFile io, RegExp leader)
    : super(parent, io, _parseLicense(io, leader));

  @override
  License licenseOfType(LicenseType type) => null;

  static License _parseLicense(fs.TextFile io, RegExp leader) {
    final String body = io.readString();
    final Match match = leader.firstMatch(body);
    if (match == null)
      throw 'failed to strip leader from $io\nleader: /$leader/\nbody:\n---\n$body\n---';
    return License.fromBodyAndName(body.substring(match.end), io.name, origin: io.fullName);
  }
}

class _RepositoryReadmeIjgFile extends _RepositorySingleLicenseFile {
  _RepositoryReadmeIjgFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = RegExp(
    r'Permission is hereby granted to use, copy, modify, and distribute this\n'
    r'software \(or portions thereof\) for any purpose, without fee, subject to these\n'
    r'conditions:\n'
    r'\(1\) If any part of the source code for this software is distributed, then this\n'
    r'README file must be included, with this copyright and no-warranty notice\n'
    r'unaltered; and any additions, deletions, or changes to the original files\n'
    r'must be clearly indicated in accompanying documentation\.\n'
    r'\(2\) If only executable code is distributed, then the accompanying\n'
    r'documentation must state that "this software is based in part on the work of\n'
    r'the Independent JPEG Group"\.\n'
    r'\(3\) Permission for use of this software is granted only if the user accepts\n'
    r'full responsibility for any undesirable consequences; the authors accept\n'
    r'NO LIABILITY for damages of any kind\.\n',
    caseSensitive: false
  );

  static License _parseLicense(fs.TextFile io) {
    final String body = io.readString();
    if (!body.contains(_pattern))
      throw 'unexpected contents in IJG README';
    return License.message(body, LicenseType.ijg, origin: io.fullName);
  }

  @override
  License licenseWithName(String name) {
    if (this.name == name)
      return license;
    return null;
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class _RepositoryDartLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryDartLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = RegExp(
    r'(Copyright (?:.|\n)+)$',
    caseSensitive: false
  );

  static License _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 1)
      throw 'unexpected Dart license file contents';
    return License.template(match.group(1), LicenseType.bsd, origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class _RepositoryLibPngLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryLibPngLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, License.blank(io.readString(), LicenseType.libpng, origin: io.fullName)) {
    _verifyLicense(io);
  }

  static void _verifyLicense(fs.TextFile io) {
    final String contents = io.readString();
    if (!contents.contains('COPYRIGHT NOTICE, DISCLAIMER, and LICENSE:') ||
        !contents.contains('png') ||
        !contents.contains('END OF COPYRIGHT NOTICE, DISCLAIMER, and LICENSE.'))
      throw 'unexpected libpng license file contents:\n----8<----\n$contents\n----<8----';
  }

  @override
  License licenseOfType(LicenseType type) {
    if (type == LicenseType.libpng)
      return license;
    return null;
  }
}

class _RepositoryBlankLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryBlankLicenseFile(_RepositoryDirectory parent, fs.TextFile io, String sanityCheck)
    : super(parent, io, License.blank(io.readString(), LicenseType.unknown)) {
    _verifyLicense(io, sanityCheck);
  }

  static void _verifyLicense(fs.TextFile io, String sanityCheck) {
    final String contents = io.readString();
    if (!contents.contains(sanityCheck))
      throw 'unexpected file contents; wanted "$sanityCheck", but got:\n----8<----\n$contents\n----<8----';
  }

  @override
  License licenseOfType(LicenseType type) => null;
}

class _RepositoryCatapultApiClientLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryCatapultApiClientLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = RegExp(
    r' *Licensed under the Apache License, Version 2\.0 \(the "License"\);\n'
    r' *you may not use this file except in compliance with the License\.\n'
    r' *You may obtain a copy of the License at\n'
    r' *\n'
    r' *(http://www\.apache\.org/licenses/LICENSE-2\.0)\n'
    r' *\n'
    r' *Unless required by applicable law or agreed to in writing, software\n'
    r' *distributed under the License is distributed on an "AS IS" BASIS,\n'
    r' *WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied\.\n'
    r' *See the License for the specific language governing permissions and\n'
    r' *limitations under the License\.\n',
    multiLine: true,
    caseSensitive: false,
  );

  static License _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 1)
      throw 'unexpected apiclient license file contents';
    return License.fromUrl(match.group(1), origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class _RepositoryCatapultCoverageLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryCatapultCoverageLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = RegExp(
    r' *Except where noted otherwise, this software is licensed under the Apache\n'
    r' *License, Version 2.0 \(the "License"\); you may not use this work except in\n'
    r' *compliance with the License\.  You may obtain a copy of the License at\n'
    r' *\n'
    r' *(http://www\.apache\.org/licenses/LICENSE-2\.0)\n'
    r' *\n'
    r' *Unless required by applicable law or agreed to in writing, software\n'
    r' *distributed under the License is distributed on an "AS IS" BASIS,\n'
    r' *WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied\.\n'
    r' *See the License for the specific language governing permissions and\n'
    r' *limitations under the License\.\n',
    multiLine: true,
    caseSensitive: false,
  );

  static License _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 1)
      throw 'unexpected coverage license file contents';
    return License.fromUrl(match.group(1), origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class _RepositoryLibJpegTurboLicense extends _RepositoryLicenseFile {
  _RepositoryLibJpegTurboLicense(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io) {
    _parseLicense(io);
  }

  static final RegExp _pattern = RegExp(
    r'libjpeg-turbo is covered by three compatible BSD-style open source licenses:\n'
    r'\n'
    r'- The IJG \(Independent JPEG Group\) License, which is listed in\n'
    r'  \[README\.ijg\]\(README\.ijg\)\n'
    r'\n'
    r'  This license applies to the libjpeg API library and associated programs\n'
    r'  \(any code inherited from libjpeg, and any modifications to that code\.\)\n'
    r'\n'
    r'- The Modified \(3-clause\) BSD License, which is listed in\n'
    r'  \[turbojpeg\.c\]\(turbojpeg\.c\)\n'
    r'\n'
    r'  This license covers the TurboJPEG API library and associated programs\.\n'
    r'\n'
    r'- The zlib License, which is listed in \[simd/jsimdext\.inc\]\(simd/jsimdext\.inc\)\n'
    r'\n'
    r'  This license is a subset of the other two, and it covers the libjpeg-turbo\n'
    r'  SIMD extensions\.\n'
  );

  static void _parseLicense(fs.TextFile io) {
    final String body = io.readString();
    if (!body.contains(_pattern))
      throw 'unexpected contents in libjpeg-turbo LICENSE';
  }

  List<License> _licenses;

  @override
  List<License> get licenses {
    if (_licenses == null) {
      final _RepositoryReadmeIjgFile readme = parent.getChildByName('README.ijg');
      final _RepositorySourceFile main = parent.getChildByName('turbojpeg.c');
      final _RepositoryDirectory simd = parent.getChildByName('simd');
      final _RepositorySourceFile zlib = simd.getChildByName('jsimdext.inc');
      _licenses = <License>[];
      _licenses.add(readme.license);
      _licenses.add(main.licenses.single);
      _licenses.add(zlib.licenses.single);
    }
    return _licenses;
  }

  @override
  License licenseWithName(String name) {
    return null;
  }

  @override
  List<License> licensesFor(String name) {
    return licenses;
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }

  @override
  License get defaultLicense => null;
}

class _RepositoryFreetypeLicenseFile extends _RepositoryLicenseFile {
  _RepositoryFreetypeLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : _target = _parseLicense(io), super(parent, io);

  static final RegExp _pattern = RegExp(
    r'The  FreeType 2  font  engine is  copyrighted  work and  cannot be  used\n'
    r'legally  without a  software license\.   In  order to  make this  project\n'
    r'usable  to a vast  majority of  developers, we  distribute it  under two\n'
    r'mutually exclusive open-source licenses\.\n'
    r'\n'
    r'This means  that \*you\* must choose  \*one\* of the  two licenses described\n'
    r'below, then obey  all its terms and conditions when  using FreeType 2 in\n'
    r'any of your projects or products.\n'
    r'\n'
    r"  - The FreeType License, found in  the file `(FTL\.TXT)', which is similar\n"
    r'    to the original BSD license \*with\* an advertising clause that forces\n'
    r"    you  to  explicitly cite  the  FreeType  project  in your  product's\n"
    r'    documentation\.  All  details are in the license  file\.  This license\n'
    r"    is  suited  to products  which  don't  use  the GNU  General  Public\n"
    r'    License\.\n'
    r'\n'
    r'    Note that  this license  is  compatible  to the  GNU General  Public\n'
    r'    License version 3, but not version 2\.\n'
    r'\n'
    r"  - The GNU General Public License version 2, found in  `GPLv2\.TXT' \(any\n"
    r'    later version can be used  also\), for programs which already use the\n'
    r'    GPL\.  Note  that the  FTL is  incompatible  with  GPLv2 due  to  its\n'
    r'    advertisement clause\.\n'
    r'\n'
    r'The contributed BDF and PCF drivers  come with a license similar to that\n'
    r'of the X Window System\.  It is compatible to the above two licenses \(see\n'
    r'file src/bdf/README and  src/pcf/README\)\.  The same holds  for the files\n'
    r"`fthash\.c' and  `fthash\.h'; their  code was  part of  the BDF  driver in\n"
    r'earlier FreeType versions\.\n'
    r'\n'
    r'The gzip module uses the zlib license \(see src/gzip/zlib\.h\) which too is\n'
    r'compatible to the above two licenses\.\n'
    r'\n'
    r'The MD5 checksum support \(only used for debugging in development builds\)\n'
    r'is in the public domain\.\n'
    r'\n*'
    r'--- end of LICENSE\.TXT ---\n*$'
  );

  static String _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 1)
      throw 'unexpected Freetype license file contents';
    return match.group(1);
  }

  final String _target;
  List<License> _targetLicense;

  void _warmCache() {
    _targetLicense ??= <License>[parent.nearestLicenseWithName(_target)];
  }

  @override
  List<License> licensesFor(String name) {
    _warmCache();
    return _targetLicense;
  }

  @override
  License licenseOfType(LicenseType type) => null;

  @override
  License licenseWithName(String name) => null;

  @override
  License get defaultLicense {
    _warmCache();
    return _targetLicense.single;
  }

  @override
  Iterable<License> get licenses sync* { }
}

class _RepositoryIcuLicenseFile extends _RepositoryLicenseFile {
  _RepositoryIcuLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : _licenses = _parseLicense(io),
      super(parent, io);

  @override
  fs.TextFile get io => super.io;

  final List<License> _licenses;

  static final RegExp _pattern = RegExp(
    r'^COPYRIGHT AND PERMISSION NOTICE \(ICU 58 and later\)\n+'
    r'( *Copyright (?:.|\n)+?)\n+' // 1
    r'Third-Party Software Licenses\n+'
    r' *This section contains third-party software notices and/or additional\n'
    r' *terms for licensed third-party software components included within ICU\n'
    r' *libraries\.\n+'
    r' *1\. ICU License - ICU 1.8.1 to ICU 57.1[ \n]+?'
    r' *COPYRIGHT AND PERMISSION NOTICE\n+'
    r'(Copyright (?:.|\n)+?)\n+' //2
    r' *2\. Chinese/Japanese Word Break Dictionary Data \(cjdict\.txt\)\n+'
    r' #     The Google Chrome software developed by Google is licensed under\n?'
    r' # the BSD license\. Other software included in this distribution is\n?'
    r' # provided under other licenses, as set forth below\.\n'
    r' #\n'
    r'( #  The BSD License\n'
    r' #  http://opensource\.org/licenses/bsd-license\.php\n'
    r' # +Copyright(?:.|\n)+?)\n' // 3
    r' #\n'
    r' #\n'
    r' #  The word list in cjdict.txt are generated by combining three word lists\n?'
    r' # listed below with further processing for compound word breaking\. The\n?'
    r' # frequency is generated with an iterative training against Google web\n?'
    r' # corpora\.\n'
    r' #\n'
    r' #  \* Libtabe \(Chinese\)\n'
    r' #    - https://sourceforge\.net/project/\?group_id=1519\n'
    r' #    - Its license terms and conditions are shown below\.\n'
    r' #\n'
    r' #  \* IPADIC \(Japanese\)\n'
    r' #    - http://chasen\.aist-nara\.ac\.jp/chasen/distribution\.html\n'
    r' #    - Its license terms and conditions are shown below\.\n'
    r' #\n'
    r' #  ---------COPYING\.libtabe ---- BEGIN--------------------\n'
    r' #\n'
    r' # +/\*\n'
    r'( # +\* Copyright (?:.|\n)+?)\n' // 4
    r' # +\*/\n'
    r' #\n'
    r' # +/\*\n'
    r'( # +\* Copyright (?:.|\n)+?)\n' // 5
    r' # +\*/\n'
    r' #\n'
    r'( # +Copyright (?:.|\n)+?)\n' // 6
    r' #\n'
    r' # +---------------COPYING\.libtabe-----END--------------------------------\n'
    r' #\n'
    r' #\n'
    r' # +---------------COPYING\.ipadic-----BEGIN-------------------------------\n'
    r' #\n'
    r'( # +Copyright (?:.|\n)+?)\n' // 7
    r' #\n'
    r' # +---------------COPYING\.ipadic-----END----------------------------------\n'
    r'\n'
    r' *3\. Lao Word Break Dictionary Data \(laodict\.txt\)\n'
    r'\n'
    r'( # +Copyright(?:.|\n)+?)\n' // 8
    r'\n'
    r' *4\. Burmese Word Break Dictionary Data \(burmesedict\.txt\)\n'
    r'\n'
    r'( # +Copyright(?:.|\n)+?)\n' // 9
    r'\n'
    r' *5\. Time Zone Database\n'
    r'((?:.|\n)+)\n' // 10
    r'\n'
    r' *6\. Google double-conversion\n'
    r'\n'
    r'(Copyright(?:.|\n)+)\n$', // 11
    multiLine: true,
    caseSensitive: false
  );

  static final RegExp _unexpectedHash = RegExp(r'^.+ #', multiLine: true);
  static final RegExp _newlineHash = RegExp(r' # ?');

  static String _dewrap(String s) {
    if (!s.startsWith(' # '))
      return s;
    if (s.contains(_unexpectedHash))
      throw 'ICU license file contained unexpected hash sequence';
    if (s.contains('\x2028'))
      throw 'ICU license file contained unexpected line separator';
    return s.replaceAll(_newlineHash, '\x2028').replaceAll('\n', '').replaceAll('\x2028', '\n');
  }

  static List<License> _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null)
      throw 'could not parse ICU license file';
    assert(match.groupCount == 11);
    if (match.group(10).contains(copyrightMentionPattern) || match.group(11).contains('7.'))
      throw 'unexpected copyright in ICU license file';
    final List<License> result = <License>[
      License.fromBodyAndType(_dewrap(match.group(1)), LicenseType.unknown, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(2)), LicenseType.icu, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(3)), LicenseType.bsd, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(4)), LicenseType.bsd, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(5)), LicenseType.bsd, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(6)), LicenseType.unknown, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(7)), LicenseType.unknown, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(8)), LicenseType.bsd, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(9)), LicenseType.bsd, origin: io.fullName),
      License.fromBodyAndType(_dewrap(match.group(11)), LicenseType.bsd, origin: io.fullName),
    ];
    return result;
  }

  @override
  List<License> licensesFor(String name) {
    return _licenses;
  }

  @override
  License licenseOfType(LicenseType type) {
    if (type == LicenseType.icu)
      return _licenses[0];
    throw 'tried to use ICU license file to find a license by type but type wasn\'t ICU';
  }

  @override
  License licenseWithName(String name) {
    throw 'tried to use ICU license file to find a license by name';
  }

  @override
  License get defaultLicense => _licenses[0];

  @override
  Iterable<License> get licenses => _licenses;
}

Iterable<List<int>> splitIntList(List<int> data, int boundary) sync* {
  int index = 0;
  List<int> getOne() {
    final int start = index;
    int end = index;
    while ((end < data.length) && (data[end] != boundary))
      end += 1;
    end += 1;
    index = end;
    return data.sublist(start, end).toList();
  }
  while (index < data.length)
    yield getOne();
}

class _RepositoryMultiLicenseNoticesForFilesFile extends _RepositoryLicenseFile {
  _RepositoryMultiLicenseNoticesForFilesFile(_RepositoryDirectory parent, fs.File io)
    : _licenses = _parseLicense(io),
      super(parent, io);

  final Map<String, License> _licenses;

  static Map<String, License> _parseLicense(fs.File io) {
    final Map<String, License> result = <String, License>{};
    // Files of this type should begin with:
    // "Notices for files contained in the"
    // ...then have a second line which is 60 "=" characters
    final List<List<int>> contents = splitIntList(io.readBytes(), 0x0A).toList();
    if (!ascii.decode(contents[0]).startsWith('Notices for files contained in') ||
        ascii.decode(contents[1]) != '============================================================\n')
      throw 'unrecognised syntax: ${io.fullName}';
    int index = 2;
    while (index < contents.length) {
      if (ascii.decode(contents[index]) != 'Notices for file(s):\n')
        throw 'unrecognised syntax on line ${index + 1}: ${io.fullName}';
      index += 1;
      final List<String> names = <String>[];
      do {
        names.add(ascii.decode(contents[index]));
        index += 1;
      } while (ascii.decode(contents[index]) != '------------------------------------------------------------\n');
      index += 1;
      final List<List<int>> body = <List<int>>[];
      do {
        body.add(contents[index]);
        index += 1;
      } while (index < contents.length &&
          ascii.decode(contents[index], allowInvalid: true) != '============================================================\n');
      index += 1;
      final List<int> bodyBytes = body.expand((List<int> line) => line).toList();
      String bodyText;
      try {
        bodyText = utf8.decode(bodyBytes);
      } on FormatException {
        bodyText = latin1.decode(bodyBytes);
      }
      final License license = License.unique(bodyText, LicenseType.unknown, origin: io.fullName);
      for (String name in names) {
        if (result[name] != null)
          throw 'conflicting license information for $name in ${io.fullName}';
        result[name] = license;
      }
    }
    return result;
  }

  @override
  List<License> licensesFor(String name) {
    final License license = _licenses[name];
    if (license != null)
      return <License>[license];
    return null;
  }

  @override
  License licenseOfType(LicenseType type) {
    throw 'tried to use multi-license license file to find a license by type';
  }

  @override
  License licenseWithName(String name) {
    throw 'tried to use multi-license license file to find a license by name';
  }

  @override
  License get defaultLicense {
    assert(false);
    throw '$this ($runtimeType) does not have a concept of a "default" license';
  }

  @override
  Iterable<License> get licenses => _licenses.values;
}

class _RepositoryCxxStlDualLicenseFile extends _RepositoryLicenseFile {
  _RepositoryCxxStlDualLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : _licenses = _parseLicenses(io), super(parent, io);

  static final RegExp _pattern = RegExp(
    r'==============================================================================\n'
    r'.+ License.*\n'
    r'==============================================================================\n'
    r'\n'
    r'The .+ library is dual licensed under both the University of Illinois\n'
    r'"BSD-Like" license and the MIT license\. +As a user of this code you may choose\n'
    r'to use it under either license\. +As a contributor, you agree to allow your code\n'
    r'to be used under both\.\n'
    r'\n'
    r'Full text of the relevant licenses is included below\.\n'
    r'\n'
    r'==============================================================================\n'
    r'((?:.|\n)+)\n'
    r'==============================================================================\n'
    r'((?:.|\n)+)'
    r'$'
  );

  static List<License> _parseLicenses(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 2)
      throw 'unexpected dual license file contents';
    return <License>[
      License.fromBodyAndType(match.group(1), LicenseType.bsd),
      License.fromBodyAndType(match.group(2), LicenseType.mit),
    ];
  }

  final List<License> _licenses;

  @override
  List<License> licensesFor(String name) {
    return _licenses;
  }

  @override
  License licenseOfType(LicenseType type) {
    throw 'tried to look up a dual-license license by type ("$type")';
  }

  @override
  License licenseWithName(String name) {
    throw 'tried to look up a dual-license license by name ("$name")';
  }

  @override
  License get defaultLicense => _licenses[0];

  @override
  Iterable<License> get licenses => _licenses;
}


// DIRECTORIES

class _RepositoryDirectory extends _RepositoryEntry implements LicenseSource {
  _RepositoryDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io) {
    crawl();
  }

  @override
  fs.Directory get io => super.io;

  final List<_RepositoryDirectory> _subdirectories = <_RepositoryDirectory>[];
  final List<_RepositoryLicensedFile> _files = <_RepositoryLicensedFile>[];
  final List<_RepositoryLicenseFile> _licenses = <_RepositoryLicenseFile>[];

  List<_RepositoryDirectory> get subdirectories => _subdirectories;

  final Map<String, _RepositoryEntry> _childrenByName = <String, _RepositoryEntry>{};

  // the bit at the beginning excludes files like "license.py".
  static final RegExp _licenseNamePattern = RegExp(r'^(?!.*\.py$)(?!.*(?:no|update)-copyright)(?!.*mh-bsd-gcc).*\b_*(?:license(?!\.html)|copying|copyright|notice|l?gpl|bsd|mpl?|ftl\.txt)_*\b', caseSensitive: false);

  void crawl() {
    for (fs.IoNode entry in io.walk) {
      if (shouldRecurse(entry)) {
        assert(!_childrenByName.containsKey(entry.name));
        if (entry is fs.Directory) {
          final _RepositoryDirectory child = createSubdirectory(entry);
          _subdirectories.add(child);
          _childrenByName[child.name] = child;
        } else if (entry is fs.File) {
          try {
            final _RepositoryFile child = createFile(entry);
            assert(child != null);
            if (child is _RepositoryLicensedFile) {
              _files.add(child);
            } else {
              assert(child is _RepositoryLicenseFile);
              _licenses.add(child);
            }
            _childrenByName[child.name] = child;
          } catch (e) {
            system.stderr.writeln('failed to handle $entry: $e');
            rethrow;
          }
        } else {
          assert(entry is fs.Link);
        }
      }
    }

    for (_RepositoryDirectory child in virtualSubdirectories) {
      _subdirectories.add(child);
      _childrenByName[child.name] = child;
    }
  }

  // Override this to add additional child directories that do not represent a
  // direct child of this directory's filesystem node.
  List<_RepositoryDirectory> get virtualSubdirectories => <_RepositoryDirectory>[];

  bool shouldRecurse(fs.IoNode entry) {
    return !entry.fullName.endsWith('third_party/gn') &&
            entry.name != '.cipd' &&
            entry.name != '.git' &&
            entry.name != '.github' &&
            entry.name != '.gitignore' &&
            entry.name != '.vscode' &&
            entry.name != 'test' &&
            entry.name != 'test.disabled' &&
            entry.name != 'test_support' &&
            entry.name != 'tests' &&
            entry.name != 'javatests' &&
            entry.name != 'testing' &&
            entry.name != '.dart_tool';  // Generated by various Dart tools, such as pub and
                                         // build_runner. Skip it because it does not contain
                                         // source code.
  }

  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryGenericThirdPartyDirectory(this, entry);
    return _RepositoryDirectory(this, entry);
  }

  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry is fs.TextFile) {
      if (_RepositoryApache4DNoticeFile.consider(entry)) {
        return _RepositoryApache4DNoticeFile(this, entry);
      } else {
        _RepositoryFile result;
        if (entry.name == 'NOTICE')
          result = _RepositoryLicenseRedirectFile.maybeCreateFrom(this, entry);
        if (result != null) {
          return result;
        } else if (entry.name.contains(_licenseNamePattern)) {
          return _RepositoryGeneralSingleLicenseFile(this, entry);
        } else if (entry.name == 'README.ijg') {
          return _RepositoryReadmeIjgFile(this, entry);
        } else {
          return _RepositorySourceFile(this, entry);
        }
      }
    } else if (entry.name == 'NOTICE.txt') {
      return _RepositoryMultiLicenseNoticesForFilesFile(this, entry);
    } else {
      return _RepositoryBinaryFile(this, entry);
    }
  }

  int get count => _files.length + _subdirectories.fold<int>(0, (int count, _RepositoryDirectory child) => count + child.count);

  @override
  List<License> nearestLicensesFor(String name) {
    if (_licenses.isEmpty) {
      if (_canGoUp(null))
        return parent.nearestLicensesFor('${io.name}/$name');
      return null;
    }
    if (_licenses.length == 1)
      return _licenses.single.licensesFor(name);
    final List<License> licenses = _licenses.expand((_RepositoryLicenseFile license) sync* {
      final List<License> licenses = license.licensesFor(name);
      if (licenses != null)
        yield* licenses;
    }).toList();
    if (licenses.isEmpty)
      return null;
    if (licenses.length > 1) {
      //print('unexpectedly found multiple matching licenses for: $name');
      return licenses; // TODO(ianh): disambiguate them, in case we have e.g. a dual GPL/BSD situation
    }
    return licenses;
  }

  @override
  License nearestLicenseOfType(LicenseType type) {
    License result = _nearestAncestorLicenseWithType(type);
    if (result == null) {
      for (_RepositoryDirectory directory in _subdirectories) {
        result = directory._localLicenseWithType(type);
        if (result != null)
          break;
      }
    }
    result ??= _fullWalkUpForLicenseWithType(type);
    return result;
  }

  /// Searches the current and all parent directories (up to the license root)
  /// for a license of the specified type.
  License _nearestAncestorLicenseWithType(LicenseType type) {
    final License result = _localLicenseWithType(type);
    if (result != null)
      return result;
    if (_canGoUp(null))
      return parent._nearestAncestorLicenseWithType(type);
    return null;
  }

  /// Searches all subdirectories below the current license root for a license
  /// of the specified type.
  License _fullWalkUpForLicenseWithType(LicenseType type) {
    return _canGoUp(null)
            ? parent._fullWalkUpForLicenseWithType(type)
            : _fullWalkDownForLicenseWithType(type);
  }

  /// Searches the current directory and all subdirectories for a license of
  /// the specified type.
  License _fullWalkDownForLicenseWithType(LicenseType type) {
    License result = _localLicenseWithType(type);
    if (result == null) {
      for (_RepositoryDirectory directory in _subdirectories) {
        result = directory._fullWalkDownForLicenseWithType(type);
        if (result != null)
          break;
      }
    }
    return result;
  }

  /// Searches the current directory for licenses of the specified type.
  License _localLicenseWithType(LicenseType type) {
    final List<License> licenses = _licenses.expand((_RepositoryLicenseFile license) sync* {
      final License result = license.licenseOfType(type);
      if (result != null)
        yield result;
    }).toList();
    if (licenses.length > 1) {
      print('unexpectedly found multiple matching licenses in $name of type $type');
      return null;
    }
    if (licenses.isNotEmpty)
      return licenses.single;
    return null;
  }

  @override
  License nearestLicenseWithName(String name, { String authors }) {
    License result = _nearestAncestorLicenseWithName(name, authors: authors);
    if (result == null) {
      for (_RepositoryDirectory directory in _subdirectories) {
        result = directory._localLicenseWithName(name, authors: authors);
        if (result != null)
          break;
      }
    }
    result ??= _fullWalkUpForLicenseWithName(name, authors: authors);
    result ??= _fullWalkUpForLicenseWithName(name, authors: authors, ignoreCase: true);
    if (authors != null && result == null) {
      // if (result == null)
      //   print('could not find $name for authors "$authors", now looking for any $name in $this');
      result = nearestLicenseWithName(name);
      // if (result == null)
      //   print('completely failed to find $name for authors "$authors"');
      // else
      //   print('ended up finding a $name for "${result.authors}" instead');
    }
    return result;
  }

  bool _canGoUp(String authors) {
    return parent != null && (authors != null || isLicenseRootException || (!isLicenseRoot && !parent.subdirectoriesAreLicenseRoots));
  }

  License _nearestAncestorLicenseWithName(String name, { String authors }) {
    final License result = _localLicenseWithName(name, authors: authors);
    if (result != null)
      return result;
    if (_canGoUp(authors))
      return parent._nearestAncestorLicenseWithName(name, authors: authors);
    return null;
  }

  License _fullWalkUpForLicenseWithName(String name, { String authors, bool ignoreCase = false }) {
    return _canGoUp(authors)
            ? parent._fullWalkUpForLicenseWithName(name, authors: authors, ignoreCase: ignoreCase)
            : _fullWalkDownForLicenseWithName(name, authors: authors, ignoreCase: ignoreCase);
  }

  License _fullWalkDownForLicenseWithName(String name, { String authors, bool ignoreCase = false }) {
    License result = _localLicenseWithName(name, authors: authors, ignoreCase: ignoreCase);
    if (result == null) {
      for (_RepositoryDirectory directory in _subdirectories) {
        result = directory._fullWalkDownForLicenseWithName(name, authors: authors, ignoreCase: ignoreCase);
        if (result != null)
          break;
      }
    }
    return result;
  }

  /// Unless isLicenseRootException is true, we should not walk up the tree from
  /// here looking for licenses.
  bool get isLicenseRoot => parent == null;

  /// Unless isLicenseRootException is true on a child, the child should not
  /// walk up the tree to here looking for licenses.
  bool get subdirectoriesAreLicenseRoots => false;

  @override
  String get libraryName {
    if (isLicenseRoot)
      return name;
    assert(parent != null);
    if (parent.subdirectoriesAreLicenseRoots)
      return name;
    return parent.libraryName;
  }

  /// Overrides isLicenseRoot and parent.subdirectoriesAreLicenseRoots for cases
  /// where a directory contains license roots instead of being one. This
  /// allows, for example, the expat third_party directory to contain a
  /// subdirectory with expat while itself containing a BUILD file that points
  /// to the LICENSE in the root of the repo.
  bool get isLicenseRootException => false;

  License _localLicenseWithName(String name, { String authors, bool ignoreCase = false }) {
    Map<String, _RepositoryEntry> map;
    if (ignoreCase) {
      // we get here if we're trying a last-ditch effort at finding a file.
      // so this should happen only rarely.
      map = HashMap<String, _RepositoryEntry>(
        equals: (String n1, String n2) => n1.toLowerCase() == n2.toLowerCase(),
        hashCode: (String n) => n.toLowerCase().hashCode
      )
        ..addAll(_childrenByName);
    } else {
      map = _childrenByName;
    }
    final _RepositoryEntry entry = map[name];
    License license;
    if (entry is _RepositoryLicensedFile) {
      license = entry.licenses.single;
    } else if (entry is _RepositoryLicenseFile) {
      license = entry.defaultLicense;
    } else if (entry != null) {
      if (authors == null)
        throw 'found "$name" in $this but it was a ${entry.runtimeType}';
    }
    if (license != null && authors != null) {
      if (license.authors?.toLowerCase() != authors.toLowerCase())
        license = null;
    }
    return license;
  }

  _RepositoryEntry getChildByName(String name) {
    return _childrenByName[name];
  }

  Set<License> getLicenses(_Progress progress) {
    final Set<License> result = <License>{};
    for (_RepositoryDirectory directory in _subdirectories)
      result.addAll(directory.getLicenses(progress));
    for (_RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts) {
        try {
          progress.label = '$file';
          final List<License> licenses = file.licenses;
          assert(licenses != null && licenses.isNotEmpty);
          result.addAll(licenses);
          progress.advance(success: true);
        } catch (e, stack) {
          system.stderr.writeln('\nerror searching for copyright in: ${file.io}\n$e');
          if (e is! String)
            system.stderr.writeln(stack);
          system.stderr.writeln('\n');
          progress.advance(success: false);
        }
      }
    }
    for (_RepositoryLicenseFile file in _licenses)
      result.addAll(file.licenses);
    return result;
  }

  int get fileCount {
    int result = 0;
    for (_RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts)
        result += 1;
    }
    for (_RepositoryDirectory directory in _subdirectories)
      result += directory.fileCount;
    return result;
  }

  Iterable<_RepositoryLicensedFile> get _signatureFiles sync* {
    for (_RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts)
        yield file;
    }
    for (_RepositoryDirectory directory in _subdirectories) {
      if (directory.includeInSignature)
        yield* directory._signatureFiles;
    }
  }

  Stream<List<int>> _signatureStream(List<_RepositoryLicensedFile> files) async* {
    for (_RepositoryLicensedFile file in files) {
      yield file.io.fullName.codeUnits;
      yield file.io.readBytes();
    }
  }

  /// Compute a signature representing a hash of all the licensed files within
  /// this directory tree.
  Future<String> get signature async {
    final List<_RepositoryLicensedFile> allFiles = _signatureFiles.toList();
    allFiles.sort((_RepositoryLicensedFile a, _RepositoryLicensedFile b) =>
        a.io.fullName.compareTo(b.io.fullName));
    final crypto.Digest digest = await crypto.md5.bind(_signatureStream(allFiles)).single;
    return digest.bytes.map((int e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// True if this directory's contents should be included when computing the signature.
  bool get includeInSignature => true;
}

class _RepositoryGenericThirdPartyDirectory extends _RepositoryDirectory {
  _RepositoryGenericThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;
}

class _RepositoryReachOutFile extends _RepositoryLicensedFile {
  _RepositoryReachOutFile(_RepositoryDirectory parent, fs.File io, this.offset) : super(parent, io);

  final int offset;

  @override
  List<License> get licenses {
    _RepositoryDirectory directory = parent;
    int index = offset;
    while (index > 1) {
      if (directory == null)
        break;
      directory = directory.parent;
      index -= 1;
    }
    return directory?.nearestLicensesFor(name);
  }
}

class _RepositoryReachOutDirectory extends _RepositoryDirectory {
  _RepositoryReachOutDirectory(_RepositoryDirectory parent, fs.Directory io, this.reachOutFilenames, this.offset) : super(parent, io);

  final Set<String> reachOutFilenames;
  final int offset;

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (reachOutFilenames.contains(entry.name))
      return _RepositoryReachOutFile(this, entry, offset);
    return super.createFile(entry);
  }
}

class _RepositoryExcludeSubpathDirectory extends _RepositoryDirectory {
  _RepositoryExcludeSubpathDirectory(_RepositoryDirectory parent, fs.Directory io, this.paths, [ this.index = 0 ]) : super(parent, io);

  final List<String> paths;
  final int index;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    if (index == paths.length - 1 && entry.name == paths.last)
      return false;
    return super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == paths[index] && (index < paths.length - 1))
      return _RepositoryExcludeSubpathDirectory(this, entry, paths, index + 1);
    return super.createSubdirectory(entry);
  }
}


// WHAT TO CRAWL AND WHAT NOT TO CRAWL

class _RepositoryAndroidPlatformDirectory extends _RepositoryDirectory {
  _RepositoryAndroidPlatformDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // we don't link with or use any of the Android NDK samples
    return entry.name != 'webview' // not used at all
        && entry.name != 'development' // not linked in
        && super.shouldRecurse(entry);
  }
}

class _RepositoryExpatDirectory extends _RepositoryDirectory {
  _RepositoryExpatDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRootException => true;

  @override
  bool get subdirectoriesAreLicenseRoots => true;
}

class _RepositoryFreetypeDocsDirectory extends _RepositoryDirectory {
  _RepositoryFreetypeDocsDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.TXT')
      return _RepositoryFreetypeLicenseFile(this, entry);
    return super.createFile(entry);
  }

  @override
  int get fileCount => 0;

  @override
  Set<License> getLicenses(_Progress progress) {
    // We don't ship anything in this directory so don't bother looking for licenses there.
    // However, there are licenses in this directory referenced from elsewhere, so we do
    // want to crawl it and expose them.
    return <License>{};
  }
}

class _RepositoryFreetypeSrcGZipDirectory extends _RepositoryDirectory {
  _RepositoryFreetypeSrcGZipDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  // advice was to make this directory's inffixed.h file (which has no license)
  // use the license in zlib.h.

  @override
  List<License> nearestLicensesFor(String name) {
    final License zlib = nearestLicenseWithName('zlib.h');
    assert(zlib != null);
    if (zlib != null)
      return <License>[zlib];
    return super.nearestLicensesFor(name);
  }

  @override
  License nearestLicenseOfType(LicenseType type) {
    if (type == LicenseType.zlib) {
      final License result = nearestLicenseWithName('zlib.h');
      assert(result != null);
      return result;
    }
    return null;
  }
}

class _RepositoryFreetypeSrcDirectory extends _RepositoryDirectory {
  _RepositoryFreetypeSrcDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'gzip')
      return _RepositoryFreetypeSrcGZipDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'tools'
        && super.shouldRecurse(entry);
  }
}

class _RepositoryFreetypeDirectory extends _RepositoryDirectory {
  _RepositoryFreetypeDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  List<License> nearestLicensesFor(String name) {
    final List<License> result = super.nearestLicensesFor(name);
    if (result == null) {
      final License license = nearestLicenseWithName('LICENSE.TXT');
      assert(license != null);
      if (license != null)
        return <License>[license];
    }
    return result;
  }

  @override
  License nearestLicenseOfType(LicenseType type) {
    if (type == LicenseType.freetype) {
      final License result = nearestLicenseWithName('FTL.TXT');
      assert(result != null);
      return result;
    }
    return null;
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'builds' // build files
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryFreetypeSrcDirectory(this, entry);
    if (entry.name == 'docs')
      return _RepositoryFreetypeDocsDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryGlfwDirectory extends _RepositoryDirectory {
  _RepositoryGlfwDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'examples' // Not linked in build.
        && entry.name != 'tests' // Not linked in build.
        && entry.name != 'deps' // Only used by examples and tests; not linked in build.
        && super.shouldRecurse(entry);
  }
}

class _RepositoryIcuDirectory extends _RepositoryDirectory {
  _RepositoryIcuDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'license.html' // redundant with LICENSE file
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return _RepositoryIcuLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryHarfbuzzDirectory extends _RepositoryDirectory {
  _RepositoryHarfbuzzDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'util' // utils are command line tools that do not end up in the binary
        && super.shouldRecurse(entry);
  }
}

class _RepositoryJSR305Directory extends _RepositoryDirectory {
  _RepositoryJSR305Directory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryJSR305SrcDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryJSR305SrcDirectory extends _RepositoryDirectory {
  _RepositoryJSR305SrcDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'javadoc'
        && entry.name != 'sampleUses'
        && super.shouldRecurse(entry);
  }
}

class _RepositoryLibcxxDirectory extends _RepositoryDirectory {
  _RepositoryLibcxxDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'utils'
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryLibcxxSrcDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.TXT')
      return _RepositoryCxxStlDualLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryLibcxxSrcDirectory extends _RepositoryDirectory {
  _RepositoryLibcxxSrcDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'support')
      return _RepositoryLibcxxSrcSupportDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryLibcxxSrcSupportDirectory extends _RepositoryDirectory {
  _RepositoryLibcxxSrcSupportDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'solaris'
        && super.shouldRecurse(entry);
  }
}

class _RepositoryLibcxxabiDirectory extends _RepositoryDirectory {
  _RepositoryLibcxxabiDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.TXT')
      return _RepositoryCxxStlDualLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryLibJpegDirectory extends _RepositoryDirectory {
  _RepositoryLibJpegDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'README')
      return _RepositoryReadmeIjgFile(this, entry);
    if (entry.name == 'LICENSE')
      return _RepositoryLicenseFileWithLeader(this, entry, RegExp(r'^\(Copied from the README\.\)\n+-+\n+'));
    return super.createFile(entry);
  }
}

class _RepositoryLibJpegTurboDirectory extends _RepositoryDirectory {
  _RepositoryLibJpegTurboDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.md')
      return _RepositoryLibJpegTurboLicense(this, entry);
    return super.createFile(entry);
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'release' // contains nothing that ends up in the binary executable
        && entry.name != 'doc' // contains nothing that ends up in the binary executable
        && entry.name != 'testimages' // test assets
        && super.shouldRecurse(entry);
  }
}

class _RepositoryLibPngDirectory extends _RepositoryDirectory {
  _RepositoryLibPngDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE' || entry.name == 'png.h')
      return _RepositoryLibPngLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryLibWebpDirectory extends _RepositoryDirectory {
  _RepositoryLibWebpDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'examples' // contains nothing that ends up in the binary executable
      && entry.name != 'swig' // not included in our build
      && entry.name != 'gradle' // not included in our build
      && super.shouldRecurse(entry);
  }
}

class _RepositoryPkgDirectory extends _RepositoryDirectory {
  _RepositoryPkgDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'when')
      return _RepositoryPkgWhenDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryPkgWhenDirectory extends _RepositoryDirectory {
  _RepositoryPkgWhenDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'example' // contains nothing that ends up in the binary executable
        && super.shouldRecurse(entry);
  }
}

class _RepositorySkiaLibWebPDirectory extends _RepositoryDirectory {
  _RepositorySkiaLibWebPDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'webp')
      return _RepositoryReachOutDirectory(this, entry, const <String>{'config.h'}, 3);
    return super.createSubdirectory(entry);
  }
}

class _RepositorySkiaLibSdlDirectory extends _RepositoryDirectory {
  _RepositorySkiaLibSdlDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRootException => true;
}

class _RepositorySkiaThirdPartyDirectory extends _RepositoryGenericThirdPartyDirectory {
  _RepositorySkiaThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'giflib' // contains nothing that ends up in the binary executable
        && entry.name != 'freetype' // we use our own version
        && entry.name != 'freetype2' // we use our own version
        && entry.name != 'gif' // not linked in
        && entry.name != 'icu' // we use our own version
        && entry.name != 'libjpeg-turbo' // we use our own version
        && entry.name != 'libpng' // we use our own version
        && entry.name != 'lua' // not linked in
        && entry.name != 'yasm' // build tool (assembler)
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'ktx')
      return _RepositoryReachOutDirectory(this, entry, const <String>{'ktx.h', 'ktx.cpp'}, 2);
    if (entry.name == 'libmicrohttpd')
      return _RepositoryReachOutDirectory(this, entry, const <String>{'MHD_config.h'}, 2);
    if (entry.name == 'libwebp')
      return _RepositorySkiaLibWebPDirectory(this, entry);
    if (entry.name == 'libsdl')
      return _RepositorySkiaLibSdlDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositorySkiaDirectory extends _RepositoryDirectory {
  _RepositorySkiaDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'platform_tools' // contains nothing that ends up in the binary executable
        && entry.name != 'tools' // contains nothing that ends up in the binary executable
        && entry.name != 'resources' // contains nothing that ends up in the binary executable
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositorySkiaThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryVulkanDirectory extends _RepositoryDirectory {
  _RepositoryVulkanDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // Flutter only uses the headers in the include directory.
    return entry.name == 'include'
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryExcludeSubpathDirectory(this, entry, const <String>['spec']);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryWuffsDirectory extends _RepositoryDirectory {
  _RepositoryWuffsDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'CONTRIBUTORS' // not linked in
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryExcludeSubpathDirectory(this, entry, const <String>['spec']);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryRootThirdPartyDirectory extends _RepositoryGenericThirdPartyDirectory {
  _RepositoryRootThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'appurify-python' // only used by tests
        && entry.name != 'benchmark' // only used by tests
        && entry.name != 'dart-sdk' // redundant with //engine/dart; https://github.com/flutter/flutter/issues/2618
        && entry.name != 'firebase' // only used by bots; https://github.com/flutter/flutter/issues/3722
        && entry.name != 'gyp' // build-time only
        && entry.name != 'jinja2' // build-time code generation
        && entry.name != 'junit' // only mentioned in build files, not used
        && entry.name != 'libxml' // dependency of the testing system that we don't actually use
        && entry.name != 'llvm-build' // only used by build
        && entry.name != 'markupsafe' // build-time only
        && entry.name != 'mockito' // only used by tests
        && entry.name != 'pymock' // presumably only used by tests
        && entry.name != 'robolectric' // testing framework for android
        && entry.name != 'yasm' // build-time dependency only
        && entry.name != 'binutils' // build-time dependency only
        && entry.name != 'instrumented_libraries' // unused according to chinmay
        && entry.name != 'android_tools' // excluded on advice
        && entry.name != 'android_support' // build-time only
        && entry.name != 'googletest' // only used by tests
        && entry.name != 'skia' // treated as a separate component
        && entry.name != 'fontconfig' // not used in standard configurations
        && entry.name != 'swiftshader' // only used on hosts for tests
        && entry.name != 'ocmock' // only used for tests
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'android_platform')
      return _RepositoryAndroidPlatformDirectory(this, entry);
    if (entry.name == 'boringssl')
      return _RepositoryBoringSSLDirectory(this, entry);
    if (entry.name == 'catapult')
      return _RepositoryCatapultDirectory(this, entry);
    if (entry.name == 'dart')
      return _RepositoryDartDirectory(this, entry);
    if (entry.name == 'expat')
      return _RepositoryExpatDirectory(this, entry);
    if (entry.name == 'freetype-android')
      throw '//third_party/freetype-android is no longer part of this client: remove it';
    if (entry.name == 'freetype2')
      return _RepositoryFreetypeDirectory(this, entry);
    if (entry.name == 'glfw')
      return _RepositoryGlfwDirectory(this, entry);
    if (entry.name == 'harfbuzz')
      return _RepositoryHarfbuzzDirectory(this, entry);
    if (entry.name == 'icu')
      return _RepositoryIcuDirectory(this, entry);
    if (entry.name == 'jsr-305')
      return _RepositoryJSR305Directory(this, entry);
    if (entry.name == 'libcxx')
      return _RepositoryLibcxxDirectory(this, entry);
    if (entry.name == 'libcxxabi')
      return _RepositoryLibcxxabiDirectory(this, entry);
    if (entry.name == 'libjpeg')
      return _RepositoryLibJpegDirectory(this, entry);
    if (entry.name == 'libjpeg_turbo' || entry.name == 'libjpeg-turbo')
      return _RepositoryLibJpegTurboDirectory(this, entry);
    if (entry.name == 'libpng')
      return _RepositoryLibPngDirectory(this, entry);
    if (entry.name == 'libwebp')
      return _RepositoryLibWebpDirectory(this, entry);
    if (entry.name == 'pkg')
      return _RepositoryPkgDirectory(this, entry);
    if (entry.name == 'vulkan')
      return _RepositoryVulkanDirectory(this, entry);
    if (entry.name == 'wuffs')
      return _RepositoryWuffsDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryBoringSSLThirdPartyDirectory extends _RepositoryDirectory {
  _RepositoryBoringSSLThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'android-cmake' // build-time only
        && super.shouldRecurse(entry);
  }
}

class _RepositoryBoringSSLSourceDirectory extends _RepositoryDirectory {
  _RepositoryBoringSSLSourceDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  String get libraryName => 'boringssl';

  @override
  bool get isLicenseRoot => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'fuzz' // testing tools, not shipped
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return _RepositoryOpenSSLLicenseFile(this, entry);
    return super.createFile(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryBoringSSLThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

/// The BoringSSL license file.
///
/// This license includes 23 lines of informational header text that are not
/// part of the copyright notices and can be skipped.
/// It also has a trailer that mentions licenses that are used during build
/// time of BoringSSL - those can be ignored as well since they don't apply
/// to code that is distributed.
class _RepositoryOpenSSLLicenseFile extends _RepositorySingleLicenseFile {
  _RepositoryOpenSSLLicenseFile(_RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io,
        License.fromBodyAndType(
            LineSplitter.split(io.readString())
                .skip(23)
                .takeWhile((String s) => !s.startsWith('BoringSSL uses the Chromium test infrastructure to run a continuous build,'))
                .join('\n'),
            LicenseType.openssl,
            origin: io.fullName)) {
    _verifyLicense(io);
  }

  static void _verifyLicense(fs.TextFile io) {
    final String contents = io.readString();
    if (!contents.contains('BoringSSL is a fork of OpenSSL. As such, large parts of it fall under OpenSSL'))
      throw 'unexpected OpenSSL license file contents:\n----8<----\n$contents\n----<8----';
  }

  @override
  License licenseOfType(LicenseType type) {
    if (type == LicenseType.openssl)
      return license;
    return null;
  }
}

class _RepositoryBoringSSLDirectory extends _RepositoryDirectory {
  _RepositoryBoringSSLDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'README')
      return _RepositoryBlankLicenseFile(this, entry, 'This repository contains the files generated by boringssl for its build.');
    return super.createFile(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return _RepositoryBoringSSLSourceDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryCatapultThirdPartyApiClientDirectory extends _RepositoryDirectory {
  _RepositoryCatapultThirdPartyApiClientDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return _RepositoryCatapultApiClientLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryCatapultThirdPartyCoverageDirectory extends _RepositoryDirectory {
  _RepositoryCatapultThirdPartyCoverageDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'NOTICE.txt')
      return _RepositoryCatapultCoverageLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class _RepositoryCatapultThirdPartyDirectory extends _RepositoryDirectory {
  _RepositoryCatapultThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'apiclient')
      return _RepositoryCatapultThirdPartyApiClientDirectory(this, entry);
    if (entry.name == 'coverage')
      return _RepositoryCatapultThirdPartyCoverageDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryCatapultDirectory extends _RepositoryDirectory {
  _RepositoryCatapultDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryCatapultThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryDartRuntimeThirdPartyDirectory extends _RepositoryGenericThirdPartyDirectory {
  _RepositoryDartRuntimeThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'd3' // Siva says "that is the charting library used by the binary size tool"
        && entry.name != 'binary_size' // not linked in either
        && super.shouldRecurse(entry);
  }
}

class _RepositoryDartThirdPartyDirectory extends _RepositoryGenericThirdPartyDirectory {
  _RepositoryDartThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'drt_resources' // test materials
        && entry.name != 'firefox_jsshell' // testing tool for dart2js
        && entry.name != 'd8' // testing tool for dart2js
        && entry.name != 'pkg'
        && entry.name != 'pkg_tested'
        && entry.name != 'requirejs' // only used by DDC
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'boringssl')
      return _RepositoryBoringSSLDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryDartRuntimeDirectory extends _RepositoryDirectory {
  _RepositoryDartRuntimeDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryDartRuntimeThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryDartDirectory extends _RepositoryDirectory {
  _RepositoryDartDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRoot => true;

  @override
  _RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return _RepositoryDartLicenseFile(this, entry);
    return super.createFile(entry);
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'pkg' // packages that don't become part of the binary (e.g. the analyzer)
        && entry.name != 'tests' // only used by tests, obviously
        && entry.name != 'docs' // not shipped in binary
        && entry.name != 'build' // not shipped in binary
        && entry.name != 'tools' // not shipped in binary
        && entry.name != 'samples-dev' // not shipped in binary
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryDartThirdPartyDirectory(this, entry);
    if (entry.name == 'runtime')
      return _RepositoryDartRuntimeDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryFlutterDirectory extends _RepositoryDirectory {
  _RepositoryFlutterDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  String get libraryName => 'engine';

  @override
  bool get isLicenseRoot => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'testing'
        && entry.name != 'tools'
        && entry.name != 'docs'
        && entry.name != 'examples'
        && entry.name != 'build'
        && entry.name != 'ci'
        && entry.name != 'frontend_server'
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'sky')
      return _RepositoryExcludeSubpathDirectory(this, entry, const <String>['packages', 'sky_engine', 'LICENSE']); // that's the output of this script!
    if (entry.name == 'third_party')
      return _RepositoryFlutterThirdPartyDirectory(this, entry);
    if (entry.name == 'lib')
      return _RepositoryLibDirectory(entry, this, entry);
    return super.createSubdirectory(entry);
  }
}

// The "lib/" directory containing the source code for "dart:ui" (both native and Web) and
// all its sub-directories.
class _RepositoryLibDirectory extends _RepositoryDirectory {
  _RepositoryLibDirectory(this.libRoot, _RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  // List of files inside the lib directory that we're not scanning.
  static const List<String> _kBlacklist = <String>[
    'web_ui/lib/assets/ahem.ttf',  // this gitignored file exists only for testing purposes
  ];

  final fs.Directory libRoot;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    final String relativePath = path.relative(entry.fullName, from: libRoot.fullName);
    if (_kBlacklist.contains(relativePath)) {
      return false;
    }
    return super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    return _RepositoryLibDirectory(libRoot, this, entry);
  }
}

class _RepositoryFuchsiaDirectory extends _RepositoryDirectory {
  _RepositoryFuchsiaDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  String get libraryName => 'fuchsia_sdk';

  @override
  bool get isLicenseRoot => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'toolchain'
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'sdk')
      return _RepositoryFuchsiaSdkDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryFuchsiaSdkDirectory extends _RepositoryDirectory {
  _RepositoryFuchsiaSdkDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'linux' || entry.name == 'mac')
      return _RepositoryFuchsiaSdkLinuxDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryFuchsiaSdkLinuxDirectory extends _RepositoryDirectory {
  _RepositoryFuchsiaSdkLinuxDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != '.build-id'
        && entry.name != 'docs'
        && entry.name != 'images'
        && entry.name != 'meta'
        && entry.name != 'tools';
  }
}

class _RepositoryFlutterThirdPartyDirectory extends _RepositoryDirectory {
  _RepositoryFlutterThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'txt')
      return _RepositoryFlutterTxtDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryFlutterTxtDirectory extends _RepositoryDirectory {
  _RepositoryFlutterTxtDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return _RepositoryFlutterTxtThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class _RepositoryFlutterTxtThirdPartyDirectory extends _RepositoryDirectory {
  _RepositoryFlutterTxtThirdPartyDirectory(_RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'fonts';
  }
}

/// The license tool directory.
///
/// This is a special-case root node that is not used for license aggregation,
/// but simply to compute a signature for the license tool itself. When this
/// signature changes, we force re-run license collection for all components in
/// order to verify the tool itself still produces the same output.
class _RepositoryFlutterLicenseToolDirectory extends _RepositoryDirectory {
  _RepositoryFlutterLicenseToolDirectory(fs.Directory io) : super(null, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'data'
        && super.shouldRecurse(entry);
  }
}

class _RepositoryRoot extends _RepositoryDirectory {
  _RepositoryRoot(fs.Directory io) : super(null, io);

  @override
  String get libraryName {
    assert(false);
    return 'engine';
  }

  @override
  bool get isLicenseRoot => true;

  @override
  bool get subdirectoriesAreLicenseRoots => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'testing' // only used by tests
        && entry.name != 'build' // only used by build
        && entry.name != 'buildtools' // only used by build
        && entry.name != 'build_overrides' // only used by build
        && entry.name != 'ios_tools' // only used by build
        && entry.name != 'tools' // not distributed in binary
        && entry.name != 'out' // output of build
        && super.shouldRecurse(entry);
  }

  @override
  _RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'base')
      throw '//base is no longer part of this client: remove it';
    if (entry.name == 'third_party')
      return _RepositoryRootThirdPartyDirectory(this, entry);
    if (entry.name == 'flutter')
      return _RepositoryFlutterDirectory(this, entry);
    if (entry.name == 'fuchsia')
      return _RepositoryFuchsiaDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  @override
  List<_RepositoryDirectory> get virtualSubdirectories {
    // Skia is updated more frequently than other third party libraries and
    // is therefore represented as a separate top-level component.
    final fs.Directory thirdPartyNode = io.walk.firstWhere((fs.IoNode node) => node.name == 'third_party');
    final fs.IoNode skiaNode = thirdPartyNode.walk.firstWhere((fs.IoNode node) => node.name == 'skia');
    return <_RepositoryDirectory>[_RepositorySkiaDirectory(this, skiaNode)];
  }
}


class _Progress {
  _Progress(this.max) {
    // This may happen when a git client contains left-over empty component
    // directories after DEPS file changes.
    if (max <= 0)
      throw ArgumentError('Progress.max must be > 0 but was: $max');
  }

  final int max;
  int get withLicense => _withLicense;
  int _withLicense = 0;
  int get withoutLicense => _withoutLicense;
  int _withoutLicense = 0;
  String get label => _label;
  String _label = '';
  int _lastLength = 0;
  set label(String value) {
    if (value.length > 50)
      value = '.../' + value.substring(math.max(0, value.lastIndexOf('/', value.length - 45) + 1));
    if (_label != value) {
      _label = value;
      update();
    }
  }
  void advance({@required bool success}) {
    assert(success != null);
    if (success)
      _withLicense += 1;
    else
      _withoutLicense += 1;
    update();
  }
  Stopwatch _lastUpdate;
  void update({bool flush = false}) {
    if (_lastUpdate == null || _lastUpdate.elapsedMilliseconds > 90 || flush) {
      _lastUpdate ??= Stopwatch();
      final String line = toString();
      system.stderr.write('\r$line');
      if (_lastLength > line.length)
        system.stderr.write(' ' * (_lastLength - line.length));
      _lastLength = line.length;
      _lastUpdate.reset();
      _lastUpdate.start();
    }
  }
  void flush() => update(flush: true);
  bool get hadErrors => _withoutLicense > 0;
  @override
  String toString() {
    final int percent = (100.0 * (_withLicense + _withoutLicense) / max).round();
    return '${(_withLicense + _withoutLicense).toString().padLeft(10)} of $max ${'█' * (percent ~/ 10)}${'░' * (10 - (percent ~/ 10))} $percent% ($_withoutLicense missing licenses)  $label';
  }
}

/// Reads the signature from a golden file.
Future<String> _readSignature(String goldenPath) async {
  try {
    final system.File goldenFile = system.File(goldenPath);
    final String goldenSignature = await utf8.decoder.bind(goldenFile.openRead())
        .transform(const LineSplitter()).first;
    final RegExp signaturePattern = RegExp(r'Signature: (\w+)');
    final Match goldenMatch = signaturePattern.matchAsPrefix(goldenSignature);
    if (goldenMatch != null)
      return goldenMatch.group(1);
  } on system.FileSystemException {
    system.stderr.writeln('    Failed to read signature file.');
    return null;
  }
  return null;
}

/// Writes a signature to an [system.IOSink] in the expected format.
void _writeSignature(String signature, system.IOSink sink) {
  if (signature != null)
    sink.writeln('Signature: $signature\n');
}

// Checks for changes to the license tool itself.
//
// Returns true if changes are detected.
Future<bool> _computeLicenseToolChanges(_RepositoryDirectory root, {String goldenSignaturePath, String outputSignaturePath}) async {
  system.stderr.writeln('Computing signature for license tool');
  final fs.Directory flutterNode = root.io.walk.firstWhere((fs.IoNode node) => node.name == 'flutter');
  final fs.Directory toolsNode = flutterNode.walk.firstWhere((fs.IoNode node) => node.name == 'tools');
  final fs.Directory licenseNode = toolsNode.walk.firstWhere((fs.IoNode node) => node.name == 'licenses');
  final _RepositoryFlutterLicenseToolDirectory licenseToolDirectory = _RepositoryFlutterLicenseToolDirectory(licenseNode);

  final String toolSignature = await licenseToolDirectory.signature;
  final system.IOSink sink = system.File(outputSignaturePath).openWrite();
  _writeSignature(toolSignature, sink);
  await sink.close();

  final String goldenSignature = await _readSignature(goldenSignaturePath);
  return toolSignature != goldenSignature;
}

/// Collects licenses for the specified component.
///
/// If [writeSignature] is set, the signature is written to the output file.
/// If [force] is set, collection is run regardless of whether or not the signature matches.
Future<void> _collectLicensesForComponent(_RepositoryDirectory componentRoot, {
  String inputGoldenPath,
  String outputGoldenPath,
  bool writeSignature,
  bool force,
}) async {
  // Check whether the golden file matches the signature of the current contents of this directory.
  final String goldenSignature = await _readSignature(inputGoldenPath);
  final String signature = await componentRoot.signature;
  if (!force && goldenSignature == signature) {
    system.stderr.writeln('    Skipping this component - no change in signature');
    return;
  }

  final _Progress progress = _Progress(componentRoot.fileCount);

  final system.File outFile = system.File(outputGoldenPath);
  final system.IOSink sink = outFile.openWrite();
  if (writeSignature)
    _writeSignature(signature, sink);

  final List<License> licenses = Set<License>.from(componentRoot.getLicenses(progress).toList()).toList();

  if (progress.hadErrors)
    throw 'Had failures while collecting licenses.';

  sink.writeln('UNUSED LICENSES:\n');
  final List<String> unusedLicenses = licenses
    .where((License license) => !license.isUsed)
    .map((License license) => license.toString())
    .toList();
  unusedLicenses.sort();
  sink.writeln(unusedLicenses.join('\n\n'));
  sink.writeln('~' * 80);

  sink.writeln('USED LICENSES:\n');
  final List<License> usedLicenses = licenses.where((License license) => license.isUsed).toList();
  final List<String> output = usedLicenses.map((License license) => license.toString()).toList();
  for (int index = 0; index < output.length; index += 1) {
    // The strings we look for here are strings which we do not expect to see in
    // any of the licenses we use. They either represent examples of misparsing
    // licenses (issues we've previously run into and fixed), or licenses we
    // know we are trying to avoid (e.g. the GPL, or licenses that only apply to
    // test content which shouldn't get built at all).
    // If you find that one of these tests is getting hit, and it's not obvious
    // to you why the relevant license is a problem, please ask around (e.g. try
    // asking Hixie). Do not merely remove one of these checks, sometimes the
    // issues involved are relatively subtle.
    if (output[index].contains('Version: MPL 1.1/GPL 2.0/LGPL 2.1'))
      throw 'Unexpected trilicense block found in: ${usedLicenses[index].origin}';
    if (output[index].contains('The contents of this file are subject to the Mozilla Public License Version'))
      throw 'Unexpected MPL block found in: ${usedLicenses[index].origin}';
    if (output[index].contains('You should have received a copy of the GNU'))
      throw 'Unexpected GPL block found in: ${usedLicenses[index].origin}';
    if (output[index].contains('BoringSSL is a fork of OpenSSL'))
      throw 'Unexpected legacy BoringSSL block found in: ${usedLicenses[index].origin}';
    if (output[index].contains('Contents of this folder are ported from'))
      throw 'Unexpected block found in: ${usedLicenses[index].origin}';
    if (output[index].contains('https://github.com/w3c/web-platform-tests/tree/master/selectors-api'))
      throw 'Unexpected W3C content found in: ${usedLicenses[index].origin}';
    if (output[index].contains('http://www.w3.org/Consortium/Legal/2008/04-testsuite-copyright.html'))
      throw 'Unexpected W3C copyright found in: ${usedLicenses[index].origin}';
    if (output[index].contains('It is based on commit'))
      throw 'Unexpected content found in: ${usedLicenses[index].origin}';
    if (output[index].contains('The original code is covered by the dual-licensing approach described in:'))
      throw 'Unexpected old license reference found in: ${usedLicenses[index].origin}';
    if (output[index].contains('must choose'))
      throw 'Unexpected indecisiveness found in: ${usedLicenses[index].origin}';
  }

  output.sort();
  sink.writeln(output.join('\n\n'));
  sink.writeln('Total license count: ${licenses.length}');

  await sink.close();
  progress.label = 'Done.';
  progress.flush();
  system.stderr.writeln('');
}


// MAIN

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addOption('src', help: 'The root of the engine source')
    ..addOption('out', help: 'The directory where output is written')
    ..addOption('golden', help: 'The directory containing golden results')
    ..addFlag('release', help: 'Print output in the format used for product releases');

  final ArgResults argResults = parser.parse(arguments);
  final bool releaseMode = argResults['release'];
  if (argResults['src'] == null) {
    print('Flutter license script: Must provide --src directory');
    print(parser.usage);
    system.exit(1);
  }
  if (!releaseMode) {
    if (argResults['out'] == null || argResults['golden'] == null) {
      print('Flutter license script: Must provide --out and --golden directories in non-release mode');
      print(parser.usage);
      system.exit(1);
    }
    if (!system.FileSystemEntity.isDirectorySync(argResults['golden'])) {
      print('Flutter license script: Golden directory does not exist');
      print(parser.usage);
      system.exit(1);
    }
    final system.Directory out = system.Directory(argResults['out']);
    if (!out.existsSync())
      out.createSync(recursive: true);
  }

  try {
    system.stderr.writeln('Finding files...');
    final fs.FileSystemDirectory rootDirectory = fs.FileSystemDirectory.fromPath(argResults['src']);
    final _RepositoryDirectory root = _RepositoryRoot(rootDirectory);

    if (releaseMode) {
      system.stderr.writeln('Collecting licenses...');
      final _Progress progress = _Progress(root.fileCount);
      final List<License> licenses = Set<License>.from(root.getLicenses(progress).toList()).toList();
      if (progress.hadErrors)
        throw 'Had failures while collecting licenses.';
      progress.label = 'Dumping results...';
      progress.flush();
      final List<String> output = licenses
        .where((License license) => license.isUsed)
        .map((License license) => license.toStringFormal())
        .where((String text) => text != null)
        .toList();
      output.sort();
      print(output.join('\n${"-" * 80}\n'));
      progress.label = 'Done.';
      progress.flush();
      system.stderr.writeln('');
    } else {
      // If changes are detected to the license tool itself, force collection
      // for all components in order to check we're still generating correct
      // output.
      const String toolSignatureFilename = 'tool_signature';
      final bool forceRunAll = await _computeLicenseToolChanges(
          root,
          goldenSignaturePath: path.join(argResults['golden'], toolSignatureFilename),
          outputSignaturePath: path.join(argResults['out'], toolSignatureFilename),
      );
      if (forceRunAll)
        system.stderr.writeln('    Detected changes to license tool. Forcing license collection for all components.');

      final List<String> usedGoldens = <String>[];
      bool isFirstComponent = true;
      for (_RepositoryDirectory component in root.subdirectories) {
        system.stderr.writeln('Collecting licenses for ${component.io.name}');

        _RepositoryDirectory componentRoot;
        if (isFirstComponent) {
          // For the first component, we can use the results of the initial repository crawl.
          isFirstComponent = false;
          componentRoot = component;
        } else {
          // For other components, we need a clean repository that does not
          // contain any state left over from previous components.
          clearLicenseRegistry();
          componentRoot = _RepositoryRoot(rootDirectory).subdirectories
              .firstWhere((_RepositoryDirectory dir) => dir.name == component.name);
        }

        // Always run the full license check on the flutter tree. The flutter
        // tree is relatively small and changes frequently in ways that do not
        // affect the license output, and we don't want to require updates to
        // the golden signature for those changes.
        final String goldenFileName = 'licenses_${component.io.name}';
        await _collectLicensesForComponent(
            componentRoot,
            inputGoldenPath: path.join(argResults['golden'], goldenFileName),
            outputGoldenPath: path.join(argResults['out'], goldenFileName),
            writeSignature: component.io.name != 'flutter',
            force: forceRunAll || component.io.name == 'flutter',
        );
        usedGoldens.add(goldenFileName);
      }

      final Set<String> unusedGoldens = system.Directory(argResults['golden']).listSync()
        .map((system.FileSystemEntity file) => path.basename(file.path)).toSet()
        ..removeAll(usedGoldens)
        ..remove(toolSignatureFilename);
      if (unusedGoldens.isNotEmpty) {
        system.stderr.writeln('The following golden files in ${argResults['golden']} are unused and need to be deleted:');
        unusedGoldens.map((String s) => ' * $s').forEach(system.stderr.writeln);
        system.exit(1);
      }
    }
  } catch (e, stack) {
    system.stderr.writeln('failure: $e\n$stack');
    system.stderr.writeln('aborted.');
    system.exit(1);
  }
}
