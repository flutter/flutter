import 'package:browser_launcher/browser_launcher.dart';

const _googleUrl = 'https://www.google.com/';
const _googleImagesUrl = 'https://www.google.com/imghp?hl=en';

Future<void> main() async {
  // Launches a chrome browser with two tabs open to [_googleUrl] and
  // [_googleImagesUrl].
  await Chrome.start([_googleUrl, _googleImagesUrl]);
  print('launched Chrome');

  // Pause briefly before opening Chrome with a debug port.
  await Future.delayed(Duration(seconds: 3));

  // Launches a chrome browser open to [_googleUrl]. Since we are launching with
  // a debug port, we will use a variety of different launch configurations,
  // such as launching in a new browser.
  final chrome = await Chrome.startWithDebugPort([_googleUrl], debugPort: 8888);
  print('launched Chrome with a debug port');

  // When running this dart code, observe that the browser stays open for 3
  // seconds before we close it.
  await Future.delayed(Duration(seconds: 3));

  await chrome.close();
  print('closed Chrome');
}
