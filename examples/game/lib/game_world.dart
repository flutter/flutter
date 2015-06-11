part of game;

class GameWorld extends Node {
  
  World world;
  List<Body> bodies = [];
  Body _bodyShip;

  Image _imgBg;
  Image _imgAsteroid;
  Image _imgShip;

  double _steeringInput;
  double _thrustInput;
  double _lastSteeringSpeed = 0.0;
  
  GameWorld(ImageMap images) {
    this.width = 1024.0;
    this.height = 1024.0;

    // Fetch images
    _imgBg = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png"];
    _imgAsteroid = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png"];
    _imgShip = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png"];

    // Create the physics world
    world = new World.withGravity(new Vector2(0.0, 0.0));
    
    // Add a background
    addBackground();

    // Add some asteroids to the game world
    for (int i = 0; i < 50; i++) {
      addAsteroid(10.0);
    }
    for (int i = 0; i < 50; i++) {
      addAsteroid(20.0);
    }

    // Add ship
    addShip();
  }

  void addBackground() {
    Sprite sprtBg = new Sprite.withImage(_imgBg);
    sprtBg.width = width;
    sprtBg.height = height;
    sprtBg.pivot = new Vector2(0.0, 0.0);
    this.addChild(sprtBg);
  }
  
  void addAsteroid([double radius=20.0]) {
    
    // Create shape
    final CircleShape shape = new CircleShape();
    shape.radius = radius;
    
    // Define fixture (links body and shape)
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 1.0;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;
    
    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.type = BodyType.DYNAMIC;
    bodyDef.position = new Vector2(0.0, 30.0);
    bodyDef.linearDamping = 0.0;
    bodyDef.angularDamping = 0.0;
    
    // Create body and fixture from definitions
    final Body body = world.createBody(bodyDef);
    body.createFixtureFromFixtureDef(activeFixtureDef);
    
    // Set position of object
    Math.Random rand = new Math.Random();
    body.setTransform(new Vector2(rand.nextDouble() * this.width, rand.nextDouble() * this.height), 0.0);
    body.applyLinearImpulse(new Vector2(rand.nextDouble()*10000.0-5000.0, rand.nextDouble()*10000.0-5000.0), new Vector2(0.0, 0.0), true);
    
    // Add to list
    bodies.add(body);

    // Create sprite
    Sprite sprt = new Sprite.withImage(_imgAsteroid);
    sprt.width = radius*2;
    sprt.height = radius*2;
//    sprt.colorOverlay = new Color(0x33ff0000);
//    sprt.transferMode = TransferMode.plusMode;
    body.userData = sprt;
    this.addChild(sprt);
  }

  void addShip() {
    double radius = 30.0;

    // Create shape
    final CircleShape shape = new CircleShape();
    shape.radius = radius;

    // Define fixture (links body and shape)
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 1.0;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;

    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.type = BodyType.DYNAMIC;
    bodyDef.position = new Vector2(0.0, 30.0);
    bodyDef.linearDamping = 0.0;
    bodyDef.angularDamping = 0.95;

    // Create body and fixture from definitions
    final Body body = world.createBody(bodyDef);
    body.createFixtureFromFixtureDef(activeFixtureDef);

    // Center on screen
    body.setTransform(new Vector2(width/2.0, height/2.0), 90.0);

    // Add to list
    bodies.add(body);
    _bodyShip = body;

    // Create sprite
    Sprite sprt = new Sprite.withImage(_imgShip);
    sprt.width = radius*2;
    sprt.height = radius*2;
    sprt.position = new Vector2(width/2.0, height/2.0);
    body.userData = sprt;
    this.addChild(sprt);
  }
  
  void update(double dt) {
    // Apply thrust
    if (_thrustInput != null) {
      double force = _thrustInput*10000.0;
      double rad = degrees2radians(_bodyShip.getAngle());
      _bodyShip.applyLinearImpulse(new Vector2(Math.cos(rad)*force, Math.sin(rad)*force), new Vector2(0.0, 0.0), true);
    }

    // Simulate world
    world.stepDt(1.0/60.0, 10, 10);  // Pass in dt

    // Apply stearing
    if (_steeringInput != null) {
      _lastSteeringSpeed = _steeringInput * 4.0;
    }
    else {
      _lastSteeringSpeed *= 0.75;
    }
    _bodyShip.setTransform(_bodyShip.position, _bodyShip.getAngle() + _lastSteeringSpeed);

    // Update all sprites
    bodies.forEach(updateBody);
  }
  
  void updateBody(Body body) {
    Sprite sprt = body.userData;
    double rot = 0.0; //body.getRotation();
    
    // Check bounds and warp objects
    if (body.position[0] < -sprt.width/2) {
      body.setTransform(new Vector2(body.position[0] + this.width + sprt.width, body.position[1]), rot);
    }
    if (body.position[0] > this.width + sprt.width/2) {
      body.setTransform(new Vector2(body.position[0] - (this.width + sprt.width), body.position[1]), rot);
    }
    if (body.position[1] < -sprt.height/2) {
      body.setTransform(new Vector2(body.position[0], body.position[1] + this.height + sprt.height), rot);
    }
    if (body.position[1] > this.height + sprt.height/2) {
      body.setTransform(new Vector2(body.position[0], body.position[1] - (this.height + sprt.height)), rot);
    }
    
    // Update sprite
    sprt.position = body.position;
    sprt.rotation = body.getAngle();
  }

  void controlSteering(double input) {
    _steeringInput = input;
  }

  void controlThrust(double input) {
    _thrustInput = input;
  }

  void controlFire() {

  }
}
