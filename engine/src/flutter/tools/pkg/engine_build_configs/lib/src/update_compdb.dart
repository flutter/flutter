  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0  215M    0 43301    0     0   130k      0  0:28:12 --:--:--  0:28:12  130k  5  215M    5 12.0M    0     0  9025k      0  0:00:24  0:00:01  0:00:23 9022k 16  215M   16 35.3M    0     0  15.2M      0  0:00:14  0:00:02  0:00:12 15.2M 33  215M   33 71.5M    0     0  21.5M      0  0:00:10  0:00:03  0:00:07 21.5M 51  215M   51  110M    0     0  25.4M      0  0:00:08  0:00:04  0:00:04 25.4M 69  215M   69  149M    0     0  28.0M      0  0:00:07  0:00:05  0:00:02 29.9M 87  215M   87  188M    0     0  29.7M      0  0:00:07  0:00:06  0:00:01 35.5M100  215M  100  215M    0     0  30.5M      0  0:00:07  0:00:07 --:--:-- 37.9M
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:path/path.dart' as p;

final RegExp _clangRegexp = RegExp(r'("command"\s*:\s*").*(\s(?:\S*/)?clang(\+\+)?)(?=[\s"])');
final RegExp _swiftEntryRegexp = RegExp(r'\{[^{}]*swiftc\.py[^{}]*\}');
final RegExp _shellQuoteRegexp = RegExp(r'[\s"\\$`!#&*|?()<>;~]');
const convert.JsonEncoder _jsonEncoder = convert.JsonEncoder.withIndent('  ');

/// Strips compiler wrapper prefixes from compiler commands in [contents].
///
/// Our build toolchain invokes certain `clang` commands from wrappers (such as
/// rewrapper and ccache) for use with RBE. This can confuse C and C++ language
/// servers like `clangd` when indexing source files.
///
/// See: https://github.com/flutter/flutter/issues/147767
String stripCompilerWrappers(String contents) {
  return contents.replaceAllMapped(_clangRegexp, (Match match) {
    return '${match[1]}${match[2]!.trim()}';
  });
}

/// Converts GN `swiftc.py` invocations in [contents] into native `swiftc` commands.
///
/// Flutter's build toolchain invokes `swiftc` from a `swiftc.py` wrapper.
/// Language servers such as SourceKit-LSP expect expanded, per-file `swiftc`
/// invocations in `compile_commands.json`. This replaces wrapper calls with
/// direct invocations that language servers understand.
String expandSwiftcCommands(String contents) {
  if (!contents.contains('swiftc.py')) {
    return contents;
  }

  return contents.replaceAllMapped(_swiftEntryRegexp, (Match match) {
    final String rawJson = match.group(0)!;
    try {
      final entry = convert.jsonDecode(rawJson) as Map<String, Object?>;
      final List<Map<String, Object?>> expanded = expandSwiftEntry(entry);
      return expanded.map((Map<String, Object?> map) => _jsonEncoder.convert(map)).join(',\n  ');
    } catch (_) {
      // If parsing fails for any reason, leave the block untouched.
      return rawJson;
    }
  });
}

/// Post-processes the contents of a `compile_commands.json` file.
///
/// Strips compiler wrapper prefixes (such as rewrapper and ccache) from clang
/// commands, and converts GN `swiftc.py` invocations into native `swiftc`
/// commands expanded per-file for SourceKit-LSP.
String updateCompilationDatabase(String contents) {
  contents = stripCompilerWrappers(contents);
  return expandSwiftcCommands(contents);
}

/// Expands a single `swiftc.py` [entry] into per-file `swiftc` compilation entries.
///
/// If [entry] has a `command` that invokes `swiftc.py`, this parses the
/// arguments, translates them to `swiftc` arguments, makes paths absolute
/// against the entry's `directory`, and returns an entry for each `.swift` file
/// compiled. Does not mutate [entry]; always returns fresh map(s).
List<Map<String, Object?>> expandSwiftEntry(Map<String, Object?> entry) {
  final String entryDir = (entry['directory'] as String?) ?? '';
  final Map<String, Object?> baseEntry = _absolutizeEntryFile(entry, entryDir);

  final origCommand = baseEntry['command'] as String?;
  if (origCommand == null) {
    return <Map<String, Object?>>[baseEntry];
  }

  final _SwiftcTranslation? translation = _translateSwiftcCommand(origCommand);
  if (translation == null) {
    return <Map<String, Object?>>[baseEntry];
  }

  final translatedEntry = <String, Object?>{
    ...baseEntry,
    'command': _resolveCommandPaths(entryDir, translation.args),
  };

  if (translation.swiftFiles.isEmpty) {
    return <Map<String, Object?>>[translatedEntry];
  }

  final List<String> absSwiftFiles = translation.swiftFiles
      .map((String f) => makePathAbsolute(entryDir, f))
      .toList();
  return _duplicateEntryPerSwiftFile(translatedEntry, absSwiftFiles);
}

