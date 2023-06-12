import 'package:pubspec_parse/src/dependency.dart';
import 'package:test/test.dart';

void main() {
  for (var item in {
    'git@github.com:google/grinder.dart.git':
        'ssh://git@github.com/google/grinder.dart.git',
    'host.xz:path/to/repo.git/': 'ssh://host.xz/path/to/repo.git/',
    'http:path/to/repo.git/': 'ssh://http/path/to/repo.git/',
    'file:path/to/repo.git/': 'ssh://file/path/to/repo.git/',
    './foo:bar': 'foo%3Abar',
    '/path/to/repo.git/': '/path/to/repo.git/',
    'file:///path/to/repo.git/': 'file:///path/to/repo.git/',
  }.entries) {
    test(item.key, () {
      final uri = parseGitUri(item.key);

      printOnFailure(
        [uri.scheme, uri.userInfo, uri.host, uri.port, uri.path].join('\n'),
      );

      expect(uri, Uri.parse(item.value));
    });
  }
}
