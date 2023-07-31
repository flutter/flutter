// import 'dart:io';

// import 'package:archive/archive_io.dart';

// void madeBackup() {
//   var encoder = ZipFileEncoder();
//   encoder.zipDirectory(Directory.current, filename: 'backup.zip');
// }

// void restoreBackup() {
//   // final file = File(Directory.current.path + '/backup.zip');
//   // final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());

//   // Extract the contents of the Zip archive to disk.
//   // for (final file in archive) {
//   //   final filename = file.name;
//   //   if (file.isFile) {
//   //     final data = file.content as List<int>;
//   //     File('out/' + filename)
//   //       ..createSync(recursive: true)
//   //       ..writeAsBytesSync(data);
//   //   } else {
//   //     Directory('out/' + filename)..create(recursive: true);
//   //   }
//   // }
// }
