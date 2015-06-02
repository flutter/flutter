part of sprites;

// TODO: Actually draw images

class SpriteNode extends TransformNode {
  
  Image _image;
  bool constrainProportions = false;
  
  SpriteNode() {
    this.pivot = new Vector2(0.5, 0.5);
  }
  
  SpriteNode.withImage(Image image) : super() {
    this.pivot = new Vector2(0.5, 0.5);
    _image = image;
  }
  
  void paint(PictureRecorder canvas) {

    if (_image != null && _image.width > 0 && _image.height > 0) {
      canvas.save();
      
      double scaleX = _width/_image.width;
      double scaleY = _height/_image.height;
      
      if (constrainProportions) {
        // Constrain proportions, using the smallest scale and by centering the image
        if (scaleX < scaleY) {
          canvas.translate(0.0, (_height - scaleX * _image.height)/2.0);
          scaleY = scaleX;
        }
        else {
          canvas.translate((_width - scaleY * _image.width)/2.0, 0.0);
          scaleX = scaleY;
        }
      }
      
      canvas.scale(scaleX, scaleY);
      canvas.drawImage(_image, 0.0, 0.0, new Paint()..setARGB(255, 255, 255, 255));
      canvas.restore();
    }
    else {
      // Paint a red square for missing texture
      canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, this.width, this.height),
          new Paint()..setARGB(255, 255, 0, 0));
    }
  }
  
}