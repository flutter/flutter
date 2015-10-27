part of flutter_sprites;

class _PhysicsCollisionGroups {

  _PhysicsCollisionGroups() {
    // Make sure there is a default entry in the groups
    getBitmaskForKeys(["Default"]);
  }

  Map<Object,int> keyLookup = <Object,int>{};

  List<Object> getKeysForBitmask(int bitmask) {
    List<Object> keys = [];
    keyLookup.forEach((Object key, int value) {
      if (value & bitmask != 0) {
        keys.add(key);
      }
    });
    return keys;
  }

  int getBitmaskForKeys(List<Object> keys) {
    if (keys == null) {
      return 0xffff;
    }

    int bitmask = 0;

    for (Object key in keys) {
      int value = keyLookup[key];
      if (value == null) {
        assert(keyLookup.length < 16);
        value = 1 << keyLookup.length;
        keyLookup[key] = value;
      }
      bitmask |= value;
    }
    return bitmask;
  }
}
