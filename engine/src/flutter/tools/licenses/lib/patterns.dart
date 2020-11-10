// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// COMMON PATTERNS

const String kIndent = r'^((?:[-;@#<!.\\"/* ]*(?:REM[-;@#<!.\\"/* ]*)?[-;@#<!.\"/*]+)?)( *)';

final RegExp stripDecorations = RegExp(
  r'^((?:(?:[-;@#<!.\\"/* ]*(?:REM[-;@#<!.\\"/* ]*)?[-;@#<!.\"/*]+)?)(?:(?: |\t)*))(.*?)[ */]*$',
  multiLine: true,
  caseSensitive: false
);

final RegExp newlinePattern = RegExp(r'\r\n?');

final RegExp beginLicenseBlock = RegExp(
  r'^([#;/* ]*) (?:\*\*\*\*\* BEGIN LICENSE BLOCK \*\*\*\*\*[ */]*'
                r'|@APPLE_LICENSE_HEADER_START@)$'
);

final RegExp endLicenseBlock = RegExp(
  r'^([#;/* ]*) (?:\*\*\*\*\* END LICENSE BLOCK \*\*\*\*\*[ */]*'
                r'|@APPLE_LICENSE_HEADER_END@)$'
);

final RegExp nonSpace = RegExp('[^ ]');
final RegExp trailingComma = RegExp(r',[ */]*$');
final RegExp trailingColon = RegExp(r':(?: |\*|/|\n|=|-)*$');
final RegExp copyrightMentionPattern = RegExp(r'©| \(c\) (?!{)|copy\s*right\b|copy\s*left', caseSensitive: false);
final RegExp licenseMentionPattern = RegExp(r'license|warrant[iy]', caseSensitive: false);
final RegExp copyrightMentionOkPattern = RegExp(
  // if a (multiline) block matches this, we ignore it even if it matches copyrightMentionPattern/licenseMentionPattern
  r'(?:These are covered by the following copyright:'
     r'|^((?:[-;#<!.\\"/* ]*(?:REM[-;#<!.\\"/* ]*)?[-;#<!.\"/*]+)?)((?: |\t)*)COPYRIGHT: *\r?\n'
     r'|copyright.*\\n"' // clearly part of a string
     r'|\$YEAR' // clearly part of a template string
     r'|LICENSE BLOCK' // MPL license block header/footer
     r'|2117.+COPYRIGHT' // probably U+2117 mention...
     r'|// The copyright below was added in 2009, but I see no record'
     r'|This ICU code derived from:'
     r'|the contents of which are also included in zip.h' // seen in minizip's unzip.c, but the upshot of the crazy license situation there is that we don't have to do anything
     r'|hold font names, copyright info, notices, etc' // seen in a comment in freetype's src/include/ftsnames.h
     r'|' // the following is from android_tools/ndk/sources/cxx-stl/gnu-libstdc++/4.9/include/ext/pb_ds/detail/splay_tree_/splay_tree_.hpp
     r'^ \* This implementation uses an idea from the SGI STL \(using a @a header node\n'
     r'^ \*    which is needed for efficient iteration\)\. Following is the SGI STL\n'
     r'^ \*    copyright\.\n'
  r')',
  caseSensitive: false, multiLine: true);
final RegExp halfCopyrightPattern = RegExp(r'^(?:Copyright(?: \(c\))? [-0-9, ]+(?: by)?|Written [0-9]+)[ */]*$', caseSensitive: false);
final RegExp authorPattern = RegExp(r'Copyright .+(The .+ Authors)\. +All rights reserved\.', caseSensitive: false);

// copyright blocks start with the first line matching this
final List<RegExp> copyrightStatementLeadingPatterns = <RegExp>[
  RegExp(r'^ *(?:Portions(?: are)? )?Copyright .+$', caseSensitive: false),
  RegExp(r'^.*All rights? reserved\.$', caseSensitive: false),
  RegExp(r'^ *\(C\) .+$', caseSensitive: false),
  RegExp(r'^:copyright: .+$', caseSensitive: false),
  RegExp(r'[-_a-zA-Z0-9()]+ function provided freely by .+'),
  RegExp(r'^.+ optimized code \(C\) COPYRIGHT .+$', caseSensitive: false),
  RegExp(r'©'),

  // TODO(ianh): I wish there was a way around including the next few lines so many times in the output:
  RegExp(r"^This file (?:is|was) part of the Independent JPEG Group's software[:.]$"),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code$'),
  RegExp(r'^relevant to libjpeg-turbo\.$'),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code relevant$'),
  RegExp(r'^to libjpeg-turbo\.$'),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code and$'),
  RegExp(r'^information relevant to libjpeg-turbo\.$'),
];

// copyright blocks end with the last line that matches this, rest is considered license
final List<RegExp> copyrightStatementPatterns = <RegExp>[
  RegExp(r'^ *(?:Portions(?: created by the Initial Developer)?(?: are)? )?Copyright .+$', caseSensitive: false),
  RegExp(r'^\(Version [-0-9.:, ]+ Copyright .+\)$', caseSensitive: false),
  RegExp(r'^.*(?:All )?rights? reserved\.$', caseSensitive: false),
  RegExp(r'^ *\(C\) .+$', caseSensitive: false),
  RegExp(r'^:copyright: .+$', caseSensitive: false),
  RegExp(r'^ *[0-9][0-9][0-9][0-9].+ [<(].+@.+[)>]$'),
  RegExp(r'^                   [^ ].* [<(].+@.+[)>]$'), // that's exactly the number of spaces to line up with the X if "Copyright (c) 2011 X" is on the previous line
  RegExp(r'^ *and .+$', caseSensitive: false),
  RegExp(r'^ *others\.?$', caseSensitive: false),
  RegExp(r'^for more details\.$', caseSensitive: false),
  RegExp(r'^ *For more info read ([^ ]+)$', caseSensitive: false),
  RegExp(r'^(?:Google )?Author\(?s?\)?: .+', caseSensitive: false),
  RegExp(r'^Written by .+', caseSensitive: false),
  RegExp(r'^Based on$', caseSensitive: false),
  RegExp(r"^based on (?:code in )?['`][^'`]+['`]$", caseSensitive: false),
  RegExp(r'^Based on .+, written by .+, [0-9]+\.$', caseSensitive: false),
  RegExp(r'^(?:Based on the )?x86 SIMD extension for IJG JPEG library(?: - version [0-9.]+|,)?$'),
  RegExp(r'^This software originally derived from .+\.$'),
  RegExp(r'^Derived from .+, which was$'),
  RegExp(r'^ *This is part of .+, a .+ library\.$'),
  RegExp(r'^This file is part of [^ ]+\.$'),
  RegExp(r'^(?:Modification )?[Dd]eveloped [-0-9]+ by .+\.$', caseSensitive: false),
  RegExp(r'^Modified .+[:.]$', caseSensitive: false),
  RegExp(r'^(?:[^ ]+ )?Modifications:$', caseSensitive: false),
  RegExp(r'^ *Modifications for', caseSensitive: false),
  RegExp(r'^ *Modifications of', caseSensitive: false),
  RegExp(r'^Last changed in .+$', caseSensitive: false),
  RegExp(r'[-_a-zA-Z0-9()]+ function provided freely by .+'), // TODO(ianh): file a bug on analyzer about what happens if you omit this comma
  RegExp(r'^.+ optimized code \(C\) COPYRIGHT .+$', caseSensitive: false),
  RegExp(r'^\(Royal Institute of Technology, Stockholm, Sweden\)\.$'),
  RegExp(r'^\(?https?://[^ ]+$\)?'),

  RegExp(r'^The Original Code is Mozilla Communicator client code, released$'),
  RegExp(r'^March 31, 1998.$'), // mozilla first release date

  RegExp(r'^The Elliptic Curve Public-Key Crypto Library \(ECC Code\) included$'),
  RegExp(r'^herein is developed by SUN MICROSYSTEMS, INC\., and is contributed$'),
  RegExp(r'^to the OpenSSL project\.$'),

  RegExp(r'^This code is derived from software contributed to The NetBSD Foundation$'),
  RegExp(r'^by (?:Atsushi Onoe|Dieter Baron|Klaus Klein|Luke Mewburn|Thomas Klausner|,| |and)*\.$'),

  RegExp(r'^FT_Raccess_Get_HeaderInfo\(\) and raccess_guess_darwin_hfsplus\(\) are$'),
  RegExp(r'^derived from ftobjs\.c\.$'),

  // TODO(ianh): I wish there was a way around including the next few lines so many times in the output:
  RegExp(r"^This file (?:is|was) part of the Independent JPEG Group's software[:.]$"),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code$'),
  RegExp(r'^relevant to libjpeg-turbo\.$'),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code relevant$'),
  RegExp(r'^to libjpeg-turbo\.$'),
  RegExp(r'^It was modified by The libjpeg-turbo Project to include only code and$'),
  RegExp(r'^information relevant to libjpeg-turbo\.$'),

  RegExp(r'^All or some portions of this file are derived from material licensed$'),
  RegExp(r'^to the University of California by American Telephone and Telegraph$'),
  RegExp(r'^Co\. or Unix System Laboratories, Inc\. and are reproduced herein with$'),
  RegExp(r'^the permission of UNIX System Laboratories, Inc.$'),

  RegExp(r'^This software was developed by the Computer Systems Engineering group$'),
  RegExp(r'^at Lawrence Berkeley Laboratory under DARPA contract BG 91-66 and$'),
  RegExp(r'^contributed to Berkeley\.$'),

  RegExp(r'^This code is derived from software contributed to Berkeley by$'),
  RegExp(r'^Ralph Campbell\. +This file is derived from the MIPS RISC$'),
  RegExp(r'^Architecture book by Gerry Kane\.$'),

  RegExp(r'^All advertising materials mentioning features or use of this software$'),
  RegExp(r'^must display the following acknowledgement:$'),
  RegExp(r'^This product includes software developed by the University of$'),
  RegExp(r'^California, Lawrence Berkeley Laboratory\.$'),

  RegExp(r'^ *Condition of use and distribution are the same than zlib :$'),
  RegExp(r'^The MIT License:$'),

  RegExp(r'^$'), // TODO(ianh): file an issue on what happens if you omit the close quote

];

