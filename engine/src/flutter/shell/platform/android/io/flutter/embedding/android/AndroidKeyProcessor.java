// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.plugin.editing.TextInputPlugin;

public class AndroidKeyProcessor {
  @NonNull private final KeyEventChannel keyEventChannel;
  @NonNull private final TextInputPlugin textInputPlugin;
  private int combiningCharacter;

  public AndroidKeyProcessor(
      @NonNull KeyEventChannel keyEventChannel, @NonNull TextInputPlugin textInputPlugin) {
    this.keyEventChannel = keyEventChannel;
    this.textInputPlugin = textInputPlugin;
  }

  public void onKeyUp(@NonNull KeyEvent keyEvent) {
    Character complexCharacter = applyCombiningCharacterToBaseCharacter(keyEvent.getUnicodeChar());
    keyEventChannel.keyUp(new KeyEventChannel.FlutterKeyEvent(keyEvent, complexCharacter));
  }

  public void onKeyDown(@NonNull KeyEvent keyEvent) {
    if (textInputPlugin.getLastInputConnection() != null
        && textInputPlugin.getInputMethodManager().isAcceptingText()) {
      textInputPlugin.getLastInputConnection().sendKeyEvent(keyEvent);
    }

    Character complexCharacter = applyCombiningCharacterToBaseCharacter(keyEvent.getUnicodeChar());
    keyEventChannel.keyDown(new KeyEventChannel.FlutterKeyEvent(keyEvent, complexCharacter));
  }

  /**
   * Applies the given Unicode character in {@code newCharacterCodePoint} to a previously entered
   * Unicode combining character and returns the combination of these characters if a combination
   * exists.
   *
   * <p>This method mutates {@link #combiningCharacter} over time to combine characters.
   *
   * <p>One of the following things happens in this method:
   *
   * <ul>
   *   <li>If no previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint}
   *       is not a combining character, then {@code newCharacterCodePoint} is returned.
   *   <li>If no previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint}
   *       is a combining character, then {@code newCharacterCodePoint} is saved as the {@link
   *       #combiningCharacter} and null is returned.
   *   <li>If a previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint} is
   *       also a combining character, then the {@code newCharacterCodePoint} is combined with the
   *       existing {@link #combiningCharacter} and null is returned.
   *   <li>If a previous {@link #combiningCharacter} exists and the {@code newCharacterCodePoint} is
   *       not a combining character, then the {@link #combiningCharacter} is applied to the regular
   *       {@code newCharacterCodePoint} and the resulting complex character is returned. The {@link
   *       #combiningCharacter} is cleared.
   * </ul>
   *
   * <p>The following reference explains the concept of a "combining character":
   * https://en.wikipedia.org/wiki/Combining_character
   */
  @Nullable
  private Character applyCombiningCharacterToBaseCharacter(int newCharacterCodePoint) {
    if (newCharacterCodePoint == 0) {
      return null;
    }

    Character complexCharacter = (char) newCharacterCodePoint;
    boolean isNewCodePointACombiningCharacter =
        (newCharacterCodePoint & KeyCharacterMap.COMBINING_ACCENT) != 0;
    if (isNewCodePointACombiningCharacter) {
      // If a combining character was entered before, combine this one with that one.
      int plainCodePoint = newCharacterCodePoint & KeyCharacterMap.COMBINING_ACCENT_MASK;
      if (combiningCharacter != 0) {
        combiningCharacter = KeyCharacterMap.getDeadChar(combiningCharacter, plainCodePoint);
      } else {
        combiningCharacter = plainCodePoint;
      }
    } else {
      // The new character is a regular character. Apply combiningCharacter to it, if it exists.
      if (combiningCharacter != 0) {
        int combinedChar = KeyCharacterMap.getDeadChar(combiningCharacter, newCharacterCodePoint);
        if (combinedChar > 0) {
          complexCharacter = (char) combinedChar;
        }
        combiningCharacter = 0;
      }
    }

    return complexCharacter;
  }
}
