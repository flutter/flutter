import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

class DecodeImageCmd extends Command {
  Uint8List data;

  DecodeImageCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeImage(data);
  }
}
