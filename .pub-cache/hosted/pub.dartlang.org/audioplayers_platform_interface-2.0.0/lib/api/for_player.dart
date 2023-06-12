class ForPlayer<T> {
  final String playerId;
  final T t;

  ForPlayer(this.playerId, this.t);

  @override
  String toString() => '[$playerId] $t';
}

extension FilterForPlayer<T> on Stream<ForPlayer<T>> {
  Stream<T> filter(String playerId) {
    return where((it) => it.playerId == playerId).map((it) => it.t);
  }
}
