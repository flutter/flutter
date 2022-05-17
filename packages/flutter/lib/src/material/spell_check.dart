import 'dart:async';

import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/services/spell_check.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter/src/services/system_channels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_text_button.dart';

class MaterialSpellCheckService implements SpellCheckService {
  late MethodChannel spellCheckChannel;

  MaterialSpellCheckService() {
    spellCheckChannel = SystemChannels.spellCheck;    
  }

    @override
    Future<List<dynamic>> fetchSpellCheckSuggestions(Locale locale, TextEditingValue value) async {
    assert(locale != null);
    assert(value.text != null);

    List<dynamic> spellCheckResults = <dynamic>[];
    final List<dynamic> rawResults;

    //TODO: handle exception
    try {
    rawResults = await spellCheckChannel.invokeMethod(
        'SpellCheck.initiateSpellCheck',
        <String>[ locale.toLanguageTag(), value.text],
      );
    } catch(e) {
      return spellCheckResults;
    }

    List<String> results = rawResults.cast<String>();

    String text = results.removeAt(0);
    List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans = <SpellCheckerSuggestionSpan>[];
    
    results.forEach((String result) {
      List<String> resultParsed = result.split(".");
      spellCheckerSuggestionSpans.add(SpellCheckerSuggestionSpan(int.parse(resultParsed[0]), int.parse(resultParsed[1]), resultParsed[2].split("\n")));
    });

  spellCheckResults.add(text);
  spellCheckResults.add(spellCheckerSuggestionSpans);

    return spellCheckResults;
  }
}