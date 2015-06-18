part of sprites;

// TODO: Actually draw images

class Sprite extends NodeWithSize {
  
  Image _image;
  bool constrainProportions = false;
  double _opacity = 1.0;
  Color colorOverlay;
  TransferMode transferMode;
  
  Sprite() {
  }
  
  Sprite.withImage(Image image) {
    pivot = new Point(0.5, 0.5);
    size = new Size(image.width.toDouble(), image.height.toDouble());
    _image = image;
  }

  double get opacity => _opacity;

  void set opacity(double opacity) {
    assert(opacity != null);
    assert(opacity >= 0.0 && opacity <= 1.0);
    _opacity = opacity;
  }

  void paint(PictureRecorder canvas) {
    canvas.save();

    // Account for pivot point
    applyTransformForPivot(canvas);

    if (_image != null && _image.width > 0 && _image.height > 0) {
      
      double scaleX = size.width/_image.width;
      double scaleY = size.height/_image.height;
      
      if (constrainProportions) {
        // Constrain proportions, using the smallest scale and by centering the image
        if (scaleX < scaleY) {
          canvas.translate(0.0, (size.height - scaleX * _image.height)/2.0);
          scaleY = scaleX;
        }
        else {
          canvas.translate((size.width - scaleY * _image.width)/2.0, 0.0);
          scaleX = scaleY;
        }
      }
      
      canvas.scale(scaleX, scaleY);

      // Setup paint object for opacity and transfer mode
      Paint paint = new Paint();
      paint.color = new Color.fromARGB((255.0*_opacity).toInt(), 255, 255, 255);
      if (colorOverlay != null) {
        paint.setColorFilter(new ColorFilter.mode(colorOverlay, TransferMode.srcATop));
      }
      if (transferMode != null) {
        paint.setTransferMode(transferMode);
      }

      canvas.drawImage(_image, 0.0, 0.0, paint);
    }
    else {
      // Paint a red square for missing texture
      canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, size.width, size.height),
          new Paint()..color = const Color.fromARGB(255, 255, 0, 0));
    }
    canvas.restore();
  }
}
