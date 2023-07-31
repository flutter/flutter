import 'dart:io' as io;

void main() async {
  final timer = Stopwatch()..start();

  final pathList = io.File('files.txt').readAsStringSync().split('\n');
  var contentLength = 0;

  if (1 == 0) {
    await Future.wait(
      pathList.map(
        (path) async {
          // return io.File(path).readAsString().then((content) {
          //   contentLength += content.length;
          // });
          try {
            final content = await io.File(path).readAsString();
            contentLength += content.length;
          } catch (_) {}
          // return io.File(path).readAsString().onError(
          //   (error, stackTrace) {
          //     print('error');
          //     return '';
          //   },
          // );
        },
      ),
    );
  } else {
    for (final path in pathList) {
      try {
        contentLength += io.File(path).readAsStringSync().length;
      } catch (_) {}
    }
  }

  timer.stop();
  print('Time: ${timer.elapsedMilliseconds} ms');
  print('Content: $contentLength bytes');
}
