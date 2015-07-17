// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_SHORTCUT_H_
#define BASE_WIN_SHORTCUT_H_

#include <windows.h>

#include "base/base_export.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/strings/string16.h"

namespace base {
namespace win {

enum ShortcutOperation {
  // Create a new shortcut (overwriting if necessary).
  SHORTCUT_CREATE_ALWAYS = 0,
  // Overwrite an existing shortcut (fails if the shortcut doesn't exist).
  // If the arguments are not specified on the new shortcut, keep the old
  // shortcut's arguments.
  SHORTCUT_REPLACE_EXISTING,
  // Update specified properties only on an existing shortcut.
  SHORTCUT_UPDATE_EXISTING,
};

// Properties for shortcuts. Properties set will be applied to the shortcut on
// creation/update, others will be ignored.
// Callers are encouraged to use the setters provided which take care of
// setting |options| as desired.
struct BASE_EXPORT ShortcutProperties {
  enum IndividualProperties {
    PROPERTIES_TARGET = 1U << 0,
    PROPERTIES_WORKING_DIR = 1U << 1,
    PROPERTIES_ARGUMENTS = 1U << 2,
    PROPERTIES_DESCRIPTION = 1U << 3,
    PROPERTIES_ICON = 1U << 4,
    PROPERTIES_APP_ID = 1U << 5,
    PROPERTIES_DUAL_MODE = 1U << 6,
    // Be sure to update the values below when adding a new property.
    PROPERTIES_BASIC = PROPERTIES_TARGET |
        PROPERTIES_WORKING_DIR |
        PROPERTIES_ARGUMENTS |
        PROPERTIES_DESCRIPTION |
        PROPERTIES_ICON,
    PROPERTIES_WIN7 = PROPERTIES_APP_ID | PROPERTIES_DUAL_MODE,
    PROPERTIES_ALL = PROPERTIES_BASIC | PROPERTIES_WIN7
  };

  ShortcutProperties();
  ~ShortcutProperties();

  void set_target(const FilePath& target_in) {
    target = target_in;
    options |= PROPERTIES_TARGET;
  }

  void set_working_dir(const FilePath& working_dir_in) {
    working_dir = working_dir_in;
    options |= PROPERTIES_WORKING_DIR;
  }

  void set_arguments(const string16& arguments_in) {
    // Size restriction as per MSDN at http://goo.gl/TJ7q5.
    DCHECK(arguments_in.size() < MAX_PATH);
    arguments = arguments_in;
    options |= PROPERTIES_ARGUMENTS;
  }

  void set_description(const string16& description_in) {
    // Size restriction as per MSDN at http://goo.gl/OdNQq.
    DCHECK(description_in.size() < MAX_PATH);
    description = description_in;
    options |= PROPERTIES_DESCRIPTION;
  }

  void set_icon(const FilePath& icon_in, int icon_index_in) {
    icon = icon_in;
    icon_index = icon_index_in;
    options |= PROPERTIES_ICON;
  }

  void set_app_id(const string16& app_id_in) {
    app_id = app_id_in;
    options |= PROPERTIES_APP_ID;
  }

  void set_dual_mode(bool dual_mode_in) {
    dual_mode = dual_mode_in;
    options |= PROPERTIES_DUAL_MODE;
  }

  // The target to launch from this shortcut. This is mandatory when creating
  // a shortcut.
  FilePath target;
  // The name of the working directory when launching the shortcut.
  FilePath working_dir;
  // The arguments to be applied to |target| when launching from this shortcut.
  // The length of this string must be less than MAX_PATH.
  string16 arguments;
  // The localized description of the shortcut.
  // The length of this string must be less than MAX_PATH.
  string16 description;
  // The path to the icon (can be a dll or exe, in which case |icon_index| is
  // the resource id).
  FilePath icon;
  int icon_index;
  // The app model id for the shortcut (Win7+).
  string16 app_id;
  // Whether this is a dual mode shortcut (Win8+).
  bool dual_mode;
  // Bitfield made of IndividualProperties. Properties set in |options| will be
  // set on the shortcut, others will be ignored.
  uint32 options;
};

// This method creates (or updates) a shortcut link at |shortcut_path| using the
// information given through |properties|.
// Ensure you have initialized COM before calling into this function.
// |operation|: a choice from the ShortcutOperation enum.
// If |operation| is SHORTCUT_REPLACE_EXISTING or SHORTCUT_UPDATE_EXISTING and
// |shortcut_path| does not exist, this method is a no-op and returns false.
BASE_EXPORT bool CreateOrUpdateShortcutLink(
    const FilePath& shortcut_path,
    const ShortcutProperties& properties,
    ShortcutOperation operation);

// Resolves Windows shortcut (.LNK file).
// This methods tries to resolve selected properties of a shortcut .LNK file.
// The path of the shortcut to resolve is in |shortcut_path|. |options| is a bit
// field composed of ShortcutProperties::IndividualProperties, to specify which
// properties to read. It should be non-0. The resulting data are read into
// |properties|, which must not be NULL. Note: PROPERTIES_TARGET will retrieve
// the target path as stored in the shortcut but won't attempt to resolve that
// path so it may not be valid. The function returns true if all requested
// properties are successfully read. Otherwise some reads have failed and
// intermediate values written to |properties| should be ignored.
BASE_EXPORT bool ResolveShortcutProperties(const FilePath& shortcut_path,
                                           uint32 options,
                                           ShortcutProperties* properties);

// Resolves Windows shortcut (.LNK file).
// This is a wrapper to ResolveShortcutProperties() to handle the common use
// case of resolving target and arguments. |target_path| and |args| are
// optional output variables that are ignored if NULL (but at least one must be
// non-NULL). The function returns true if all requested fields are found
// successfully. Callers can safely use the same variable for both
// |shortcut_path| and |target_path|.
BASE_EXPORT bool ResolveShortcut(const FilePath& shortcut_path,
                                 FilePath* target_path,
                                 string16* args);

// Pins a shortcut to the Windows 7 taskbar. The shortcut file must already
// exist and be a shortcut that points to an executable. The app id of the
// shortcut is used to group windows and must be set correctly.
BASE_EXPORT bool TaskbarPinShortcutLink(const FilePath& shortcut);

// Unpins a shortcut from the Windows 7 taskbar. The shortcut must exist and
// already be pinned to the taskbar. The app id of the shortcut is used as the
// identifier for the taskbar item to remove and must be set correctly.
BASE_EXPORT bool TaskbarUnpinShortcutLink(const FilePath& shortcut);

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_SHORTCUT_H_
