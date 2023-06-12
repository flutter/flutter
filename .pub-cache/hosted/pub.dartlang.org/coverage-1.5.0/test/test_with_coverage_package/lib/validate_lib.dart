int sum(Iterable<int> values) {
  var val = 0;
  for (var value in values) {
    val += value;
  }
  return val;
}

int product(Iterable<int> values) {
  var val = 1;
  for (var value in values) {
    val *= value;
  }
  return val;
}