// patterns that indicate we're running into another license
final List<RegExp> licenseFragments = <RegExp>[
  RegExp(r'"as is" without express or implied warranty\.'),
  RegExp(r'version of this file under any of the LGPL, the MPL or the GPL\.'),
  RegExp(r'SUCH DAMAGE\.'),
  RegExp(r'found in the LICENSE file'),
  RegExp(r'<http://www\.gnu\.org/licenses/>'),
  RegExp(r'License & terms of use'),
];

const String _linebreak      = r' *(?:(?:\*/ *|[*#])?(?:\r?\n\1 *(?:\*/ *)?)*\r?\n\1\2 *)?';
const String _linebreakLoose = r' *(?:(?:\*/ *|[*#])?\r?\n(?:-|;|#|<|!|/|\*| |REM)*)*';

// LICENSE RECOGNIZERS

final RegExp lrApache = RegExp(r'^(?: |\r|\n)*Apache License\b');
final RegExp lrMPL = RegExp(r'^(?: |\r|\n)*Mozilla Public License Version 2\.0\n');
final RegExp lrGPL = RegExp(r'^(?: |\r|\n)*GNU GENERAL PUBLIC LICENSE\n');
final RegExp lrAPSL = RegExp(r'^APPLE PUBLIC SOURCE LICENSE Version 2\.0 +- +August 6, 2003');
final RegExp lrMIT = RegExp(r'Permission(?: |\n)+is(?: |\n)+hereby(?: |\n)+granted,(?: |\n)+free(?: |\n)+of(?: |\n)+charge,(?: |\n)+to(?: |\n)+any(?: |\n)+person(?: |\n)+obtaining(?: |\n)+a(?: |\n)+copy(?: |\n)+of(?: |\n)+this(?: |\n)+software(?: |\n)+and(?: |\n)+associated(?: |\n)+documentation(?: |\n)+files(?: |\n)+\(the(?: |\n)+"Software"\),(?: |\n)+to(?: |\n)+deal(?: |\n)+in(?: |\n)+the(?: |\n)+Software(?: |\n)+without(?: |\n)+restriction,(?: |\n)+including(?: |\n)+without(?: |\n)+limitation(?: |\n)+the(?: |\n)+rights(?: |\n)+to(?: |\n)+use,(?: |\n)+copy,(?: |\n)+modify,(?: |\n)+merge,(?: |\n)+publish,(?: |\n)+distribute,(?: |\n)+sublicense,(?: |\n)+and/or(?: |\n)+sell(?: |\n)+copies(?: |\n)+of(?: |\n)+the(?: |\n)+Software,(?: |\n)+and(?: |\n)+to(?: |\n)+permit(?: |\n)+persons(?: |\n)+to(?: |\n)+whom(?: |\n)+the(?: |\n)+Software(?: |\n)+is(?: |\n)+furnished(?: |\n)+to(?: |\n)+do(?: |\n)+so,(?: |\n)+subject(?: |\n)+to(?: |\n)+the(?: |\n)+following(?: |\n)+conditions:');
final RegExp lrOpenSSL = RegExp(r'Copyright \(c\) 1998-2011 The OpenSSL Project\.  All rights reserved\.(.|\n)*Original SSLeay License');
final RegExp lrBSD = RegExp(r'Redistribution(?: |\n)+and(?: |\n)+use(?: |\n)+in(?: |\n)+source(?: |\n)+and(?: |\n)+binary(?: |\n)+forms(?:(?: |\n)+of(?: |\n)+the(?: |\n)+software(?: |\n)+as(?: |\n)+well(?: |\n)+as(?: |\n)+documentation)?,(?: |\n)+with(?: |\n)+or(?: |\n)+without(?: |\n)+modification,(?: |\n)+are(?: |\n)+permitted(?: |\n)+provided(?: |\n)+that(?: |\n)+the(?: |\n)+following(?: |\n)+conditions(?: |\n)+are(?: |\n)+met:');
final RegExp lrZlib = RegExp(r'Permission(?: |\n)+is(?: |\n)+granted(?: |\n)+to(?: |\n)+anyone(?: |\n)+to(?: |\n)+use(?: |\n)+this(?: |\n)+software(?: |\n)+for(?: |\n)+any(?: |\n)+purpose,(?: |\n)+including(?: |\n)+commercial(?: |\n)+applications,(?: |\n)+and(?: |\n)+to(?: |\n)+alter(?: |\n)+it(?: |\n)+and(?: |\n)+redistribute(?: |\n)+it(?: |\n)+freely,(?: |\n)+subject(?: |\n)+to(?: |\n)+the(?: |\n)+following(?: |\n)+restrictions:');
final RegExp lrPNG = RegExp(r'This code is released under the libpng license\.');
final RegExp lrBison = RegExp(r'This special exception was added by the Free Software Foundation in *\n *version 2.2 of Bison.');


// "NO COPYRIGHT" STATEMENTS

