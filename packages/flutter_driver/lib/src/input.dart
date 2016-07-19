// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'message.dart';
import 'find.dart';

class SetInputText extends CommandWithTarget {
  @override
  final String kind = 'setInputText';

  SetInputText(SerializableFinder finder, this.text) : super(finder);

  final String text;

  static SetInputText deserialize(Map<String, dynamic> json) {
    String text = json['text'];
    return new SetInputText(SerializableFinder.deserialize(json), text);
  }

  @override
  Map<String, String> serialize() {
    Map<String, String> json = super.serialize();
    json['text'] = text;
    return json;
  }
}

class SetInputTextResult extends Result {
  static SetInputTextResult fromJson(Map<String, dynamic> json) {
    return new SetInputTextResult();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

class SubmitInputText extends CommandWithTarget {
  @override
  final String kind = 'submitInputText';

  SubmitInputText(SerializableFinder finder) : super(finder);

  static SubmitInputText deserialize(Map<String, dynamic> json) {
    return new SubmitInputText(SerializableFinder.deserialize(json));
  }
}

class SubmitInputTextResult extends Result {
  SubmitInputTextResult(this.text);

  final String text;

  static SubmitInputTextResult fromJson(Map<String, dynamic> json) {
    return new SubmitInputTextResult(json['text']);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text
  };
}
