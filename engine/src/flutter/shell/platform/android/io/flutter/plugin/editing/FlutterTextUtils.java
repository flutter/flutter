// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import io.flutter.embedding.engine.FlutterJNI;

class FlutterTextUtils {
  public static final int LINE_FEED = 0x0A;
  public static final int CARRIAGE_RETURN = 0x0D;
  public static final int COMBINING_ENCLOSING_KEYCAP = 0x20E3;
  public static final int CANCEL_TAG = 0xE007F;
  public static final int ZERO_WIDTH_JOINER = 0x200D;
  private final FlutterJNI flutterJNI;

  public FlutterTextUtils(FlutterJNI flutterJNI) {
    this.flutterJNI = flutterJNI;
  }

  public boolean isEmoji(int codePoint) {
    return flutterJNI.nativeFlutterTextUtilsIsEmoji(codePoint);
  }

  public boolean isEmojiModifier(int codePoint) {
    return flutterJNI.nativeFlutterTextUtilsIsEmojiModifier(codePoint);
  }

  public boolean isEmojiModifierBase(int codePoint) {
    return flutterJNI.nativeFlutterTextUtilsIsEmojiModifierBase(codePoint);
  }

  public boolean isVariationSelector(int codePoint) {
    return flutterJNI.nativeFlutterTextUtilsIsVariationSelector(codePoint);
  }

  public boolean isRegionalIndicatorSymbol(int codePoint) {
    return flutterJNI.nativeFlutterTextUtilsIsRegionalIndicator(codePoint);
  }

  public boolean isTagSpecChar(int codePoint) {
    return 0xE0020 <= codePoint && codePoint <= 0xE007E;
  }

  public boolean isKeycapBase(int codePoint) {
    return ('0' <= codePoint && codePoint <= '9') || codePoint == '#' || codePoint == '*';
  }

  /**
   * Start offset for backspace key or moving left from the current offset. Same methods are also
   * included in Android APIs but they don't work as expected in API Levels lower than 24. Reference
   * for the logic in this code is the Android source code.
   *
   * @see <a target="_new"
   *     href="https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android10-s3-release/core/java/android/text/method/BaseKeyListener.java#111">https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android10-s3-release/core/java/android/text/method/BaseKeyListener.java#111</a>
   */
  public int getOffsetBefore(CharSequence text, int offset) {
    if (offset <= 1) {
      return 0;
    }

    int codePoint = Character.codePointBefore(text, offset);
    int deleteCharCount = Character.charCount(codePoint);
    int lastOffset = offset - deleteCharCount;

    if (lastOffset == 0) {
      return 0;
    }

    // Line Feed
    if (codePoint == LINE_FEED) {
      codePoint = Character.codePointBefore(text, lastOffset);
      if (codePoint == CARRIAGE_RETURN) {
        ++deleteCharCount;
      }
      return offset - deleteCharCount;
    }

    // Flags
    if (isRegionalIndicatorSymbol(codePoint)) {
      codePoint = Character.codePointBefore(text, lastOffset);
      lastOffset -= Character.charCount(codePoint);
      int regionalIndicatorSymbolCount = 1;
      while (lastOffset > 0 && isRegionalIndicatorSymbol(codePoint)) {
        codePoint = Character.codePointBefore(text, lastOffset);
        lastOffset -= Character.charCount(codePoint);
        regionalIndicatorSymbolCount++;
      }
      if (regionalIndicatorSymbolCount % 2 == 0) {
        deleteCharCount += 2;
      }
      return offset - deleteCharCount;
    }

    // Keycaps
    if (codePoint == COMBINING_ENCLOSING_KEYCAP) {
      codePoint = Character.codePointBefore(text, lastOffset);
      lastOffset -= Character.charCount(codePoint);
      if (lastOffset > 0 && isVariationSelector(codePoint)) {
        int tmpCodePoint = Character.codePointBefore(text, lastOffset);
        if (isKeycapBase(tmpCodePoint)) {
          deleteCharCount += Character.charCount(codePoint) + Character.charCount(tmpCodePoint);
        }
      } else if (isKeycapBase(codePoint)) {
        deleteCharCount += Character.charCount(codePoint);
      }
      return offset - deleteCharCount;
    }

    /**
     * Following if statements for Emoji tag sequence and Variation selector are skipping these
     * modifiers for going through the last statement that is for handling emojis. They return the
     * offset if they don't find proper base characters
     */
    // Emoji Tag Sequence
    if (codePoint == CANCEL_TAG) { // tag_end
      codePoint = Character.codePointBefore(text, lastOffset);
      lastOffset -= Character.charCount(codePoint);
      while (lastOffset > 0 && isTagSpecChar(codePoint)) { // tag_spec
        deleteCharCount += Character.charCount(codePoint);
        codePoint = Character.codePointBefore(text, lastOffset);
        lastOffset -= Character.charCount(codePoint);
      }
      if (!isEmoji(codePoint)) { // tag_base not found. Just delete the end.
        return offset - 2;
      }
      deleteCharCount += Character.charCount(codePoint);
    }

    if (isVariationSelector(codePoint)) {
      codePoint = Character.codePointBefore(text, lastOffset);
      if (!isEmoji(codePoint)) {
        return offset - deleteCharCount;
      }
      deleteCharCount += Character.charCount(codePoint);

      lastOffset -= deleteCharCount;
    }

    if (isEmoji(codePoint)) {
      boolean isZwj = false;
      int lastSeenVariantSelectorCharCount = 0;
      do {
        if (isZwj) {
          deleteCharCount += Character.charCount(codePoint) + lastSeenVariantSelectorCharCount + 1;
          isZwj = false;
        }
        lastSeenVariantSelectorCharCount = 0;
        if (isEmojiModifier(codePoint)) {
          codePoint = Character.codePointBefore(text, lastOffset);
          lastOffset -= Character.charCount(codePoint);
          if (lastOffset > 0 && isVariationSelector(codePoint)) {
            codePoint = Character.codePointBefore(text, lastOffset);
            if (!isEmoji(codePoint)) {
              return offset - deleteCharCount;
            }
            lastSeenVariantSelectorCharCount = Character.charCount(codePoint);
            lastOffset -= Character.charCount(codePoint);
          }
          if (isEmojiModifierBase(codePoint)) {
            deleteCharCount += lastSeenVariantSelectorCharCount + Character.charCount(codePoint);
          }
          break;
        }

        if (lastOffset > 0) {
          codePoint = Character.codePointBefore(text, lastOffset);
          lastOffset -= Character.charCount(codePoint);
          if (codePoint == ZERO_WIDTH_JOINER) {
            isZwj = true;
            codePoint = Character.codePointBefore(text, lastOffset);
            lastOffset -= Character.charCount(codePoint);
            if (lastOffset > 0 && isVariationSelector(codePoint)) {
              codePoint = Character.codePointBefore(text, lastOffset);
              lastSeenVariantSelectorCharCount = Character.charCount(codePoint);
              lastOffset -= Character.charCount(codePoint);
            }
          }
        }

        if (lastOffset == 0) {
          break;
        }
      } while (isZwj && isEmoji(codePoint));
    }

    return offset - deleteCharCount;
  }
}
