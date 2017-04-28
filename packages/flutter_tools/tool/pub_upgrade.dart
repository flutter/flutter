import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<Null> _streamStd(Stream<List<int>> source, Stdout target) => source
    .transform(SYSTEM_ENCODING.decoder)
    .transform(const LineSplitter())
    .forEach(target.writeln);

Future<Null> main() async {
  final Process process = await Process.start('pub', <String>[
    'upgrade',
    '--verbosity=error'
  ], environment: <String, String>{
    _pubEnvironmentKey: _getPubEnvironmentValue()
  });

  final List<dynamic> result =
      await Future.wait<Future<dynamic>>(<Future<dynamic>>[
    process.exitCode,
    _streamStd(process.stdout, stdout),
    _streamStd(process.stderr, stderr)
  ]);

  exitCode = result.first;
}

/// Returns the environment value that should be used when running pub.
///
/// Includes any existing environment variable, if one exists.
String _getPubEnvironmentValue() {
  final List<String> values = <String>[];

  final String existing = Platform.environment[_pubEnvironmentKey];

  if ((existing != null) && existing.isNotEmpty) {
    values.add(existing);
  }

  if (_isRunningOnBot) {
    values.add('flutter_bot');
  }

  values.add('flutter_install');

  return values.join(':');
}

/// The console environment key used by the pub tool.
const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

bool get _isRunningOnBot {
  // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
  // CHROME_HEADLESS is one property set on Flutter's Chrome Infra bots.
  return Platform.environment['TRAVIS'] == 'true' ||
      Platform.environment['BOT'] == 'true' ||
      Platform.environment['CONTINUOUS_INTEGRATION'] == 'true' ||
      Platform.environment['CHROME_HEADLESS'] == '1';
}
