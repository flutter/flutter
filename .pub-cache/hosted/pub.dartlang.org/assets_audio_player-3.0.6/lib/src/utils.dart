extension MapUtils<K, V> on Map<K, V> {
  void addIfNotNull(K key, V value) {
    if (key != null && value != null) {
      this[key] = value;
    }
  }
}
