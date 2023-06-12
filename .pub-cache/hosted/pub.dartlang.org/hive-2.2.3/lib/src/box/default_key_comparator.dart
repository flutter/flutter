/// Efficient default implementation to compare keys
int defaultKeyComparator(dynamic k1, dynamic k2) {
  if (k1 is int) {
    if (k2 is int) {
      if (k1 > k2) {
        return 1;
      } else if (k1 < k2) {
        return -1;
      } else {
        return 0;
      }
    } else {
      return -1;
    }
  } else if (k2 is String) {
    return (k1 as String).compareTo(k2);
  } else {
    return 1;
  }
}
