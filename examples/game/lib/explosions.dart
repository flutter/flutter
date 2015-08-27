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
      redVar: 127
    );
    particlesDebris.zPosition = 1010.0;
    addChild(particlesDebris);

    ParticleSystem particlesFire = new ParticleSystem(
      sheet["fire_particle.png"],
      colorSequence: new ColorSequence([new Color(0xffffff33), new Color(0xffff3333), new Color(0x00ff3333)], [0.0, 0.5, 1.0]),
      numParticlesToEmit: 25,
      emissionRate: 1000.0,
      startSize: 0.5,
      startSizeVar: 0.1,
      endSize: 0.5,
      endSizeVar: 0.1,
      posVar: new Point(10.0, 10.0),
      speed: 10.0,
      speedVar: 5.0
    );
    particlesFire.zPosition = 1011.0;
    addChild(particlesFire);

    // Add ring
    Sprite sprtRing = new Sprite(sheet["explosion_ring.png"]);
    sprtRing.transferMode = sky.TransferMode.plus;
    addChild(sprtRing);

    Action scale = new ActionTween( (a) => sprtRing.scale = a, 0.2, 1.0, 1.5);
    Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtRing)]);
    Action fade = new ActionTween( (a) => sprtRing.opacity = a, 1.0, 0.0, 1.5);
    actions.run(scaleAndRemove);
    actions.run(fade);

    // Add streaks
    for (int i = 0; i < 5; i++) {
      Sprite sprtFlare = new Sprite(sheet["explosion_flare.png"]);
      sprtFlare.pivot = new Point(0.3, 1.0);
      sprtFlare.scaleX = 0.3;
      sprtFlare.transferMode = sky.TransferMode.plus;
      sprtFlare.rotation = randomDouble() * 360.0;
      addChild(sprtFlare);

      double multiplier = randomDouble() * 0.3 + 1.0;

      Action scale = new ActionTween( (a) => sprtFlare.scaleY = a, 0.3 * multiplier, 0.8, 1.5 * multiplier);
      Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtFlare)]);
      Action fadeIn = new ActionTween( (a) => sprtFlare.opacity = a, 0.0, 1.0, 0.5 * multiplier);
      Action fadeOut = new ActionTween( (a) => sprtFlare.opacity = a, 1.0, 0.0, 1.0 * multiplier);
      Action fadeInOut = new ActionSequence([fadeIn, fadeOut]);
      actions.run(scaleAndRemove);
      actions.run(fadeInOut);
    }
  }
}

class ExplosionMini extends Explosion {

}
