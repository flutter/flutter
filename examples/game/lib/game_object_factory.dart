part of game;

class GameObjectFactory {
  GameObjectFactory(this.sheet, this.sounds, this.level, this.playerState);

  SpriteSheet sheet;
  Map<String,SoundEffect> sounds;
  Level level;
  PlayerState playerState;

  void addAsteroids(int numAsteroids, double yPos, double distribution) {
    for (int i = 0; i < numAsteroids; i++) {
      GameObject obj;
      if (i == 0)
        obj = new AsteroidPowerUp(this);
      else if (randomDouble() < distribution)
        obj = new AsteroidBig(this);
      else
        obj = new AsteroidSmall(this);

      Point pos = new Point(randomSignedDouble() * 160.0,
                            yPos + _chunkSpacing * randomDouble());
      addGameObject(obj, pos);
    }
  }

  void addEnemyScoutSwarm(int numEnemies, double yPos) {
    for (int i = 0; i < numEnemies; i++) {
      double spacing = math.max(_chunkSpacing / (numEnemies + 1.0), 80.0);
      double y = yPos + _chunkSpacing / 2.0 - (numEnemies - 1) * spacing / 2.0 + i * spacing;
      addGameObject(new EnemyScout(this), new Point(0.0, y));
    }
  }

  void addEnemyDestroyerSwarm(int numEnemies, double yPos) {
    for (int i = 0; i < numEnemies; i++) {
      addGameObject(new EnemyDestroyer(this), new Point(randomSignedDouble() * 120.0 , yPos + _chunkSpacing * randomDouble()));
    }
  }

  void addGameObject(GameObject obj, Point pos) {
    obj.position = pos;
    obj.setupActions();

    level.addChild(obj);
  }

  void addBossFight(int l, double yPos) {
    // Add boss
    EnemyBoss boss = new EnemyBoss(this);
    Point pos = new Point(0.0, yPos + _chunkSpacing / 2.0);

    addGameObject(boss, pos);

    playerState.boss = boss;

    // Add boss's helpers
    if (l >= 1) {
      EnemyDestroyer destroyer0 = new EnemyDestroyer(this);
      addGameObject(destroyer0, new Point(-80.0, yPos + _chunkSpacing / 2.0 + 70.0));

      EnemyDestroyer destroyer1 = new EnemyDestroyer(this);
      addGameObject(destroyer1, new Point(80.0, yPos + _chunkSpacing / 2.0 + 70.0));

      if (l >= 2) {
        EnemyDestroyer destroyer0 = new EnemyDestroyer(this);
        addGameObject(destroyer0, new Point(-80.0, yPos + _chunkSpacing / 2.0 - 70.0));

        EnemyDestroyer destroyer1 = new EnemyDestroyer(this);
        addGameObject(destroyer1, new Point(80.0, yPos + _chunkSpacing / 2.0 - 70.0));
      }
    }
  }
}
