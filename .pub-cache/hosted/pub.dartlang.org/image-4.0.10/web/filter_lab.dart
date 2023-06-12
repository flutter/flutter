import 'dart:html';

import 'package:image/image.dart' as img;

late ImageData filterImageData;
late CanvasElement canvas;
late DivElement logDiv;
late img.Image origImage;

void _addControl(String label, String value, DivElement parent,
    void Function(double) callback) {
  final amountLabel = LabelElement()..text = '$label:';
  final amountEdit = InputElement()
    ..value = value
    ..id = '${label}_edit';
  amountEdit.onChange.listen((e) {
    try {
      final d = double.parse(amountEdit.value!);
      callback(d);
    } catch (e) {
      //print(e);
    }
  });
  amountLabel.htmlFor = '${label}_edit';
  parent.append(amountLabel)
    ..append(amountEdit)
    ..append(ParagraphElement());
}

void testSepia() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Sepia';
  sidebar.children.add(label);

  num amount = 1.0;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.sepia(image, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());

    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    apply();
  });

  apply();
}

void testSobel() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Sepia';
  sidebar.children.add(label);

  num amount = 1.0;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.sobel(image, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    apply();
  });

  apply();
}

void testGaussian() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Gaussian Blur';
  sidebar.children.add(label);

  var radius = 5;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.gaussianBlur(image, radius: radius);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Radius', radius.toString(), sidebar, (num v) {
    radius = v.toInt();
    apply();
  });

  apply();
}

void testVignette() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Vignette';
  sidebar.children.add(label);

  num start = 0.3;
  num end = 0.75;
  num amount = 1.0;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.vignette(image, start: start, end: end, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Start', start.toString(), sidebar, (num v) {
    start = v;
    apply();
  });

  _addControl('End', end.toString(), sidebar, (num v) {
    end = v;
    apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    apply();
  });

  apply();
}

void testPixelate() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Pixelate';
  sidebar.children.add(label);

  var blockSize = 5;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.pixelate(image, size: blockSize);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('blockSize', blockSize.toString(), sidebar, (num v) {
    blockSize = v.toInt();
    apply();
  });

  apply();
}

void testColorOffset() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Pixelate';
  sidebar.children.add(label);

  var red = 0;
  var green = 0;
  var blue = 0;
  var alpha = 0;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);
    image = img.colorOffset(image,
        red: red, green: green, blue: blue, alpha: alpha);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('red', red.toString(), sidebar, (num v) {
    red = v.toInt();
    apply();
  });

  _addControl('green', red.toString(), sidebar, (num v) {
    green = v.toInt();
    apply();
  });

  _addControl('blue', red.toString(), sidebar, (num v) {
    blue = v.toInt();
    apply();
  });

  _addControl('alpha', red.toString(), sidebar, (num v) {
    alpha = v.toInt();
    apply();
  });

  apply();
}

void testAdjustColor() {
  final sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  final label = Element.tag('h1')..text = 'Adjust Color';
  sidebar.children.add(label);

  num contrast = 1.0;
  num saturation = 1.0;
  num brightness = 1.0;
  num gamma = 0.8;
  num exposure = 0.3;
  num hue = 0.0;
  num amount = 1.0;

  void apply() {
    final t = Stopwatch()..start();
    var image = img.Image.from(origImage);

    image = img.adjustColor(image,
        contrast: contrast,
        saturation: saturation,
        brightness: brightness,
        gamma: gamma,
        exposure: exposure,
        hue: hue,
        amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.toUint8List());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width!, canvas.height!);
    canvas.context2D.putImageData(filterImageData, 0, 0);

    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    //print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Contrast', contrast.toString(), sidebar, (num v) {
    contrast = v;
    apply();
  });

  _addControl('Saturation', saturation.toString(), sidebar, (num v) {
    saturation = v;
    apply();
  });

  _addControl('Brightness', brightness.toString(), sidebar, (num v) {
    brightness = v;
    apply();
  });

  _addControl('Gamma', gamma.toString(), sidebar, (num v) {
    gamma = v;
    apply();
  });

  _addControl('Exposure', exposure.toString(), sidebar, (num v) {
    exposure = v;
    apply();
  });

  _addControl('Hue', hue.toString(), sidebar, (num v) {
    hue = v;
    apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    apply();
  });

  apply();
}

void main() {
  canvas = document.querySelector('#filter_canvas') as CanvasElement;
  logDiv = document.querySelector('#log') as DivElement;

  final menu = document.querySelector('#FilterType') as SelectElement;
  menu.onChange.listen((e) {
    if (menu.value == 'Pixelate') {
      testPixelate();
    } else if (menu.value == 'Sepia') {
      testSepia();
    } else if (menu.value == 'Gaussian') {
      testGaussian();
    } else if (menu.value == 'Adjust Color') {
      testAdjustColor();
    } else if (menu.value == 'Sobel') {
      testSobel();
    } else if (menu.value == 'Vignette') {
      testVignette();
    } else if (menu.value == 'Color Offset') {
      testColorOffset();
    }
  });

  final image = ImageElement(src: 'res/big_buck_bunny.jpg');
  image.onLoad.listen((e) {
    final c = CanvasElement()
      ..width = image.width
      ..height = image.height
      ..context2D.drawImage(image, 0, 0);

    final imageData =
        c.context2D.getImageData(0, 0, image.width!, image.height!);

    origImage = img.Image.fromBytes(
        width: image.width!,
        height: image.height!,
        bytes: imageData.data.buffer,
        numChannels: 4);

    canvas.width = image.width;
    canvas.height = image.height;
    filterImageData =
        canvas.context2D.createImageData(image.width, image.height);

    testSepia();
  });
}
