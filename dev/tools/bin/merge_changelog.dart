// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 3.10

import 'dart:io' as io;

final RegExp _h2RegExp = RegExp(r'^## Flutter (\d+)\.(\d+) Changes[ \t]*$', multiLine: true);
final RegExp _invalidHeadingRegExp = RegExp(
  r'^(?:#(?!#).*|##(?!#)(?! Flutter \d+\.\d+ Changes[ \t]*$).*|#{4,}[ \t]+\[?\d+\.\d+\.\d+.*)$',
  multiLine: true,
);
final RegExp _h3RegExp = RegExp(r'^### (.+)$', multiLine: true);
final RegExp _semverRegExp = RegExp(r'^\[?(\d+)\.(\d+)\.(\d+)(?:\]|\s|$)');
final RegExp _trailingNewlinesRegExp = RegExp(r'\n+$');
final RegExp _fenceOpenRegExp = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final RegExp _fenceCloseRegExp = RegExp(r'^ {0,3}(`{3,}|~{3,})[ \t]*$');

typedef _MinorVersion = (int, int);
typedef _Semver = (int, int, int);

final class _PatchEntry {
  const _PatchEntry({required this.key, required this.version, required this.raw});

  final String key;
  final _Semver? version;
  final String raw;
}

final class _MinorSection {
  const _MinorSection({
    required this.minor,
    required this.header,
    required this.patches,
    required this.raw,
  });

  final _MinorVersion minor;
  final String header;
  final List<_PatchEntry> patches;
  final String raw;
}

/// CLI entry point that merges release sections from stable `CHANGELOG.md`
/// into master `CHANGELOG.md` in place.
///
/// Uses only `dart:io` (pinned to `@dart = 3.10`) so
/// `.github/workflows/merge-changelog.yml` can invoke `./bin/dart` directly on
/// a shallow `--depth=1` checkout without running `flutter pub get`.
void main(List<String> arguments) {
  io.exitCode = run(arguments);
}

/// Runs the changelog merge CLI with [arguments] (`[masterPath, stablePath]`).
///
/// Returns `0` on success or `2` on invalid arguments.
int run(List<String> arguments, {StringSink? errSink}) {
  if (arguments.length != 2) {
    (errSink ?? io.stderr).writeln(
      'Usage: dart dev/tools/bin/merge_changelog.dart <master_changelog_path> <stable_changelog_path>',
    );
    return 2;
  }

  final masterFile = io.File(arguments[0]);
  final stableFile = io.File(arguments[1]);
  final String merged = mergeChangelogs(
    masterFile.readAsStringSync(),
    stableFile.readAsStringSync(),
  );
  masterFile.writeAsStringSync(merged);
  return 0;
}

/// Merges release sections from [stableText] into [masterText].
///
/// Normalizes CRLF/CR line endings to LF, masks HTML comments and fenced code
/// blocks during heading scans, lets `stable` win for the active `stable` minor
/// series when at least as new as `master`, and preserves hotfix entries on
/// older minor release series present on `master`.
///
/// Throws a [FormatException] if headings are malformed, duplicated, or lost.
String mergeChangelogs(String masterText, String stableText) {
  final String normalizedMaster = _normalizeLineEndings(masterText);
  final String normalizedStable = _normalizeLineEndings(stableText);
  final String maskedMaster = _maskInertMarkdown(normalizedMaster);
  final String maskedStable = _maskInertMarkdown(normalizedStable);

  final (String preamble, Map<_MinorVersion, _MinorSection> masterMinors) = _parseChangelog(
    normalizedMaster,
    maskedMaster,
  );
  final (_, Map<_MinorVersion, _MinorSection> stableMinors) = _parseChangelog(
    normalizedStable,
    maskedStable,
  );

  final List<_MinorVersion> sortedStableMinors = stableMinors.keys.toList()
    ..sort(_compareMinorDesc);
  final _MinorVersion activeStableMinor = sortedStableMinors.first;

  final List<_MinorVersion> allMinors = <_MinorVersion>{
    ...masterMinors.keys,
    ...stableMinors.keys,
  }.toList()..sort(_compareMinorDesc);

  final buffer = StringBuffer(preamble);
  for (var i = 0; i < allMinors.length; i++) {
    final _MinorVersion minor = allMinors[i];
    final isLast = i == allMinors.length - 1;
    final _MinorSection? masterSec = masterMinors[minor];
    final _MinorSection? stableSec = stableMinors[minor];
    buffer.write(
      _resolveMinorBlock(
        masterSec,
        stableSec,
        preferStable: minor == activeStableMinor && _isStableAtLeastAsNew(masterSec, stableSec),
        isLast: isLast,
      ),
    );
  }

  final merged = buffer.toString();
  _verifyOutputInvariants(
    maskedMaster: maskedMaster,
    maskedStable: maskedStable,
    mergedText: merged,
    expectedMinorCount: allMinors.length,
  );
  return merged;
}

