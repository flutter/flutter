## Files

### General

| File name | Explanation |
| ---- | ---- |
| [`physical_key_data.g.json`](physical_key_data.g.json) | Contains the merged physical key data from all the other sources. This file is regenerated if "--collect" is specified for the gen_keycodes script, or used as a source otherwise. |
| [`logical_key_data.g.json`](logical_key_data.g.json) | Contains the merged logical key data from all the other sources. This file is regenerated if "--collect" is specified for the gen_keycodes script, or used as a source otherwise. |
| [`supplemental_hid_codes.inc`](supplemental_hid_codes.inc) | A supplementary HID list on top of Chromium's list of HID codes for extra physical keys. Certain entries may also overwrite Chromium's corresponding entries. |
| [`supplemental_key_data.inc`](supplemental_key_data.inc) | A supplementary key list on top of Chromium's list of keys for extra logical keys.|
| [`chromium_modifiers.json`](chromium_modifiers.json) | Maps the web's `key` for modifier keys to the names of the logical keys for these keys' left and right variations.This is used when generating logical keys to provide independent values for sided logical keys. Web uses the same `key` for modifier keys of different sides, but Flutter's logical key model treats them as different keys.|
| [`printable.json`](printable.json) | Maps Flutter key name to its printable character. This character is used as the key label.|
| [`synonyms.json`](synonyms.json) | Maps pseudo-keys that represent other keys to the sets of keys they represent. For example, this contains the "shift" key that represents either a "shiftLeft" or "shiftRight" key.|
| [`layout_goals.json`](layout_goals.json) | A list of layout goals, keys that the platform keyboard manager should find mappings for. Each key in this file is the key name of the goal, both logical and physical simultaneously, while its value represents whether the goal is mandatory. A mandatory goal must be fulfilled, and the manager will use the default value from this file if a mapping can not be found. A non-mandatory goal is suggestive, only used if the key mapping information is malformed (e.g. contains no ASCII characters.) |

### Framework

| File name | Explanation |
| ---- | ---- |
| [`keyboard_key.tmpl`](keyboard_key.tmpl) | The template for `keyboard_key.g.dart`. |
| [`keyboard_maps.tmpl`](keyboard_maps.tmpl) | The template for `keyboard_maps.g.dart`. |


### Android

| File name | Explanation |
| ---- | ---- |
| [`android_keyboard_map_java.tmpl`](android_keyboard_map_java.tmpl) | The template for `KeyboardMap.java`. |
| [`android_key_name_to_name.json`](android_key_name_to_name.json) | Maps a logical key name to the names of its corresponding keycode constants. This is used to convert logical keys.|


### iOS

| File name | Explanation |
| ---- | ---- |
| [`ios_logical_to_physical.json`](ios_logical_to_physical.json) | Maps a logical key name to the names of its corresponding physical keys. This is used to derive logical keys (from `keyCode`) that can't or shouldn't be derived from `characterIgnoringModifiers`. |
| [`ios_key_code_map_mm.tmpl`](ios_key_code_map_mm.tmpl) | The template for `KeyCodeMap.mm`.|

### Web

| File name | Explanation |
| ---- | ---- |
| [`web_key_map_dart.tmpl`](web_key_map_dart.tmpl) | The template for `key_map.dart`. |
| [`web_logical_location_mapping.json`](web_logical_location_mapping.json) | Maps a pair of the web's `key` and `location` to the name for its corresponding logical key. This is used to distinguish between logical keys with the same `key` but different `locations`. |

### Windows

| File name | Explanation |
| ---- | ---- |
| [`windows_flutter_key_map_cc.tmpl`](windows_flutter_key_map_cc.tmpl) | The template for `flutter_key_map.cc`. |
| [`windows_logical_to_window_vk.json`](windows_logical_to_window_vk.json) | Maps a logical key name to the names of its corresponding virtual keys in Win32. |
| [`windows_scancode_logical_map.json`](windows_scancode_logical_map.json) | Maps a physical key name to a logical key name. This is used to when a `keycode` maps to multiple keys (including when the `keycode` is 0), therefore can only be told apart by the scan code. |

### Linux (GTK)

| File name | Explanation |
| ---- | ---- |
| [`gtk_key_mapping_cc.tmpl`](gtk_key_mapping_cc.tmpl) | The template for `key_mapping.cc`. |
| [`gtk_lock_bit_mapping.json`](gtk_lock_bit_mapping.json) | Maps a name for GTK's modifier bit macro to Flutter's logical name (element #0) and physical name (element #1). This is used to generate checked keys that GTK should keep lock state synchronous on.|
| [`gtk_logical_name_mapping.json`](gtk_logical_name_mapping.json) | Maps a logical key name to the macro names of its corresponding `keyval`s. This is used to convert logical keys.|
| [`gtk_modifier_bit_mapping.json`](gtk_modifier_bit_mapping.json) | Maps a name for GTK's modifier bit macro to Flutter's physical name (element #0), logical name (element #1), and the logical name for the paired key (element #2). This is used to generate checked keys where GTK should keep the pressed state synchronized.|
| [`gtk_numpad_shift.json`](gtk_numpad_shift.json) | Maps the name of a `keyval` macro of a numpad key to that of the corresponding key with NumLock on. GTK uses different `keyval` for numpad keys with and without NumLock on, but Flutter's logical key model treats them as the same key.|

### Linux (GLFW)

| File name | Explanation |
| ---- | ---- |
| [`glfw_key_name_to_name.json`](glfw_key_name_to_name.json) | Maps a logical key name to the names of its GLFW macro. (Unused for now.) |
| [`glfw_keyboard_map_cc.tmpl`](glfw_keyboard_map_cc.tmpl) | The template for `keyboard_map.cc`. (Unused for now.) |

### macOS

| File name | Explanation |
| ---- | ---- |
| [`macos_key_code_map_cc.tmpl`](macos_key_code_map_cc.tmpl) | The template for `KeyCodeMap.mm`. |
| [`macos_logical_to_physical.json`](macos_logical_to_physical.json) | Maps a logical key name to the names of its corresponding physical keys. This is used to derive logical keys (from `keyCode`) that can't or shouldn't be derived from `characterIgnoringModifiers`. |

### Fuchsia

| File name | Explanation |
| ---- | ---- |
| [`fuchsia_keyboard_map_cc.tmpl`](fuchsia_keyboard_map_cc.tmpl) | The template for `keyboard_map.cc`. (Unused for now.) |
