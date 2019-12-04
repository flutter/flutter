/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///  chips contain related descriptive text or categories.
///  *   [FilterChip], uses tags or descriptive words as a way to filter content.
///  - [ActionChip], represents an action related to primary content.
///  * [CircleAvatar], which shows images or initials of entities.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>

import 'dart:async';
import 'dart:io';

Future<List<FileSystemEntity>> dirContents(Directory dir, {bool recursive = false, bool includeDirs = true, RegExp matcher}) {
  final List<FileSystemEntity> files = <FileSystemEntity>[];
  final Completer<List<FileSystemEntity>> completer = Completer<List<FileSystemEntity>>();
  final Stream<FileSystemEntity> lister = dir.list(recursive: recursive);
  lister.listen(
    (FileSystemEntity file) {
      if (!includeDirs && file is Directory) {
        return;
      }
      if (matcher == null || matcher.hasMatch(file.uri.pathSegments.last)) {
        files.add(file);
      }
    },
    // should also register onError
    onDone: () => completer.complete(files),
  );
  return completer.future;
}

Future<void> main(List<String> args) async {
  final RegExp docCommentRe = RegExp(r'(?<prefix>\s*\/\/\/)\s*(?<text>.*)');
  final RegExp bulletRe = RegExp(r'(?<prefix>\s*\/\/\/)(?<bullet>\s*[-*])?\s+(?<text>.*)');
  final RegExp seeAlsoRe = RegExp(r'(?<prefix>\s*\/\/\/)\s*see\s+also:?\s*', caseSensitive: false);
  final String directoryName = args.isNotEmpty ? args[0] : '.';
  final List<FileSystemEntity> entities = await dirContents(Directory(directoryName), matcher: RegExp(r'.*\.dart$'), includeDirs: false);
  for (FileSystemEntity entity in entities) {
    final File file = entity;
    final File tmpFile = File('${entity.path}.gtmp');
    final RandomAccessFile output = tmpFile.openSync(mode: FileMode.write);
    print('>>>>>>> Working on ${file.path} <<<<<<<<<<<<<');
    final List<String> contents = file.readAsLinesSync();
    bool inSeeAlso = false;
    bool nextLineBlank = false;

    for (String line in contents) {
      final RegExpMatch commentMatch = docCommentRe.firstMatch(line);
      final bool inDocComment = commentMatch != null;
      final RegExpMatch seeAlsoMatch = seeAlsoRe.firstMatch(line);
      if (nextLineBlank && inDocComment) {
        if (commentMatch.namedGroup('text').isNotEmpty) {
          // Add an extra blank comment line between 'See also:' and the bullets if there wasn't one already.
          output.writeStringSync('${commentMatch.namedGroup('prefix')}\n');
        }
        nextLineBlank = false;
      }
      if (seeAlsoMatch != null) {
        line = '${seeAlsoMatch.namedGroup('prefix')} See also:';
        inSeeAlso = true;
        nextLineBlank = true;
      } else {
        if (inSeeAlso) {
          if (!inDocComment) {
            inSeeAlso = false;
          } else {
            final RegExpMatch bulletMatch = bulletRe.firstMatch(line);
            if (bulletMatch != null) {
              line = '${bulletMatch.namedGroup('prefix')}  ${bulletMatch.namedGroup('bullet') != null ? '*' : ' '} ${bulletMatch.namedGroup('text')}';
            }
          }
        }
      }
      output.writeStringSync('$line\n');
    }
    file.deleteSync();
    tmpFile.renameSync(file.path);
  }
}
