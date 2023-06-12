// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.sharedpreferences;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Base64;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.sharedpreferences.Messages.SharedPreferencesApi;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** SharedPreferencesPlugin */
public class SharedPreferencesPlugin implements FlutterPlugin, SharedPreferencesApi {
  private static final String TAG = "SharedPreferencesPlugin";
  private static final String SHARED_PREFERENCES_NAME = "FlutterSharedPreferences";
  private static final String LIST_IDENTIFIER = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu";
  private static final String BIG_INTEGER_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy";
  private static final String DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu";

  private SharedPreferences preferences;
  private SharedPreferencesListEncoder listEncoder;

  public SharedPreferencesPlugin() {
    this(new ListEncoder());
  }

  @VisibleForTesting
  SharedPreferencesPlugin(@NonNull SharedPreferencesListEncoder listEncoder) {
    this.listEncoder = listEncoder;
  }

  @SuppressWarnings("deprecation")
  public static void registerWith(
      @NonNull io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    final SharedPreferencesPlugin plugin = new SharedPreferencesPlugin();
    plugin.setUp(registrar.messenger(), registrar.context());
  }

  private void setUp(@NonNull BinaryMessenger messenger, @NonNull Context context) {
    preferences = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
    try {
      SharedPreferencesApi.setup(messenger, this);
    } catch (Exception ex) {
      Log.e(TAG, "Received exception while setting up SharedPreferencesPlugin", ex);
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    setUp(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    SharedPreferencesApi.setup(binding.getBinaryMessenger(), null);
  }

  @Override
  public @NonNull Boolean setBool(@NonNull String key, @NonNull Boolean value) {
    return preferences.edit().putBoolean(key, value).commit();
  }

  @Override
  public @NonNull Boolean setString(@NonNull String key, @NonNull String value) {
    // TODO (tarrinneal): Move this string prefix checking logic to dart code and make it an Argument Error.
    if (value.startsWith(LIST_IDENTIFIER)
        || value.startsWith(BIG_INTEGER_PREFIX)
        || value.startsWith(DOUBLE_PREFIX)) {
      throw new RuntimeException(
          "StorageError: This string cannot be stored as it clashes with special identifier prefixes");
    }
    return preferences.edit().putString(key, value).commit();
  }

  @Override
  public @NonNull Boolean setInt(@NonNull String key, @NonNull Long value) {
    return preferences.edit().putLong(key, value).commit();
  }

  @Override
  public @NonNull Boolean setDouble(@NonNull String key, @NonNull Double value) {
    String doubleValueStr = Double.toString(value);
    return preferences.edit().putString(key, DOUBLE_PREFIX + doubleValueStr).commit();
  }

  @Override
  public @NonNull Boolean remove(@NonNull String key) {
    return preferences.edit().remove(key).commit();
  }

  @Override
  public @NonNull Boolean setStringList(@NonNull String key, @NonNull List<String> value)
      throws RuntimeException {
    return preferences.edit().putString(key, LIST_IDENTIFIER + listEncoder.encode(value)).commit();
  }

  @Override
  public @NonNull Map<String, Object> getAllWithPrefix(@NonNull String prefix)
      throws RuntimeException {
    return getAllPrefs(prefix);
  }

  @Override
  public @NonNull Boolean clearWithPrefix(@NonNull String prefix) throws RuntimeException {
    SharedPreferences.Editor clearEditor = preferences.edit();
    Map<String, ?> allPrefs = preferences.getAll();
    ArrayList<String> filteredPrefs = new ArrayList<>();
    for (String key : allPrefs.keySet()) {
      if (key.startsWith(prefix)) {
        filteredPrefs.add(key);
      }
    }
    for (String key : filteredPrefs) {
      clearEditor.remove(key);
    }
    return clearEditor.commit();
  }

  // Gets all shared preferences, filtered to only those set with the given prefix.
  @SuppressWarnings("unchecked")
  private @NonNull Map<String, Object> getAllPrefs(@NonNull String prefix) throws RuntimeException {
    Map<String, ?> allPrefs = preferences.getAll();
    Map<String, Object> filteredPrefs = new HashMap<>();
    for (String key : allPrefs.keySet()) {
      if (key.startsWith(prefix)) {
        filteredPrefs.put(key, transformPref(key, allPrefs.get(key)));
      }
    }

    return filteredPrefs;
  }

  private Object transformPref(@NonNull String key, @NonNull Object value) {
    if (value instanceof String) {
      String stringValue = (String) value;
      if (stringValue.startsWith(LIST_IDENTIFIER)) {
        return listEncoder.decode(stringValue.substring(LIST_IDENTIFIER.length()));
      } else if (stringValue.startsWith(BIG_INTEGER_PREFIX)) {
        // TODO (tarrinneal): Remove all BigInt code.
        // https://github.com/flutter/flutter/issues/124420
        String encoded = stringValue.substring(BIG_INTEGER_PREFIX.length());
        return new BigInteger(encoded, Character.MAX_RADIX);
      } else if (stringValue.startsWith(DOUBLE_PREFIX)) {
        String doubleStr = stringValue.substring(DOUBLE_PREFIX.length());
        return Double.valueOf(doubleStr);
      }
    } else if (value instanceof Set) {
      // TODO (tarrinneal): Remove Set code.
      // https://github.com/flutter/flutter/issues/124420

      // This only happens for previous usage of setStringSet. The app expects a list.
      @SuppressWarnings("unchecked")
      List<String> listValue = new ArrayList<>((Set<String>) value);
      // Let's migrate the value too while we are at it.
      preferences
          .edit()
          .remove(key)
          .putString(key, LIST_IDENTIFIER + listEncoder.encode(listValue))
          .apply();

      return listValue;
    }
    return value;
  }

  static class ListEncoder implements SharedPreferencesListEncoder {
    @Override
    public @NonNull String encode(@NonNull List<String> list) throws RuntimeException {
      try {
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
        ObjectOutputStream stream = new ObjectOutputStream(byteStream);
        stream.writeObject(list);
        stream.flush();
        return Base64.encodeToString(byteStream.toByteArray(), 0);
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }

    @SuppressWarnings("unchecked")
    @Override
    public @NonNull List<String> decode(@NonNull String listString) throws RuntimeException {
      try {
        ObjectInputStream stream =
            new ObjectInputStream(new ByteArrayInputStream(Base64.decode(listString, 0)));
        return (List<String>) stream.readObject();
      } catch (IOException | ClassNotFoundException e) {
        throw new RuntimeException(e);
      }
    }
  }
}
