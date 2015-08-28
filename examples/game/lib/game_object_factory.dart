part of game;

enum GameObjectType {
  asteroidBig,
  asteroidSmall,
  asteroidPowerUp,
  enemyScout,
  enemyDestroyer,
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
      if (i == 0) type = GameObjectType.asteroidPowerUp;
      Point pos = new Point(randomSignedDouble() * 160.0,
                            yPos + _chunkSpacing * randomDouble());
      addGameObject(type, pos);
    }
  }

  void addEnemyScoutSwarm(int numEnemies, double yPos) {
    for (int i = 0; i < numEnemies; i++) {
      double spacing = math.max(_chunkSpacing / (numEnemies + 1.0), 80.0);
      double y = yPos + _chunkSpacing / 2.0 - (numEnemies - 1) * spacing / 2.0 + i * spacing;
      addGameObject(GameObjectType.enemyScout, new Point(0.0, y));
    }
  }

  void addEnemyDestroyerSwarm(int numEnemies, double yPos) {
    for (int i = 0; i < numEnemies; i++) {
      addGameObject(GameObjectType.enemyDestroyer, new Point(randomSignedDouble() * 120.0 , yPos + _chunkSpacing * randomDouble()));
    }
  }

  void addGameObject(GameObjectType type, Point pos) {
    GameObject obj;
    if (type == GameObjectType.asteroidBig)
      obj = new AsteroidBig(this);
    else if (type == GameObjectType.asteroidSmall)
      obj = new AsteroidSmall(this);
    else if (type == GameObjectType.asteroidPowerUp)
      obj = new AsteroidPowerUp(this);
    else if (type == GameObjectType.enemyScout)
      obj = new EnemyScout(this);
    else if (type == GameObjectType.enemyDestroyer)
      obj = new EnemyDestroyer(this);
    else if (type == GameObjectType.coin)
      obj = new Coin(this);

    obj.position = pos;
    obj.setupActions();

    level.addChild(obj);
  }
}
