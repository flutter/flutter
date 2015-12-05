part of flutter_sprites;

class _Particle {
  Vector2 pos;
  Vector2 startPos;

  double colorPos = 0.0;
  double deltaColorPos = 0.0;

  double size = 0.0;
  double deltaSize = 0.0;

  double rotation = 0.0;
  double deltaRotation = 0.0;

  double timeToLive = 0.0;

  Vector2 dir;

  _ParticleAccelerations accelerations;

  Float64List simpleColorSequence;

  ColorSequence colorSequence;
}

class _ParticleAccelerations {
  double radialAccel = 0.0;
  double tangentialAccel = 0.0;
}

/// A particle system uses a large number of sprites to draw complex effects
/// such as explosions, smoke, rain, or fire. There are a number of properties
/// that can be set to control the look of the particle system. Most of the
/// properties have a base value and a variance, these values are used when
/// creating each individual particle. For instance, by setting the [life] to
/// 1.0 and the [lifeVar] to 0.5, each particle will get a life time in the
/// range of 0.5 to 1.5.
///
/// Particles are created and added to the system at [emissionRate], but the
/// number of particles can never exceed the [maxParticles] limit.
class ParticleSystem extends Node {

  /// The texture used to draw each individual sprite.
  Texture texture;

  /// The time in seconds each particle will be alive.
  double life;

  /// Variance of the [life] property.
  double lifeVar;

  /// The variance of a particles initial position.
  Point posVar;

  /// The start scale of each individual particle.
  double startSize;

  /// Variance of the [startSize] property.
  double startSizeVar;

  /// The end scale of each individual particle.
  double endSize;

  /// Variance of the [endSize] property.
  double endSizeVar;

  /// The start rotation of each individual particle.
  double startRotation;

  /// Variance of the [startRotation] property.
  double startRotationVar;

  /// The end rotation of each individual particle.
  double endRotation;

  /// Variance of the [endRotation] property.
  double endRotationVar;

  /// If true, each particle will be rotated to the direction of the movement
  /// of the particle. The calculated rotation will be added to the current
  /// rotation as calculated by the [startRotation] and [endRotation]
  /// properties.
  bool rotateToMovement;

  /// The direction in which each particle will be emitted in degrees.
  double direction;

  /// Variance of the [direction] property.
  double directionVar;

  /// The speed at which each particle will be emitted.
  double speed;

  /// Variance of the [direction] property.
  double speedVar;

  /// The radial acceleration of each induvidual particle.
  double radialAcceleration;

  /// Variance of the [radialAcceleration] property.
  double radialAccelerationVar;

  /// The tangential acceleration of each individual particle.
  double tangentialAcceleration;

  /// Variance of the [tangentialAcceleration] property.
  double tangentialAccelerationVar;

  /// The gravity vector of the particle system.
  Vector2 gravity;

  /// The maximum number of particles the system can display at a single time.
  int maxParticles;

  /// Total number of particles to emit, if the value is set to 0 the system
  /// will continue to emit particles for an indifinte period of time.
  int numParticlesToEmit;

  /// The rate at which particles are emitted, defined in particles per second.
  double emissionRate;

  /// If set to true, the particle system will be automatically removed as soon
  /// as there are no more particles left to draw.
  bool autoRemoveOnFinish;

  /// The [ColorSequence] used to animate the color of each individual particle
  /// over the duration of its [life]. When applied to a particle the sequence's
  /// color stops modified in accordance with the [alphaVar], [redVar],
  /// [greenVar], and [blueVar] properties.
  ColorSequence colorSequence;

  /// Alpha varience of the [colorSequence] property.
  int alphaVar;

  /// Red varience of the [colorSequence] property.
  int redVar;

  /// Green varience of the [colorSequence] property.
  int greenVar;

  /// Blue varience of the [colorSequence] property.
  int blueVar;

  /// The transfer mode used to draw the particle system. Default is
  /// [TransferMode.plus].
  ui.TransferMode transferMode;

  List<_Particle> _particles;

  double _emitCounter;
  int _numEmittedParticles = 0;

