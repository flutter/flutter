// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef SpeechRecognitionErrorCode = String;
typedef SpeechSynthesisErrorCode = String;

@JS('SpeechRecognition')
@staticInterop
class SpeechRecognition implements EventTarget {
  external factory SpeechRecognition();
}

extension SpeechRecognitionExtension on SpeechRecognition {
  external void start();
  external void stop();
  external void abort();
  external set grammars(SpeechGrammarList value);
  external SpeechGrammarList get grammars;
  external set lang(String value);
  external String get lang;
  external set continuous(bool value);
  external bool get continuous;
  external set interimResults(bool value);
  external bool get interimResults;
  external set maxAlternatives(int value);
  external int get maxAlternatives;
  external set onaudiostart(EventHandler value);
  external EventHandler get onaudiostart;
  external set onsoundstart(EventHandler value);
  external EventHandler get onsoundstart;
  external set onspeechstart(EventHandler value);
  external EventHandler get onspeechstart;
  external set onspeechend(EventHandler value);
  external EventHandler get onspeechend;
  external set onsoundend(EventHandler value);
  external EventHandler get onsoundend;
  external set onaudioend(EventHandler value);
  external EventHandler get onaudioend;
  external set onresult(EventHandler value);
  external EventHandler get onresult;
  external set onnomatch(EventHandler value);
  external EventHandler get onnomatch;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onstart(EventHandler value);
  external EventHandler get onstart;
  external set onend(EventHandler value);
  external EventHandler get onend;
}

@JS('SpeechRecognitionErrorEvent')
@staticInterop
class SpeechRecognitionErrorEvent implements Event {
  external factory SpeechRecognitionErrorEvent(
    String type,
    SpeechRecognitionErrorEventInit eventInitDict,
  );
}

extension SpeechRecognitionErrorEventExtension on SpeechRecognitionErrorEvent {
  external SpeechRecognitionErrorCode get error;
  external String get message;
}

@JS()
@staticInterop
@anonymous
class SpeechRecognitionErrorEventInit implements EventInit {
  external factory SpeechRecognitionErrorEventInit({
    required SpeechRecognitionErrorCode error,
    String message,
  });
}

extension SpeechRecognitionErrorEventInitExtension
    on SpeechRecognitionErrorEventInit {
  external set error(SpeechRecognitionErrorCode value);
  external SpeechRecognitionErrorCode get error;
  external set message(String value);
  external String get message;
}

@JS('SpeechRecognitionAlternative')
@staticInterop
class SpeechRecognitionAlternative {}

extension SpeechRecognitionAlternativeExtension
    on SpeechRecognitionAlternative {
  external String get transcript;
  external num get confidence;
}

@JS('SpeechRecognitionResult')
@staticInterop
class SpeechRecognitionResult {}

extension SpeechRecognitionResultExtension on SpeechRecognitionResult {
  external SpeechRecognitionAlternative item(int index);
  external int get length;
  external bool get isFinal;
}

@JS('SpeechRecognitionResultList')
@staticInterop
class SpeechRecognitionResultList {}

extension SpeechRecognitionResultListExtension on SpeechRecognitionResultList {
  external SpeechRecognitionResult item(int index);
  external int get length;
}

@JS('SpeechRecognitionEvent')
@staticInterop
class SpeechRecognitionEvent implements Event {
  external factory SpeechRecognitionEvent(
    String type,
    SpeechRecognitionEventInit eventInitDict,
  );
}

extension SpeechRecognitionEventExtension on SpeechRecognitionEvent {
  external int get resultIndex;
  external SpeechRecognitionResultList get results;
}

@JS()
@staticInterop
@anonymous
class SpeechRecognitionEventInit implements EventInit {
  external factory SpeechRecognitionEventInit({
    int resultIndex,
    required SpeechRecognitionResultList results,
  });
}

extension SpeechRecognitionEventInitExtension on SpeechRecognitionEventInit {
  external set resultIndex(int value);
  external int get resultIndex;
  external set results(SpeechRecognitionResultList value);
  external SpeechRecognitionResultList get results;
}

@JS('SpeechGrammar')
@staticInterop
class SpeechGrammar {}

extension SpeechGrammarExtension on SpeechGrammar {
  external set src(String value);
  external String get src;
  external set weight(num value);
  external num get weight;
}

