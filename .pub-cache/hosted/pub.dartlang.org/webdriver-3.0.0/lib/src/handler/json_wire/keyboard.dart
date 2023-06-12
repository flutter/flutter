import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class JsonWireKeyboardHandler extends KeyboardHandler {
  static const String nullChar = '\uE000';

  @override
  WebDriverRequest buildSendChordRequest(Iterable<String> chordToSend) =>
      buildSendKeysRequest(_createChord(chordToSend));

  @override
  WebDriverRequest buildSendKeysRequest(String keysToSend) =>
      WebDriverRequest.postRequest('keys', {
        'value': [keysToSend]
      });

  @override
  void parseSendKeysResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  String _createChord(Iterable<String> chord) {
    var chordString = StringBuffer();
    for (var s in chord) {
      chordString.write(s);
    }
    chordString.write(nullChar);

    return chordString.toString();
  }

  @override
  void parseSendChordResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }
}
