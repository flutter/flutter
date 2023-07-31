String unexpectedEnd() => 'Unexpected end of input';

String unexpectedToken(String token, String? source, int? line, int? column) {
  final sourceOrEmpty = source != null ? '$source:' : '';
  final positionStr = '$sourceOrEmpty$line:$column';
  return 'Unexpected token <$token> at $positionStr';
}
