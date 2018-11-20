// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See README in this directory for information on how this code is organised.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as system;
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:licenses/patterns.dart';
import 'package:path/path.dart' as path;

import 'filesystem.dart' as fs;
import 'licenses.dart';


// REPOSITORY OBJECTS

abstract class RepositoryEntry implements Comparable<RepositoryEntry> {
  RepositoryEntry(this.parent, this.io);
  final RepositoryDirectory parent;
  final fs.IoNode io;
  String get name => io.name;
  String get libraryName;

  @override
  int compareTo(RepositoryEntry other) => toString().compareTo(other.toString());

  @override
  String toString() => io.fullName;
}

abstract class RepositoryFile extends RepositoryEntry {
  RepositoryFile(RepositoryDirectory parent, fs.File io) : super(parent, io);

  Iterable<License> get licenses;

  @override
  String get libraryName => parent.libraryName;

  @override
  fs.File get io => super.io;
}

abstract class RepositoryLicensedFile extends RepositoryFile {
  RepositoryLicensedFile(RepositoryDirectory parent, fs.File io) : super(parent, io);

  // file names that we are confident won't be included in the final build product
  static final RegExp _readmeNamePattern = new RegExp(r'\b_*(?:readme|contributing|patents)_*\b', caseSensitive: false);
  static final RegExp _buildTimePattern = new RegExp(r'^(?!.*gen$)(?:CMakeLists\.txt|(?:pkgdata)?Makefile(?:\.inc)?(?:\.am|\.in|)|configure(?:\.ac|\.in)?|config\.(?:sub|guess)|.+\.m4|install-sh|.+\.sh|.+\.bat|.+\.pyc?|.+\.pl|icu-configure|.+\.gypi?|.*\.gni?|.+\.mk|.+\.cmake|.+\.gradle|.+\.yaml|pubspec\.lock|\.packages|vms_make\.com|pom\.xml|\.project|source\.properties)$', caseSensitive: false);
  static final RegExp _docsPattern = new RegExp(r'^(?:INSTALL|NEWS|OWNERS|AUTHORS|ChangeLog(?:\.rst|\.[0-9]+)?|.+\.txt|.+\.md|.+\.log|.+\.css|.+\.1|doxygen\.config|.+\.spec(?:\.in)?)$', caseSensitive: false);
  static final RegExp _devPattern = new RegExp(r'^(?:codereview\.settings|.+\.~|.+\.~[0-9]+~|\.clang-format|\.gitattributes|\.landmines|\.DS_Store|\.travis\.yml|\.cirrus\.yml)$', caseSensitive: false);
  static final RegExp _testsPattern = new RegExp(r'^(?:tj(?:bench|example)test\.(?:java\.)?in|example\.c)$', caseSensitive: false);

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

class RepositorySourceFile extends RepositoryLicensedFile {
  RepositorySourceFile(RepositoryDirectory parent, fs.TextFile io) : super(parent, io);

  @override
  fs.TextFile get io => super.io;

  static final RegExp _hashBangPattern = new RegExp(r'^#! *(?:/bin/sh|/bin/bash|/usr/bin/env +(?:python|bash))\b');

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
    _licenses.forEach((License license) => license.markUsed(io.fullName, libraryName));
    assert(_licenses != null && _licenses.isNotEmpty);
    return _licenses;
  }
}

class RepositoryBinaryFile extends RepositoryLicensedFile {
  RepositoryBinaryFile(RepositoryDirectory parent, fs.File io) : super(parent, io);

  @override
  fs.File get io => super.io;

  List<License> _licenses;

  @override
  List<License> get licenses {
    if (_licenses == null) {
      _licenses = parent.nearestLicensesFor(name);
      if (_licenses == null || _licenses.isEmpty)
        throw 'no license file found in scope for ${io.fullName}';
      _licenses.forEach((License license) => license.markUsed(io.fullName, libraryName));
    }
    return _licenses;
  }
}


// LICENSES

abstract class RepositoryLicenseFile extends RepositoryFile {
  RepositoryLicenseFile(RepositoryDirectory parent, fs.File io) : super(parent, io);

  List<License> licensesFor(String name);
  License licenseOfType(LicenseType type);
  License licenseWithName(String name);

  License get defaultLicense;
}

abstract class RepositorySingleLicenseFile extends RepositoryLicenseFile {
  RepositorySingleLicenseFile(RepositoryDirectory parent, fs.TextFile io, this.license)
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

class RepositoryGeneralSingleLicenseFile extends RepositorySingleLicenseFile {
  RepositoryGeneralSingleLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, new License.fromBodyAndName(io.readString(), io.name, origin: io.fullName));

  RepositoryGeneralSingleLicenseFile.fromLicense(RepositoryDirectory parent, fs.TextFile io, License license)
    : super(parent, io, license);

  @override
  License licenseOfType(LicenseType type) {
    if (type == license.type)
      return license;
    return null;
  }
}

class RepositoryApache4DNoticeFile extends RepositorySingleLicenseFile {
  RepositoryApache4DNoticeFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  @override
  License licenseOfType(LicenseType type) => null;

  static final RegExp _pattern = new RegExp(
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
    return new License.unique(match.group(2), LicenseType.apacheNotice, origin: io.fullName);
  }
}

class RepositoryLicenseRedirectFile extends RepositorySingleLicenseFile {
  RepositoryLicenseRedirectFile(RepositoryDirectory parent, fs.TextFile io, License license)
    : super(parent, io, license);

  @override
  License licenseOfType(LicenseType type) {
    if (type == license.type)
      return license;
    return null;
  }

  static RepositoryLicenseRedirectFile maybeCreateFrom(RepositoryDirectory parent, fs.TextFile io) {
    String contents = io.readString();
    License license = interpretAsRedirectLicense(contents, parent, origin: io.fullName);
    if (license != null)
      return new RepositoryLicenseRedirectFile(parent, io, license);
    return null;
  }
}

class RepositoryLicenseFileWithLeader extends RepositorySingleLicenseFile {
  RepositoryLicenseFileWithLeader(RepositoryDirectory parent, fs.TextFile io, RegExp leader)
    : super(parent, io, _parseLicense(io, leader));

  @override
  License licenseOfType(LicenseType type) => null;