@JS('SpeechGrammarList')
@staticInterop
class SpeechGrammarList {
  external factory SpeechGrammarList();
}

extension SpeechGrammarListExtension on SpeechGrammarList {
  external SpeechGrammar item(int index);
  external void addFromURI(
    String src, [
    num weight,
  ]);
  external void addFromString(
    String string, [
    num weight,
  ]);
  external int get length;
}

@JS('SpeechSynthesis')
@staticInterop
class SpeechSynthesis implements EventTarget {}

extension SpeechSynthesisExtension on SpeechSynthesis {
  external void speak(SpeechSynthesisUtterance utterance);
  external void cancel();
  external void pause();
  external void resume();
  external JSArray getVoices();
  external bool get pending;
  external bool get speaking;
  external bool get paused;
  external set onvoiceschanged(EventHandler value);
  external EventHandler get onvoiceschanged;
}

@JS('SpeechSynthesisUtterance')
@staticInterop
class SpeechSynthesisUtterance implements EventTarget {
  external factory SpeechSynthesisUtterance([String text]);
}

extension SpeechSynthesisUtteranceExtension on SpeechSynthesisUtterance {
  external set text(String value);
  external String get text;
  external set lang(String value);
  external String get lang;
  external set voice(SpeechSynthesisVoice? value);
  external SpeechSynthesisVoice? get voice;
  external set volume(num value);
  external num get volume;
  external set rate(num value);
  external num get rate;
  external set pitch(num value);
  external num get pitch;
  external set onstart(EventHandler value);
  external EventHandler get onstart;
  external set onend(EventHandler value);
  external EventHandler get onend;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onpause(EventHandler value);
  external EventHandler get onpause;
  external set onresume(EventHandler value);
  external EventHandler get onresume;
  external set onmark(EventHandler value);
  external EventHandler get onmark;
  external set onboundary(EventHandler value);
  external EventHandler get onboundary;
}

@JS('SpeechSynthesisEvent')
@staticInterop
class SpeechSynthesisEvent implements Event {
  external factory SpeechSynthesisEvent(
    String type,
    SpeechSynthesisEventInit eventInitDict,
  );
}

extension SpeechSynthesisEventExtension on SpeechSynthesisEvent {
  external SpeechSynthesisUtterance get utterance;
  external int get charIndex;
  external int get charLength;
  external num get elapsedTime;
  external String get name;
}

@JS()
@staticInterop
@anonymous
class SpeechSynthesisEventInit implements EventInit {
  external factory SpeechSynthesisEventInit({
    required SpeechSynthesisUtterance utterance,
    int charIndex,
    int charLength,
    num elapsedTime,
    String name,
  });
}

extension SpeechSynthesisEventInitExtension on SpeechSynthesisEventInit {
  external set utterance(SpeechSynthesisUtterance value);
  external SpeechSynthesisUtterance get utterance;
  external set charIndex(int value);
  external int get charIndex;
  external set charLength(int value);
  external int get charLength;
  external set elapsedTime(num value);
  external num get elapsedTime;
  external set name(String value);
  external String get name;
}

@JS('SpeechSynthesisErrorEvent')
@staticInterop
class SpeechSynthesisErrorEvent implements SpeechSynthesisEvent {
  external factory SpeechSynthesisErrorEvent(
    String type,
    SpeechSynthesisErrorEventInit eventInitDict,
  );
}

extension SpeechSynthesisErrorEventExtension on SpeechSynthesisErrorEvent {
  external SpeechSynthesisErrorCode get error;
}

@JS()
@staticInterop
@anonymous
class SpeechSynthesisErrorEventInit implements SpeechSynthesisEventInit {
  external factory SpeechSynthesisErrorEventInit(
      {required SpeechSynthesisErrorCode error});
}

extension SpeechSynthesisErrorEventInitExtension
    on SpeechSynthesisErrorEventInit {
  external set error(SpeechSynthesisErrorCode value);
  external SpeechSynthesisErrorCode get error;
}

@JS('SpeechSynthesisVoice')
@staticInterop
class SpeechSynthesisVoice {}

extension SpeechSynthesisVoiceExtension on SpeechSynthesisVoice {
  external String get voiceURI;
  external String get name;
  external String get lang;
  external bool get localService;
  @JS('default')
  external bool get default_;
}
