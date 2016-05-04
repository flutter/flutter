part of flutter_sprites;

/// A NineSliceSprite is similar to a [Sprite], but it it can strech its
/// inner area to fit the size of the [Node]. This is ideal for fast drawing
/// of things like buttons.
class NineSliceSprite extends NodeWithSize with SpritePaint {

  /// Creates a new NineSliceSprite from the privided [texture], [size], and
  /// texture [insets].
  NineSliceSprite(Texture texture, Size size, EdgeInsets insets) : super(size) {
    assert(texture != null && !texture.rotated);
    assert(size != null);
    assert(insets != null);
    pivot = const Point(0.5, 0.5);
    this.texture = texture;
    this.insets = insets;
  }

  /// Creates a new NineSliceSprite from the provided [image], [size], and
  /// texture [insets].
  NineSliceSprite.fromImage(ui.Image image, Size size, EdgeInsets insets)
    : this(new Texture(image), size, insets);

  /// The texture that the sprite will render to screen. Cannot be null.
  ///
  ///     my9Sprite.texture = myTexture;
  Texture get texture => _texture;

  Texture _texture;

  void set texture(Texture texture) {
    _texture = texture;
    _isDirty = true;
    if (texture == null) {
      _cachedPaint = new Paint();
    } else {
      Matrix4 matrix = new Matrix4.identity();
      ImageShader shader = new ImageShader(texture.image,
        TileMode.repeated, TileMode.repeated, matrix.storage);

      _cachedPaint = new Paint()
        ..shader = shader;
    }
  }

  /// The insets of the texture as normalized values. The insets define the
  /// areas of the texture that will not be deformed as the sprite stretches.
  EdgeInsets get insets => _insets;

  EdgeInsets _insets;

  void set insets(EdgeInsets insets) {
    assert(insets != null);
    _insets = insets;
    _isDirty = true;
  }

  /// If true, the center part of the sprite will be drawn, this is the default
  /// behavior.
  bool get drawCenterPart => _drawCenterPart;

  bool _drawCenterPart = true;

  void set drawCenterPart(bool drawCenterPart) {
    _drawCenterPart = drawCenterPart;
    _isDirty = true;
  }

  @override
  void set size(Size size) {
    super.size = size;
    _isDirty = true;
  }

  Paint _cachedPaint = new Paint()
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = false;

  // Cached values.
  bool _isDirty = true;
  List<Point> _vertices;
  List<Point> _textureCoordinates;
  List<Color> _colors;
  List<int> _indices;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    // Setup paint object for opacity and transfer mode.
    _updatePaint(_cachedPaint);

    if (_isDirty) {
      // Calcuate vertices and indices.
      _vertices = <Point>[
        Point.origin,

      ];

      // Texture width and height.
      double tw = texture.frame.width;
      double th = texture.frame.height;
      _textureCoordinates = <Point>[];
      _vertices = <Point>[];
      _colors = <Color>[];

      for (int y = 0; y < 4; y += 1) {
        double vy;
        double ty;

        switch(y) {
          case 0:
            vy = 0.0;
            ty = texture.frame.top;
            break;
          case 1:
            vy = insets.top * th;
            ty = texture.frame.top + insets.top * th;
            break;
          case 2:
            vy = size.height - insets.bottom * th;
            ty = texture.frame.bottom - insets.bottom * th;
            break;
          case 3:
            vy = size.height;
            ty = texture.frame.bottom;
            break;
        }

        for (int x = 0; x < 4; x += 1) {
          double vx;
          double tx;

          switch(x) {
            case 0:
              vx = 0.0;
              tx = texture.frame.left;
              break;
            case 1:
              vx = insets.left * tw;
              tx = texture.frame.left + insets.left * tw;
              break;
            case 2:
              vx = size.width - insets.right * tw;
              tx = texture.frame.right - insets.right * tw;
              break;
            case 3:
              vx = size.width;
              tx = texture.frame.right;
              break;
          }

          _vertices.add(new Point(vx, vy));
          _textureCoordinates.add(new Point(tx, ty));
          _colors.add(const Color(0xffffffff));
        }
      }

      // Build indices.
      _indices = <int>[];
      for (int y = 0; y < 3; y += 1) {
        for (int x = 0; x < 3; x += 1) {
          // Check if we should skip the middle rectangle.
          if (!drawCenterPart && x == 1 && y == 1)
            continue;

          // Add a rectangle (two triangles).
          int index = y * 4 + x;

          _indices.add(index);
          _indices.add(index + 1);
          _indices.add(index + 4);

          _indices.add(index + 1);
          _indices.add(index + 5);
          _indices.add(index + 4);
        }
      }
    }

    canvas.drawVertices(
      VertexMode.triangles,
      _vertices,
      _textureCoordinates,
      _colors,
      TransferMode.modulate,
      _indices,
      _cachedPaint
    );
  }
}
