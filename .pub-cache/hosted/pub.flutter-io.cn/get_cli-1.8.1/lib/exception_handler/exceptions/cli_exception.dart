class CliException implements Exception {
  String? message;
  String? codeSample;
  CliException(this.message, {this.codeSample = ''});
}
