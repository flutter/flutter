part of game;

class GameWorld extends TransformNode {
  
  World world;
  List<Body> bodies = [];
  Image _image;
  
  GameWorld(ImageMap images) {
    this.width = 1024.0;
    this.height = 1024.0;
    
    world = new World.withGravity(new Vector2(0.0, 0.0));
    
    // Load and add background
    Image imgBg = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png"];
    SpriteNode sprtBg = new SpriteNode.withImage(imgBg);
    sprtBg.width = width;
    sprtBg.height = height;
    sprtBg.pivot = new Vector2(0.0, 0.0);
    this.children.add(sprtBg);

    // Load asteroid image
    _image = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png"];

    // Add some asteroids to the game world
    for (int i = 0; i < 50; i++) {
      addAsteroid(10.0);
    }
    for (int i = 0; i < 50; i++) {
      addAsteroid(20.0);
    }
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
    
    SpriteNode sprt = new SpriteNode.withImage(_image);
    sprt.width = radius*2;
    sprt.height = radius*2;
    sprt.colorOverlay = new Color(0x33ff0000);
    sprt.transferMode = TransferMode.plusMode;
    body.userData = sprt;
    this.children.add(sprt);
  }
  
  void update(double dt) {
    world.stepDt(1.0/60.0, 10, 10);  // Pass in dt
    
    bodies.forEach(updateBody);
  }
  
  void updateBody(Body body) {
    SpriteNode sprt = body.userData;
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
}