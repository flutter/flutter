import 'dart:convert';
import 'dart:html';

import 'package:image/image.dart';

void main() {
  final theImg = document.getElementById('testimage') as ImageElement;

  final cvs = document.createElement('canvas') as CanvasElement
    ..width = theImg.width
    ..height = theImg.height;

  final ctx = cvs.getContext('2d') as CanvasRenderingContext2D
    ..drawImage(theImg, 0, 0);

  final bytes = ctx.getImageData(0, 0, cvs.width!, cvs.height!).data;

  final image = Image.fromBytes(
      width: cvs.width!,
      height: cvs.height!,
      bytes: bytes.buffer,
      numChannels: 4);

  final jpg = encodeJpg(image, quality: 25);

  final jpg64 = base64Encode(jpg);
  final img = ImageElement(src: 'data:image/jpeg;base64,$jpg64');
  document.body!.append(img);
}
