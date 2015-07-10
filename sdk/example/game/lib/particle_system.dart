part of sprites;

class _Particle {
  Vector2 pos;
  Vector2 startPos;

  double colorPos;
  double deltaColorPos;

  double size;
  double deltaSize;

  double rotation;
  double deltaRotation;

  double timeToLive;

  Vector2 dir;
  double radialAccel;
  double tangentialAccel;

  ColorSequence colorSequence;
}


class ParticleSystem extends Node {

  Texture texture;

  double life;
  double lifeVar;

  Point posVar;

  double startSize;
  double startSizeVar;

  double endSize;
  double endSizeVar;

  double startRotation;
  double startRotationVar;

  double endRotation;
  double endRotationVar;

  bool rotateToMovement;

  double direction;
  double directionVar;

  double speed;
  double speedVar;

  double radialAcceleration;
  double radialAccelerationVar;

  double tangentialAcceleration;
  double tangentialAccelerationVar;

  Vector2 gravity;

  int maxParticles;
  int numParticlesToEmit;
  double emissionRate;
  bool autoRemoveOnFinish;

  ColorSequence colorSequence;
  int alphaVar;
  int redVar;
  int greenVar;
  int blueVar;
  TransferMode colorTransferMode;
  TransferMode transferMode;

  List<_Particle> _particles;

  double _emitCounter;
  double _elapsedTime;
  int _numEmittedParticles = 0;

  Math.Random _rand;

  ParticleSystem(this.texture,
                 {this.life: 1.5,
                  this.lifeVar: 1.0,
                  this.posVar: Point.origin,
                  this.startSize: 2.5,
                  this.startSizeVar: 0.5,
                  this.endSize: 0.0,
                  this.endSizeVar: 0.0,
                  this.startRotation: 0.0,
                  this.startRotationVar: 0.0,
                  this.endRotation: 0.0,
                  this.endRotationVar: 0.0,
                  this.rotateToMovement : false,
                  this.direction: 0.0,
                  this.directionVar: 360.0,
                  this.speed: 100.0,
                  this.speedVar: 50.0,
                  this.radialAcceleration: 0.0,
                  this.radialAccelerationVar: 0.0,
                  this.tangentialAcceleration: 0.0,
                  this.tangentialAccelerationVar: 0.0,
                  this.gravity,
                  this.maxParticles: 100,
                  this.emissionRate: 50.0,
                  this.colorSequence,
                  this.alphaVar: 0,
                  this.redVar: 0,
                  this.greenVar: 0,
                  this.blueVar: 0,
                  this.colorTransferMode: TransferMode.multiply,
                  this.transferMode: TransferMode.plus,
                  this.numParticlesToEmit: 0,
                  this.autoRemoveOnFinish: true}) {
    _particles = new List<_Particle>();
    _rand = new Math.Random();
    _emitCounter = 0.0;
    _elapsedTime = 0.0;
    if (gravity == null) gravity = new Vector2.zero();
    if (colorSequence == null) colorSequence = new ColorSequence.fromStartAndEndColor(new Color(0xffffffff), new Color(0x00ffffff));
  }

  void update(double dt) {

    // Create new particles
    double rate = 1.0 / emissionRate;

    if (_particles.length < maxParticles) {
      _emitCounter += dt;
    }

    while(_particles.length < maxParticles
       && _emitCounter > rate
       && (numParticlesToEmit == 0 || _numEmittedParticles < numParticlesToEmit)) {
      // Add a new particle
      _addParticle();
      _emitCounter -= rate;
    }

    _elapsedTime += dt;

    // Iterate over all particles
    for (int i = _particles.length -1; i >= 0; i--) {
      _Particle particle = _particles[i];

      // Manage life time
      particle.timeToLive -= dt;
      if (particle.timeToLive <= 0) {
        _particles.removeAt(i);
        continue;
      }

      // Update the particle

      // Radial acceleration
      Vector2 radial;
      if (particle.pos[0] != 0 || particle.pos[1] != 0) {
        radial = new Vector2.copy(particle.pos).normalize();
      } else {
        radial = new Vector2.zero();
      }
      Vector2 tangential = new Vector2.copy(radial);
      radial.scale(particle.radialAccel);

      // Tangential acceleration
      double newY = tangential.x;
      tangential.x = -tangential.y;
      tangential.y = newY;
      tangential.scale(particle.tangentialAccel);

      // (gravity + radial + tangential) * dt
      Vector2 accel = (gravity + radial + tangential).scale(dt);
      particle.dir += accel;
      particle.pos += new Vector2.copy(particle.dir).scale(dt);

      // Size
      particle.size = Math.max(particle.size + particle.deltaSize * dt, 0.0);

      // Angle
      particle.rotation += particle.deltaRotation * dt;

      // Color
      particle.colorPos = Math.min(particle.colorPos + particle.deltaColorPos * dt, 1.0);
    }

    if (autoRemoveOnFinish && _particles.length == 0 && _numEmittedParticles > 0) {
      if (parent != null) removeFromParent();
    }
  }

