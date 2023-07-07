///
/// Exception that indicates that the given tag is not supported
///
class UnsupportedASN1TagException implements Exception {
  int tag;

  UnsupportedASN1TagException(this.tag);

  @override
  String toString() =>
      'UnsupportedASN1TagException: Tag $tag is not supported yet';
}