  static License _parseLicense(fs.TextFile io, RegExp leader) {
    final String body = io.readString();
    final Match match = leader.firstMatch(body);
    if (match == null)
      throw 'failed to strip leader from $io\nleader: /$leader/\nbody:\n---\n$body\n---';
    return new License.fromBodyAndName(body.substring(match.end), io.name, origin: io.fullName);
  }
}

class RepositoryReadmeIjgFile extends RepositorySingleLicenseFile {
  RepositoryReadmeIjgFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = new RegExp(
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
    String body = io.readString();
    if (!body.contains(_pattern))
      throw 'unexpected contents in IJG README';
    return new License.message(body, LicenseType.ijg, origin: io.fullName);
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

class RepositoryDartLicenseFile extends RepositorySingleLicenseFile {
  RepositoryDartLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = new RegExp(
    r'^This license applies to all parts of Dart that are not externally\n'
    r'maintained libraries\. The external maintained libraries used by\n'
    r'Dart are:\n'
    r'\n'
    r'(?:.+\n)+'
    r'\n'
    r'The libraries may have their own licenses; we recommend you read them,\n'
    r'as their terms may differ from the terms below\.\n'
    r'\n'
    r'(Copyright (?:.|\n)+)$',
    caseSensitive: false
  );

  static License _parseLicense(fs.TextFile io) {
    final Match match = _pattern.firstMatch(io.readString());
    if (match == null || match.groupCount != 1)
      throw 'unexpected Dart license file contents';
    return new License.template(match.group(1), LicenseType.bsd, origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class RepositoryLibPngLicenseFile extends RepositorySingleLicenseFile {
  RepositoryLibPngLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, new License.blank(io.readString(), LicenseType.libpng, origin: io.fullName)) {
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

class RepositoryBlankLicenseFile extends RepositorySingleLicenseFile {
  RepositoryBlankLicenseFile(RepositoryDirectory parent, fs.TextFile io, String sanityCheck)
    : super(parent, io, new License.blank(io.readString(), LicenseType.unknown)) {
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

class RepositoryCatapultApiClientLicenseFile extends RepositorySingleLicenseFile {
  RepositoryCatapultApiClientLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = new RegExp(
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
    return new License.fromUrl(match.group(1), origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class RepositoryCatapultCoverageLicenseFile extends RepositorySingleLicenseFile {
  RepositoryCatapultCoverageLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io, _parseLicense(io));

  static final RegExp _pattern = new RegExp(
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
    return new License.fromUrl(match.group(1), origin: io.fullName);
  }

  @override
  License licenseOfType(LicenseType type) {
    return null;
  }
}

class RepositoryLibJpegTurboLicense extends RepositoryLicenseFile {
  RepositoryLibJpegTurboLicense(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io) {
    _parseLicense(io);
  }

  static final RegExp _pattern = new RegExp(
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
    String body = io.readString();
    if (!body.contains(_pattern))
      throw 'unexpected contents in libjpeg-turbo LICENSE';
  }

  List<License> _licenses;

  @override
  List<License> get licenses {
    if (_licenses == null) {
      final RepositoryReadmeIjgFile readme = parent.getChildByName('README.ijg');
      final RepositorySourceFile main = parent.getChildByName('turbojpeg.c');
      final RepositoryDirectory simd = parent.getChildByName('simd');
      final RepositorySourceFile zlib = simd.getChildByName('jsimdext.inc');
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

class RepositoryFreetypeLicenseFile extends RepositoryLicenseFile {
  RepositoryFreetypeLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : _target = _parseLicense(io), super(parent, io);

  static final RegExp _pattern = new RegExp(
    r"The  FreeType 2  font  engine is  copyrighted  work and  cannot be  used\n"
    r"legally  without a  software license\.   In  order to  make this  project\n"
    r"usable  to a vast  majority of  developers, we  distribute it  under two\n"
    r"mutually exclusive open-source licenses\.\n"
    r"\n"
    r"This means  that \*you\* must choose  \*one\* of the  two licenses described\n"
    r"below, then obey  all its terms and conditions when  using FreeType 2 in\n"
    r"any of your projects or products.\n"
    r"\n"
    r"  - The FreeType License, found in  the file `(FTL\.TXT)', which is similar\n"
    r"    to the original BSD license \*with\* an advertising clause that forces\n"
    r"    you  to  explicitly cite  the  FreeType  project  in your  product's\n"
    r"    documentation\.  All  details are in the license  file\.  This license\n"
    r"    is  suited  to products  which  don't  use  the GNU  General  Public\n"
    r"    License\.\n"
    r"\n"
    r"    Note that  this license  is  compatible  to the  GNU General  Public\n"
    r"    License version 3, but not version 2\.\n"
    r"\n"
    r"  - The GNU General Public License version 2, found in  `GPLv2\.TXT' \(any\n"
    r"    later version can be used  also\), for programs which already use the\n"
    r"    GPL\.  Note  that the  FTL is  incompatible  with  GPLv2 due  to  its\n"
    r"    advertisement clause\.\n"
    r"\n"
    r"The contributed BDF and PCF drivers  come with a license similar to that\n"
    r"of the X Window System\.  It is compatible to the above two licenses \(see\n"
    r"file src/bdf/README and  src/pcf/README\)\.  The same holds  for the files\n"
    r"`fthash\.c' and  `fthash\.h'; their  code was  part of  the BDF  driver in\n"
    r"earlier FreeType versions\.\n"
    r"\n"
    r"The gzip module uses the zlib license \(see src/gzip/zlib\.h\) which too is\n"
    r"compatible to the above two licenses\.\n"
    r"\n"
    r"The MD5 checksum support \(only used for debugging in development builds\)\n"
    r"is in the public domain\.\n"
    r"\n*"
    r"--- end of LICENSE\.TXT ---\n*$"
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

class RepositoryIcuLicenseFile extends RepositoryLicenseFile {
  RepositoryIcuLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : _licenses = _parseLicense(io),
      super(parent, io);

  @override
  fs.TextFile get io => super.io;

  final List<License> _licenses;

  static final RegExp _pattern = new RegExp(
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

  static final RegExp _unexpectedHash = new RegExp(r'^.+ #', multiLine: true);
  static final RegExp _newlineHash = new RegExp(r' # ?');

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
      new License.fromBodyAndType(_dewrap(match.group(1)), LicenseType.unknown, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(2)), LicenseType.icu, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(3)), LicenseType.bsd, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(4)), LicenseType.bsd, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(5)), LicenseType.bsd, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(6)), LicenseType.unknown, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(7)), LicenseType.unknown, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(8)), LicenseType.bsd, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(9)), LicenseType.bsd, origin: io.fullName),
      new License.fromBodyAndType(_dewrap(match.group(11)), LicenseType.bsd, origin: io.fullName),
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
    int start = index;
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

class RepositoryMultiLicenseNoticesForFilesFile extends RepositoryLicenseFile {
  RepositoryMultiLicenseNoticesForFilesFile(RepositoryDirectory parent, fs.File io)
    : _licenses = _parseLicense(io),
      super(parent, io);

  @override
  fs.File get io => super.io;

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
      License license = new License.unique(bodyText, LicenseType.unknown, origin: io.fullName);
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
    License license = _licenses[name];
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

class RepositoryCxxStlDualLicenseFile extends RepositoryLicenseFile {
  RepositoryCxxStlDualLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : _licenses = _parseLicenses(io), super(parent, io);

  static final RegExp _pattern = new RegExp(
    r'^'
    r'==============================================================================\n'
    r'.+ License\n'
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
      new License.fromBodyAndType(match.group(1), LicenseType.bsd),
      new License.fromBodyAndType(match.group(2), LicenseType.mit),
    ];
  }

  List<License> _licenses;

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

class RepositoryDirectory extends RepositoryEntry implements LicenseSource {
  RepositoryDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io) {
    crawl();
  }

  @override
  fs.Directory get io => super.io;

  final List<RepositoryDirectory> _subdirectories = <RepositoryDirectory>[];
  final List<RepositoryLicensedFile> _files = <RepositoryLicensedFile>[];
  final List<RepositoryLicenseFile> _licenses = <RepositoryLicenseFile>[];

  List<RepositoryDirectory> get subdirectories => _subdirectories;

  final Map<String, RepositoryEntry> _childrenByName = <String, RepositoryEntry>{};

  // the bit at the beginning excludes files like "license.py".
  static final RegExp _licenseNamePattern = new RegExp(r'^(?!.*\.py$)(?!.*(?:no|update)-copyright)(?!.*mh-bsd-gcc).*\b_*(?:license(?!\.html)|copying|copyright|notice|l?gpl|bsd|mpl?|ftl\.txt)_*\b', caseSensitive: false);

  void crawl() {
    for (fs.IoNode entry in io.walk) {
      if (shouldRecurse(entry)) {
        assert(!_childrenByName.containsKey(entry.name));
        if (entry is fs.Directory) {
          RepositoryDirectory child = createSubdirectory(entry);
          _subdirectories.add(child);
          _childrenByName[child.name] = child;
        } else if (entry is fs.File) {
          try {
            RepositoryFile child = createFile(entry);
            assert(child != null);
            if (child is RepositoryLicensedFile) {
              _files.add(child);
            } else {
              assert(child is RepositoryLicenseFile);
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

    for (RepositoryDirectory child in virtualSubdirectories) {
      _subdirectories.add(child);
      _childrenByName[child.name] = child;
    }
  }

  // Override this to add additional child directories that do not represent a
  // direct child of this directory's filesystem node.
  List<RepositoryDirectory> get virtualSubdirectories => <RepositoryDirectory>[];

  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != '.cipd' &&
           entry.name != '.git' &&
           entry.name != '.github' &&
           entry.name != '.gitignore' &&
           entry.name != 'test' &&
           entry.name != 'test.disabled' &&
           entry.name != 'test_support' &&
           entry.name != 'tests' &&
           entry.name != 'javatests' &&
           entry.name != 'testing';
  }

  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryGenericThirdPartyDirectory(this, entry);
    return new RepositoryDirectory(this, entry);
  }

  RepositoryFile createFile(fs.IoNode entry) {
    if (entry is fs.TextFile) {
      if (RepositoryApache4DNoticeFile.consider(entry)) {
        return new RepositoryApache4DNoticeFile(this, entry);
      } else {
        RepositoryFile result;
        if (entry.name == 'NOTICE')
          result = RepositoryLicenseRedirectFile.maybeCreateFrom(this, entry);
        if (result != null) {
          return result;
        } else if (entry.name.contains(_licenseNamePattern)) {
          return new RepositoryGeneralSingleLicenseFile(this, entry);
        } else if (entry.name == 'README.ijg') {
          return new RepositoryReadmeIjgFile(this, entry);
        } else {
          return new RepositorySourceFile(this, entry);
        }
      }
    } else if (entry.name == 'NOTICE.txt') {
      return new RepositoryMultiLicenseNoticesForFilesFile(this, entry);
    } else {
      return new RepositoryBinaryFile(this, entry);
    }
  }

  int get count => _files.length + _subdirectories.fold<int>(0, (int count, RepositoryDirectory child) => count + child.count);

  @override
  List<License> nearestLicensesFor(String name) {
    if (_licenses.isEmpty) {
      if (_canGoUp(null))
        return parent.nearestLicensesFor('${io.name}/$name');
      return null;
    }
    if (_licenses.length == 1)
      return _licenses.single.licensesFor(name);
    List<License> licenses = _licenses.expand/*License*/((RepositoryLicenseFile license) sync* {
      List<License> licenses = license.licensesFor(name);
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
      for (RepositoryDirectory directory in _subdirectories) {
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
    License result = _localLicenseWithType(type);
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
      for (RepositoryDirectory directory in _subdirectories) {
        result = directory._fullWalkDownForLicenseWithType(type);
        if (result != null)
          break;
      }
    }
    return result;
  }

  /// Searches the current directory for licenses of the specified type.
  License _localLicenseWithType(LicenseType type) {
    List<License> licenses = _licenses.expand/*License*/((RepositoryLicenseFile license) sync* {
      License result = license.licenseOfType(type);
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
      for (RepositoryDirectory directory in _subdirectories) {
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
    License result = _localLicenseWithName(name, authors: authors);
    if (result != null)
      return result;
    if (_canGoUp(authors))
      return parent._nearestAncestorLicenseWithName(name, authors: authors);
    return null;
  }

  License _fullWalkUpForLicenseWithName(String name, { String authors, bool ignoreCase: false }) {
    return _canGoUp(authors)
            ? parent._fullWalkUpForLicenseWithName(name, authors: authors, ignoreCase: ignoreCase)
            : _fullWalkDownForLicenseWithName(name, authors: authors, ignoreCase: ignoreCase);
  }

  License _fullWalkDownForLicenseWithName(String name, { String authors, bool ignoreCase: false }) {
    License result = _localLicenseWithName(name, authors: authors, ignoreCase: ignoreCase);
    if (result == null) {
      for (RepositoryDirectory directory in _subdirectories) {
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

  License _localLicenseWithName(String name, { String authors, bool ignoreCase: false }) {
    Map<String, RepositoryEntry> map;
    if (ignoreCase) {
      // we get here if we're trying a last-ditch effort at finding a file.
      // so this should happen only rarely.
      map = new HashMap<String, RepositoryEntry>(
        equals: (String n1, String n2) => n1.toLowerCase() == n2.toLowerCase(),
        hashCode: (String n) => n.toLowerCase().hashCode
      )
        ..addAll(_childrenByName);
    } else {
      map = _childrenByName;
    }
    final RepositoryEntry entry = map[name];
    License license;
    if (entry is RepositoryLicensedFile) {
      license = entry.licenses.single;
    } else if (entry is RepositoryLicenseFile) {
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

  RepositoryEntry getChildByName(String name) {
    return _childrenByName[name];
  }

  Set<License> getLicenses(Progress progress) {
    Set<License> result = new Set<License>();
    for (RepositoryDirectory directory in _subdirectories)
      result.addAll(directory.getLicenses(progress));
    for (RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts) {
        try {
          progress.label = '$file';
          List<License> licenses = file.licenses;
          assert(licenses != null && licenses.isNotEmpty);
          result.addAll(licenses);
          progress.advance(true);
        } catch (e, stack) {
          system.stderr.writeln('error searching for copyright in: ${file.io}\n$e');
          if (e is! String)
            system.stderr.writeln(stack);
          system.stderr.writeln('\n');
          progress.advance(false);
        }
      }
    }
    for (RepositoryLicenseFile file in _licenses)
      result.addAll(file.licenses);
    return result;
  }

  int get fileCount {
    int result = 0;
    for (RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts)
        result += 1;
    }
    for (RepositoryDirectory directory in _subdirectories)
      result += directory.fileCount;
    return result;
  }

  Iterable<RepositoryLicensedFile> get _signatureFiles sync* {
    for (RepositoryLicensedFile file in _files) {
      if (file.isIncludedInBuildProducts)
        yield file;
    }
    for (RepositoryDirectory directory in _subdirectories) {
      if (directory.includeInSignature)
        yield* directory._signatureFiles;
    }
  }

  Stream<List<int>> _signatureStream(List<RepositoryLicensedFile> files) async* {
    for (RepositoryLicensedFile file in files) {
      yield file.io.fullName.codeUnits;
      yield file.io.readBytes();
    }
  }

  /// Compute a signature representing a hash of all the licensed files within
  /// this directory tree.
  Future<String> get signature async {
    List<RepositoryLicensedFile> allFiles = _signatureFiles.toList();
    allFiles.sort((RepositoryLicensedFile a, RepositoryLicensedFile b) =>
        a.io.fullName.compareTo(b.io.fullName));
    crypto.Digest digest = await crypto.md5.bind(_signatureStream(allFiles)).single;
    return digest.bytes.map((int e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// True if this directory's contents should be included when computing the signature.
  bool get includeInSignature => true;
}

class RepositoryGenericThirdPartyDirectory extends RepositoryDirectory {
  RepositoryGenericThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;
}

class RepositoryReachOutFile extends RepositoryLicensedFile {
  RepositoryReachOutFile(RepositoryDirectory parent, fs.File io, this.offset) : super(parent, io);

  @override
  fs.File get io => super.io;

  final int offset;

  @override
  List<License> get licenses {
    RepositoryDirectory directory = parent;
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

class RepositoryReachOutDirectory extends RepositoryDirectory {
  RepositoryReachOutDirectory(RepositoryDirectory parent, fs.Directory io, this.reachOutFilenames, this.offset) : super(parent, io);

  final Set<String> reachOutFilenames;
  final int offset;

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (reachOutFilenames.contains(entry.name))
      return new RepositoryReachOutFile(this, entry, offset);
    return super.createFile(entry);
  }
}

class RepositoryExcludeSubpathDirectory extends RepositoryDirectory {
  RepositoryExcludeSubpathDirectory(RepositoryDirectory parent, fs.Directory io, this.paths, [ this.index = 0 ]) : super(parent, io);

  final List<String> paths;
  final int index;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    if (index == paths.length - 1 && entry.name == paths.last)
      return false;
    return super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == paths[index] && (index < paths.length - 1))
      return new RepositoryExcludeSubpathDirectory(this, entry, paths, index + 1);
    return super.createSubdirectory(entry);
  }
}


// WHAT TO CRAWL AND WHAT NOT TO CRAWL

class RepositoryAndroidSdkPlatformsWithJarDirectory extends RepositoryDirectory {
  RepositoryAndroidSdkPlatformsWithJarDirectory(RepositoryDirectory parent, fs.Directory io)
    : _jarLicense = <License>[new License.fromUrl('http://www.apache.org/licenses/LICENSE-2.0', origin: 'implicit android.jar license')],
      super(parent, io);

  final List<License> _jarLicense;

  @override
  List<License> nearestLicensesFor(String name) => _jarLicense;

  @override
  License nearestLicenseOfType(LicenseType type) {
    if (_jarLicense.single.type == type)
      return _jarLicense.single;
    return null;
  }

  @override
  License nearestLicenseWithName(String name, { String authors }) {
    return null;
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // we only use android.jar from the SDK, everything else we ignore
    return entry.name == 'android.jar';
  }
}

class RepositoryAndroidSdkPlatformsDirectory extends RepositoryDirectory {
  RepositoryAndroidSdkPlatformsDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'android-22') // chinmay says we only use 22 for the SDK
      return new RepositoryAndroidSdkPlatformsWithJarDirectory(this, entry);
    throw 'unknown Android SDK version: ${entry.name}';
  }
}

class RepositoryAndroidSdkDirectory extends RepositoryDirectory {
  RepositoryAndroidSdkDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // We don't link with any of the Android SDK tools, Google-specific
    // packages, system images, samples, etc, when building the engine. We do
    // use some (especially those in build-tools/), but it is our understanding
    // that nothing from those files actually ends up in our final build output,
    // and therefore we don't worry about their licenses.
    return entry.name != 'add-ons'
        && entry.name != 'build-tools'
        && entry.name != 'extras'
        && entry.name != 'platform-tools'
        && entry.name != 'samples'
        && entry.name != 'system-images'
        && entry.name != 'tools'
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'platforms')
      return new RepositoryAndroidSdkPlatformsDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryAndroidNdkPlatformsDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkPlatformsDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    if (entry.name == 'android-9' ||
        entry.name == 'android-12' ||
        entry.name == 'android-13' ||
        entry.name == 'android-14' ||
        entry.name == 'android-15' ||
        entry.name == 'android-17' ||
        entry.name == 'android-18' ||
        entry.name == 'android-19' ||
        entry.name == 'android-21' ||
        entry.name == 'android-23' ||
        entry.name == 'android-24')
      return false;
    if (entry.name == 'android-16' || // chinmay says we use this for armv7
        entry.name == 'android-22') // chinmay says we use this for everything else
      return true;
    throw 'unknown Android NDK version: ${entry.name}';
  }
}

class RepositoryAndroidNdkSourcesAndroidSupportDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesAndroidSupportDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'NOTICE' && entry is fs.TextFile) {
      return new RepositoryGeneralSingleLicenseFile.fromLicense(
        this,
        entry,
        new License.unique(
          entry.readString(),
          LicenseType.unknown,
          origin: entry.fullName,
          yesWeKnowWhatItLooksLikeButItIsNot: true, // lawyer said to include this file verbatim
        )
      );
    }
    return super.createFile(entry);
  }

}

class RepositoryAndroidNdkSourcesAndroidDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesAndroidDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'libthread_db' // README in that directory says we aren't using this
        && entry.name != 'crazy_linker' // build-time only (not that we use it anyway)
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'support')
      return new RepositoryAndroidNdkSourcesAndroidSupportDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryAndroidNdkSourcesCxxStlSubsubdirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesCxxStlSubsubdirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.TXT')
      return new RepositoryCxxStlDualLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class RepositoryAndroidNdkSourcesCxxStlSubdirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesCxxStlSubdirectory(RepositoryDirectory parent, fs.Directory io, this.subdirectoryName) : super(parent, io);

  final String subdirectoryName;

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == subdirectoryName)
      return new RepositoryAndroidNdkSourcesCxxStlSubsubdirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryAndroidNdkSourcesCxxStlDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesCxxStlDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'gabi++' // abarth says jamesr says we don't use these two
        && entry.name != 'stlport'
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'llvm-libc++abi')
      return new RepositoryAndroidNdkSourcesCxxStlSubdirectory(this, entry, 'libcxxabi');
    if (entry.name == 'llvm-libc++')
      return new RepositoryAndroidNdkSourcesCxxStlSubdirectory(this, entry, 'libcxx');
    return super.createSubdirectory(entry);
  }
}

class RepositoryAndroidNdkSourcesThirdPartyDirectory extends RepositoryGenericThirdPartyDirectory {
  RepositoryAndroidNdkSourcesThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    if (entry.name == 'googletest')
      return false; // testing infrastructure, not shipped with flutter engine
    if (entry.name == 'shaderc')
      return false; // abarth says we don't use any shader stuff
    if (entry.name == 'vulkan')
      return false; // abath says we do use vulkan so might use this
    throw 'unexpected Android NDK third-party package: ${entry.name}';
  }
}

class RepositoryAndroidNdkSourcesDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkSourcesDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'android')
      return new RepositoryAndroidNdkSourcesAndroidDirectory(this, entry);
    if (entry.name == 'cxx-stl')
      return new RepositoryAndroidNdkSourcesCxxStlDirectory(this, entry);
    if (entry.name == 'third_party')
      return new RepositoryAndroidNdkSourcesThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}


class RepositoryAndroidNdkDirectory extends RepositoryDirectory {
  RepositoryAndroidNdkDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // we don't link with or use any of the Android NDK samples
    return entry.name != 'build'
        && entry.name != 'docs'
        && entry.name != 'prebuilt' // only used by engine debug builds, which we don't ship
        && entry.name != 'samples'
        && entry.name != 'tests'
        && entry.name != 'toolchains' // only used at build time, doesn't seem to contain anything that gets shipped with the build output
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'platforms')
      return new RepositoryAndroidNdkPlatformsDirectory(this, entry);
    if (entry.name == 'sources')
      return new RepositoryAndroidNdkSourcesDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryAndroidToolsDirectory extends RepositoryDirectory {
  RepositoryAndroidToolsDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'VERSION_LINUX_SDK'
        && entry.name != 'VERSION_LINUX_NDK'
        && entry.name != 'VERSION_MACOSX_SDK'
        && entry.name != 'VERSION_MACOSX_NDK'
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'sdk')
      return new RepositoryAndroidSdkDirectory(this, entry);
    if (entry.name == 'ndk')
      return new RepositoryAndroidNdkDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  // This directory's contents are different on each host platform.  We assume
  // that the components of the Android SDK that are linked into our releases
  // are consistent among all host platforms.  Given that the host SDK will not
  // affect the signature, be sure to force a regeneration of the third_party
  // golden licenses if the SDK is ever updated.
  @override
  bool get includeInSignature => false;
}

class RepositoryAndroidPlatformDirectory extends RepositoryDirectory {
  RepositoryAndroidPlatformDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // we don't link with or use any of the Android NDK samples
    return entry.name != 'webview' // not used at all
        && entry.name != 'development' // not linked in
        && super.shouldRecurse(entry);
  }
}

class RepositoryExpatDirectory extends RepositoryDirectory {
  RepositoryExpatDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRootException => true;

  @override
  bool get subdirectoriesAreLicenseRoots => true;
}

class RepositoryFreetypeDocsDirectory extends RepositoryDirectory {
  RepositoryFreetypeDocsDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.TXT')
      return new RepositoryFreetypeLicenseFile(this, entry);
    return super.createFile(entry);
  }

  @override
  int get fileCount => 0;

  @override
  Set<License> getLicenses(Progress progress) {
    // We don't ship anything in this directory so don't bother looking for licenses there.
    // However, there are licenses in this directory referenced from elsewhere, so we do
    // want to crawl it and expose them.
    return new Set<License>();
  }
}

class RepositoryFreetypeSrcGZipDirectory extends RepositoryDirectory {
  RepositoryFreetypeSrcGZipDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  // advice was to make this directory's inffixed.h file (which has no license)
  // use the license in zlib.h.

  @override
  List<License> nearestLicensesFor(String name) {
    License zlib = nearestLicenseWithName('zlib.h');
    assert(zlib != null);
    if (zlib != null)
      return <License>[zlib];
    return super.nearestLicensesFor(name);
  }

  @override
  License nearestLicenseOfType(LicenseType type) {
    if (type == LicenseType.zlib) {
      License result = nearestLicenseWithName('zlib.h');
      assert(result != null);
      return result;
    }
    return null;
  }
}

class RepositoryFreetypeSrcDirectory extends RepositoryDirectory {
  RepositoryFreetypeSrcDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'gzip')
      return new RepositoryFreetypeSrcGZipDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'tools'
        && super.shouldRecurse(entry);
  }
}

class RepositoryFreetypeDirectory extends RepositoryDirectory {
  RepositoryFreetypeDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  List<License> nearestLicensesFor(String name) {
    List<License> result = super.nearestLicensesFor(name);
    if (result == null) {
      License license = nearestLicenseWithName('LICENSE.TXT');
      assert(license != null);
      if (license != null)
        return <License>[license];
    }
    return result;
  }

  @override
  License nearestLicenseOfType(LicenseType type) {
    if (type == LicenseType.freetype) {
      License result = nearestLicenseWithName('FTL.TXT');
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
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return new RepositoryFreetypeSrcDirectory(this, entry);
    if (entry.name == 'docs')
      return new RepositoryFreetypeDocsDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryIcuDirectory extends RepositoryDirectory {
  RepositoryIcuDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'license.html' // redundant with LICENSE file
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return new RepositoryIcuLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class RepositoryHarfbuzzDirectory extends RepositoryDirectory {
  RepositoryHarfbuzzDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'util' // utils are command line tools that do not end up in the binary
        && super.shouldRecurse(entry);
  }
}

class RepositoryJSR305Directory extends RepositoryDirectory {
  RepositoryJSR305Directory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return new RepositoryJSR305SrcDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryJSR305SrcDirectory extends RepositoryDirectory {
  RepositoryJSR305SrcDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'javadoc'
        && entry.name != 'sampleUses'
        && super.shouldRecurse(entry);
  }
}

class RepositoryLibJpegDirectory extends RepositoryDirectory {
  RepositoryLibJpegDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'README')
      return new RepositoryReadmeIjgFile(this, entry);
    if (entry.name == 'LICENSE')
      return new RepositoryLicenseFileWithLeader(this, entry, new RegExp(r'^\(Copied from the README\.\)\n+-+\n+'));
    return super.createFile(entry);
  }
}

class RepositoryLibJpegTurboDirectory extends RepositoryDirectory {
  RepositoryLibJpegTurboDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE.md')
      return new RepositoryLibJpegTurboLicense(this, entry);
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

class RepositoryLibPngDirectory extends RepositoryDirectory {
  RepositoryLibPngDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE' || entry.name == 'png.h')
      return new RepositoryLibPngLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class RepositoryLibWebpDirectory extends RepositoryDirectory {
  RepositoryLibWebpDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'examples' // contains nothing that ends up in the binary executable
      && entry.name != 'swig' // not included in our build
      && entry.name != 'gradle' // not included in our build
      && super.shouldRecurse(entry);
  }
}

class RepositoryPkgDirectory extends RepositoryDirectory {
  RepositoryPkgDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'when')
      return new RepositoryPkgWhenDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryPkgWhenDirectory extends RepositoryDirectory {
  RepositoryPkgWhenDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'example' // contains nothing that ends up in the binary executable
        && super.shouldRecurse(entry);
  }
}

class RepositorySkiaLibWebPDirectory extends RepositoryDirectory {
  RepositorySkiaLibWebPDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'webp')
      return new RepositoryReachOutDirectory(this, entry, new Set<String>.from(const <String>['config.h']), 3);
    return super.createSubdirectory(entry);
  }
}

class RepositorySkiaLibSdlDirectory extends RepositoryDirectory {
  RepositorySkiaLibSdlDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRootException => true;
}

class RepositorySkiaThirdPartyDirectory extends RepositoryGenericThirdPartyDirectory {
  RepositorySkiaThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'giflib' // contains nothing that ends up in the binary executable
        && entry.name != 'freetype' // we use our own version
        && entry.name != 'freetype2' // we use our own version
        && entry.name != 'icu' // we use our own version
        && entry.name != 'libjpeg-turbo' // we use our own version
        && entry.name != 'libpng' // we use our own version
        && entry.name != 'lua' // not linked in
        && entry.name != 'yasm' // build tool (assembler)
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'ktx')
      return new RepositoryReachOutDirectory(this, entry, new Set<String>.from(const <String>['ktx.h', 'ktx.cpp']), 2);
    if (entry.name == 'libmicrohttpd')
      return new RepositoryReachOutDirectory(this, entry, new Set<String>.from(const <String>['MHD_config.h']), 2);
    if (entry.name == 'libwebp')
      return new RepositorySkiaLibWebPDirectory(this, entry);
    if (entry.name == 'libsdl')
      return new RepositorySkiaLibSdlDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositorySkiaDirectory extends RepositoryDirectory {
  RepositorySkiaDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'platform_tools' // contains nothing that ends up in the binary executable
        && entry.name != 'tools' // contains nothing that ends up in the binary executable
        && entry.name != 'resources' // contains nothing that ends up in the binary executable
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositorySkiaThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryVulkanDirectory extends RepositoryDirectory {
  RepositoryVulkanDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    // Flutter only uses the headers in the include directory.
    return entry.name == 'include'
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return new RepositoryExcludeSubpathDirectory(this, entry, const <String>['spec']);
    return super.createSubdirectory(entry);
  }
}

class RepositoryRootThirdPartyDirectory extends RepositoryGenericThirdPartyDirectory {
  RepositoryRootThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

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
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'android_platform')
      return new RepositoryAndroidPlatformDirectory(this, entry);
    if (entry.name == 'boringssl')
      return new RepositoryBoringSSLDirectory(this, entry);
    if (entry.name == 'catapult')
      return new RepositoryCatapultDirectory(this, entry);
    if (entry.name == 'dart')
      return new RepositoryDartDirectory(this, entry);
    if (entry.name == 'expat')
      return new RepositoryExpatDirectory(this, entry);
    if (entry.name == 'freetype-android')
      throw '//third_party/freetype-android is no longer part of this client: remove it';
    if (entry.name == 'freetype2')
      return new RepositoryFreetypeDirectory(this, entry);
    if (entry.name == 'harfbuzz')
      return new RepositoryHarfbuzzDirectory(this, entry);
    if (entry.name == 'icu')
      return new RepositoryIcuDirectory(this, entry);
    if (entry.name == 'jsr-305')
      return new RepositoryJSR305Directory(this, entry);
    if (entry.name == 'libjpeg')
      return new RepositoryLibJpegDirectory(this, entry);
    if (entry.name == 'libjpeg_turbo' || entry.name == 'libjpeg-turbo')
      return new RepositoryLibJpegTurboDirectory(this, entry);
    if (entry.name == 'libpng')
      return new RepositoryLibPngDirectory(this, entry);
    if (entry.name == 'libwebp')
      return new RepositoryLibWebpDirectory(this, entry);
    if (entry.name == 'pkg')
      return new RepositoryPkgDirectory(this, entry);
    if (entry.name == 'vulkan')
      return new RepositoryVulkanDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryBoringSSLThirdPartyDirectory extends RepositoryDirectory {
  RepositoryBoringSSLThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'android-cmake' // build-time only
        && super.shouldRecurse(entry);
  }
}

