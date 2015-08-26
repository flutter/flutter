part of game;

enum GameObjectType {
  asteroidBig,
  asteroidSmall,
  movingEnemy,
  coin,
}

class GameObjectFactory {
  GameObjectFactory(this.sheet, this.sounds, this.level, this.playerState);

  SpriteSheet sheet;
  Map<String,SoundEffect> sounds;
  Level level;
  PlayerState playerState;

  void addAsteroids(int numAsteroids, double yPos, double distribution) {
    for (int i = 0; i < numAsteroids; i++) {
      GameObjectType type = (randomDouble() < distribution) ? GameObjectType.asteroidBig : GameObjectType.asteroidSmall;
      Point pos = new Point(randomSignedDouble() * 160.0,
                            yPos + _chunkSpacing * randomDouble());
      addGameObject(type, pos);
    }
  }

  void addSwarm(int numEnemies, double yPos) {
    for (int i = 0; i < numEnemies; i++) {
      double spacing = math.max(_chunkSpacing / (numEnemies + 1.0), 80.0);
      double y = yPos + _chunkSpacing / 2.0 - (numEnemies - 1) * spacing / 2.0 + i * spacing;
      addGameObject(GameObjectType.movingEnemy, new Point(0.0, y));
    }
  }

  void addGameObject(GameObjectType type, Point pos) {
    GameObject obj;
    if (type == GameObjectType.asteroidBig)
      obj = new AsteroidBig(this);
    else if (type == GameObjectType.asteroidSmall)
      obj = new AsteroidSmall(this);
    else if (type == GameObjectType.movingEnemy)
      obj = new MovingEnemy(this);
    else if (type == GameObjectType.coin)
      obj = new Coin(this);

    obj.position = pos;
    obj.setupActions();

    level.addChild(obj);
  }
}
