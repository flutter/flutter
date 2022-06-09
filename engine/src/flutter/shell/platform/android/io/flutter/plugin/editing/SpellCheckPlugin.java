// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.view.textservice.SentenceSuggestionsInfo;
import android.view.textservice.SpellCheckerSession;
import android.view.textservice.SuggestionsInfo;
import android.view.textservice.TextInfo;
import android.view.textservice.TextServicesManager;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.systemchannels.SpellCheckChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.localization.LocalizationPlugin;
import java.util.ArrayList;
import java.util.Locale;

/**
 * {@link SpellCheckPlugin} is the implementation of all functionality needed for spell check for
 * text input.
 *
 * <p>The plugin handles requests for spell check sent by the {@link
 * io.flutter.embedding.engine.systemchannels.SpellCheckChannel} via sending requests to the Android
 * spell checker. It also receives the spell check results from the service and sends them back to
 * the framework through the {@link io.flutter.embedding.engine.systemchannels.SpellCheckChannel}.
 */
public class SpellCheckPlugin
    implements SpellCheckChannel.SpellCheckMethodHandler,
        SpellCheckerSession.SpellCheckerSessionListener {

  private final SpellCheckChannel mSpellCheckChannel;
  private final TextServicesManager mTextServicesManager;
  private SpellCheckerSession mSpellCheckerSession;

  @VisibleForTesting MethodChannel.Result pendingResult;

  // The maximum number of suggestions that the Android spell check service is allowed to provide
  // per word. Same number that is used by default for Android's TextViews.
  private static final int MAX_SPELL_CHECK_SUGGESTIONS = 5;

  public SpellCheckPlugin(
      @NonNull TextServicesManager textServicesManager,
      @NonNull SpellCheckChannel spellCheckChannel) {
    mTextServicesManager = textServicesManager;
    mSpellCheckChannel = spellCheckChannel;

    mSpellCheckChannel.setSpellCheckMethodHandler(this);
  }

  /**
   * Unregisters this {@code SpellCheckPlugin} as the {@code
   * SpellCheckChannel.SpellCheckMethodHandler}, for the {@link
   * io.flutter.embedding.engine.systemchannels.SpellCheckChannel}, and closes the most recently
   * opened {@code SpellCheckerSession}.
   *
   * <p>Do not invoke any methods on a {@code SpellCheckPlugin} after invoking this method.
   */
  public void destroy() {
    mSpellCheckChannel.setSpellCheckMethodHandler(null);

    if (mSpellCheckerSession != null) {
      mSpellCheckerSession.close();
    }
  }

  /**
   * Initiates call to native spell checker to spell check specified text if there is no result
   * awaiting a response.
   */
  @Override
  public void initiateSpellCheck(
      @NonNull String locale, @NonNull String text, @NonNull MethodChannel.Result result) {
    if (pendingResult != null) {
      result.error("error", "Previous spell check request still pending.", null);
      return;
    }

    pendingResult = result;

    performSpellCheck(locale, text);
  }

  /** Calls on the Android spell check API to spell check specified text. */
  public void performSpellCheck(@NonNull String locale, @NonNull String text) {
    String[] localeCodes = locale.split("-");
    Locale localeFromString = LocalizationPlugin.localeFromString(locale);

    if (mSpellCheckerSession == null) {
      mSpellCheckerSession =
          mTextServicesManager.newSpellCheckerSession(
              null,
              localeFromString,
              this,
              /** referToSpellCheckerLanguageSettings= */
              true);
    }

    TextInfo[] textInfos = new TextInfo[] {new TextInfo(text)};
    mSpellCheckerSession.getSentenceSuggestions(textInfos, MAX_SPELL_CHECK_SUGGESTIONS);
  }

  /**
   * Callback for Android spell check API that decomposes results and send results through the
   * {@link SpellCheckChannel}.
   *
   * <p>Spell check results will be encoded as a string representing the span of that result, with
   * the format "start_index.end_index.suggestion_1/nsuggestion_2/nsuggestion_3", where there may be
   * up to 5 suggestions.
   */
  @Override
  public void onGetSentenceSuggestions(SentenceSuggestionsInfo[] results) {
    if (results.length == 0) {
      pendingResult.success(new ArrayList<String>());
      pendingResult = null;
      return;
    }

    ArrayList<String> spellCheckerSuggestionSpans = new ArrayList<String>();
    SentenceSuggestionsInfo spellCheckResults = results[0];

    for (int i = 0; i < spellCheckResults.getSuggestionsCount(); i++) {
      SuggestionsInfo suggestionsInfo = spellCheckResults.getSuggestionsInfoAt(i);
      int suggestionsCount = suggestionsInfo.getSuggestionsCount();

      if (suggestionsCount <= 0) {
        continue;
      }

      String spellCheckerSuggestionSpan = "";
      int start = spellCheckResults.getOffsetAt(i);
      int end = start + spellCheckResults.getLengthAt(i) - 1;

      spellCheckerSuggestionSpan += String.valueOf(start) + ".";
      spellCheckerSuggestionSpan += String.valueOf(end) + ".";

      for (int j = 0; j < suggestionsCount; j++) {
        spellCheckerSuggestionSpan += suggestionsInfo.getSuggestionAt(j) + "\n";
      }

      spellCheckerSuggestionSpans.add(
          spellCheckerSuggestionSpan.substring(0, spellCheckerSuggestionSpan.length() - 1));
    }

    pendingResult.success(spellCheckerSuggestionSpans);
    pendingResult = null;
  }

  @Override
  public void onGetSuggestions(SuggestionsInfo[] results) {
    // Deprecated callback for Android spell check API; will not use.
  }
}