class RepositoryBoringSSLSourceDirectory extends RepositoryDirectory {
  RepositoryBoringSSLSourceDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

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
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return new RepositoryOpenSSLLicenseFile(this, entry);
    return super.createFile(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryBoringSSLThirdPartyDirectory(this, entry);
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
class RepositoryOpenSSLLicenseFile extends RepositorySingleLicenseFile {
  RepositoryOpenSSLLicenseFile(RepositoryDirectory parent, fs.TextFile io)
    : super(parent, io,
        new License.fromBodyAndType(
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

class RepositoryBoringSSLDirectory extends RepositoryDirectory {
  RepositoryBoringSSLDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'README')
      return new RepositoryBlankLicenseFile(this, entry, 'This repository contains the files generated by boringssl for its build.');
    return super.createFile(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'src')
      return new RepositoryBoringSSLSourceDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryCatapultThirdPartyApiClientDirectory extends RepositoryDirectory {
  RepositoryCatapultThirdPartyApiClientDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return new RepositoryCatapultApiClientLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class RepositoryCatapultThirdPartyCoverageDirectory extends RepositoryDirectory {
  RepositoryCatapultThirdPartyCoverageDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'NOTICE.txt')
      return new RepositoryCatapultCoverageLicenseFile(this, entry);
    return super.createFile(entry);
  }
}

class RepositoryCatapultThirdPartyDirectory extends RepositoryDirectory {
  RepositoryCatapultThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'apiclient')
      return new RepositoryCatapultThirdPartyApiClientDirectory(this, entry);
    if (entry.name == 'coverage')
      return new RepositoryCatapultThirdPartyCoverageDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryCatapultDirectory extends RepositoryDirectory {
  RepositoryCatapultDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryCatapultThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryDartRuntimeThirdPartyDirectory extends RepositoryGenericThirdPartyDirectory {
  RepositoryDartRuntimeThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'd3' // Siva says "that is the charting library used by the binary size tool"
        && entry.name != 'binary_size' // not linked in either
        && super.shouldRecurse(entry);
  }
}

class RepositoryDartThirdPartyDirectory extends RepositoryGenericThirdPartyDirectory {
  RepositoryDartThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

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
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'boringssl')
      return new RepositoryBoringSSLDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryDartRuntimeDirectory extends RepositoryDirectory {
  RepositoryDartRuntimeDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryDartRuntimeThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryDartDirectory extends RepositoryDirectory {
  RepositoryDartDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get isLicenseRoot => true;

  @override
  RepositoryFile createFile(fs.IoNode entry) {
    if (entry.name == 'LICENSE')
      return new RepositoryDartLicenseFile(this, entry);
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
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryDartThirdPartyDirectory(this, entry);
    if (entry.name == 'runtime')
      return new RepositoryDartRuntimeDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryFlutterDirectory extends RepositoryDirectory {
  RepositoryFlutterDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

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
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'sky')
      return new RepositoryExcludeSubpathDirectory(this, entry, const <String>['packages', 'sky_engine', 'LICENSE']); // that's the output of this script!
    if (entry.name == 'third_party')
      return new RepositoryFlutterThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryFlutterThirdPartyDirectory extends RepositoryDirectory {
  RepositoryFlutterThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool get subdirectoriesAreLicenseRoots => true;

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'txt')
      return new RepositoryFlutterTxtDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryFlutterTxtDirectory extends RepositoryDirectory {
  RepositoryFlutterTxtDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'third_party')
      return new RepositoryFlutterTxtThirdPartyDirectory(this, entry);
    return super.createSubdirectory(entry);
  }
}

class RepositoryFlutterTxtThirdPartyDirectory extends RepositoryDirectory {
  RepositoryFlutterTxtThirdPartyDirectory(RepositoryDirectory parent, fs.Directory io) : super(parent, io);

  @override
  bool shouldRecurse(fs.IoNode entry) {
    return entry.name != 'fonts';
  }
}

class RepositoryRoot extends RepositoryDirectory {
  RepositoryRoot(fs.Directory io) : super(null, io);

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
        && entry.name != 'ios_tools' // only used by build
        && entry.name != 'tools' // not distributed in binary
        && entry.name != 'out' // output of build
        && super.shouldRecurse(entry);
  }

  @override
  RepositoryDirectory createSubdirectory(fs.Directory entry) {
    if (entry.name == 'base')
      throw '//base is no longer part of this client: remove it';
    if (entry.name == 'third_party')
      return new RepositoryRootThirdPartyDirectory(this, entry);
    if (entry.name == 'flutter')
      return new RepositoryFlutterDirectory(this, entry);
    return super.createSubdirectory(entry);
  }

  @override
  List<RepositoryDirectory> get virtualSubdirectories {
    // Skia is updated more frequently than other third party libraries and
    // is therefore represented as a separate top-level component.
    fs.Directory thirdPartyNode = io.walk.firstWhere((fs.IoNode node) => node.name == 'third_party');
    fs.IoNode skiaNode = thirdPartyNode.walk.firstWhere((fs.IoNode node) => node.name == 'skia');
    return <RepositoryDirectory>[new RepositorySkiaDirectory(this, skiaNode)];
  }
}


class Progress {
  Progress(this.max) {
    // This may happen when a git client contains left-over empty component
    // directories after DEPS file changes.
    if (max <= 0)
      throw new ArgumentError('Progress.max must be > 0 but was: $max');
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
  void advance(bool success) {
    if (success)
      _withLicense += 1;
    else
      _withoutLicense += 1;
    update();
  }
  Stopwatch _lastUpdate;
  void update({bool flush = false}) {
    if (_lastUpdate == null || _lastUpdate.elapsedMilliseconds > 90 || flush) {
      _lastUpdate ??= new Stopwatch();
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
    int percent = (100.0 * (_withLicense + _withoutLicense) / max).round();
    return '${(_withLicense + _withoutLicense).toString().padLeft(10)} of $max ${'█' * (percent ~/ 10)}${'░' * (10 - (percent ~/ 10))} $percent% ($_withoutLicense missing licenses)  $label';
  }
}


// MAIN

Future<Null> main(List<String> arguments) async {
  final ArgParser parser = new ArgParser()
    ..addOption('src', help: 'The root of the engine source')
    ..addOption('out', help: 'The directory where output is written')
    ..addOption('golden', help: 'The directory containing golden results')
    ..addFlag('release', help: 'Print output in the format used for product releases');

  ArgResults argResults = parser.parse(arguments);
  bool releaseMode = argResults['release'];
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
    system.Directory out = new system.Directory(argResults['out']);
    if (!out.existsSync())
      out.createSync(recursive: true);
  }

  try {
    system.stderr.writeln('Finding files...');
    fs.FileSystemDirectory rootDirectory = new fs.FileSystemDirectory.fromPath(argResults['src']);
    final RepositoryDirectory root = new RepositoryRoot(rootDirectory);

    if (releaseMode) {
      system.stderr.writeln('Collecting licenses...');
      Progress progress = new Progress(root.fileCount);
      List<License> licenses = new Set<License>.from(root.getLicenses(progress).toList()).toList();
      if (progress.hadErrors)
        throw 'Had failures while collecting licenses.';
      progress.label = 'Dumping results...';
      progress.flush();
      List<String> output = licenses
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
      RegExp signaturePattern = new RegExp(r'Signature: (\w+)');

      final List<String> usedGoldens = <String>[];
      bool isFirstComponent = true;
      for (RepositoryDirectory component in root.subdirectories) {
        system.stderr.writeln('Collecting licenses for ${component.io.name}');

        String signature;
        if (component.io.name == 'flutter') {
          // Always run the full license check on the flutter tree.  This tree is
          // relatively small but changes frequently in ways that do not affect
          // the license output, and we don't want to require updates to the golden
          // signature for those changes.
          signature = null;
        } else {
          signature = await component.signature;
        }

        // Check whether the golden file matches the signature of the current contents
        // of this directory.
        try {
          final String goldenFileName = 'licenses_${component.io.name}';
          system.File goldenFile = new system.File(path.join(argResults['golden'], goldenFileName));
          String goldenSignature = await goldenFile.openRead()
              .transform(utf8.decoder).transform(new LineSplitter()).first;
          usedGoldens.add(goldenFileName);
          Match goldenMatch = signaturePattern.matchAsPrefix(goldenSignature);
          if (goldenMatch != null && goldenMatch.group(1) == signature) {
            system.stderr.writeln('    Skipping this component - no change in signature');
            continue;
          }
        } on system.FileSystemException {
            system.stderr.writeln('    Failed to read signature file, scanning directory.');
        }

        Progress progress = new Progress(component.fileCount);

        system.File outFile = new system.File(
            path.join(argResults['out'], 'licenses_${component.name}'));
        system.IOSink sink = outFile.openWrite();
        if (signature != null)
          sink.writeln('Signature: $signature\n');

        RepositoryDirectory componentRoot;
        if (isFirstComponent) {
          // For the first component, we can use the results of the initial
          // repository crawl.
          isFirstComponent = false;
          componentRoot = component;
        } else {
          // For other components, we need a clean repository that does not
          // contain any state left over from previous components.
          clearLicenseRegistry();
          componentRoot = new RepositoryRoot(rootDirectory).subdirectories.firstWhere(
            (RepositoryDirectory dir) => dir.name == component.name
          );
        }
        List<License> licenses = new Set<License>.from(
            componentRoot.getLicenses(progress).toList()).toList();

        sink.writeln('UNUSED LICENSES:\n');
        List<String> unusedLicenses = licenses
          .where((License license) => !license.isUsed)
          .map((License license) => license.toString())
          .toList();
        unusedLicenses.sort();
        sink.writeln(unusedLicenses.join('\n\n'));
        sink.writeln('~' * 80);

        sink.writeln('USED LICENSES:\n');
        List<License> usedLicenses = licenses.where((License license) => license.isUsed).toList();
        List<String> output = usedLicenses.map((License license) => license.toString()).toList();
        output.sort();
        sink.writeln(output.join('\n\n'));
        sink.writeln('Total license count: ${licenses.length}');

        await sink.close();
        progress.label = 'Done.';
        progress.flush();
        system.stderr.writeln('');
      }

      final Set<String> unusedGoldens = system.Directory(argResults['golden']).listSync().map((system.FileSystemEntity file) => path.basename(file.path)).toSet()
        ..removeAll(usedGoldens);
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

// Sanity checks:
//
// The following substrings shouldn't be in the output:
//   Version: MPL 1.1/GPL 2.0/LGPL 2.1
//   The contents of this file are subject to the Mozilla Public License Version
//   You should have received a copy of the GNU
//   BoringSSL is a fork of OpenSSL
//   Contents of this folder are ported from
//   https://github.com/w3c/web-platform-tests/tree/master/selectors-api
//   It is based on commit
//   The original code is covered by the dual-licensing approach described in:
//   http://www.w3.org/Consortium/Legal/2008/04-testsuite-copyright.html
//   must choose
