import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

Future<void> main() async {
  final io.Process process = await io.Process.start(
    'dart',
    const <String>['bin/flutter_tools.dart', 'doctor', '-v', '--android-licenses'],
  );
  await process.stdin.close();
  final StreamSubscription<String> subscription = process.stdout
      .transform<String>(utf8.decoder)
      .listen((String out) => print('[STDOUT] $out'));
  final int code = await process.exitCode;
  await subscription.cancel();
  final String stderr = await process.stderr.transform<String>(utf8.decoder).join();
  print('code: $code');
  if (stderr.isNotEmpty) print('stderr: $stderr');
}
