import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

main() {
  runTest();
}

const int numSystems = 1000;
const int numFrames = 1000;

void runTest() {
  int timeStart;
  timeStart = new DateTime.now().millisecondsSinceEpoch;

  // Create systems
  List<TestParticleSystem> systems = <TestParticleSystem>[];
  for (int i = 0; i < numSystems; i++)
    systems.add(new TestParticleSystem());

  int timeAfterCreate = new DateTime.now().millisecondsSinceEpoch;
  print("TIME creation ${(timeAfterCreate - timeStart) / 1000.0}");
  timeStart =  new DateTime.now().millisecondsSinceEpoch;

  // Update systems
  for (int frame = 0; frame < numFrames; frame++) {
    for (int i = 0; i < numSystems; i++) {
      systems[i].update(1.0 / 60.0);
    }
  }

  int timeAfterUpdates = new DateTime.now().millisecondsSinceEpoch;
  print("TIME updates ${(timeAfterUpdates - timeStart) / 1000.0}");
  timeStart =  new DateTime.now().millisecondsSinceEpoch;

  // Calculate matrices
  for (int frame = 0; frame < numFrames; frame++) {
    for (int i = 0; i < numSystems; i++) {
      systems[i].paint();
    }
  }

  int timeAfterMatrices = new DateTime.now().millisecondsSinceEpoch;
  print("TIME matrices ${(timeAfterMatrices - timeStart) / 1000.0}");
}

class TestParticle {
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

  Float64List simpleColorSequence;

  Matrix4 transform;
}

class TestParticleSystem {
  double life;
  double lifeVar;

  Vector2 posVar;

  double startSize;
  double startSizeVar;

  double endSize;
  double endSizeVar;

  double startRotation;
  double startRotationVar;

  double endRotation;
  double endRotationVar;

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

  List<TestParticle> _particles;

  double _emitCounter;
  int _numEmittedParticles = 0;

  TestParticleSystem({this.life: 1.5,
                  this.lifeVar: 0.0,
                  this.startSize: 2.5,
                  this.startSizeVar: 0.5,
                  this.endSize: 0.0,
                  this.endSizeVar: 0.0,
                  this.startRotation: 0.0,
                  this.startRotationVar: 0.0,
                  this.endRotation: 0.0,
                  this.endRotationVar: 0.0,
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
                  this.numParticlesToEmit: 0}) {
    posVar = new Vector2.zero();
    _particles = new List<TestParticle>();
    _emitCounter = 0.0;
    gravity = new Vector2.zero();
  }

  void update(double dt) {
    // Create new particles
    double rate = 1.0 / emissionRate;

    if (_particles.length < maxParticles) {
      _emitCounter += dt;
    }

    while (_particles.length < maxParticles
       && _emitCounter > rate
       && (numParticlesToEmit == 0 || _numEmittedParticles < numParticlesToEmit)) {
      // Add a new particle
      _addParticle();
      _emitCounter -= rate;
    }

    // Iterate over all particles
    for (int i = _particles.length -1; i >= 0; i--) {
      TestParticle particle = _particles[i];

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
  }

  void _addParticle() {

    TestParticle particle = new TestParticle();

    // Time to live
    particle.timeToLive = math.max(life + lifeVar * randomSignedDouble(), 0.0);

    // Position
    Vector2 srcPos = new Vector2.zero();
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
    double dirRadians = radians(direction + directionVar * randomSignedDouble());
    Vector2 dirVector = new Vector2(math.cos(dirRadians), math.sin(dirRadians));
    double speedFinal = speed + speedVar * randomSignedDouble();
    particle.dir = dirVector.scale(speedFinal);

    // Radial acceleration
    particle.radialAccel = radialAcceleration + radialAccelerationVar * randomSignedDouble();

    // Tangential acceleration
    particle.tangentialAccel = tangentialAcceleration + tangentialAccelerationVar * randomSignedDouble();

    // Colors
    particle.simpleColorSequence = new Float64List(8);
    particle.simpleColorSequence[0] = 255.0;
    particle.simpleColorSequence[1] = 255.0;
    particle.simpleColorSequence[2] = 255.0;
    particle.simpleColorSequence[3] = 255.0;

    particle.simpleColorSequence[4] = 255.0;
    particle.simpleColorSequence[5] = 0.0;
    particle.simpleColorSequence[6] = 0.0;
    particle.simpleColorSequence[7] = 0.0;

    // Transform
    particle.transform = new Matrix4.identity();

    // Add particle
    _particles.add(particle);
    _numEmittedParticles++;
  }


  void paint() {

    if (!printed) {
      printed = true;
    }

    for (int i = _particles.length -1; i >= 0; i--) {
      TestParticle particle = _particles[i];
      particle.rotation + randomSignedDouble();

      // Transform
      double c = math.cos(radians(particle.rotation));
      double s = math.sin(radians(particle.rotation));

      // Create transformation matrix for scale, position and rotation
      Matrix4 matrix = new Matrix4(c * particle.size, s * particle.size, 0.0, 0.0,
                 -s * particle.size, c * particle.size, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                particle.pos.x, particle.pos.y, 0.0, 1.0);

      particle.transform.multiply(matrix);
    }
  }
}

math.Random _random = new math.Random();

bool printed = false;

// Random methods

double randomDouble() {
  return _random.nextDouble();
}

double randomSignedDouble() {
  return _random.nextDouble() * 2.0 - 1.0;
}

int randomInt(int max) {
  return _random.nextInt(max);
}
