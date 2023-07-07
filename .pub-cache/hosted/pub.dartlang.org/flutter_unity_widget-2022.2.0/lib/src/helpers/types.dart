class SceneLoaded {
  final String? name;
  final int? buildIndex;
  final bool? isLoaded;
  final bool? isValid;

  SceneLoaded({this.name, this.buildIndex, this.isLoaded, this.isValid});

  /// Mainly for internal use when calling [CameraUpdate.newCameraPosition].
  dynamic toMap() => <String, dynamic>{
        'name': name,
        'buildIndex': buildIndex,
        'isLoaded': isLoaded,
        'isValid': isValid,
      };

  /// Deserializes [SceneLoaded] from a map.
  ///
  /// Mainly for internal use.
  static SceneLoaded? fromMap(dynamic json) {
    if (json == null) {
      return null;
    }
    return SceneLoaded(
      name: json['name'],
      buildIndex: json['buildIndex'],
      isLoaded: json['isLoaded'],
      isValid: json['isValid'],
    );
  }
}
