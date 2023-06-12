// import 'package:flutter_driver/flutter_driver.dart';
// import 'package:test/test.dart';

// void main() {
//   group('simple functionality', () {
//     final url1Finder = find.byValueKey('url1');

//     FlutterDriver? driver;

//     // Connect to the Flutter driver before running any tests.
//     setUpAll(() async {
//       driver = await FlutterDriver.connect();
//     });

//     // Close the connection to the driver after the tests have completed.
//     tearDownAll(() async {
//       if (driver != null) {
//         driver?.close();
//       }
//     });

//     test('simplest test', () async {
//       expect(await driver?.getText(url1Finder),
//           'Sample 1 (https://luan.xyz/files/audio/ambient_c_motion.mp3)');
//     });
//   });
// }
