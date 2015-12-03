/**
 * DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
 * This is a library that looks up messages for specific locales by
 * delegating to the appropriate library.
 */

library messages_all;

import 'dart:async';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';
import 'package:intl/intl.dart';

import 'stock_messages_en.dart' as messages_en;
import 'stock_messages_es.dart' as messages_es;


Map<String, Function> _deferredLibraries = {
  'en' : () => new Future.value(null),
  'es' : () => new Future.value(null),
};

MessageLookupByLibrary _findExact(localeName) {
  switch (localeName) {
    case 'en' : return messages_en.messages;
    case 'es' : return messages_es.messages;
    default: return null;
  }
}

/** User programs should call this before using [localeName] for messages.*/
Future initializeMessages(String localeName) {
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  var lib = _deferredLibraries[Intl.canonicalizedLocale(localeName)];
  var load = lib == null ? new Future.value(false) : lib();
  return load.then((_) =>
      messageLookup.addLocale(localeName, _findGeneratedMessagesFor));
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, (x) => _findExact(x) != null,
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
