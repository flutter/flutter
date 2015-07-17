// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/shortcut.h"

#include <shellapi.h>
#include <shldisp.h>
#include <shlobj.h>
#include <propkey.h>

#include "base/files/file_util.h"
#include "base/strings/string_util.h"
#include "base/threading/thread_restrictions.h"
#include "base/win/scoped_bstr.h"
#include "base/win/scoped_comptr.h"
#include "base/win/scoped_handle.h"
#include "base/win/scoped_propvariant.h"
#include "base/win/scoped_variant.h"
#include "base/win/win_util.h"
#include "base/win/windows_version.h"

namespace base {
namespace win {

namespace {

// String resource IDs in shell32.dll.
const uint32_t kPinToTaskbarID = 5386;
const uint32_t kUnpinFromTaskbarID = 5387;

// Traits for a GenericScopedHandle that will free a module on closure.
struct ModuleTraits {
  typedef HMODULE Handle;
  static Handle NullHandle() { return nullptr; }
  static bool IsHandleValid(Handle module) { return !!module; }
  static bool CloseHandle(Handle module) { return !!::FreeLibrary(module); }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(ModuleTraits);
};

// An object that will free a module when it goes out of scope.
using ScopedLibrary = GenericScopedHandle<ModuleTraits, DummyVerifierTraits>;

// Returns the shell resource string identified by |resource_id|, or an empty
// string on error.
string16 LoadShellResourceString(uint32_t resource_id) {
  ScopedLibrary shell32(::LoadLibrary(L"shell32.dll"));
  if (!shell32.IsValid())
    return string16();

  const wchar_t* resource_ptr = nullptr;
  int length = ::LoadStringW(shell32.Get(), resource_id,
                             reinterpret_cast<wchar_t*>(&resource_ptr), 0);
  if (!length || !resource_ptr)
    return string16();
  return string16(resource_ptr, length);
}

// Uses the shell to perform the verb identified by |resource_id| on |path|.
bool DoVerbOnFile(uint32_t resource_id, const FilePath& path) {
  string16 verb_name(LoadShellResourceString(resource_id));
  if (verb_name.empty())
    return false;

  ScopedComPtr<IShellDispatch> shell_dispatch;
  HRESULT hresult =
      shell_dispatch.CreateInstance(CLSID_Shell, nullptr, CLSCTX_INPROC_SERVER);
  if (FAILED(hresult) || !shell_dispatch.get())
    return false;

  ScopedComPtr<Folder> folder;
  hresult = shell_dispatch->NameSpace(
      ScopedVariant(path.DirName().value().c_str()), folder.Receive());
  if (FAILED(hresult) || !folder.get())
    return false;

  ScopedComPtr<FolderItem> item;
  hresult = folder->ParseName(ScopedBstr(path.BaseName().value().c_str()),
                              item.Receive());
  if (FAILED(hresult) || !item.get())
    return false;

  ScopedComPtr<FolderItemVerbs> verbs;
  hresult = item->Verbs(verbs.Receive());
  if (FAILED(hresult) || !verbs.get())
    return false;

  long verb_count = 0;
  hresult = verbs->get_Count(&verb_count);
  if (FAILED(hresult))
    return false;

  for (long i = 0; i < verb_count; ++i) {
    ScopedComPtr<FolderItemVerb> verb;
    hresult = verbs->Item(ScopedVariant(i, VT_I4), verb.Receive());
    if (FAILED(hresult) || !verb.get())
      continue;
    ScopedBstr name;
    hresult = verb->get_Name(name.Receive());
    if (FAILED(hresult))
      continue;
    if (StringPiece16(name, name.Length()) == verb_name) {
      hresult = verb->DoIt();
      return SUCCEEDED(hresult);
    }
  }
  return false;
}

// Initializes |i_shell_link| and |i_persist_file| (releasing them first if they
// are already initialized).
// If |shortcut| is not NULL, loads |shortcut| into |i_persist_file|.
// If any of the above steps fail, both |i_shell_link| and |i_persist_file| will
// be released.
void InitializeShortcutInterfaces(
    const wchar_t* shortcut,
    ScopedComPtr<IShellLink>* i_shell_link,
    ScopedComPtr<IPersistFile>* i_persist_file) {
  i_shell_link->Release();
  i_persist_file->Release();
  if (FAILED(i_shell_link->CreateInstance(CLSID_ShellLink, NULL,
                                          CLSCTX_INPROC_SERVER)) ||
      FAILED(i_persist_file->QueryFrom(i_shell_link->get())) ||
      (shortcut && FAILED((*i_persist_file)->Load(shortcut, STGM_READWRITE)))) {
    i_shell_link->Release();
    i_persist_file->Release();
  }
}

}  // namespace

ShortcutProperties::ShortcutProperties()
    : icon_index(-1), dual_mode(false), options(0U) {
}

ShortcutProperties::~ShortcutProperties() {
}

bool CreateOrUpdateShortcutLink(const FilePath& shortcut_path,
                                const ShortcutProperties& properties,
                                ShortcutOperation operation) {
  base::ThreadRestrictions::AssertIOAllowed();

  // A target is required unless |operation| is SHORTCUT_UPDATE_EXISTING.
  if (operation != SHORTCUT_UPDATE_EXISTING &&
      !(properties.options & ShortcutProperties::PROPERTIES_TARGET)) {
    NOTREACHED();
    return false;
  }

  bool shortcut_existed = PathExists(shortcut_path);

  // Interfaces to the old shortcut when replacing an existing shortcut.
  ScopedComPtr<IShellLink> old_i_shell_link;
  ScopedComPtr<IPersistFile> old_i_persist_file;

  // Interfaces to the shortcut being created/updated.
  ScopedComPtr<IShellLink> i_shell_link;
  ScopedComPtr<IPersistFile> i_persist_file;
  switch (operation) {
    case SHORTCUT_CREATE_ALWAYS:
      InitializeShortcutInterfaces(NULL, &i_shell_link, &i_persist_file);
      break;
    case SHORTCUT_UPDATE_EXISTING:
      InitializeShortcutInterfaces(shortcut_path.value().c_str(), &i_shell_link,
                                   &i_persist_file);
      break;
    case SHORTCUT_REPLACE_EXISTING:
      InitializeShortcutInterfaces(shortcut_path.value().c_str(),
                                   &old_i_shell_link, &old_i_persist_file);
      // Confirm |shortcut_path| exists and is a shortcut by verifying
      // |old_i_persist_file| was successfully initialized in the call above. If
      // so, initialize the interfaces to begin writing a new shortcut (to
      // overwrite the current one if successful).
      if (old_i_persist_file.get())
        InitializeShortcutInterfaces(NULL, &i_shell_link, &i_persist_file);
      break;
    default:
      NOTREACHED();
  }

  // Return false immediately upon failure to initialize shortcut interfaces.
  if (!i_persist_file.get())
    return false;

  if ((properties.options & ShortcutProperties::PROPERTIES_TARGET) &&
      FAILED(i_shell_link->SetPath(properties.target.value().c_str()))) {
    return false;
  }

  if ((properties.options & ShortcutProperties::PROPERTIES_WORKING_DIR) &&
      FAILED(i_shell_link->SetWorkingDirectory(
          properties.working_dir.value().c_str()))) {
    return false;
  }

  if (properties.options & ShortcutProperties::PROPERTIES_ARGUMENTS) {
    if (FAILED(i_shell_link->SetArguments(properties.arguments.c_str())))
      return false;
  } else if (old_i_persist_file.get()) {
    wchar_t current_arguments[MAX_PATH] = {0};
    if (SUCCEEDED(old_i_shell_link->GetArguments(current_arguments,
                                                 MAX_PATH))) {
      i_shell_link->SetArguments(current_arguments);
    }
  }

  if ((properties.options & ShortcutProperties::PROPERTIES_DESCRIPTION) &&
      FAILED(i_shell_link->SetDescription(properties.description.c_str()))) {
    return false;
  }

  if ((properties.options & ShortcutProperties::PROPERTIES_ICON) &&
      FAILED(i_shell_link->SetIconLocation(properties.icon.value().c_str(),
                                           properties.icon_index))) {
    return false;
  }

  bool has_app_id =
      (properties.options & ShortcutProperties::PROPERTIES_APP_ID) != 0;
  bool has_dual_mode =
      (properties.options & ShortcutProperties::PROPERTIES_DUAL_MODE) != 0;
  if ((has_app_id || has_dual_mode) &&
      GetVersion() >= VERSION_WIN7) {
    ScopedComPtr<IPropertyStore> property_store;
    if (FAILED(property_store.QueryFrom(i_shell_link.get())) ||
        !property_store.get())
      return false;

    if (has_app_id &&
        !SetAppIdForPropertyStore(property_store.get(),
                                  properties.app_id.c_str())) {
      return false;
    }
    if (has_dual_mode &&
        !SetBooleanValueForPropertyStore(property_store.get(),
                                         PKEY_AppUserModel_IsDualMode,
                                         properties.dual_mode)) {
      return false;
    }
  }

  // Release the interfaces to the old shortcut to make sure it doesn't prevent
  // overwriting it if needed.
  old_i_persist_file.Release();
  old_i_shell_link.Release();

  HRESULT result = i_persist_file->Save(shortcut_path.value().c_str(), TRUE);

  // Release the interfaces in case the SHChangeNotify call below depends on
  // the operations above being fully completed.
  i_persist_file.Release();
  i_shell_link.Release();

  // If we successfully created/updated the icon, notify the shell that we have
  // done so.
  const bool succeeded = SUCCEEDED(result);
  if (succeeded) {
    if (shortcut_existed) {
      // TODO(gab): SHCNE_UPDATEITEM might be sufficient here; further testing
      // required.
      SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NULL, NULL);
    } else {
      SHChangeNotify(SHCNE_CREATE, SHCNF_PATH, shortcut_path.value().c_str(),
                     NULL);
    }
  }

