import 'dart:io' show Platform;

void main() {
  print('Main, woohoo');
  String toolPath = '/src/mojo/src/sky/sdk/packages/sky/bin/sky';

  Process.run(toolPath, []).then((ProcessResult results) {
    print(results.stdout);
  });
}
