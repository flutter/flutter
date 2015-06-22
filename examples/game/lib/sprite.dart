part of sprites;

/// A Sprite is a [Node] that renders a bitmap image to the screen.
class Sprite extends NodeWithSize {

  /// The image that the sprite will render to screen.
  ///
  /// If the image is null, the sprite will be rendered as a red square
  /// marking the bounds of the sprite.
  ///
  ///     mySprite.image = myImage;
  Image image;

  /// If true, constrains the proportions of the image by scaling it down, if its proportions doesn't match the [size].
  ///
  ///     mySprite.constrainProportions = true;
  bool constrainProportions = false;
  double _opacity = 1.0;

  /// The color to draw on top of the sprite, null if no color overlay is used.
  ///
  ///     // Color the sprite red
  ///     mySprite.colorOverlay = new Color(0x77ff0000);
  Color colorOverlay;

  /// The transfer mode used when drawing the sprite to screen.
  ///
  ///     // Add the colors of the sprite with the colors of the background
  ///     mySprite.transferMode = TransferMode.plusMode;
  TransferMode transferMode;

  /// Creates a new sprite from the provided [image].
  ///
  /// var mySprite = new Sprite(myImage);
  Sprite([Image this.image]) {
    pivot = new Point(0.5, 0.5);
    if (image != null) {
      size = new Size(image.width.toDouble(), image.height.toDouble());
    }
  }

  /// The opacity of the sprite in the range 0.0 to 1.0.
  ///
  ///     mySprite.opacity = 0.5;
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

    if (image != null && image.width > 0 && image.height > 0) {
      
      double scaleX = size.width/image.width;
      double scaleY = size.height/image.height;
      
      if (constrainProportions) {
        // Constrain proportions, using the smallest scale and by centering the image
        if (scaleX < scaleY) {
          canvas.translate(0.0, (size.height - scaleX * image.height)/2.0);
          scaleY = scaleX;
        }
        else {
          canvas.translate((size.width - scaleY * image.width)/2.0, 0.0);
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

      canvas.drawImage(image, 0.0, 0.0, paint);
    }
    else {
      // Paint a red square for missing texture
      canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, size.width, size.height),
          new Paint()..color = const Color.fromARGB(255, 255, 0, 0));
    }
    canvas.restore();
  }
}
