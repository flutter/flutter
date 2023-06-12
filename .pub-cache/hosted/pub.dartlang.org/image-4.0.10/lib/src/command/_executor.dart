import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

Future<ExecuteResult> executeCommandAsync(Command? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Image? executeCommandImage(Command? command) =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Future<Image?> executeCommandImageAsync(Command? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Uint8List? executeCommandBytes(Command? command) =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Future<Uint8List?> executeCommandBytesAsync(Command? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');
