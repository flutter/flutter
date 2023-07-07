import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

Future<ExecuteResult> executeCommandAsync(Command? command) async {
  await command?.execute();
  return ExecuteResult(
      command?.outputImage, command?.outputBytes, command?.outputObject);
}

Future<Image?> executeCommandImage(Command? command) async {
  await command?.execute();
  return command?.outputImage;
}

Future<Image?> executeCommandImageAsync(Command? command) async {
  await command?.execute();
  return command?.outputImage;
}

Future<Uint8List?> executeCommandBytes(Command? command) async {
  await command?.execute();
  return command?.outputBytes;
}

Future<Uint8List?> executeCommandBytesAsync(Command? command) async {
  await command?.execute();
  return command?.outputBytes;
}