String _normalizeLineEndings(String text) {
  final String withoutBom = text.startsWith('\uFEFF') ? text.substring(1) : text;
  return withoutBom.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String _stripTrailingNewlines(String text) => text.replaceFirst(_trailingNewlinesRegExp, '');

int _compareMinorDesc(_MinorVersion a, _MinorVersion b) {
  final int majorCmp = b.$1.compareTo(a.$1);
  return majorCmp != 0 ? majorCmp : b.$2.compareTo(a.$2);
}

int _compareSemverDesc(_Semver a, _Semver b) {
  final int majorCmp = b.$1.compareTo(a.$1);
  if (majorCmp != 0) {
    return majorCmp;
  }
  final int minorCmp = b.$2.compareTo(a.$2);
  return minorCmp != 0 ? minorCmp : b.$3.compareTo(a.$3);
}

bool _isStableAtLeastAsNew(_MinorSection? masterSec, _MinorSection? stableSec) {
  if (masterSec == null || stableSec == null) {
    return true;
  }
  final _Semver? masterMax = _maxSemver(masterSec.patches);
  final _Semver? stableMax = _maxSemver(stableSec.patches);
  if (masterMax == null || stableMax == null) {
    return true;
  }
  return _compareSemverDesc(stableMax, masterMax) <= 0;
}

_Semver? _maxSemver(List<_PatchEntry> patches) {
  _Semver? best;
  for (final patch in patches) {
    final _Semver? ver = patch.version;
    if (ver != null && (best == null || _compareSemverDesc(ver, best) < 0)) {
      best = ver;
    }
  }
  return best;
}

(String, int)? _fenceOpener(String line) {
  final RegExpMatch? match = _fenceOpenRegExp.firstMatch(line);
  if (match == null) {
    return null;
  }
  final String fence = match.group(1)!;
  final String info = match.group(2)!;
  if (fence.startsWith('`') && info.contains('`')) {
    return null;
  }
  return (fence[0], fence.length);
}

bool _isFenceCloser(String line, String fenceChar, int minLen) {
  final RegExpMatch? match = _fenceCloseRegExp.firstMatch(line);
  if (match == null) {
    return false;
  }
  final String run = match.group(1)!;
  return run[0] == fenceChar && run.length >= minLen;
}

(String, bool) _maskHtmlCommentsInLine(String line, bool startInComment) {
  final buf = StringBuffer();
  var index = 0;
  var inComment = startInComment;
  while (index < line.length) {
    if (inComment) {
      final int closeIdx = line.indexOf('-->', index);
      if (closeIdx == -1) {
        buf.write(' ' * (line.length - index));
        break;
      }
      buf.write(' ' * (closeIdx + 3 - index));
      index = closeIdx + 3;
      inComment = false;
    } else {
      final int openIdx = line.indexOf('<!--', index);
      if (openIdx == -1) {
        buf.write(line.substring(index));
        break;
      }
      buf.write(line.substring(index, openIdx));
      buf.write('    ');
      index = openIdx + 4;
      inComment = true;
    }
  }
  return (buf.toString(), inComment);
}

String _maskInertMarkdown(String text) {
  final out = StringBuffer();
  var inHtmlComment = false;
  String? fenceChar;
  var fenceLen = 0;
  var offset = 0;

  while (offset < text.length) {
    final int nlIdx = text.indexOf('\n', offset);
    final int lineEnd = nlIdx == -1 ? text.length : nlIdx;
    final String line = text.substring(offset, lineEnd);

    if (fenceChar != null) {
      if (_isFenceCloser(line, fenceChar, fenceLen)) {
        fenceChar = null;
        fenceLen = 0;
      }
      out.write(' ' * line.length);
    } else if (!inHtmlComment && _fenceOpener(line) != null) {
      final (String ch, int len) = _fenceOpener(line)!;
      fenceChar = ch;
      fenceLen = len;
      out.write(' ' * line.length);
    } else {
      final (String maskedLine, bool stillInComment) = _maskHtmlCommentsInLine(line, inHtmlComment);
      inHtmlComment = stillInComment;
      out.write(maskedLine);
    }

    if (nlIdx != -1) {
      out.write('\n');
      offset = nlIdx + 1;
    } else {
      offset = text.length;
    }
  }

  if (inHtmlComment) {
    throw const FormatException('Unclosed HTML comment in CHANGELOG.md.');
  }
  if (fenceChar != null) {
    throw const FormatException('Unclosed fenced code block in CHANGELOG.md.');
  }
  final masked = out.toString();
  assert(masked.length == text.length);
  return masked;
}

(String, Map<_MinorVersion, _MinorSection>) _parseChangelog(String text, String masked) {
  final List<String> invalid = _invalidHeadingRegExp
      .allMatches(masked)
      .map((RegExpMatch m) => text.substring(m.start, m.end))
      .toList();
  if (invalid.isNotEmpty) {
    throw FormatException('Unexpected heading(s) in CHANGELOG.md: $invalid');
  }

  final List<RegExpMatch> matches = _h2RegExp.allMatches(masked).toList();
  if (matches.isEmpty) {
    throw const FormatException("No '## Flutter X.Y Changes' sections found in CHANGELOG.md.");
  }

  final String preamble = text.substring(0, matches.first.start);
  final sections = <_MinorVersion, _MinorSection>{};

  for (var i = 0; i < matches.length; i++) {
    final RegExpMatch match = matches[i];
    final _MinorVersion minor = (int.parse(match.group(1)!), int.parse(match.group(2)!));
    if (sections.containsKey(minor)) {
      throw FormatException('Duplicate minor section: Flutter ${minor.$1}.${minor.$2}');
    }
    final int end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final String raw = text.substring(match.start, end);
    final String maskedSec = masked.substring(match.start, end);
    final (String header, List<_PatchEntry> patches) = _parsePatches(raw, maskedSec);
    sections[minor] = _MinorSection(minor: minor, header: header, patches: patches, raw: raw);
  }

  return (preamble, sections);
}

(String, List<_PatchEntry>) _parsePatches(String rawSection, String maskedSection) {
  final List<RegExpMatch> h3Matches = _h3RegExp.allMatches(maskedSection).toList();
  if (h3Matches.isEmpty) {
    return (rawSection, const <_PatchEntry>[]);
  }

  final String header = rawSection.substring(0, h3Matches.first.start);
  final patches = <_PatchEntry>[];
  final seenKeys = <String>{};
  for (var j = 0; j < h3Matches.length; j++) {
    final RegExpMatch h3Match = h3Matches[j];
    final int pEnd = j + 1 < h3Matches.length ? h3Matches[j + 1].start : rawSection.length;
    final String pRaw = rawSection.substring(h3Match.start, pEnd);
    final String title = rawSection.substring(h3Match.start + 4, h3Match.end).trim();
    final String maskedTitle = h3Match.group(1)!.trim();
    final RegExpMatch? sv = _semverRegExp.firstMatch(maskedTitle);
    final _PatchEntry entry;
    if (sv != null) {
      final _Semver ver = (
        int.parse(sv.group(1)!),
        int.parse(sv.group(2)!),
        int.parse(sv.group(3)!),
      );
      entry = _PatchEntry(key: '${ver.$1}.${ver.$2}.${ver.$3}', version: ver, raw: pRaw);
    } else {
      entry = _PatchEntry(key: title, version: null, raw: pRaw);
    }
    if (!seenKeys.add(entry.key)) {
      throw FormatException('Duplicate patch heading in CHANGELOG.md: ${entry.key}');
    }
    patches.add(entry);
  }
  return (header, patches);
}

String _resolveMinorBlock(
  _MinorSection? masterSec,
  _MinorSection? stableSec, {
  required bool preferStable,
  required bool isLast,
}) {
  if (masterSec == null) {
    final String block = stableSec!.raw;
    return (!isLast && !block.endsWith('\n\n')) ? '${_stripTrailingNewlines(block)}\n\n' : block;
  }
  if (stableSec == null) {
    final String block = masterSec.raw;
    return (!isLast && !block.endsWith('\n')) ? '$block\n' : block;
  }
  final String block = _mergeMinorSection(masterSec, stableSec, preferStable: preferStable);
  if (preferStable && !isLast && !block.endsWith('\n\n')) {
    return '${_stripTrailingNewlines(block)}\n\n';
  }
  if (!isLast && !block.endsWith('\n')) {
    return '$block\n';
  }
  return block;
}

String _mergeMinorSection(
  _MinorSection masterSec,
  _MinorSection stableSec, {
  required bool preferStable,
}) {
  final Set<String> masterKeys = masterSec.patches.map((_PatchEntry p) => p.key).toSet();
  final Set<String> stableKeys = stableSec.patches.map((_PatchEntry p) => p.key).toSet();

  if (preferStable && stableKeys.containsAll(masterKeys)) {
    return stableSec.raw;
  }
  if (!preferStable && masterKeys.containsAll(stableKeys)) {
    return masterSec.raw;
  }

  final primary = preferStable ? stableSec : masterSec;
  final secondary = preferStable ? masterSec : stableSec;

  final byKey = <String, _PatchEntry>{
    for (final _PatchEntry p in secondary.patches) p.key: p,
    for (final _PatchEntry p in primary.patches) p.key: p,
  };

  final List<_PatchEntry> semverPatches =
      byKey.values.where((_PatchEntry p) => p.version != null).toList()
        ..sort((_PatchEntry a, _PatchEntry b) => _compareSemverDesc(a.version!, b.version!));

  final seenNonSemver = <String>{};
  final otherPatches = <_PatchEntry>[];
  for (final p in <_PatchEntry>[...primary.patches, ...secondary.patches]) {
    if (p.version == null && seenNonSemver.add(p.key)) {
      otherPatches.add(byKey[p.key]!);
    }
  }

  final ordered = <_PatchEntry>[...semverPatches, ...otherPatches];
  final int trailingCount = primary.raw.length - _stripTrailingNewlines(primary.raw).length;
  final trailingNewlines = trailingCount == 0 ? 2 : trailingCount;
  final String normalizedHeader = primary.header.endsWith('\n')
      ? primary.header
      : '${primary.header}\n';
  final String body = ordered.map((_PatchEntry p) => _stripTrailingNewlines(p.raw)).join('\n\n');
  return '$normalizedHeader$body${'\n' * trailingNewlines}';
}

List<_Semver> _extractSemverList(String maskedText) {
  final versions = <_Semver>[];
  for (final RegExpMatch h3Match in _h3RegExp.allMatches(maskedText)) {
    final RegExpMatch? sv = _semverRegExp.firstMatch(h3Match.group(1)!.trim());
    if (sv != null) {
      versions.add((int.parse(sv.group(1)!), int.parse(sv.group(2)!), int.parse(sv.group(3)!)));
    }
  }
  return versions;
}

void _verifyOutputInvariants({
  required String maskedMaster,
  required String maskedStable,
  required String mergedText,
  required int expectedMinorCount,
}) {
  final String maskedMerged = _maskInertMarkdown(mergedText);
  final int actualMinorCount = _h2RegExp.allMatches(maskedMerged).length;
  if (actualMinorCount != expectedMinorCount) {
    throw FormatException(
      'Merged CHANGELOG.md minor section count mismatch ($actualMinorCount != $expectedMinorCount).',
    );
  }

  final List<_Semver> masterVers = _extractSemverList(maskedMaster);
  final List<_Semver> stableVers = _extractSemverList(maskedStable);
  final List<_Semver> mergedVers = _extractSemverList(maskedMerged);
  final Set<_Semver> mergedSet = mergedVers.toSet();
  if (mergedVers.length != mergedSet.length) {
    throw const FormatException('Merged CHANGELOG.md contains duplicate version headings.');
  }
  final expected = <_Semver>{...masterVers, ...stableVers};
  if (mergedSet.length != expected.length || !mergedSet.containsAll(expected)) {
    final List<_Semver> missing = expected.difference(mergedSet).toList()..sort(_compareSemverDesc);
    throw FormatException('Merged CHANGELOG.md lost version headings: $missing');
  }
}
