import 'dart:convert';
import 'dart:html';

import 'package:image/image.dart';

late InputElement fileInput;

void main() {
  // There are at least two ways to get a file into an html dart app:
  // using a file Input element, or an AJAX HttpRequest.

  // This example demonstrates using a file Input element.
  fileInput = querySelector('#file') as InputElement;

  fileInput.addEventListener('change', onFileChanged);
}

/// Called when the user has selected a file.
void onFileChanged(Event event) {
  final files = fileInput.files as FileList;
  final file = files.item(0)!;

  final reader = FileReader();
  reader.addEventListener('load', onFileLoaded);
  reader.readAsArrayBuffer(file);
}

/// Called when the file has been read.
void onFileLoaded(Event event) {
  final reader = event.currentTarget as FileReader;

  final bytes = reader.result as List<int>;

  // Find a decoder that is able to decode the given file contents.
  final decoder = findDecoderForData(bytes);
  if (decoder == null) {
    print('Could not find format decoder for file');
    return;
  }

  // If a decoder was found, decode the file contents into an image.
  final image = decoder.decodeImage(bytes);

  // If the image was able to be decoded, we can display it in a couple
  // different ways. We could encode it to a format that can be displayed
  // by an IMG image element (like PNG or JPEG); or we could draw it into
  // a canvas.
  if (image != null) {
    // Add a separator to the html page
    document.body!.append(ParagraphElement());

    // Draw the image into a canvas. First create a canvas at the correct
    // resolution.
    final c = CanvasElement();
    document.body!.append(c);
    c.width = image.width;
    c.height = image.height;

    // Create a buffer that the canvas can draw.
    final d = c.context2D.createImageData(c.width, c.height);
    // Fill the buffer with our image data.
    d.data.setRange(0, d.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    c.context2D.putImageData(d, 0, 0);

    // OR we could use an IMG element to display the image.
    // This requires encoding it to a common format (like PNG), base64 encoding
    // the encoded image, and using a data url for the img src.

    // encode the image to a PNG
    final png = encodePng(image);
    // base64 encode the png
    final png64 = base64Encode(png);
    final img = ImageElement(src: 'data:image/png;base64,$png64');
    document.body!.append(img);
  }

  return;
}