/// Returns a copy of [entry] with its `file` path made absolute against
/// [entryDir], if present and relative.
Map<String, Object?> _absolutizeEntryFile(Map<String, Object?> entry, String entryDir) {
  final file = entry['file'] as String?;
  return <String, Object?>{
    ...entry,
    if (file != null && !p.isAbsolute(file)) 'file': makePathAbsolute(entryDir, file),
  };
}

/// Duplicates [entry] once per file in [absSwiftFiles] (skipping [entry]'s own
/// `file`, which is already covered), overriding `file` on each copy, so
/// language servers can index every compiled Swift file.
List<Map<String, Object?>> _duplicateEntryPerSwiftFile(
  Map<String, Object?> entry,
  List<String> absSwiftFiles,
) {
  final origFileAbs = entry['file'] as String?;
  final results = <Map<String, Object?>>[entry];
  for (final absFile in absSwiftFiles) {
    if (absFile != origFileAbs) {
      results.add(<String, Object?>{...entry, 'file': absFile});
    }
  }
  return results;
}

/// Resolves [filePath] against [directory] and returns the normalized absolute path.
String makePathAbsolute(String directory, String filePath) =>
    p.isAbsolute(filePath) ? p.normalize(filePath) : p.normalize(p.join(directory, filePath));

/// The `swiftc` arguments translated from a GN `swiftc.py` command, and any
/// `.swift` source files found among them.
typedef _SwiftcTranslation = ({List<String> args, List<String> swiftFiles});

/// Parses [cmdStr] and translates it to `swiftc` arguments, or returns `null`
/// if [cmdStr] is not a `swiftc.py` invocation.
_SwiftcTranslation? _translateSwiftcCommand(String cmdStr) {
  if (!cmdStr.contains('swiftc.py')) {
    return null;
  }
  final List<String> words = splitShellWords(cmdStr);
  final int swiftcPyIdx = words.indexWhere((String w) => w.contains('swiftc.py'));
  if (swiftcPyIdx == -1) {
    return null;
  }
  return _translateSwiftcArgs(words.sublist(swiftcPyIdx + 1));
}

/// Translates GN `swiftc.py` [args] (the tokens following the script path)
/// into native `swiftc` arguments, and extracts any `.swift` source files.
///
/// Note on architectural separation: non-path `-Xcc` flag synthesis (such as
/// preprocessor defines `-D`) is handled here, during syntactic argument
/// translation. Path-dependent `-Xcc` flag synthesis (such as `-I` or `-F`) is
/// deferred to [_resolveCommandPaths], where relative filesystem paths are
/// resolved to absolute paths.
_SwiftcTranslation _translateSwiftcArgs(List<String> args) {
  final newArgs = <String>['swiftc', '-parse-as-library'];
  final swiftFiles = <String>[];

  var i = 0;
  while (i < args.length) {
    final String arg = args[i];
    if (arg == '-import-objc-header') {
      if (i + 1 < args.length) {
        final String val = args[i + 1];
        if (val.isNotEmpty && val != '""' && val != "''") {
          newArgs.addAll(<String>['-import-objc-header', val]);
        }
      }
      i += 2;
    } else if (arg == '--whole-module-optimization') {
      newArgs.add('-whole-module-optimization');
      i += 1;
    } else if (arg.startsWith('--')) {
      // swiftc.py's own `--flag`s are all value-taking except this one; a
      // future boolean `--flag` added to swiftc.py's argparse would need a
      // case here too.
      if (arg == '--fix-generated-header') {
        i += 1;
      } else {
        i += 2;
      }
    } else if (arg == '-D') {
      if (i + 1 < args.length) {
        final String val = args[i + 1];
        // Swift's `-D` only supports bare conditional-compilation flags, not
        // `key=value` defines, so those are only forwarded to clang.
        if (!val.contains('=')) {
          newArgs.addAll(<String>['-D', val]);
        }
        newArgs.addAll(<String>['-Xcc', '-D$val']);
      }
      i += 2;
    } else if (arg.startsWith('-D')) {
      final String val = arg.substring(2);
      if (!val.contains('=')) {
        newArgs.add(arg);
      }
      newArgs.addAll(<String>['-Xcc', '-D$val']);
      i += 1;
    } else {
      newArgs.add(arg);
      if (arg.endsWith('.swift')) {
        swiftFiles.add(arg);
      }
      i += 1;
    }
  }

  return (args: newArgs, swiftFiles: swiftFiles);
}