final List<RegExp> csNoCopyrights = <RegExp>[

  // used with _tryNone
  // groups are ignored

  // Seen in Expat files
  RegExp(
    r'^// No copyright notice; this file based on autogenerated header',
    multiLine: true,
    caseSensitive: false
  ),

  // Seen in Android NDK
  RegExp(
    r'^[/* ]*This header was automatically generated from a Linux kernel header\n'
    r'^[/* ]*of the same name, to make information necessary for userspace to\n'
    r'^[/* ]*call into the kernel available to libc.  It contains only constants,\n'
    r'^[/* ]*structures, and macros generated from the original header, and thus,\n'
    r'^[/* ]*contains no copyrightable information.',
    multiLine: true,
    caseSensitive: false
  ),

  RegExp(
    kIndent +
    r'These constants were taken from version 3 of the DWARF standard, *\n'
    r'^\1\2which is Copyright \(c\) 2005 Free Standards Group, and *\n'
    r'^\1\2Copyright \(c\) 1992, 1993 UNIX International, Inc\. *\n',
    multiLine: true,
    caseSensitive: false
  ),

  // Freetype
  RegExp(
    kIndent +
    (r'This is a dummy file, used to please the build system\. It is never included by the auto-fitter sources\.'.replaceAll(' ', _linebreak)),
    multiLine: true,
    caseSensitive: false
  ),

  // Freetype
  RegExp(
    kIndent +
    (
      r'This software was written by Alexander Peslyak in 2001\. No copyright is '
      r'claimed, and the software is hereby placed in the public domain\. In case '
      r'this attempt to disclaim copyright and place the software in the public '
      r'domain is deemed null and void, then the software is Copyright \(c\) 2001 '
      r'Alexander Peslyak and it is hereby released to the general public under the '
      r'following terms: Redistribution and use in source and binary forms, with or '
      r"without modification, are permitted\. There\'s ABSOLUTELY NO WARRANTY, "
      r'express or implied\.(?: \(This is a heavily cut-down "BSD license"\.\))?'
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false
  ),

];


// ATTRIBUTION STATEMENTS

final List<RegExp> csAttribution = <RegExp>[

  // used with _tryAttribution
  // group 1 is the prefix, group 2 is the attribution

  // Seen in musl in Android SDK
  RegExp(
    r'^([/* ]*)This code was written by (.+) in [0-9]+; no copyright is claimed\.\n'
    r'^\1This code is in the public domain\. +Attribution is appreciated but\n'
    r'^\1unnecessary\.',
    multiLine: true,
    caseSensitive: false
  ),

];


// REFERENCES TO OTHER FILES

class LicenseFileReferencePattern {
  LicenseFileReferencePattern({
    this.firstPrefixIndex,
    this.indentPrefixIndex,
    this.copyrightIndex,
    this.authorIndex,
    this.fileIndex,
    this.pattern,
    this.needsCopyright = true
  });
  final int firstPrefixIndex;
  final int indentPrefixIndex;
  final int copyrightIndex;
  final int authorIndex;
  final int fileIndex;
  final bool needsCopyright;
  final RegExp pattern;
}

final List<LicenseFileReferencePattern> csReferencesByFilename = <LicenseFileReferencePattern>[

  // used with _tryReferenceByFilename

  // libpng files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    needsCopyright: true,
    pattern: RegExp(
      kIndent +
      r'This code is released under the libpng license. For conditions of distribution and use, see the disclaimer and license in (png.h)\b'.replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false
    ),
  ),

  // typical of much Google-written code
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent +
      r'Use of this source(?: code)? is governed by a BS?D-style license that can be found in the '.replaceAll(' ', _linebreak) +
      r'([^ ]+) file\b(?! or at)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Chromium's zlib extensions.
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    copyrightIndex: 3,
    authorIndex: 4,
    fileIndex: 5,
    pattern: RegExp(
      kIndent +
      // The " \* " is needed to ensure that both copyright lines start with
      // the comment decoration in the captured match, otherwise it won't be
      // stripped from the second line when generating output.
      r'((?: \* Copyright \(C\) 2017 ARM, Inc.\n)?'
      r'Copyright .+(The .+ Authors)\. +All rights reserved\.)\n'
      r'Use of this source code is governed by a BSD-style license that can be\n'
      r'found in the Chromium source repository ([^ ]+) file.'.replaceAll(r'\n', _linebreakLoose),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Mojo code
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    copyrightIndex: 3,
    authorIndex: 4,
    fileIndex: 5,
    pattern: RegExp(
      kIndent +
      r'(Copyright .+(the .+ authors)\. +All rights reserved.) +' +
      r'Use of this source(?: code)? is governed by a BS?D-style license that can be found in the '.replaceAll(' ', _linebreak) +
      r'([^ ]+) file\b(?! or at)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ANGLE .json files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    copyrightIndex: 3,
    authorIndex: 4,
    fileIndex: 5,
    pattern: RegExp(
      kIndent +
      r'(Copyright .+(The .+ Authors)\. +All rights reserved.)", *\n'
      r'^\1\2Use of this source code is governed by a BSD-style license that can be", *\n'
      r'^\1\2found in the ([^ ]+) file.",',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // typical of Dart-derived files
  LicenseFileReferencePattern(
    firstPrefixIndex: 2,
    indentPrefixIndex: 3,
    copyrightIndex: 1,
    authorIndex: 4,
    fileIndex: 5,
    pattern: RegExp(
      r'(' + kIndent +
      r'Copyright .+(the .+ authors)\[?\. '
      r'Please see the AUTHORS file for details. All rights (?:re|solve)served\.) '
      r'Use of this source(?: code)? is governed by a BS?D-style license '
      r'that can be found in the '.replaceAll(' ', _linebreakLoose) +
      r'([^ ]+) file\b(?! or at)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in libjpeg-turbo
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent + r'For conditions of distribution and use, see (?:the accompanying|copyright notice in)? ([-_.a-zA-Z0-9]+)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in Expat files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent + r'See the file ([^ ]+) for copying permission\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in Expat files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent +
      r'This is free software. You are permitted to copy, distribute, or modify *\n'
      r'^\1\2it under the terms of the MIT/X license \(contained in the ([^ ]+) file *\n'
      r'^\1\2with this distribution\.\)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in FreeType software
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent +
      r'This file (?:is part of the FreeType project, and )?may only be used,? '
      r'modified,? and distributed under the terms of the FreeType project '
      r'license, (LICENSE\.TXT). By continuing to use, modify, or distribute this '
      r'file you indicate that you have read the license and understand and '
      r'accept it fully\.'.replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in FreeType cff software from Adobe
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent +
      r'This software, and all works of authorship, whether in source or '
      r'object code form as indicated by the copyright notice\(s\) included '
      r'herein \(collectively, the "Work"\) is made available, and may only be '
      r'used, modified, and distributed under the FreeType Project License, '
      r'(LICENSE\.TXT)\. Additionally, subject to the terms and conditions of the '
      r'FreeType Project License, each contributor to the Work hereby grants '
      r'to any individual or legal entity exercising permissions granted by '
      r'the FreeType Project License and this section \(hereafter, "You" or '
      r'"Your"\) a perpetual, worldwide, non-exclusive, no-charge, '
      r'royalty-free, irrevocable \(except as stated in this section\) patent '
      r'license to make, have made, use, offer to sell, sell, import, and '
      r'otherwise transfer the Work, where such license applies only to those '
      r'patent claims licensable by such contributor that are necessarily '
      r'infringed by their contribution\(s\) alone or by combination of their '
      r'contribution\(s\) with the Work to which such contribution\(s\) was '
      r'submitted\. If You institute patent litigation against any entity '
      r'\(including a cross-claim or counterclaim in a lawsuit\) alleging that '
      r'the Work or a contribution incorporated within the Work constitutes '
      r'direct or contributory patent infringement, then any patent licenses '
      r'granted to You under this License for that Work shall terminate as of '
      r'the date such litigation is filed\. '
      r'By using, modifying, or distributing the Work you indicate that you '
      r'have read and understood the terms and conditions of the '
      r'FreeType Project License as well as those provided in this section, '
      r'and you accept them fully\.'.replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in Jinja files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent + r':license: [A-Z0-9]+, see (.+) for more details\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in modp_b64
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent + r'Released under [^ ]+ license\. +See ([^ ]+) for details\.$',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in libxml files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    pattern: RegExp(
      kIndent + r'(?:Copy: )?See ([A-Z0-9]+) for the status of this software\.?',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in libxml files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    needsCopyright: false,
    pattern: RegExp(
      kIndent +
      r'// This file is dual licensed under the MIT and the University of Illinois Open *\n'
      r'^\1\2// Source Licenses. See (LICENSE\.TXT) for details\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // BoringSSL
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    needsCopyright: true,
    pattern: RegExp(
      kIndent +
      r'Licensed under the OpenSSL license \(the "License"\)\. You may not use '
      r'this file except in compliance with the License\. You can obtain a copy '
      r'in the file (LICENSE) in the source distribution or at '
      r'https://www\.openssl\.org/source/license\.html'
      .replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in Fuchsia SDK files
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    needsCopyright: false,
    pattern: RegExp(
      kIndent +
      r'Copyright .+\. All rights reserved\. '
      r'This is a GENERATED file, see //zircon/.+/abigen\. '
      r'The license governing this file can be found in the (LICENSE) file\.'
      .replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Seen in Fuchsia SDK files.
  // TODO(chinmaygarde): This is a broken license file that is being patched
  // upstream. Remove this once DX-1477 is patched.
  LicenseFileReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    fileIndex: 3,
    needsCopyright: false,
    pattern: RegExp(
      kIndent +
      r'Use of this source code is governed by a BSD-style license that can be '
      r'Copyright .+\. All rights reserved\. '
      r'found in the (LICENSE) file\.'
      .replaceAll(' ', _linebreak),
      multiLine: true,
      caseSensitive: false,
    )
  ),

];


// INDIRECT REFERENCES TO OTHER FILES

final List<RegExp> csReferencesByType = <RegExp>[

  // used with _tryReferenceByType
  // groups 1 and 2 are the prefix, group 3 is the license type

  // Seen in Jinja files, markupsafe files
  RegExp(
    kIndent + r':license: ([A-Z0-9]+)',
    multiLine: true,
    caseSensitive: false
  ),

  RegExp(
    kIndent +
    r'This software is made available under the terms of the (ICU) License -- ICU 1\.\8\.1 and later\.'.replaceAll(' ', _linebreak),
    multiLine: true,
    caseSensitive: false
  ),

  RegExp(
    kIndent +
    (
      r'(?:@APPLE_LICENSE_HEADER_START@)? '
      r'This file contains Original Code and/or Modifications of Original Code '
      r'as defined in and that are subject to the (Apple Public Source License) '
      r"Version (2\.0) \(the 'License'\)\. You may not use this file except in "
      r'compliance with the License\. Please obtain a copy of the License at '
      r'(http://www\.opensource\.apple\.com/apsl/) and read it before using this '
      r'file\. '
      r'The Original Code and all software distributed under the License are '
      r"distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER "
      r'EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES, '
      r'INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, '
      r'FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT\. '
      r'Please see the License for the specific language governing rights and '
      r'limitations under the License\.'
      r'(?:@APPLE_LICENSE_HEADER_END@)? '
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false
  ),

];

final List<RegExp> csReferencesByTypeNoCopyright = <RegExp>[

  // used with _tryReferenceByType
  // groups 1 and 2 are the prefix, group 3 is the license type

  RegExp(
    kIndent +
    r'Written by Andy Polyakov <appro@openssl\.org> for the OpenSSL '
    r'project\. The module is, however, dual licensed under (OpenSSL) and '
    r'CRYPTOGAMS licenses depending on where you obtain it\. For further '
    r'details see http://www\.openssl\.org/~appro/cryptogams/\. '
    r'Permission to use under GPL terms is granted\.'.replaceAll(' ', _linebreak),
    multiLine: true,
    caseSensitive: false
  ),

];

class MultipleVersionedLicenseReferencePattern {
  MultipleVersionedLicenseReferencePattern({
    this.firstPrefixIndex,
    this.indentPrefixIndex,
    this.licenseIndices,
    this.versionIndicies,
    this.checkLocalFirst = true,
    this.pattern
  });

  final int firstPrefixIndex;
  final int indentPrefixIndex;
  final List<int> licenseIndices;
  final bool checkLocalFirst;
  final Map<int, int> versionIndicies;
  final RegExp pattern;
}

final List<MultipleVersionedLicenseReferencePattern> csReferencesByUrl = <MultipleVersionedLicenseReferencePattern>[

  // used with _tryReferenceByUrl

  // SPDX
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent + r'SPDX-License-Identifier: (.*)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // AFL
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    versionIndicies: const <int, int>{ 3:4 },
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent + r'Licensed under the (Academic Free License) version (3\.0)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Eclipse
  // Seen in auto-generated Java code in the Dart repository.
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      r'^(?:[-;#<!.\\"/* ]*[-;#<!.\"/*]+)?( *)Licensed under the Eclipse Public License v1\.0 \(the "License"\); you may not use this file except *\n'
      r'^\1\2in compliance with the License\. +You may obtain a copy of the License at *\n'
      r'^\1\2 *\n'
      r'^\1\2 *(http://www\.eclipse\.org/legal/epl-v10\.html) *\n'
      r'^\1\2 *\n'
      r'^\1\2Unless required by applicable law or agreed to in writing, software distributed under the License *\n'
      r'^\1\2is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express *\n'
      r'^\1\2or implied\. +See the License for the specific language governing permissions and limitations under *\n'
      r'^\1\2the License\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Apache reference.
  // Seen in Android code.
  // TODO(ianh): For this license we only need to include the text once, not once per copyright
  // TODO(ianh): For this license we must also include all the NOTICE text (see section 4d)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'Licensed under the Apache License, Version 2\.0 \(the "License"\); *\n'
      r'^\1\2you may not use this file except in compliance with the License\. *\n'
      r'^\1\2You may obtain a copy of the License at *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2 *(https?://www\.apache\.org/licenses/LICENSE-2\.0) *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2 *Unless required by applicable law or agreed to in writing, software *\n'
      r'^\1\2 *distributed under the License is distributed on an "AS IS" BASIS, *\n'
      r'^\1\2 *WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied\. *\n'
      r'^\1\2 *See the License for the specific language governing permissions and *\n'
      r'^\1\2 *limitations under the License\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // BSD
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'Use of this source code is governed by a BS?D-style *\n'
      r'^\1\2license that can be found in the LICENSE file or at *\n'
      r'^\1\2(https://developers.google.com/open-source/licenses/bsd)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // MIT
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      (
       r'Use of this source code is governed by a MIT-style '
       r'license that can be found in the LICENSE file or at '
       r'(https://opensource.org/licenses/MIT)'
       .replaceAll(' ', _linebreak)
      ),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // MIT
  // the crazy s/./->/ thing is someone being over-eager with search-and-replace in rapidjson
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'Licensed under the MIT License \(the "License"\); you may not use this file except *\n'
      r'^\1\2in compliance with the License(?:\.|->) You may obtain a copy of the License at *\n'
      r'^\1\n'
      r'^\1\2(http://opensource(?:\.|->)org/licenses/MIT) *\n'
      r'^\1\n'
      r'^\1\2Unless required by applicable law or agreed to in writing, software distributed *\n'
      r'^\1\2under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR *\n'
      r'^\1\2CONDITIONS OF ANY KIND, either express or implied(?:\.|->) See the License for the *\n'
      r'^\1\2specific language governing permissions and limitations under the License(?:\.|->)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // Observatory (polymer)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'This code may only be used under the BSD style license found at (http://polymer.github.io/LICENSE.txt)$',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ashmem
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    versionIndicies: const <int, int>{3:4},
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'This file is dual licensed. +It may be redistributed and/or modified *\n'
      r'^\1\2under the terms of the (Apache) (2\.0) License OR version 2 of the GNU *\n'
      r'^\1\2General Public License\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // GNU ISO C++ GPL+Exception
  // Seen in gnu-libstdc++ in Android NDK
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[5, 6],
    versionIndicies: const <int, int>{5:3, 6:4},
    pattern: RegExp(
      kIndent +
      r'This file is part of the GNU ISO C\+\+ Library\. +This library is free *\n'
      r'^\1\2software; you can redistribute _?_?it and/or modify _?_?it under the terms *\n'
      r'^\1\2of the GNU General Public License as published by the Free Software *\n'
      r'^\1\2Foundation; either version (3), or \(at your option\) any later *\n'
      r'^\1\2version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that _?_?it will be useful, but *\n'
      r'^\1\2WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the GNU *\n'
      r'^\1\2General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Under Section 7 of GPL version \3, you are granted additional *\n'
      r'^\1\2permissions described in the GCC Runtime Library Exception, version *\n'
      r'^\1\2(3\.1), as published by the Free Software Foundation\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU General Public License and *\n'
      r'^\1\2a copy of the GCC Runtime Library Exception along with this program; *\n'
      r'^\1\2see the files (COPYING3) and (COPYING\.RUNTIME) respectively\. +If not, see *\n'
      r'^\1\2<http://www\.gnu\.org/licenses/>\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // GNU ISO C++ GPL+Exception, alternative wrapping
  // Seen in gnu-libstdc++ in Android NDK
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[5, 6],
    versionIndicies: const <int, int>{5:3, 6:4},
    pattern: RegExp(
      kIndent +
      r'This file is part of the GNU ISO C\+\+ Library\. +This library is free *\n'
      r'^\1\2software; you can redistribute it and/or modify it under the *\n'
      r'^\1\2terms of the GNU General Public License as published by the *\n'
      r'^\1\2Free Software Foundation; either version (3), or \(at your option\) *\n'
      r'^\1\2any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the *\n'
      r'^\1\2GNU General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Under Section 7 of GPL version \3, you are granted additional *\n'
      r'^\1\2permissions described in the GCC Runtime Library Exception, version *\n'
      r'^\1\2(3\.1), as published by the(?:, 2009)? Free Software Foundation\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU General Public License and *\n'
      r'^\1\2a copy of the GCC Runtime Library Exception along with this program; *\n'
      r'^\1\2see the files (COPYING3) and (COPYING\.RUNTIME) respectively\. +If not, see *\n'
      r'^\1\2<http://www\.gnu\.org/licenses/>\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // GNU ISO C++ GPL+Exception, alternative footer without exception filename
  // Seen in gnu-libstdc++ in Android NDK
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[6, 4],
    versionIndicies: const <int, int>{6:3, 4:5},
    pattern: RegExp(
      kIndent +
      r'This file is part of the GNU ISO C\+\+ Library\. +This library is free *\n'
      r'^\1\2software; you can redistribute it and/or modify it under the *\n'
      r'^\1\2terms of the GNU General Public License as published by the *\n'
      r'^\1\2Free Software Foundation; either version (3), or \(at your option\) *\n' // group 3 is the version of the gpl
      r'^\1\2any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the *\n'
      r'^\1\2GNU General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Under Section 7 of GPL version \3, you are granted additional *\n'
      r'^\1\2permissions described in the (GCC Runtime Library Exception), version *\n' // group 4 is the "file name" of the exception (it's missing in this version, so we use this as a hook to later, see the url mappings)
      r'^\1\2(3\.1), as published by the Free Software Foundation\. *\n' // group 5 is the version of the exception
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU General Public License along *\n'
      r'^\1\2with this library; see the file (COPYING3)\. +If not see *\n' // group 6 is the gpl file name
      r'^\1\2<http://www\.gnu\.org/licenses/>\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // GCC GPL+Exception
  // Seen in gnu-libstdc++ in Android NDK
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[5, 6],
    versionIndicies: const <int, int>{5:3, 6:4},
    pattern: RegExp(
      kIndent +
      r'This file is part of GCC. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2GCC is free software; you can redistribute it and/or modify it under *\n'
      r'^\1\2the terms of the GNU General Public License as published by the Free *\n'
      r'^\1\2Software Foundation; either version (3), or \(at your option\) any later *\n'
      r'^\1\2version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2GCC is distributed in the hope that it will be useful, but WITHOUT ANY *\n'
      r'^\1\2WARRANTY; without even the implied warranty of MERCHANTABILITY or *\n'
      r'^\1\2FITNESS FOR A PARTICULAR PURPOSE\. +See the GNU General Public License *\n'
      r'^\1\2for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Under Section 7 of GPL version \3, you are granted additional *\n'
      r'^\1\2permissions described in the GCC Runtime Library Exception, version *\n'
      r'^\1\2(3\.1), as published by the Free Software Foundation\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU General Public License and *\n'
      r'^\1\2a copy of the GCC Runtime Library Exception along with this program; *\n'
      r'^\1\2see the files (COPYING3) and (COPYING\.RUNTIME) respectively\. +If not, see *\n'
      r'^\1\2<http://www\.gnu\.org/licenses/>\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // GCC GPL+Exception, alternative line wrapping
  // Seen in gnu-libstdc++ in Android NDK
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[5, 6],
    versionIndicies: const <int, int>{ 5:3, 6:4 },
    pattern: RegExp(
      kIndent +
      r'This file is part of GCC. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2GCC is free software; you can redistribute it and/or modify *\n'
      r'^\1\2it under the terms of the GNU General Public License as published by *\n'
      r'^\1\2the Free Software Foundation; either version (3), or \(at your option\) *\n'
      r'^\1\2any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2GCC is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the *\n'
      r'^\1\2GNU General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Under Section 7 of GPL version \3, you are granted additional *\n'
      r'^\1\2permissions described in the GCC Runtime Library Exception, version *\n'
      r'^\1\2(3\.1), as published by the Free Software Foundation\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU General Public License and *\n'
      r'^\1\2a copy of the GCC Runtime Library Exception along with this program; *\n'
      r'^\1\2see the files (COPYING3) and (COPYING\.RUNTIME) respectively\. +If not, see *\n'
      r'^\1\2<http://www\.gnu\.org/licenses/>\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // LGPL 2.1
  // some engine code
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[4],
    versionIndicies: const <int, int>{ 4:3 },
    pattern: RegExp(
      kIndent +
      r'This library is free software; you can redistribute it and/or *\n'
      r'^\1\2modify it under the terms of the GNU Library General Public *\n'
      r'^\1\2License as published by the Free Software Foundation; either *\n'
      r'^\1\2version (2) of the License, or \(at your option\) any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n?'
       r'\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the GNU *\n?'
       r'\1\2Library General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the GNU Library General Public License *\n'
      r'^\1\2(?:along|aint) with this library; see the file (COPYING\.LI(?:B|other\.m_))\.?  If not, write to *\n'
      r'^\1\2the Free Software Foundation, Inc\., (?:51 Franklin Street, Fifth Floor|59 Temple Place - Suite 330), *\n'
      r'^\1\2Boston, MA 0211[01]-130[17], US(?:A\.|m_)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // AFL/LGPL
  // xdg_mime
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[4],
    versionIndicies: const <int, int>{ 4:3 },
    pattern: RegExp(
      kIndent +
      r'Licensed under the Academic Free License version 2.0 *\n'
      r'^\1\2Or under the following terms: *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is free software; you can redistribute it and/or *\n'
      r'^\1\2modify it under the terms of the GNU Lesser General Public *\n'
      r'^\1\2License as published by the Free Software Foundation; either *\n'
      r'^\1\2version (2) of the License, or \(at your option\) any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\.\t? +See the GNU *\n'
      r'^\1\2Lesser General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the (GNU Lesser) General Public *\n'
      r'^\1\2License along with this library; if not, write to the *\n'
      r'^\1\2Free Software Foundation, Inc\., 59 Temple Place - Suite 330, *\n'
      r'^\1\2Boston, MA 0211[01]-1307, USA\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // MPL
  // root_certificates
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[4],
    versionIndicies: const <int, int>{ 4:3 },
    pattern: RegExp(
      kIndent +
      r'This Source Code Form is subject to the terms of the Mozilla Public *\n'
      r'^\1\2License, v\. (2.0)\. +If a copy of the MPL was not distributed with this *\n'
      r'^\1\2file, You can obtain one at (http://mozilla\.org/MPL/2\.0/)\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // MPL/GPL/LGPL
  // engine
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3], // 5 is lgpl, which we're actively not selecting
    versionIndicies: const <int, int>{ 3:4 }, // 5:6 for lgpl
    pattern: RegExp(
      kIndent +
      r'(?:Version: [GMPL/012. ]+ *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2)?The contents of this file are subject to the (Mozilla Public License) Version *\n'
      r'^\1\2(1\.1) \(the "License"\); you may not use this file except in compliance with *\n'
      r'^\1\2the License\. +You may obtain a copy of the License at *\n'
      r'^\1\2http://www\.mozilla\.org/MPL/ *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Software distributed under the License is distributed on an "AS IS" basis, *\n'
      r'^\1\2WITHOUT WARRANTY OF ANY KIND, either express or implied\. +See the License *\n'
      r'^\1\2for the specific language governing rights and limitations under the *\n'
      r'^\1\2License\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2The Original Code is .+?(?:released\n'
      r'^\1\2March 31, 1998\.)?\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2The Initial Developer of the Original Code is *\n'
      r'^\1\2.+\n'
      r'^\1\2Portions created by the Initial Developer are Copyright \(C\) [0-9]+ *\n'
      r'^\1\2the Initial Developer\. +All Rights Reserved\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Contributor\(s\): *\n'
      r'(?:\1\2  .+\n)*'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2'
      +
      (
        r'Alternatively, the contents of this file may be used under the terms of '
        r'either (?:of )?the GNU General Public License Version 2 or later \(the "GPL"\), '
        r'or the (GNU Lesser) General Public License Version (2\.1) or later \(the '
        r'"LGPL"\), in which case the provisions of the GPL or the LGPL are '
        r'applicable instead of those above\. If you wish to allow use of your '
        r'version of this file only under the terms of either the GPL or the LGPL, '
        r'and not to allow others to use your version of this file under the terms '
        r'of the MPL, indicate your decision by deleting the provisions above and '
        r'replace them with the notice and other provisions required by the GPL or '
        r'the LGPL\. If you do not delete the provisions above, a recipient may use '
        r'your version of this file under the terms of any one of the MPL, the GPL or '
        r'the LGPL\.'
        .replaceAll(' ', _linebreak)
      ),
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // LGPL/MPL/GPL
  // engine
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[4],
    versionIndicies: const <int, int>{ 4:3 },
    pattern: RegExp(
      kIndent +
      r'This library is free software; you can redistribute it and/or *\n'
      r'^\1\2modify it under the terms of the GNU Lesser General Public *\n'
      r'^\1\2License as published by the Free Software Foundation; either *\n'
      r'^\1\2version (2\.1) of the License, or \(at your option\) any later version\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2This library is distributed in the hope that it will be useful, *\n'
      r'^\1\2but WITHOUT ANY WARRANTY; without even the implied warranty of *\n'
      r'^\1\2MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\. +See the GNU *\n'
      r'^\1\2Lesser General Public License for more details\. *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2You should have received a copy of the (GNU Lesser) General Public *\n'
      r'^\1\2License along with this library; if not, write to the Free Software *\n'
      r'^\1\2Foundation, Inc\., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 +USA *\n'
      r'^(?:(?:\1\2? *)? *\n)*'
      r'^\1\2Alternatively, the contents of this file may be used under the terms *\n'
      r'^\1\2of either the Mozilla Public License Version 1\.1, found at *\n'
      r'^\1\2http://www\.mozilla\.org/MPL/ \(the "MPL"\) or the GNU General Public *\n'
      r'^\1\2License Version 2\.0, found at http://www\.fsf\.org/copyleft/gpl\.html *\n'
      r'^\1\2\(the "GPL"\), in which case the provisions of the MPL or the GPL are *\n'
      r'^\1\2applicable instead of those above\. +If you wish to allow use of your *\n'
      r'^\1\2version of this file only under the terms of one of those two *\n'
      r'^\1\2licenses \(the MPL or the GPL\) and not to allow others to use your *\n'
      r'^\1\2version of this file under the LGPL, indicate your decision by *\n'
      r'^\1\2deletingthe provisions above and replace them with the notice and *\n'
      r'^\1\2other provisions required by the MPL or the GPL, as the case may be\. *\n'
      r'^\1\2If you do not delete the provisions above, a recipient may use your *\n'
      r'^\1\2version of this file under any of the LGPL, the MPL or the GPL\.',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ICU (Unicode)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[4],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'(?:©|Copyright (©|\(C\))) 20.. and later: Unicode, Inc. and others.[ *]*\n'
      r'^\1\2License & terms of use: (http://www.unicode.org/copyright.html)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ICU (Unicode)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'(?:Copyright ©) 20..-20.. Unicode, Inc. and others. All rights reserved. '
      r'Distributed under the Terms of Use in (http://www.unicode.org/copyright.html)',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ICU (Unicode)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'Copyright \(C\) 2016 and later: Unicode, Inc. and others. License & terms of use: (http://www.unicode.org/copyright.html) *\n',
      multiLine: true,
      caseSensitive: false,
    )
  ),

  // ICU (Unicode)
  MultipleVersionedLicenseReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    licenseIndices: const <int>[3],
    checkLocalFirst: false,
    pattern: RegExp(
      kIndent +
      r'© 2016 and later: Unicode, Inc. and others. *\n'
      r'^ *License & terms of use: (http://www.unicode.org/copyright.html)#License *\n'
      r'^ *\n'
      r'^ *Copyright \(c\) 2000 IBM, Inc. and Others. *\n',
      multiLine: true,
      caseSensitive: false,
    )
  ),
];


// INLINE LICENSES

final List<RegExp> csLicenses = <RegExp>[

  // used with _tryInline, with needsCopyright: true (will only match if preceded by a copyright notice)
  // should have two groups, prefixes 1 and 2

  // BoringSSL
  RegExp(
    kIndent +
    r'Redistribution and use in source and binary forms, with or without *\n'
    r'^\1\2modification, are permitted provided that the following conditions *\n'
    r'^\1\2are met: *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)Redistributions of source code must retain the above copyright *\n'
    r'^\1\2 *notice, this list of conditions and the following disclaimer\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)Redistributions in binary form must reproduce the above copyright *\n'
    r'^\1\2 *notice, this list of conditions and the following disclaimer in *\n'
    r'^\1\2 *the documentation and/or other materials provided with the *\n'
    r'^\1\2 *distribution\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)All advertising materials mentioning features or use of this *\n'
    r'^\1\2 *software must display the following acknowledgment: *\n'
    r'^\1\2 *"This product includes software developed by the OpenSSL Project *\n'
    r'^\1\2 *for use in the OpenSSL Toolkit\. \(http://www\.OpenSSL\.org/\)" *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to *\n'
    r'^\1\2 *endorse or promote products derived from this software without *\n'
    r'^\1\2 *prior written permission\. +For written permission, please contact *\n'
    r'^\1\2 *[^@ ]+@OpenSSL\.org\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)Products derived from this software may not be called "OpenSSL" *\n'
    r'^\1\2 *nor may "OpenSSL" appear in their names without prior written *\n'
    r'^\1\2 *permission of the OpenSSL Project\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)Redistributions of any form whatsoever must retain the following *\n'
    r'^\1\2 *acknowledgment: *\n'
    r'^\1\2 *"This product includes software developed by the OpenSSL Project *\n'
    r'^\1\2 *for use in the OpenSSL Toolkit \(http://www\.OpenSSL\.org/\)" *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r"^\1\2THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY *\n"
    r'^\1\2EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE *\n'
    r'^\1\2IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR *\n'
    r'^\1\2PURPOSE ARE DISCLAIMED\. +IN NO EVENT SHALL THE OpenSSL PROJECT OR *\n'
    r'^\1\2ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, *\n'
    r'^\1\2SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES \(INCLUDING, BUT *\n'
    r'^\1\2NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; *\n'
    r'^\1\2LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\) *\n'
    r'^\1\2HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, *\n'
    r'^\1\2STRICT LIABILITY, OR TORT \(INCLUDING NEGLIGENCE OR OTHERWISE\) *\n'
    r'^\1\2ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED *\n'
    r'^\1\2OF THE POSSIBILITY OF SUCH DAMAGE\.',
    multiLine: true,
    caseSensitive: false
  ),

  RegExp(
    kIndent +
    r'(?:This package is an SSL implementation written *\n'
    r'^\1\2by Eric Young \(eay@cryptsoft\.com\)\. *\n'
    r'^\1\2The implementation was written so as to conform with Netscapes SSL\. *\n'
    r'^(?:(?:\1\2?g? *)? *\n)*'
    r'^\1\2This library is free for commercial and non-commercial use as long as *\n'
    r'^\1\2the following conditions are aheared to\. +The following conditions *\n'
    r'^\1\2apply to all code found in this distribution, be it the RC4, RSA, *\n'
    r'^\1\2lhash, DES, etc\., code; not just the SSL code\. +The SSL documentation *\n'
    r'^\1\2included with this distribution is covered by the same copyright terms *\n'
    r'^\1\2except that the holder is Tim Hudson \(tjh@cryptsoft\.com\)\. *\n'
    r'^(?:(?:\1\2?g? *)? *\n)*'
    r"^\1\2Copyright remains Eric Young's, and as such any Copyright notices in *\n"
    r'^\1\2the code are not to be removed\. *\n'
    r'^\1\2If this package is used in a product, Eric Young should be given attribution *\n'
    r'^\1\2as the author of the parts of the library used\. *\n'
    r'^\1\2This can be in the form of a textual message at program startup or *\n'
    r'^\1\2in documentation \(online or textual\) provided with the package\. *\n'
    r'^(?:(?:\1\2?g? *)? *\n)*'
    r'^\1\2)?Redistribution and use in source and binary forms, with or without *\n'
    r'^\1\2modification, are permitted provided that the following conditions *\n'
    r'^\1\2are met: *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)Redistributions of source code must retain the copyright *\n'
    r'^\1\2 *notice, this list of conditions and the following disclaimer\. *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)Redistributions in binary form must reproduce the above copyright *\n'
    r'^\1\2 *notice, this list of conditions and the following disclaimer in the *\n'
    r'^\1\2 *documentation and/or other materials provided with the distribution\. *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)All advertising materials mentioning features or use of this software *\n'
    r'^\1\2 *must display the following acknowledgement: *\n'
    r'^\1\2 *"This product includes cryptographic software written by *\n'
    r'^\1\2 *Eric Young \(eay@cryptsoft\.com\)" *\n'
    r"^\1\2 *The word 'cryptographic' can be left out if the rouines from the library *\n" // TODO(ianh): File a bug on the number of analyzer errors you get if you replace the " characters on this line with '
    r'^\1\2 *being used are not cryptographic related :-\)\. *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)If you include any Windows specific code \(or a derivative thereof\) fromg? *\n'
    r'^\1\2 *the apps directory \(application code\) you must include an acknowledgement: *\n'
    r'^\1\2 *"This product includes software written by Tim Hudson \(tjh@cryptsoft\.com\)" *\n'
    r'^(?:(?:\1\2?g? *)? *\n)*'
    r"^\1\2THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND *\n"
    r'^\1\2ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE *\n'
    r'^\1\2IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE *\n'
    r'^\1\2ARE DISCLAIMED\. +IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE *\n'
    r'^\1\2FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL *\n'
    r'^\1\2DAMAGES \(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS *\n'
    r'^\1\2OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\) *\n'
    r'^\1\2HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT *\n'
    r'^\1\2LIABILITY, OR TORT \(INCLUDING NEGLIGENCE OR OTHERWISE\) ARISING IN ANY WAY *\n'
    r'^\1\2OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF *\n'
    r'^\1\2SUCH DAMAGE\. *\n'
    r'^(?:(?:\1\2?g? *)? *\n)*'
    r'^\1\2The licence and distribution terms for any publically available version or *\n'
    r'^\1\2derivative of this code cannot be changed\. +i\.e\. +this code cannot simply be *\n'
    r'^\1\2copied and put under another distribution licence *\n'
    r'^\1\2\[including the GNU Public Licence\.\]',
    multiLine: true,
    caseSensitive: false
  ),

  RegExp(
    kIndent +
    (
      r'License to copy and use this software is granted provided that it '
      r'is identified as the "RSA Data Security, Inc\. MD5 Message-Digest '
      r'Algorithm" in all material mentioning or referencing this software '
      r'or this function\. '
      r'License is also granted to make and use derivative works provided '
      r'that such works are identified as "derived from the RSA Data '
      r'Security, Inc\. MD5 Message-Digest Algorithm" in all material '
      r'mentioning or referencing the derived work\. '
      r'RSA Data Security, Inc\. makes no representations concerning either '
      r'the merchantability of this software or the suitability of this '
      r'software for any particular purpose\. It is provided "as is" '
      r'without express or implied warranty of any kind\. '
      r'These notices must be retained in any copies of any part of this '
      r'documentation and/or software\.'
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false,
  ),

  // BSD-DERIVED LICENSES

  RegExp(
    kIndent +

    // Some files in ANGLE prefix the license with a description of the license.
    r'(?:BSD 2-Clause License \(http://www.opensource.org/licenses/bsd-license.php\))?' +
    _linebreak +

    (
      'Redistribution and use in source and binary forms, with or without '
      'modification, are permitted provided that the following conditions are met:'
      .replaceAll(' ', _linebreak)
    )
    +

    // the conditions:
    r'(?:' +

    // indented blank lines
    _linebreak +

    // truly blank lines
    r'|[\r\n]+' +

    // ad clause - ucb
    r'|(?:[-*1-9.)/ ]*)' +
    (
      'All advertising materials mentioning features or use of this software '
      'must display the following acknowledgement: This product includes software '
      'developed by the University of California, Berkeley and its contributors\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    // ad clause - netbsd
    r'|(?:[-*1-9.)/ ]*)' +
    (
      'All advertising materials mentioning features or use of this software '
      'must display the following acknowledgement: This product includes software '
      'developed by the NetBSD Foundation, Inc\\. and its contributors\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    // ack clause
    r'|(?:[-*1-9.)/ ]*)' +
    (
      r'The origin of this software must not be misrepresented; you must not claim '
      r'that you wrote the original software\. If you use this software in a product, '
      r'an acknowledgment in the product documentation would be appreciated but is '
      r'not required\.'
      .replaceAll(' ', _linebreak)
    )
    +

    r'|(?:[-*1-9.)/ ]*)' +
    (
      r'Altered source versions must be plainly marked as such, and must not be '
      r'misrepresented as being the original software\.'
      .replaceAll(' ', _linebreak)
    )
    +

    // no ad clauses
    r'|(?:[-*1-9.)/ ]*)' +
    (
      'Neither my name, .+, nor the names of any other contributors to the code '
      'use may not be used to endorse or promote products derived from this '
      'software without specific prior written permission\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    r'|(?:[-*1-9.)/ ]*)' +
    (
      'The name of the author may not be used to endorse or promote products '
      'derived from this software without specific prior written permission\\.?'
      .replaceAll(' ', _linebreak)
    )
    +

    r'|(?:[-*1-9.)/ ]*)' +
    (
      'Neither the name of .+ nor the names of its contributors may be used '
      'to endorse or promote products derived from this software without '
      'specific prior written permission\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    // notice clauses
    r'|(?:[-*1-9.)/ ]*)' +
    (
      'Redistributions of source code must retain the above copyright notice, '
      'this list of conditions and the following disclaimer\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    r'|(?:[-*1-9.)/ ]*)' +
    (
      'Redistributions in binary form must reproduce the above copyright notice, '
      'this list of conditions and the following disclaimer in the documentation '
      'and/or other materials provided with the distribution\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    r'|(?:[-*1-9.)/ ]*)' +
    (
      'Redistributions in binary form must reproduce the above copyright notice, '
      'this list of conditions and the following disclaimer\\.'
      .replaceAll(' ', _linebreak)
    )
    +

    // end of conditions
    r')*'
    +

    // disclaimers
    (
      'THIS SOFTWARE IS PROVIDED (?:BY .+(?: .+)? )?["“`]+AS IS["”\']+,? AND ANY EXPRESS OR IMPLIED '
      'WARRANTIES,(?::tabnew)? INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF '
      'MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED\\. IN NO EVENT '
      'SHALL .+(?: .+)? BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR '
      'CONSEQUENTIAL DAMAGES \\(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS '
      'OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\\) HOWEVER CAUSED '
      'AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT \\(INCLUDING '
      'NEGLIGENCE OR OTHERWISE\\) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF '
      'ADVISED OF THE POSSIBILITY OF SUCH DAMAGE\\.'
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false,
  ),


  // THREE-CLAUSE LICENSES
  // licenses in this section are sorted first by the length of the last line, in words,
  // and then by the length of the bulletted clauses, in total lines.

  // Seen in libjpeg-turbo
  // TODO(ianh): Mark License as not needing to be shown
  RegExp(
    kIndent +
    r"This software is provided 'as-is', without any express or implied *\n"
    r'^\1\2warranty\. +In no event will the authors be held liable for any damages *\n'
    r'^\1\2arising from the use of this software\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2Permission is granted to anyone to use this software for any purpose, *\n'
    r'^\1\2including commercial applications, and to alter it and redistribute it *\n'
    r'^\1\2freely, subject to the following restrictions: *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)The origin of this software must not be misrepresented; you must not *\n'
    r'^\1\2 *claim that you wrote the original software\. +If you use this software *\n'
    r'^\1\2 *in a product, an acknowledgment in the product documentation would be *\n'
    r'^\1\2 *appreciated but is not required\. *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)Altered source versions must be plainly marked as such, and must not be *\n'
    r'^\1\2 *misrepresented as being the original software\. *\n'
    r'^\1\2(?:[-*1-9.)/ ]+)This notice may not be removed or altered from any source distribution\.',
    multiLine: true,
    caseSensitive: false
  ),

  // seen in GLFW
  RegExp(
    kIndent +
    r"This software is provided 'as-is', without any express or implied *\n"
    r'^\1\2warranty\. +In no event will the authors be held liable for any damages *\n'
    r'^\1\2arising from the use of this software\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2Permission is granted to anyone to use this software for any purpose, *\n'
    r'^\1\2including commercial applications, and to alter it and redistribute it *\n'
    r'^\1\2freely, subject to the following restrictions: *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)The origin of this software must not be misrepresented; you must not *\n'
    r'^\1\2 *claim that you wrote the original software\. +If you use this software *\n'
    r'^\1\2 *in a product, an acknowledgment in the product documentation would *\n'
    r'^\1\2 *be appreciated but is not required\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)Altered source versions must be plainly marked as such, and must not *\n'
    r'^\1\2 *be misrepresented as being the original software\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2(?:[-*1-9.)/ ]+)This notice may not be removed or altered from any source *\n'
    r'^\1\2 *distribution\.',
    multiLine: true,
    caseSensitive: false
  ),


  // MIT-DERIVED LICENSES

  // Seen in Mesa, among others.
  // A version with "// -------" between sections seen in ffx_spd.
  RegExp(
    kIndent +
    (
      r'Permission is hereby granted, free of charge, to any person obtaining '
      r'a copy of this software and(?: /or)? associated documentation files \(the "(?:Software|Materials) "\), '
      r'to deal in the (?:Software|Materials) without restriction, including without limitation '
      r'the rights to use, copy, modify, merge, publish, distribute, sub license, '
      r'and/or sell copies of the (?:Software|Materials), and to permit persons to whom the '
      r'(?:Software|Materials) (?:is|are) furnished to do so, subject to the following conditions:'
      .replaceAll(' ', _linebreak)
    )
    +
    r'(?:'
    +
    (
      r'(?:(?:\1\2?(?: *| -*))? *\r?\n)*'

      +

      r'|'

      r'\1\2 '
      r'The above copyright notice and this permission notice'
      r'(?: \(including the next paragraph\))? '
      r'shall be included in all copies or substantial portions '
      r'of the (?:Software|Materials)\.'

      r'|'

      r'\1\2 '
      r'In addition, the following condition applies:'

      r'|'

      r'\1\2 '
      r'All redistributions must retain an intact copy of this copyright notice and disclaimer\.'

      r'|'

      r'\1\2 '
      r'THE (?:SOFTWARE|MATERIALS) (?:IS|ARE) PROVIDED "AS -? IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS '
      r'OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
      r'FITNESS FOR A PARTICULAR PURPOSE AND NON-?INFRINGEMENT\. IN NO EVENT SHALL '
      r'.+(?: .+)? BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER '
      r'IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN '
      r'CONNECTION WITH THE (?:SOFTWARE|MATERIALS) OR THE USE OR OTHER DEALINGS IN THE (?:SOFTWARE|MATERIALS)\.'

      r'|'

      r'\1\2 '
      r'THE (?:SOFTWARE|MATERIALS) (?:IS|ARE) PROVIDED "AS -? IS" AND WITHOUT WARRANTY OF ANY KIND, '
      r'EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY '
      r'OR FITNESS FOR A PARTICULAR PURPOSE\.'

      r'|'

      r'\1\2 '
      r'IN NO EVENT SHALL .+ BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL '
      r'DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, '
      r'WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING '
      r'OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE\.'

      .replaceAll(' ', _linebreak)
    )
    +
    r')*',
    multiLine: true,
    caseSensitive: false
  ),

  // BISON LICENSE
  // Seen in some ANGLE source. The usage falls under the "special exception" clause.
  RegExp(
    kIndent +
    r'This program is free software: you can redistribute it and/or modify\n'
    r'^(?:\1\2)?it under the terms of the GNU General Public License as published by\n'
    r'^(?:\1\2)?the Free Software Foundation, either version 3 of the License, or\n'
    r'^(?:\1\2)?\(at your option\) any later version.\n'
    r'^(?:\1\2)?\n*'
    r'^(?:\1\2)?This program is distributed in the hope that it will be useful,\n'
    r'^(?:\1\2)?but WITHOUT ANY WARRANTY; without even the implied warranty of\n'
    r'^(?:\1\2)?MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n'
    r'^(?:\1\2)?GNU General Public License for more details.\n'
    r'^(?:\1\2)?\n*'
    r'^(?:\1\2)?You should have received a copy of the GNU General Public License\n'
    r'^(?:\1\2)?along with this program.  If not, see <http://www.gnu.org/licenses/>.  \*/\n'
    r'^(?:\1\2)?\n*' +
    kIndent +
    r'As a special exception, you may create a larger work that contains\n'
    r'^(?:\1\2)?part or all of the Bison parser skeleton and distribute that work\n'
    r"^(?:\1\2)?under terms of your choice, so long as that work isn't itself a\n"
    r'^(?:\1\2)?parser generator using the skeleton or a modified version thereof\n'
    r'^(?:\1\2)?as a parser skeleton.  Alternatively, if you modify or redistribute\n'
    r'^(?:\1\2)?the parser skeleton itself, you may \(at your option\) remove this\n'
    r'^(?:\1\2)?special exception, which will cause the skeleton and the resulting\n'
    r'^(?:\1\2)?Bison output files to be licensed under the GNU General Public\n'
    r'^(?:\1\2)?License without this special exception.\n'
    r'^(?:\1\2)?\n*'
    r'^(?:\1\2)?This special exception was added by the Free Software Foundation in\n'
    r'^(?:\1\2)?version 2.2 of Bison.  \*/\n',
    multiLine: true,
    caseSensitive: false
  ),

  // OTHER BRIEF LICENSES

  RegExp(
    kIndent +
    r'Permission to use, copy, modify, and distribute this software for any *\n'
    r'^(?:\1\2)?purpose with or without fee is hereby granted, provided that the above *\n'
    r'^(?:\1\2)?copyright notice and this permission notice appear in all copies(?:, and that *\n'
    r'^(?:\1\2)?the name of .+ not be used in advertising or *\n'
    r'^(?:\1\2)?publicity pertaining to distribution of the document or software without *\n'
    r'^(?:\1\2)?specific, written prior permission)?\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^(?:\1\2)?THE SOFTWARE IS PROVIDED "AS IS" AND .+ DISCLAIMS ALL(?: WARRANTIES)? *\n'
    r'^(?:\1\2)?(?:WARRANTIES )?WITH REGARD TO THIS SOFTWARE,? INCLUDING ALL IMPLIED WARRANTIES(?: OF)? *\n'
    r'^(?:\1\2)?(?:OF )?MERCHANTABILITY AND FITNESS\. +IN NO EVENT SHALL .+(?: BE LIABLE FOR)? *\n'
    r'^(?:\1\2)?(?:.+ BE LIABLE FOR )?ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL(?: DAMAGES OR ANY DAMAGES)? *\n'
    r'^(?:\1\2)?(?:DAMAGES OR ANY DAMAGES )?WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR(?: PROFITS, WHETHER IN AN)? *\n'
    r'^(?:\1\2)?(?:PROFITS, WHETHER IN AN )?ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS(?: ACTION, ARISING OUT OF)? *\n'
    r'^(?:\1\2)?(?:ACTION, ARISING OUT OF )?OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS(?: SOFTWARE)?(?: *\n'
    r'^(?:\1\2)?SOFTWARE)?\.',
    multiLine: true,
    caseSensitive: false
  ),

  // Seen in the NDK
  RegExp(
    kIndent +
    r'Permission to use, copy, modify, and/or distribute this software for any *\n'
    r'^\1\2purpose with or without fee is hereby granted, provided that the above *\n'
    r'^\1\2copyright notice and this permission notice appear in all copies\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2THE SOFTWARE IS PROVIDED "AS IS" AND .+ DISCLAIMS ALL WARRANTIES(?: WITH)? *\n'
    r'^\1\2(?:WITH )?REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF(?: MERCHANTABILITY)? *\n'
    r'^\1\2(?:MERCHANTABILITY )?AND FITNESS\. +IN NO EVENT SHALL .+ BE LIABLE FOR(?: ANY(?: SPECIAL, DIRECT,)?)? *\n'
    r'^\1\2(?:(?:ANY )?SPECIAL, DIRECT, )?INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES(?: WHATSOEVER RESULTING FROM)? *\n'
    r'^\1\2(?:WHATSOEVER RESULTING FROM )?LOSS OF USE, DATA OR PROFITS, WHETHER IN AN(?: ACTION(?: OF CONTRACT, NEGLIGENCE)?)? *\n'
    r'^\1\2(?:(?:ACTION )?OF CONTRACT, NEGLIGENCE )?OR OTHER TORTIOUS ACTION, ARISING OUT OF(?: OR IN(?: CONNECTION WITH THE USE OR)?)? *\n'
    r'^\1\2(?:(?:OR IN )?CONNECTION WITH THE USE OR )?PERFORMANCE OF THIS SOFTWARE\.',
    multiLine: true,
    caseSensitive: false
  ),

  // seen in GLFW
  RegExp(
    kIndent +
    r'Permission to use, copy, modify, and distribute this software for any *\n'
    r'^\1\2purpose with or without fee is hereby granted, provided that the above *\n'
    r'^\1\2copyright notice and this permission notice appear in all copies\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r"^\1\2THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED *\n"
    r'^\1\2WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF *\n'
    r'^\1\2MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE\. +THE AUTHORS AND *\n'
    r'^\1\2CONTRIBUTORS ACCEPT NO RESPONSIBILITY IN ANY CONCEIVABLE MANNER\.',
    multiLine: true,
    caseSensitive: false
  ),

  // seen in GLFW, base
  RegExp(
    kIndent +
    r'Permission to use, copy, modify, and distribute this software for any *\n'
    r'^\1\2purpose without fee is hereby granted, provided that this entire notice *\n'
    r'^\1\2is included in all copies of any software which is or includes a copy *\n'
    r'^\1\2or modification of this software and in all copies of the supporting *\n'
    r'^\1\2documentation for such software\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED *\n'
    r'^\1\2WARRANTY\. +IN PARTICULAR, NEITHER THE AUTHOR NOR .+ MAKES ANY *\n'
    r'^\1\2REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY *\n'
    r'^\1\2OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE\.',
    multiLine: true,
    caseSensitive: false
  ),

  // harfbuzz
  RegExp(
    kIndent +
    r'Permission is hereby granted, without written agreement and without *\n'
    r'^\1\2license or royalty fees, to use, copy, modify, and distribute this *\n'
    r'^\1\2software and its documentation for any purpose, provided that the *\n'
    r'^\1\2above copyright notice and the following two paragraphs appear in *\n'
    r'^\1\2all copies of this software\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE TO ANY PARTY FOR *\n'
    r'^\1\2DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES *\n'
    r'^\1\2ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN *\n'
    r'^\1\2IF THE COPYRIGHT HOLDER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH *\n'
    r'^\1\2DAMAGE\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2THE COPYRIGHT HOLDER SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, *\n'
    r'^\1\2BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND *\n'
    r'^\1\2FITNESS FOR A PARTICULAR PURPOSE\. +THE SOFTWARE PROVIDED HEREUNDER IS *\n'
    r'^\1\2ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDER HAS NO OBLIGATION TO *\n'
    r'^\1\2PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS\. *\n',
    multiLine: true,
    caseSensitive: false
  ),

  // NDK
  RegExp(
    kIndent +
    r'Permission to use, copy, modify and distribute this software and *\n'
    r'^\1\2its documentation is hereby granted, provided that both the copyright *\n'
    r'^\1\2notice and this permission notice appear in all copies of the *\n'
    r'^\1\2software, derivative works or modified versions, and any portions *\n'
    r'^\1\2thereof, and that both notices appear in supporting documentation. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2CARNEGIE MELLON ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS" *\n'
    r'^\1\2CONDITION.  CARNEGIE MELLON DISCLAIMS ANY LIABILITY OF ANY KIND *\n'
    r'^\1\2FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2Carnegie Mellon requests users of this software to return to *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2 Software Distribution Coordinator  or  Software.Distribution@CS.CMU.EDU *\n'
    r'^\1\2 School of Computer Science *\n'
    r'^\1\2 Carnegie Mellon University *\n'
    r'^\1\2 Pittsburgh PA 15213-3890 *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2any improvements or extensions that they make and grant Carnegie the *\n'
    r'^\1\2rights to redistribute these changes. *\n',
    multiLine: true,
    caseSensitive: false
  ),

  // seen in Android NDK gnu-libstdc++
  RegExp(
    kIndent +
    (
      r'Permission to use, copy, modify, (?:distribute and sell|sell, and distribute) this software '
      r'(?:and its documentation for any purpose )?is hereby granted without fee, '
      r'provided that the above copyright notice appears? in all copies,? and '
      r'that both that copyright notice and this permission notice appear '
      r'in supporting documentation\. '
      r'(?:.+'
        r'|Hewlett-Packard Company'
        r'|Silicon Graphics'
        r'|None of the above authors, nor IBM Haifa Research Laboratories,'
      r') makes? (?:no|any) '
      r'representations? about the suitability of this software for any '
      r'(?:purpose\. It is provi)?ded "as is" without express or implied warranty\.'
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false
  ),

  // Seen in Android NDK
  RegExp(
    kIndent +
    r'Developed at (?:SunPro|SunSoft), a Sun Microsystems, Inc. business. *\n'
    r'^\1\2Permission to use, copy, modify, and distribute this *\n'
    r'^\1\2software is freely granted, provided that this notice *\n'
    r'^\1\2is preserved.',
    multiLine: true,
    caseSensitive: false
  ),

  // Seen in Android NDK (stlport)
  RegExp(
    kIndent +
    r'This material is provided "as is", with absolutely no warranty expressed *\n'
    r'^\1\2or implied\. +Any use is at your own risk\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2Permission to use or copy this software for any purpose is hereby granted *\n'
    r'^\1\2without fee, provided the above notices are retained on all copies\. *\n'
    r'^\1\2Permission to modify the code and to distribute modified code is granted, *\n'
    r'^\1\2provided the above notices are retained, and a notice that the code was *\n'
    r'^\1\2modified is included with the above copyright notice\.',
    multiLine: true,
    caseSensitive: false
  ),

  // freetype2.
  RegExp(
    kIndent +
    (
      r'Permission to use, copy, modify, distribute, and sell this software and its '
      r'documentation for any purpose is hereby granted without fee, provided that '
      r'the above copyright notice appear in all copies and that both that '
      r'copyright notice and this permission notice appear in supporting '
      r'documentation\. '
      r'The above copyright notice and this permission notice shall be included in '
      r'all copies or substantial portions of the Software\. '
      r'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      r'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
      r'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT\.  IN NO EVENT SHALL THE '
      r'OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN '
      r'AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN '
      r'CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE\. '
      r'Except as contained in this notice, the name of The Open Group shall not be '
      r'used in advertising or otherwise to promote the sale, use or other dealings '
      r'in this Software without prior written authorization from The Open Group\. '
      .replaceAll(' ', _linebreak)
    ),
    multiLine: true,
    caseSensitive: false
  ),

  // TODO(ianh): File a bug on what happens if you replace the // with a #
  // ICU
  RegExp(
    kIndent +
    r'This file is provided as-is by Unicode, Inc\. \(The Unicode Consortium\)\. '
    r'No claims are made as to fitness for any particular purpose\. No '
    r'warranties of any kind are expressed or implied\. The recipient '
    r'agrees to determine applicability of information provided\. If this '
    r'file has been provided on optical media by Unicode, Inc\., the sole '
    r'remedy for any claim will be exchange of defective media within 90 '
    r'days of receipt\. '
    r'Unicode, Inc\. hereby grants the right to freely use the information '
    r'supplied in this file in the creation of products supporting the '
    r'Unicode Standard, and to make copies of this file in any form for '
    r'internal or external distribution as long as this notice remains '
    r'attached\.'
    .replaceAll(' ', _linebreak),
    multiLine: true,
    caseSensitive: false
  ),

  // OpenSSL
  RegExp(
    kIndent +
    r'The portions of the attached software \("Contribution"\) is developed by *\n'
    r'^\1\2Nokia Corporation and is licensed pursuant to the OpenSSL open source *\n'
    r'^\1\2license\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2The Contribution, originally written by Mika Kousa and Pasi Eronen of *\n'
    r'^\1\2Nokia Corporation, consists of the "PSK" \(Pre-Shared Key\) ciphersuites *\n'
    r'^\1\2support \(see RFC 4279\) to OpenSSL\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2No patent licenses or other rights except those expressly stated in *\n'
    r'^\1\2the OpenSSL open source license shall be deemed granted or received *\n'
    r'^\1\2expressly, by implication, estoppel, or otherwise\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2No assurances are provided by Nokia that the Contribution does not *\n'
    r'^\1\2infringe the patent or other intellectual property rights of any third *\n'
    r'^\1\2party or that the license provides you with all the necessary rights *\n'
    r'^\1\2to make use of the Contribution\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND\. IN *\n'
    r'^\1\2ADDITION TO THE DISCLAIMERS INCLUDED IN THE LICENSE, NOKIA *\n'
    r'^\1\2SPECIFICALLY DISCLAIMS ANY LIABILITY FOR CLAIMS BROUGHT BY YOU OR ANY *\n'
    r'^\1\2OTHER ENTITY BASED ON INFRINGEMENT OF INTELLECTUAL PROPERTY RIGHTS OR *\n'
    r'^\1\2OTHERWISE\.',
    multiLine: true,
    caseSensitive: false
  ),

];

final List<RegExp> csNotices = <RegExp>[

  // used with _tryInline, with needsCopyright: false
  // should have two groups, prefixes 1 and 2

  RegExp(
    kIndent +
    r'The Graphics Interchange Format\(c\) is the copyright property of CompuServe *\n'
    r'^\1\2Incorporated\. +Only CompuServe Incorporated is authorized to define, redefine, *\n'
    r'^\1\2enhance, alter, modify or change in any way the definition of the format\. *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2CompuServe Incorporated hereby grants a limited, non-exclusive, royalty-free *\n'
    r'^\1\2license for the use of the Graphics Interchange Format\(sm\) in computer *\n'
    r'^\1\2software; computer software utilizing GIF\(sm\) must acknowledge ownership of the *\n'
    r'^\1\2Graphics Interchange Format and its Service Mark by CompuServe Incorporated, in *\n'
    r'^\1\2User and Technical Documentation\. +Computer software utilizing GIF, which is *\n'
    r'^\1\2distributed or may be distributed without User or Technical Documentation must *\n'
    r'^\1\2display to the screen or printer a message acknowledging ownership of the *\n'
    r'^\1\2Graphics Interchange Format and the Service Mark by CompuServe Incorporated; in *\n'
    r'^\1\2this case, the acknowledgement may be displayed in an opening screen or leading *\n'
    r'^\1\2banner, or a closing screen or trailing banner\. +A message such as the following *\n'
    r'^\1\2may be used: *\n'
    r'^(?:(?:\1\2? *)? *\n)*'
    r'^\1\2 *"The Graphics Interchange Format\(c\) is the Copyright property of *\n'
    r'^\1\2 *CompuServe Incorporated\. +GIF\(sm\) is a Service Mark property of *\n'
    r'^\1\2 *CompuServe Incorporated\." *\n',
    multiLine: true,
    caseSensitive: false
  ),

  // NSPR
  // (Showing the entire block instead of the LGPL for this file is based
  // on advice specifically regarding the prtime.cc file.)
  RegExp(
    r'()()/\* Portions are Copyright \(C\) 2011 Google Inc \*/\n'
    r'/\* \*\*\*\*\* BEGIN LICENSE BLOCK \*\*\*\*\*\n'
    r' \* Version: MPL 1\.1/GPL 2\.0/LGPL 2\.1\n'
    r' \*\n'
    r' \* The contents of this file are subject to the Mozilla Public License Version\n'
    r' \* 1\.1 \(the "License"\); you may not use this file except in compliance with\n'
    r' \* the License\. +You may obtain a copy of the License at\n'
    r' \* http://www\.mozilla\.org/MPL/\n'
    r' \*\n'
    r' \* Software distributed under the License is distributed on an "AS IS" basis,\n'
    r' \* WITHOUT WARRANTY OF ANY KIND, either express or implied\. +See the License\n'
    r' \* for the specific language governing rights and limitations under the\n'
    r' \* License\.\n'
    r' \*\n'
    r' \* The Original Code is the Netscape Portable Runtime \(NSPR\)\.\n'
    r' \*\n'
    r' \* The Initial Developer of the Original Code is\n'
    r' \* Netscape Communications Corporation\.\n'
    r' \* Portions created by the Initial Developer are Copyright \(C\) 1998-2000\n'
    r' \* the Initial Developer\. +All Rights Reserved\.\n'
    r' \*\n'
    r' \* Contributor\(s\):\n'
    r' \*\n'
    r' \* Alternatively, the contents of this file may be used under the terms of\n'
    r' \* either the GNU General Public License Version 2 or later \(the "GPL"\), or\n'
    r' \* the GNU Lesser General Public License Version 2\.1 or later \(the "LGPL"\),\n'
    r' \* in which case the provisions of the GPL or the LGPL are applicable instead\n'
    r' \* of those above\. +If you wish to allow use of your version of this file only\n'
    r' \* under the terms of either the GPL or the LGPL, and not to allow others to\n'
    r' \* use your version of this file under the terms of the MPL, indicate your\n'
    r' \* decision by deleting the provisions above and replace them with the notice\n'
    r' \* and other provisions required by the GPL or the LGPL\. +If you do not delete\n'
    r' \* the provisions above, a recipient may use your version of this file under\n'
    r' \* the terms of any one of the MPL, the GPL or the LGPL\.\n'
    r' \*\n'
    r' \* \*\*\*\*\* END LICENSE BLOCK \*\*\*\*\* \*/\n'
  ),

  // Advice for this was "text verbatim".
  RegExp(
    kIndent +
    r'Copyright \(c\) 2015-2016 Khronos Group\. This work is licensed under a\n'
    r'\1\2Creative Commons Attribution 4\.0 International License; see\n'
    r'\1\2http://creativecommons\.org/licenses/by/4\.0/',
    multiLine: true,
    caseSensitive: false,
  ),

  // by analogy to the above one
  // seen in jsr305
  RegExp(
    kIndent +
    r'Copyright .+\n'
    r'\1\2Released under the Creative Commons Attribution License\n'
    r'\1\2 *\(?http://creativecommons\.org/licenses/by/2\.5/?\)?\n'
    r'\1\2Official home: .+',
    multiLine: true,
    caseSensitive: false,
  ),

  // Advice for this was "Just display its text as a politeness. Nothing else required".
  RegExp(
    r'()()/\* mdXhl\.c \* ----------------------------------------------------------------------------\n'
    r' \* "THE BEER-WARE LICENSE" \(Revision 42\):\n'
    r' \* <phk@FreeBSD\.org> wrote this file\. +As long as you retain this notice you\n'
    r' \* can do whatever you want with this stuff\. If we meet some day, and you think\n'
    r' \* this stuff is worth it, you can buy me a beer in return\. +Poul-Henning Kamp\n'
    r' \* ----------------------------------------------------------------------------\n'
    r' \* libjpeg-turbo Modifications:\n'
    r' \* Copyright \(C\) 2016, D\. R\. Commander\.?\n'
    r' \* Modifications are under the same license as the original code \(see above\)\n'
    r' \* ----------------------------------------------------------------------------'
  ),
];


// FALLBACK PATTERNS

final List<RegExp> csFallbacks = <RegExp>[

  // used with _tryNone
  // groups are ignored

];


// FORWARD REFERENCE

class ForwardReferencePattern {
  ForwardReferencePattern({ this.firstPrefixIndex, this.indentPrefixIndex, this.pattern, this.targetPattern });
  final int firstPrefixIndex;
  final int indentPrefixIndex;
  final RegExp pattern;
  final RegExp targetPattern;
}

final List<ForwardReferencePattern> csForwardReferenceLicenses = <ForwardReferencePattern>[

  // used with _tryForwardReferencePattern

  // OpenSSL (in Dart third_party)
  ForwardReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    pattern: RegExp(
      kIndent + r'(?:'
      +
      (
        r'Portions of the attached software \("Contribution"\) are developed by .+ and are contributed to the OpenSSL project\.'
        .replaceAll(' ', _linebreak)
      )
      +
      r'|'
      +
      (
        r'The .+ included herein is developed by .+, and is contributed to the OpenSSL project\.'
        .replaceAll(' ', _linebreak)
      )
      +
      r'|'
      r'(?:\1? *\n)+'
      r')*'
      r'\1\2 *'
      +
      (
        r'The .+ is licensed pursuant to the OpenSSL open source license provided (?:below|above)\.'
        .replaceAll(' ', _linebreak)
      ),
      multiLine: true,
      caseSensitive: false,
    ),
    targetPattern: RegExp('Redistribution and use in source and binary forms(?:.|\n)+OpenSSL')
  ),

  // libevent
  ForwardReferencePattern(
    firstPrefixIndex: 1,
    indentPrefixIndex: 2,
    pattern: RegExp(
      kIndent + r'Use is subject to license terms\.$',
      multiLine: true,
      caseSensitive: false,
    ),
    targetPattern: RegExp('Redistribution and use in source and binary forms(?:.|\n)+SUN MICROSYSTEMS')
  ),

];
