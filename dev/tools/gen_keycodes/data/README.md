## Files

### For This Tool

| File name | Explanation |
| ---- | ---- |
| `chromium_modifiers.json` | Maps Web's `key` of modifier keys to the names of the logical keys for these keys' left and right variations. This is used supplement the list of logical keys based on Chromium's list of `key`s, whose indistinction of left and right modifier keys is undesired in Flutter's key model.|
| `supplemental_hid_codes.inc` | A supplementary HID list on top of Chromium's list of HID codes for extra physical keys.|
| `physical_key_data.json` | Contains the merged physical key data from all the other sources. This file is regenerated if "--collect" is specified for the gen_keycodes script, or used as a source otherwise. |
| `logicall_key_data.json` | Contains the merged logical key data from all the other sources. This file is regenerated if "--collect" is specified for the gen_keycodes script, or used as a source otherwise. |

### Framework

| File name | Explanation |
| ---- | ---- |
| `data/keyboard_keys.tmpl` | The template for `keyboard_keys.dart`. |
| `data/keyboard_maps.tmpl` | The template for `keyboard_maps.dart`. |


### Android

| File name | Explanation |
| ---- | ---- |
| `android_keyboard_map_java.tmpl` | The template for `KeyboardMap.java`. |
| `android_key_name_to_name.json` | Maps a logical key name to the names of its corresponding keycode constants. This is used to convert logical keys.|


### iOS

### Web

| File name | Explanation |
| ---- | ---- |
| `web_key_map_dart.tmpl` | The template for `key_map.dart`. |
| `web_logical_location_mapping.json` | Maps a pair of Web's `key` and `locaion` to the name for its corresponding logical key. This is used to distinguish between logical keys with the same `key` but different `locations`. |

### Windows

| File name | Explanation |
| ---- | ---- |
| `windows_flutter_key_map_cc.tmpl` | The template for `flutter_key_map.cc`. |
| `windows_logical_to_window_vk.json` | Maps a logical key name to the names of its corresponding virtual keys in Win32. |
| `windows_scancode_logical_map.json` | Maps a physical key name to a logical key name. This is used to when a `keycode` maps to multiple keys (including when the `keycode` is 0), therefore can only be told apart by the scan code. |

### Linux (GTK)

| File name | Explanation |
| ---- | ---- |
| `gtk_keyboard_map_cc.tmpl` | The template for `keyboard_map.cc`. |
| `gtk_logical_name_mapping.json` | Maps a logical key name to the macro names of its corresponding `keyval`s. This is used to convert logical keys.|
| `gtk_numpad_shift.json` | Maps the name of a `keyval` macro of a numpad key to that of the corresponding key with NumLock on. GTK uses different `keyval` for numpad keys with and without NumLock on, but Flutter's logical key model treats them as the same key.|

### macOS

| File name | Explanation |
| ---- | ---- |
| `macos_key_code_map_cc.tmpl` | The template for `KeyCodeMap.cc`. |
| `macos_logical_to_physical.json` | Maps a logical key name to the names of its corresponding physical keys. This is used to derive logical keys (from `keyCode`) that can't or shouldn't be derived from `characterIgnoringModifiers`. |
