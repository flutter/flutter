// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();


final _keepAnalysisHappy = Intl.defaultLocale;


typedef MessageIfAbsent(String message_str, List args);

class MessageLookup extends MessageLookupByLibrary {
  get localeName => 'en';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "market" : MessageLookupByLibrary.simpleMessage("MARKET"),
    "portfolio" : MessageLookupByLibrary.simpleMessage("PORTFOLIO"),
    "title" : MessageLookupByLibrary.simpleMessage("Stocks")
  };
}