/// Resolves relative paths in [words] to absolute paths against [directory],
/// synthesizes path-dependent `-Xcc` flags for include and framework search
/// paths (`-I`, `-F`, `-isystem`, `-Fsystem`), and returns the quoted, joined
/// command string. Non-path `-Xcc` synthesis (`-D`) happens upstream, in
/// [_translateSwiftcArgs].
///
/// `-isystem` is clang-only: it's forwarded to swift only as `-Xcc -isystem
/// -Xcc <path>`, never as a bare swift-side flag.
String _resolveCommandPaths(String directory, List<String> words) {
  final newArgs = <String>[];

  // `-isystem` is the only one of these forwarded to clang exclusively; see
  // the doc comment above.
  bool isClangOnly(String flag) => flag == '-isystem';

  int addSeparatedIncludeFlag(int i) {
    final String flag = words[i];
    if (!isClangOnly(flag)) {
      newArgs.add(flag);
    }
    if (i + 1 >= words.length) {
      return i + 1;
    }
    final String absVal = makePathAbsolute(directory, words[i + 1]);
    if (!isClangOnly(flag)) {
      newArgs.add(absVal);
    }
    if (flag == '-I' || flag == '-isystem' || flag == '-F' || flag == '-Fsystem') {
      newArgs.addAll(<String>['-Xcc', flag, '-Xcc', absVal]);
    }
    return i + 2;
  }

  void addAttachedIncludeFlag(String arg) {
    String prefix;
    if (arg.startsWith('-isystem')) {
      prefix = '-isystem';
    } else if (arg.startsWith('-Fsystem')) {
      prefix = '-Fsystem';
    } else if (arg.startsWith('-F')) {
      prefix = '-F';
    } else {
      prefix = '-I';
    }

    // A bare `-I`/`-isystem`/`-F`/`-Fsystem` (no attached value) is caught by
    // the exact-match branch below instead, so `val` is never empty here.
    final String val = makePathAbsolute(directory, arg.substring(prefix.length));
    if (!isClangOnly(prefix)) {
      newArgs.add('$prefix$val');
    }
    newArgs.addAll(<String>['-Xcc', '$prefix$val']);
  }

  var i = 0;
  while (i < words.length) {
    final String arg = words[i];
    if (arg.endsWith('.swift')) {
      newArgs.add(makePathAbsolute(directory, arg));
      i += 1;
    } else if (arg == '-I' ||
        arg == '-isystem' ||
        arg == '-F' ||
        arg == '-Fsystem' ||
        arg == '-import-objc-header' ||
        arg == '-sdk') {
      i = addSeparatedIncludeFlag(i);
    } else if (arg.startsWith('-I') || arg.startsWith('-F') || arg.startsWith('-isystem')) {
      addAttachedIncludeFlag(arg);
      i += 1;
    } else {
      newArgs.add(arg);
      i += 1;
    }
  }
  return newArgs.map(quoteShellWord).join(' ');
}

/// Parses [cmd] into individual shell arguments.
///
/// An empty quoted argument (`""` or `''`) is preserved as an empty-string
/// element rather than disappearing, so callers can distinguish "argument
/// present but empty" from "argument absent".
List<String> splitShellWords(String cmd) {
  final args = <String>[];
  final buffer = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escape = false;
  var quoted = false;

  for (var i = 0; i < cmd.length; i += 1) {
    final String char = cmd[i];
    if (escape) {
      buffer.write(char);
      escape = false;
    } else if (char == r'\' && !inSingleQuote) {
      escape = true;
    } else if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      quoted = true;
    } else if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      quoted = true;
    } else if ((char == ' ' || char == '\t') && !inSingleQuote && !inDoubleQuote) {
      if (buffer.isNotEmpty || quoted) {
        args.add(buffer.toString());
        buffer.clear();
        quoted = false;
      }
    } else {
      buffer.write(char);
    }
  }
  if (buffer.isNotEmpty || quoted) {
    args.add(buffer.toString());
  }
  return args;
}

/// Quotes and escapes [arg] for safe inclusion as a shell argument.
String quoteShellWord(String arg) {
  if (arg.isEmpty) {
    return "''";
  }
  if (!arg.contains(_shellQuoteRegexp)) {
    return arg;
  }
  if (!arg.contains("'")) {
    return "'$arg'";
  }
  return r'"'
      '${arg.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}'
      r'"';
}