  static Paint _paint = new Paint()
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false;

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
                  this.transferMode: ui.TransferMode.plus,
                  this.numParticlesToEmit: 0,
                  this.autoRemoveOnFinish: true}) {
    _particles = new List<_Particle>();
    _emitCounter = 0.0;
    // _elapsedTime = 0.0;
    if (gravity == null) gravity = new Vector2.zero();
    if (colorSequence == null) colorSequence = new ColorSequence.fromStartAndEndColor(new Color(0xffffffff), new Color(0x00ffffff));
  }

  void update(double dt) {
    // TODO: Fix this (it's a temp fix for low framerates)
    if (dt > 0.1) dt = 0.1;

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

    // _elapsedTime += dt;

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

      if (particle.accelerations != null) {
      // Radial acceleration
      Vector2 radial;
        if (particle.pos[0] != 0 || particle.pos[1] != 0) {
          radial = new Vector2.copy(particle.pos).normalize();
        } else {
          radial = new Vector2.zero();
        }
        Vector2 tangential = new Vector2.copy(radial);
        radial.scale(particle.accelerations.radialAccel);

        // Tangential acceleration
        double newY = tangential.x;
        tangential.x = -tangential.y;
        tangential.y = newY;
        tangential.scale(particle.accelerations.tangentialAccel);

        // (gravity + radial + tangential) * dt
        Vector2 accel = (gravity + radial + tangential).scale(dt);
        particle.dir += accel;
      } else if (gravity[0] != 0.0 || gravity[1] != 0) {
        // gravity
        Vector2 accel = gravity.scale(dt);
        particle.dir += accel;
      }

      // Update particle position
      particle.pos[0] += particle.dir[0] * dt;
      particle.pos[1] += particle.dir[1] * dt;

      // Size
      particle.size = math.max(particle.size + particle.deltaSize * dt, 0.0);

      // Angle
      particle.rotation += particle.deltaRotation * dt;

      // Color
      if (particle.simpleColorSequence != null) {
        for (int i = 0; i < 4; i++) {
          particle.simpleColorSequence[i] += particle.simpleColorSequence[i + 4] * dt;
        }
      } else {
        particle.colorPos = math.min(particle.colorPos + particle.deltaColorPos * dt, 1.0);
      }
    }

    if (autoRemoveOnFinish && _particles.length == 0 && _numEmittedParticles > 0) {
      if (parent != null) removeFromParent();
    }
  }

  void _addParticle() {

    _Particle particle = new _Particle();

    // Time to live
    particle.timeToLive = math.max(life + lifeVar * randomSignedDouble(), 0.0);

    // Position
    Point srcPos = Point.origin;
    particle.pos = new Vector2(srcPos.x + posVar.x * randomSignedDouble(),
                               srcPos.y + posVar.y * randomSignedDouble());

    // Size
    particle.size = math.max(startSize + startSizeVar * randomSignedDouble(), 0.0);
    double endSizeFinal = math.max(endSize + endSizeVar * randomSignedDouble(), 0.0);
    particle.deltaSize = (endSizeFinal - particle.size) / particle.timeToLive;

    // Rotation
    particle.rotation = startRotation + startRotationVar * randomSignedDouble();
    double endRotationFinal = endRotation + endRotationVar * randomSignedDouble();
    particle.deltaRotation = (endRotationFinal - particle.rotation) / particle.timeToLive;

    // Direction
    double dirRadians = convertDegrees2Radians(direction + directionVar * randomSignedDouble());
    Vector2 dirVector = new Vector2(math.cos(dirRadians), math.sin(dirRadians));
    double speedFinal = speed + speedVar * randomSignedDouble();
    particle.dir = dirVector.scale(speedFinal);

    // Accelerations
    if (radialAcceleration != 0.0 || radialAccelerationVar != 0.0 ||
        tangentialAcceleration != 0.0 || tangentialAccelerationVar != 0.0) {
      particle.accelerations = new _ParticleAccelerations();

      // Radial acceleration
      particle.accelerations.radialAccel = radialAcceleration + radialAccelerationVar * randomSignedDouble();

      // Tangential acceleration
      particle.accelerations.tangentialAccel = tangentialAcceleration + tangentialAccelerationVar * randomSignedDouble();
    }

    // Color
    particle.colorPos = 0.0;
    particle.deltaColorPos = 1.0 / particle.timeToLive;

    if (alphaVar != 0 || redVar != 0 || greenVar != 0 || blueVar != 0) {
      particle.colorSequence = _ColorSequenceUtil.copyWithVariance(colorSequence, alphaVar, redVar, greenVar, blueVar);
    }

    // Optimizes the case where there are only two colors in the sequence
    if (colorSequence.colors.length == 2) {
      Color startColor;
      Color endColor;

      if (particle.colorSequence != null) {
        startColor = particle.colorSequence.colors[0];
        endColor = particle.colorSequence.colors[1];
      } else {
        startColor = colorSequence.colors[0];
        endColor = colorSequence.colors[1];
      }

      // First 4 elements are start ARGB, last 4 are delta ARGB
      particle.simpleColorSequence = new Float64List(8);
      particle.simpleColorSequence[0] = startColor.alpha.toDouble();
      particle.simpleColorSequence[1] = startColor.red.toDouble();
      particle.simpleColorSequence[2] = startColor.green.toDouble();
      particle.simpleColorSequence[3] = startColor.blue.toDouble();

      particle.simpleColorSequence[4] = (endColor.alpha.toDouble() - startColor.alpha.toDouble()) / particle.timeToLive;
      particle.simpleColorSequence[5] = (endColor.red.toDouble() - startColor.red.toDouble()) / particle.timeToLive;
      particle.simpleColorSequence[6] = (endColor.green.toDouble() - startColor.green.toDouble()) / particle.timeToLive;
      particle.simpleColorSequence[7] = (endColor.blue.toDouble() - startColor.blue.toDouble()) / particle.timeToLive;
    }

    _particles.add(particle);
    _numEmittedParticles++;
  }

  void paint(Canvas canvas) {

    List<ui.RSTransform> transforms = <ui.RSTransform>[];
    List<Rect> rects = <Rect>[];
    List<Color> colors = <Color>[];

    _paint.transferMode = transferMode;

    for (_Particle particle in _particles) {
      // Rect
      Rect rect = texture.frame;
      rects.add(rect);

      // Transform
      double scos;
      double ssin;
      if (rotateToMovement) {
        double extraRotation = GameMath.atan2(particle.dir[1], particle.dir[0]);
        scos = math.cos(convertDegrees2Radians(particle.rotation) + extraRotation) * particle.size;
        ssin = math.sin(convertDegrees2Radians(particle.rotation) + extraRotation) * particle.size;
      } else if (particle.rotation != 0.0) {
        scos = math.cos(convertDegrees2Radians(particle.rotation)) * particle.size;
        ssin = math.sin(convertDegrees2Radians(particle.rotation)) * particle.size;
      } else {
        scos = particle.size;
        ssin = 0.0;
      }
      double ax = rect.width / 2;
      double ay = rect.height / 2;
      double tx = particle.pos[0] + -scos * ax + ssin * ay;
      double ty = particle.pos[1] + -ssin * ax - scos * ay;
      ui.RSTransform transform = new ui.RSTransform(scos, ssin, tx, ty);
      transforms.add(transform);

      // Color
      if (particle.simpleColorSequence != null) {
        Color particleColor = new Color.fromARGB(
          particle.simpleColorSequence[0].toInt().clamp(0, 255),
          particle.simpleColorSequence[1].toInt().clamp(0, 255),
          particle.simpleColorSequence[2].toInt().clamp(0, 255),
          particle.simpleColorSequence[3].toInt().clamp(0, 255));
        colors.add(particleColor);
      } else {
        Color particleColor;
        if (particle.colorSequence != null) {
          particleColor = particle.colorSequence.colorAtPosition(particle.colorPos);
        } else {
          particleColor = colorSequence.colorAtPosition(particle.colorPos);
        }
        colors.add(particleColor);
      }
    }

    canvas.drawAtlas(texture.image, transforms, rects, colors,
      ui.TransferMode.modulate, null, _paint);
  }
}

class _ColorSequenceUtil {
  static ColorSequence copyWithVariance(
    ColorSequence sequence,
    int alphaVar,
    int redVar,
    int greenVar,
    int blueVar
  ) {
    ColorSequence copy = new ColorSequence.copy(sequence);

    int i = 0;
    for (Color color in sequence.colors) {
      int aDelta = ((randomDouble() * 2.0 - 1.0) * alphaVar).toInt();
      int rDelta = ((randomDouble() * 2.0 - 1.0) * redVar).toInt();
      int gDelta = ((randomDouble() * 2.0 - 1.0) * greenVar).toInt();
      int bDelta = ((randomDouble() * 2.0 - 1.0) * blueVar).toInt();

      int aNew = (color.alpha + aDelta).clamp(0, 255);
      int rNew = (color.red + rDelta).clamp(0, 255);
      int gNew = (color.green + gDelta).clamp(0, 255);
      int bNew = (color.blue + bDelta).clamp(0, 255);

      copy.colors[i] = new Color.fromARGB(aNew, rNew, gNew, bNew);
      i++;
    }

    return copy;
  }
}