  void _addParticle() {

    _Particle particle = new _Particle();

    // Time to live
    particle.timeToLive = Math.max(life + lifeVar * randMinus1To1(), 0.0);

    // Position
    Point srcPos = Point.origin;
    particle.pos = new Vector2(srcPos.x + posVar.x * randMinus1To1(),
                               srcPos.y + posVar.y * randMinus1To1());

    // Size
    particle.size = Math.max(startSize + startSizeVar * randMinus1To1(), 0.0);
    double endSizeFinal = Math.max(endSize + endSizeVar * randMinus1To1(), 0.0);
    particle.deltaSize = (endSizeFinal - particle.size) / particle.timeToLive;

    // Rotation
    particle.rotation = startRotation + startRotationVar * randMinus1To1();
    double endRotationFinal = endRotation + endRotationVar * randMinus1To1();
    particle.deltaRotation = (endRotationFinal - particle.rotation) / particle.timeToLive;

    // Direction
    double dirRadians = convertDegrees2Radians(direction + directionVar * randMinus1To1());
    Vector2 dirVector = new Vector2(Math.cos(dirRadians), Math.sin(dirRadians));
    double speedFinal = speed + speedVar * randMinus1To1();
    particle.dir = dirVector.scale(speedFinal);

    // Radial acceleration
    particle.radialAccel = radialAcceleration + radialAccelerationVar * randMinus1To1();

    // Tangential acceleration
    particle.tangentialAccel = tangentialAcceleration + tangentialAccelerationVar * randMinus1To1();

    // Color
    particle.colorPos = 0.0;
    particle.deltaColorPos = 1.0 / particle.timeToLive;

    if (alphaVar != 0 || redVar != 0 || greenVar != 0 || blueVar != 0) {
      particle.colorSequence = new ColorSequence.copyWithVariance(colorSequence, alphaVar, redVar, greenVar, blueVar);
    }

    _particles.add(particle);
    _numEmittedParticles++;
  }

  void paint(PaintingCanvas canvas) {

    List<RSTransform> transforms = [];
    List<Rect> rects = [];
    List<Color> colors = [];

    for (_Particle particle in _particles) {
      // Transform
      double scos;
      double ssin;
      if (rotateToMovement) {
        double extraRotation = Math.atan2(particle.dir[1], particle.dir[0]);
        scos = Math.cos(convertDegrees2Radians(particle.rotation) + extraRotation) * particle.size;
        ssin = Math.sin(convertDegrees2Radians(particle.rotation) + extraRotation) * particle.size;
      } else {
        scos = Math.cos(convertDegrees2Radians(particle.rotation)) * particle.size;
        ssin = Math.sin(convertDegrees2Radians(particle.rotation)) * particle.size;
      }
      RSTransform transform = new RSTransform(scos, ssin, particle.pos[0], particle.pos[1]);
      transforms.add(transform);

      // Rect
      Rect rect = texture.frame;
      rects.add(rect);

      // Color
      Color particleColor;
      if (particle.colorSequence != null) {
        particleColor = particle.colorSequence.colorAtPosition(particle.colorPos);
      } else {
        particleColor = colorSequence.colorAtPosition(particle.colorPos);
      }
      colors.add(particleColor);
    }

    drawAtlas(canvas, texture.image, transforms, rects, colors, TransferMode.modulate,
              new Paint()..setTransferMode(transferMode));
  }

  double randMinus1To1() => _rand.nextDouble() * 2.0 - 1.0;
}

// TODO: Needs bindings to Skia method in SkCanvas (exclude canvas parameter)
void drawAtlas(Canvas canvas, Image image, List<RSTransform> transforms, List<Rect> rects, List<Color> colors,
               TransferMode transferMode, Paint paint) {
  assert(transforms.length == rects.length && transforms.length == colors.length);

  Texture mainTexture = new Texture(image);

  for (int i = 0; i < transforms.length; i++) {
    RSTransform transform = transforms[i];
    Rect rect = rects[i];
    Color color = colors[i];

    canvas.save();

    Matrix4 matrix = new Matrix4(transform.scos, transform.ssin, 0.0, 0.0,
                                -transform.ssin, transform.scos, 0.0, 0.0,
                                0.0, 0.0, 1.0, 0.0,
                                transform.tx, transform.ty, 0.0, 1.0);
    canvas.concat(matrix.storage);

    paint.setColorFilter(new ColorFilter.mode(color, transferMode));
    paint.color = color;

    Texture texture = mainTexture.textureFromRect(rect);
    texture.drawTexture(canvas, new Point(-texture.size.width/2.0, -texture.size.height/2.0), paint);

    canvas.restore();
  }
}

// TODO: Needs bindings to Skia SkRSXform
class RSTransform {
  double scos;
  double ssin;
  double tx;
  double ty;

  RSTransform(this.scos, this.ssin, this.tx, this.ty);
}
