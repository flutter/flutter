part of game;

class Explosion extends Node {
  Explosion() {
    zPosition = 10.0;
  }
}

class ExplosionBig extends Explosion {
  ExplosionBig(SpriteSheet sheet) {
    // Add particles
    ParticleSystem particlesDebris = new ParticleSystem(
      sheet["explosion_particle.png"],
      rotateToMovement: true,
      startRotation:90.0,
      startRotationVar: 0.0,
      endRotation: 90.0,
      startSize: 0.3,
      startSizeVar: 0.1,
      endSize: 0.3,
      endSizeVar: 0.1,
      numParticlesToEmit: 25,
      emissionRate:1000.0,
      greenVar: 127,
      redVar: 127,
      life: 0.75,
      lifeVar: 0.5
    );
    particlesDebris.zPosition = 1010.0;
    addChild(particlesDebris);

    ParticleSystem particlesFire = new ParticleSystem(
      sheet["fire_particle.png"],
      colorSequence: new ColorSequence(<Color>[new Color(0xffffff33), new Color(0xffff3333), new Color(0x00ff3333)], <double>[0.0, 0.5, 1.0]),
      numParticlesToEmit: 25,
      emissionRate: 1000.0,
      startSize: 0.5,
      startSizeVar: 0.1,
      endSize: 0.5,
      endSizeVar: 0.1,
      posVar: new Point(10.0, 10.0),
      speed: 10.0,
      speedVar: 5.0,
      life: 0.75,
      lifeVar: 0.5
    );
    particlesFire.zPosition = 1011.0;
    addChild(particlesFire);

    // Add ring
    Sprite spriteRing = new Sprite(sheet["explosion_ring.png"]);
    spriteRing.transferMode = ui.TransferMode.plus;
    addChild(spriteRing);

    Action scale = new ActionTween((double a) { spriteRing.scale = a; }, 0.2, 1.0, 0.75);
    Action scaleAndRemove = new ActionSequence(<Action>[scale, new ActionRemoveNode(spriteRing)]);
    Action fade = new ActionTween((double a) { spriteRing.opacity = a; }, 1.0, 0.0, 0.75);
    actions.run(scaleAndRemove);
    actions.run(fade);

    // Add streaks
    for (int i = 0; i < 5; i++) {
      Sprite spriteFlare = new Sprite(sheet["explosion_flare.png"]);
      spriteFlare.pivot = new Point(0.3, 1.0);
      spriteFlare.scaleX = 0.3;
      spriteFlare.transferMode = ui.TransferMode.plus;
      spriteFlare.rotation = randomDouble() * 360.0;
      addChild(spriteFlare);

      double multiplier = randomDouble() * 0.3 + 1.0;

      Action scale = new ActionTween((double a) { spriteFlare.scaleY = a; }, 0.3 * multiplier, 0.8, 0.75 * multiplier);
      Action scaleAndRemove = new ActionSequence(<Action>[scale, new ActionRemoveNode(spriteFlare)]);
      Action fadeIn = new ActionTween((double a) { spriteFlare.opacity = a; }, 0.0, 1.0, 0.25 * multiplier);
      Action fadeOut = new ActionTween((double a) { spriteFlare.opacity = a; }, 1.0, 0.0, 0.5 * multiplier);
      Action fadeInOut = new ActionSequence(<Action>[fadeIn, fadeOut]);
      actions.run(scaleAndRemove);
      actions.run(fadeInOut);
    }
  }
}

class ExplosionMini extends Explosion {
  ExplosionMini(SpriteSheet sheet) {
    for (int i = 0; i < 2; i++) {
      Sprite star = new Sprite(sheet["star_0.png"]);
      star.scale = 0.5;
      star.colorOverlay = new Color(0xff95f4fb);
      star.transferMode = ui.TransferMode.plus;
      addChild(star);

      double rotationStart = randomDouble() * 90.0;
      double rotationEnd = 180.0 + randomDouble() * 90.0;
      if (i == 0) {
        rotationStart = -rotationStart;
        rotationEnd = -rotationEnd;
      }

      ActionTween rotate = new ActionTween((double a) { star.rotation = a; }, rotationStart, rotationEnd, 0.2);
      actions.run(rotate);

      ActionTween fade = new ActionTween((double a) { star.opacity = a; }, 1.0, 0.0, 0.2);
      actions.run(fade);
    }

    ActionSequence seq = new ActionSequence(<Action>[new ActionDelay(0.2), new ActionRemoveNode(this)]);
    actions.run(seq);
  }
}