  return succeeded;
}

bool ResolveShortcutProperties(const FilePath& shortcut_path,
                               uint32 options,
                               ShortcutProperties* properties) {
  DCHECK(options && properties);
  base::ThreadRestrictions::AssertIOAllowed();

  if (options & ~ShortcutProperties::PROPERTIES_ALL)
    NOTREACHED() << "Unhandled property is used.";

  ScopedComPtr<IShellLink> i_shell_link;

  // Get pointer to the IShellLink interface.
  if (FAILED(i_shell_link.CreateInstance(CLSID_ShellLink, NULL,
                                         CLSCTX_INPROC_SERVER))) {
    return false;
  }

  ScopedComPtr<IPersistFile> persist;
  // Query IShellLink for the IPersistFile interface.
  if (FAILED(persist.QueryFrom(i_shell_link.get())))
    return false;

  // Load the shell link.
  if (FAILED(persist->Load(shortcut_path.value().c_str(), STGM_READ)))
    return false;

  // Reset |properties|.
  properties->options = 0;

  wchar_t temp[MAX_PATH];
  if (options & ShortcutProperties::PROPERTIES_TARGET) {
    if (FAILED(i_shell_link->GetPath(temp, MAX_PATH, NULL, SLGP_UNCPRIORITY)))
      return false;
    properties->set_target(FilePath(temp));
  }

  if (options & ShortcutProperties::PROPERTIES_WORKING_DIR) {
    if (FAILED(i_shell_link->GetWorkingDirectory(temp, MAX_PATH)))
      return false;
    properties->set_working_dir(FilePath(temp));
  }

  if (options & ShortcutProperties::PROPERTIES_ARGUMENTS) {
    if (FAILED(i_shell_link->GetArguments(temp, MAX_PATH)))
      return false;
    properties->set_arguments(temp);
  }

  if (options & ShortcutProperties::PROPERTIES_DESCRIPTION) {
    // Note: description length constrained by MAX_PATH.
    if (FAILED(i_shell_link->GetDescription(temp, MAX_PATH)))
      return false;
    properties->set_description(temp);
  }

  if (options & ShortcutProperties::PROPERTIES_ICON) {
    int temp_index;
    if (FAILED(i_shell_link->GetIconLocation(temp, MAX_PATH, &temp_index)))
      return false;
    properties->set_icon(FilePath(temp), temp_index);
  }

  // Windows 7+ options, avoiding unnecessary work.
  if ((options & ShortcutProperties::PROPERTIES_WIN7) &&
      GetVersion() >= VERSION_WIN7) {
    ScopedComPtr<IPropertyStore> property_store;
    if (FAILED(property_store.QueryFrom(i_shell_link.get())))
      return false;

    if (options & ShortcutProperties::PROPERTIES_APP_ID) {
      ScopedPropVariant pv_app_id;
      if (property_store->GetValue(PKEY_AppUserModel_ID,
                                   pv_app_id.Receive()) != S_OK) {
        return false;
      }
      switch (pv_app_id.get().vt) {
        case VT_EMPTY:
          properties->set_app_id(L"");
          break;
        case VT_LPWSTR:
          properties->set_app_id(pv_app_id.get().pwszVal);
          break;
        default:
          NOTREACHED() << "Unexpected variant type: " << pv_app_id.get().vt;
          return false;
      }
    }

    if (options & ShortcutProperties::PROPERTIES_DUAL_MODE) {
      ScopedPropVariant pv_dual_mode;
      if (property_store->GetValue(PKEY_AppUserModel_IsDualMode,
                                   pv_dual_mode.Receive()) != S_OK) {
        return false;
      }
      switch (pv_dual_mode.get().vt) {
        case VT_EMPTY:
          properties->set_dual_mode(false);
          break;
        case VT_BOOL:
          properties->set_dual_mode(pv_dual_mode.get().boolVal == VARIANT_TRUE);
          break;
        default:
          NOTREACHED() << "Unexpected variant type: " << pv_dual_mode.get().vt;
          return false;
      }
    }
  }

  return true;
}

bool ResolveShortcut(const FilePath& shortcut_path,
                     FilePath* target_path,
                     string16* args) {
  uint32 options = 0;
  if (target_path)
    options |= ShortcutProperties::PROPERTIES_TARGET;
  if (args)
    options |= ShortcutProperties::PROPERTIES_ARGUMENTS;
  DCHECK(options);

  ShortcutProperties properties;
  if (!ResolveShortcutProperties(shortcut_path, options, &properties))
    return false;

  if (target_path)
    *target_path = properties.target;
  if (args)
    *args = properties.arguments;
  return true;
}

bool TaskbarPinShortcutLink(const FilePath& shortcut) {
  base::ThreadRestrictions::AssertIOAllowed();

  // "Pin to taskbar" is only supported after Win7.
  if (GetVersion() < VERSION_WIN7)
    return false;

  return DoVerbOnFile(kPinToTaskbarID, shortcut);
}

bool TaskbarUnpinShortcutLink(const FilePath& shortcut) {
  base::ThreadRestrictions::AssertIOAllowed();

  // "Unpin from taskbar" is only supported after Win7.
  if (GetVersion() < VERSION_WIN7)
    return false;

  return DoVerbOnFile(kUnpinFromTaskbarID, shortcut);
}

}  // namespace win
}  // namespace base
