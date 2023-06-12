import 'dart:io';
import 'package:archive/archive_io.dart';

void main() {
  // Read the Zip file from disk.
  final bytes = File('test.zip').readAsBytesSync();

  // Decode the Zip file
  final archive = ZipDecoder().decodeBytes(bytes);

  // Extract the contents of the Zip archive to disk.
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('out/' + filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('out/' + filename).create(recursive: true);
    }
  }

  // Encode the archive as a BZip2 compressed Tar file.
  final tarData = TarEncoder().encode(archive);
  final tarBz2 = BZip2Encoder().encode(tarData);

  // Write the compressed tar file to disk.
  final fp = File('test.tbz');
  fp.writeAsBytesSync(tarBz2);

  // Zip a directory to out.zip using the zipDirectory convenience method
  var encoder = ZipFileEncoder();
  encoder.zipDirectory(Directory('out'), filename: 'out.zip');

  // Manually create a zip of a directory and individual files.
  encoder.create('out2.zip');
  encoder.addDirectory(Directory('out'));
  encoder.addFile(File('test.zip'));
  encoder.close();
}
