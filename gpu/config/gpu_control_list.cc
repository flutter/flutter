// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_control_list.h"

#include "base/cpu.h"
#include "base/json/json_reader.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/sys_info.h"
#include "gpu/config/gpu_info.h"
#include "gpu/config/gpu_util.h"
#include "third_party/re2/re2/re2.h"

namespace gpu {
namespace {

// Break a version string into segments.  Return true if each segment is
// a valid number, and not all segment is 0.
bool ProcessVersionString(const std::string& version_string,
                          char splitter,
                          std::vector<std::string>* version) {
  DCHECK(version);
  base::SplitString(version_string, splitter, version);
  if (version->size() == 0)
    return false;
  // If the splitter is '-', we assume it's a date with format "mm-dd-yyyy";
  // we split it into the order of "yyyy", "mm", "dd".
  if (splitter == '-') {
    std::string year = (*version)[version->size() - 1];
    for (int i = version->size() - 1; i > 0; --i) {
      (*version)[i] = (*version)[i - 1];
    }
    (*version)[0] = year;
  }
  bool all_zero = true;
  for (size_t i = 0; i < version->size(); ++i) {
    unsigned num = 0;
    if (!base::StringToUint((*version)[i], &num))
      return false;
    if (num)
      all_zero = false;
  }
  return !all_zero;
}

// Compare two number strings using numerical ordering.
// Return  0 if number = number_ref,
//         1 if number > number_ref,
//        -1 if number < number_ref.
int CompareNumericalNumberStrings(
    const std::string& number, const std::string& number_ref) {
  unsigned value1 = 0;
  unsigned value2 = 0;
  bool valid = base::StringToUint(number, &value1);
  DCHECK(valid);
  valid = base::StringToUint(number_ref, &value2);
  DCHECK(valid);
  if (value1 == value2)
    return 0;
  if (value1 > value2)
    return 1;
  return -1;
}

// Compare two number strings using lexical ordering.
// Return  0 if number = number_ref,
//         1 if number > number_ref,
//        -1 if number < number_ref.
// We only compare as many digits as number_ref contains.
// If number_ref is xxx, it's considered as xxx*
// For example: CompareLexicalNumberStrings("121", "12") returns 0,
//              CompareLexicalNumberStrings("12", "121") returns -1.
int CompareLexicalNumberStrings(
    const std::string& number, const std::string& number_ref) {
  for (size_t i = 0; i < number_ref.length(); ++i) {
    unsigned value1 = 0;
    if (i < number.length())
      value1 = number[i] - '0';
    unsigned value2 = number_ref[i] - '0';
    if (value1 > value2)
      return 1;
    if (value1 < value2)
      return -1;
  }
  return 0;
}

// A mismatch is identified only if both |input| and |pattern| are not empty.
bool StringMismatch(const std::string& input, const std::string& pattern) {
  if (input.empty() || pattern.empty())
    return false;
  return !RE2::FullMatch(input, pattern);
}

const char kMultiGpuStyleStringAMDSwitchable[] = "amd_switchable";
const char kMultiGpuStyleStringAMDSwitchableDiscrete[] =
    "amd_switchable_discrete";
const char kMultiGpuStyleStringAMDSwitchableIntegrated[] =
    "amd_switchable_integrated";
const char kMultiGpuStyleStringOptimus[] = "optimus";

const char kMultiGpuCategoryStringPrimary[] = "primary";
const char kMultiGpuCategoryStringSecondary[] = "secondary";
const char kMultiGpuCategoryStringActive[] = "active";
const char kMultiGpuCategoryStringAny[] = "any";

const char kGLTypeStringGL[] = "gl";
const char kGLTypeStringGLES[] = "gles";
const char kGLTypeStringANGLE[] = "angle";

const char kVersionStyleStringNumerical[] = "numerical";
const char kVersionStyleStringLexical[] = "lexical";

const char kOp[] = "op";

}  // namespace anonymous

GpuControlList::VersionInfo::VersionInfo(
    const std::string& version_op,
    const std::string& version_style,
    const std::string& version_string,
    const std::string& version_string2)
    : version_style_(kVersionStyleNumerical) {
  op_ = StringToNumericOp(version_op);
  if (op_ == kUnknown || op_ == kAny)
    return;
  version_style_ = StringToVersionStyle(version_style);
  if (!ProcessVersionString(version_string, '.', &version_)) {
    op_ = kUnknown;
    return;
  }
  if (op_ == kBetween) {
    if (!ProcessVersionString(version_string2, '.', &version2_))
      op_ = kUnknown;
  }
}

GpuControlList::VersionInfo::~VersionInfo() {
}

bool GpuControlList::VersionInfo::Contains(
    const std::string& version_string) const {
  return Contains(version_string, '.');
}

bool GpuControlList::VersionInfo::Contains(
    const std::string& version_string, char splitter) const {
  if (op_ == kUnknown)
    return false;
  if (op_ == kAny)
    return true;
  std::vector<std::string> version;
  if (!ProcessVersionString(version_string, splitter, &version))
    return false;
  int relation = Compare(version, version_, version_style_);
  if (op_ == kEQ)
    return (relation == 0);
  else if (op_ == kLT)
    return (relation < 0);
  else if (op_ == kLE)
    return (relation <= 0);
  else if (op_ == kGT)
    return (relation > 0);
  else if (op_ == kGE)
    return (relation >= 0);
  // op_ == kBetween
  if (relation < 0)
    return false;
  return Compare(version, version2_, version_style_) <= 0;
}

bool GpuControlList::VersionInfo::IsValid() const {
  return (op_ != kUnknown && version_style_ != kVersionStyleUnknown);
}

bool GpuControlList::VersionInfo::IsLexical() const {
  return version_style_ == kVersionStyleLexical;
}

// static
int GpuControlList::VersionInfo::Compare(
    const std::vector<std::string>& version,
    const std::vector<std::string>& version_ref,
    VersionStyle version_style) {
  DCHECK(version.size() > 0 && version_ref.size() > 0);
  DCHECK(version_style != kVersionStyleUnknown);
  for (size_t i = 0; i < version_ref.size(); ++i) {
    if (i >= version.size())
      return 0;
    int ret = 0;
    // We assume both versions are checked by ProcessVersionString().
    if (i > 0 && version_style == kVersionStyleLexical)
      ret = CompareLexicalNumberStrings(version[i], version_ref[i]);
    else
      ret = CompareNumericalNumberStrings(version[i], version_ref[i]);
    if (ret != 0)
      return ret;
  }
  return 0;
}

// static
GpuControlList::VersionInfo::VersionStyle
GpuControlList::VersionInfo::StringToVersionStyle(
    const std::string& version_style) {
  if (version_style.empty() || version_style == kVersionStyleStringNumerical)
    return kVersionStyleNumerical;
  if (version_style == kVersionStyleStringLexical)
    return kVersionStyleLexical;
  return kVersionStyleUnknown;
}

GpuControlList::OsInfo::OsInfo(const std::string& os,
                             const std::string& version_op,
                             const std::string& version_string,
                             const std::string& version_string2) {
  type_ = StringToOsType(os);
  if (type_ != kOsUnknown) {
    version_info_.reset(new VersionInfo(
        version_op, std::string(), version_string, version_string2));
  }
}

GpuControlList::OsInfo::~OsInfo() {}

bool GpuControlList::OsInfo::Contains(
    OsType type, const std::string& version) const {
  if (!IsValid())
    return false;
  if (type_ != type && type_ != kOsAny)
    return false;
  std::string processed_version;
  size_t pos = version.find_first_not_of("0123456789.");
  if (pos != std::string::npos)
    processed_version = version.substr(0, pos);
  else
    processed_version = version;

  return version_info_->Contains(processed_version);
}

bool GpuControlList::OsInfo::IsValid() const {
  return type_ != kOsUnknown && version_info_->IsValid();
}

GpuControlList::OsType GpuControlList::OsInfo::type() const {
  return type_;
}

GpuControlList::OsType GpuControlList::OsInfo::StringToOsType(
    const std::string& os) {
  if (os == "win")
    return kOsWin;
  else if (os == "macosx")
    return kOsMacosx;
  else if (os == "android")
    return kOsAndroid;
  else if (os == "linux")
    return kOsLinux;
  else if (os == "chromeos")
    return kOsChromeOS;
  else if (os == "any")
    return kOsAny;
  return kOsUnknown;
}

GpuControlList::FloatInfo::FloatInfo(const std::string& float_op,
                                     const std::string& float_value,
                                     const std::string& float_value2)
    : op_(kUnknown),
      value_(0.f),
      value2_(0.f) {
  op_ = StringToNumericOp(float_op);
  if (op_ == kAny)
    return;
  double dvalue = 0;
  if (!base::StringToDouble(float_value, &dvalue)) {
    op_ = kUnknown;
    return;
  }
  value_ = static_cast<float>(dvalue);
  if (op_ == kBetween) {
    if (!base::StringToDouble(float_value2, &dvalue)) {
      op_ = kUnknown;
      return;
    }
    value2_ = static_cast<float>(dvalue);
  }
}

bool GpuControlList::FloatInfo::Contains(float value) const {
  if (op_ == kUnknown)
    return false;
  if (op_ == kAny)
    return true;
  if (op_ == kEQ)
    return (value == value_);
  if (op_ == kLT)
    return (value < value_);
  if (op_ == kLE)
    return (value <= value_);
  if (op_ == kGT)
    return (value > value_);
  if (op_ == kGE)
    return (value >= value_);
  DCHECK(op_ == kBetween);
  return ((value_ <= value && value <= value2_) ||
          (value2_ <= value && value <= value_));
}

bool GpuControlList::FloatInfo::IsValid() const {
  return op_ != kUnknown;
}

GpuControlList::IntInfo::IntInfo(const std::string& int_op,
                                 const std::string& int_value,
                                 const std::string& int_value2)
    : op_(kUnknown),
      value_(0),
      value2_(0) {
  op_ = StringToNumericOp(int_op);
  if (op_ == kAny)
    return;
  if (!base::StringToInt(int_value, &value_)) {
    op_ = kUnknown;
    return;
  }
  if (op_ == kBetween &&
      !base::StringToInt(int_value2, &value2_))
    op_ = kUnknown;
}

bool GpuControlList::IntInfo::Contains(int value) const {
  if (op_ == kUnknown)
    return false;
  if (op_ == kAny)
    return true;
  if (op_ == kEQ)
    return (value == value_);
  if (op_ == kLT)
    return (value < value_);
  if (op_ == kLE)
    return (value <= value_);
  if (op_ == kGT)
    return (value > value_);
  if (op_ == kGE)
    return (value >= value_);
  DCHECK(op_ == kBetween);
  return ((value_ <= value && value <= value2_) ||
          (value2_ <= value && value <= value_));
}

bool GpuControlList::IntInfo::IsValid() const {
  return op_ != kUnknown;
}

GpuControlList::BoolInfo::BoolInfo(bool value) : value_(value) {}

bool GpuControlList::BoolInfo::Contains(bool value) const {
  return value_ == value;
}

// static
GpuControlList::ScopedGpuControlListEntry
GpuControlList::GpuControlListEntry::GetEntryFromValue(
    const base::DictionaryValue* value, bool top_level,
    const FeatureMap& feature_map,
    bool supports_feature_type_all) {
  DCHECK(value);
  ScopedGpuControlListEntry entry(new GpuControlListEntry());

  size_t dictionary_entry_count = 0;

  if (top_level) {
    uint32 id;
    if (!value->GetInteger("id", reinterpret_cast<int*>(&id)) ||
        !entry->SetId(id)) {
      LOG(WARNING) << "Malformed id entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;

    bool disabled;
    if (value->GetBoolean("disabled", &disabled)) {
      entry->SetDisabled(disabled);
      dictionary_entry_count++;
    }
  }

  std::string description;
  if (value->GetString("description", &description)) {
    entry->description_ = description;
    dictionary_entry_count++;
  } else {
    entry->description_ = "The GPU is unavailable for an unexplained reason.";
  }

  const base::ListValue* cr_bugs;
  if (value->GetList("cr_bugs", &cr_bugs)) {
    for (size_t i = 0; i < cr_bugs->GetSize(); ++i) {
      int bug_id;
      if (cr_bugs->GetInteger(i, &bug_id)) {
        entry->cr_bugs_.push_back(bug_id);
      } else {
        LOG(WARNING) << "Malformed cr_bugs entry " << entry->id();
        return NULL;
      }
    }
    dictionary_entry_count++;
  }

  const base::ListValue* webkit_bugs;
  if (value->GetList("webkit_bugs", &webkit_bugs)) {
    for (size_t i = 0; i < webkit_bugs->GetSize(); ++i) {
      int bug_id;
      if (webkit_bugs->GetInteger(i, &bug_id)) {
        entry->webkit_bugs_.push_back(bug_id);
      } else {
        LOG(WARNING) << "Malformed webkit_bugs entry " << entry->id();
        return NULL;
      }
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* os_value = NULL;
  if (value->GetDictionary("os", &os_value)) {
    std::string os_type;
    std::string os_version_op = "any";
    std::string os_version_string;
    std::string os_version_string2;
    os_value->GetString("type", &os_type);
    const base::DictionaryValue* os_version_value = NULL;
    if (os_value->GetDictionary("version", &os_version_value)) {
      os_version_value->GetString(kOp, &os_version_op);
      os_version_value->GetString("value", &os_version_string);
      os_version_value->GetString("value2", &os_version_string2);
    }
    if (!entry->SetOsInfo(os_type, os_version_op, os_version_string,
                          os_version_string2)) {
      LOG(WARNING) << "Malformed os entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string vendor_id;
  if (value->GetString("vendor_id", &vendor_id)) {
    if (!entry->SetVendorId(vendor_id)) {
      LOG(WARNING) << "Malformed vendor_id entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::ListValue* device_id_list;
  if (value->GetList("device_id", &device_id_list)) {
    for (size_t i = 0; i < device_id_list->GetSize(); ++i) {
      std::string device_id;
      if (!device_id_list->GetString(i, &device_id) ||
          !entry->AddDeviceId(device_id)) {
        LOG(WARNING) << "Malformed device_id entry " << entry->id();
        return NULL;
      }
    }
    dictionary_entry_count++;
  }

  std::string multi_gpu_style;
  if (value->GetString("multi_gpu_style", &multi_gpu_style)) {
    if (!entry->SetMultiGpuStyle(multi_gpu_style)) {
      LOG(WARNING) << "Malformed multi_gpu_style entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string multi_gpu_category;
  if (value->GetString("multi_gpu_category", &multi_gpu_category)) {
    if (!entry->SetMultiGpuCategory(multi_gpu_category)) {
      LOG(WARNING) << "Malformed multi_gpu_category entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string driver_vendor_value;
  if (value->GetString("driver_vendor", &driver_vendor_value)) {
    if (!entry->SetDriverVendorInfo(driver_vendor_value)) {
      LOG(WARNING) << "Malformed driver_vendor entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* driver_version_value = NULL;
  if (value->GetDictionary("driver_version", &driver_version_value)) {
    std::string driver_version_op = "any";
    std::string driver_version_style;
    std::string driver_version_string;
    std::string driver_version_string2;
    driver_version_value->GetString(kOp, &driver_version_op);
    driver_version_value->GetString("style", &driver_version_style);
    driver_version_value->GetString("value", &driver_version_string);
    driver_version_value->GetString("value2", &driver_version_string2);
    if (!entry->SetDriverVersionInfo(driver_version_op,
                                     driver_version_style,
                                     driver_version_string,
                                     driver_version_string2)) {
      LOG(WARNING) << "Malformed driver_version entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* driver_date_value = NULL;
  if (value->GetDictionary("driver_date", &driver_date_value)) {
    std::string driver_date_op = "any";
    std::string driver_date_string;
    std::string driver_date_string2;
    driver_date_value->GetString(kOp, &driver_date_op);
    driver_date_value->GetString("value", &driver_date_string);
    driver_date_value->GetString("value2", &driver_date_string2);
    if (!entry->SetDriverDateInfo(driver_date_op, driver_date_string,
                                  driver_date_string2)) {
      LOG(WARNING) << "Malformed driver_date entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string gl_type;
  if (value->GetString("gl_type", &gl_type)) {
    if (!entry->SetGLType(gl_type)) {
      LOG(WARNING) << "Malformed gl_type entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* gl_version_value = NULL;
  if (value->GetDictionary("gl_version", &gl_version_value)) {
    std::string version_op = "any";
    std::string version_string;
    std::string version_string2;
    gl_version_value->GetString(kOp, &version_op);
    gl_version_value->GetString("value", &version_string);
    gl_version_value->GetString("value2", &version_string2);
    if (!entry->SetGLVersionInfo(
            version_op, version_string, version_string2)) {
      LOG(WARNING) << "Malformed gl_version entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string gl_vendor_value;
  if (value->GetString("gl_vendor", &gl_vendor_value)) {
    if (!entry->SetGLVendorInfo(gl_vendor_value)) {
      LOG(WARNING) << "Malformed gl_vendor entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string gl_renderer_value;
  if (value->GetString("gl_renderer", &gl_renderer_value)) {
    if (!entry->SetGLRendererInfo(gl_renderer_value)) {
      LOG(WARNING) << "Malformed gl_renderer entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string gl_extensions_value;
  if (value->GetString("gl_extensions", &gl_extensions_value)) {
    if (!entry->SetGLExtensionsInfo(gl_extensions_value)) {
      LOG(WARNING) << "Malformed gl_extensions entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* gl_reset_notification_strategy_value = NULL;
  if (value->GetDictionary("gl_reset_notification_strategy",
                           &gl_reset_notification_strategy_value)) {
    std::string op;
    std::string int_value;
    std::string int_value2;
    gl_reset_notification_strategy_value->GetString(kOp, &op);
    gl_reset_notification_strategy_value->GetString("value", &int_value);
    gl_reset_notification_strategy_value->GetString("value2", &int_value2);
    if (!entry->SetGLResetNotificationStrategyInfo(
            op, int_value, int_value2)) {
      LOG(WARNING) << "Malformed gl_reset_notification_strategy entry "
                   << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  std::string cpu_brand_value;
  if (value->GetString("cpu_info", &cpu_brand_value)) {
    if (!entry->SetCpuBrand(cpu_brand_value)) {
      LOG(WARNING) << "Malformed cpu_brand entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* perf_graphics_value = NULL;
  if (value->GetDictionary("perf_graphics", &perf_graphics_value)) {
    std::string op;
    std::string float_value;
    std::string float_value2;
    perf_graphics_value->GetString(kOp, &op);
    perf_graphics_value->GetString("value", &float_value);
    perf_graphics_value->GetString("value2", &float_value2);
    if (!entry->SetPerfGraphicsInfo(op, float_value, float_value2)) {
      LOG(WARNING) << "Malformed perf_graphics entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* perf_gaming_value = NULL;
  if (value->GetDictionary("perf_gaming", &perf_gaming_value)) {
    std::string op;
    std::string float_value;
    std::string float_value2;
    perf_gaming_value->GetString(kOp, &op);
    perf_gaming_value->GetString("value", &float_value);
    perf_gaming_value->GetString("value2", &float_value2);
    if (!entry->SetPerfGamingInfo(op, float_value, float_value2)) {
      LOG(WARNING) << "Malformed perf_gaming entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* perf_overall_value = NULL;
  if (value->GetDictionary("perf_overall", &perf_overall_value)) {
    std::string op;
    std::string float_value;
    std::string float_value2;
    perf_overall_value->GetString(kOp, &op);
    perf_overall_value->GetString("value", &float_value);
    perf_overall_value->GetString("value2", &float_value2);
    if (!entry->SetPerfOverallInfo(op, float_value, float_value2)) {
      LOG(WARNING) << "Malformed perf_overall entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::ListValue* machine_model_name_list;
  if (value->GetList("machine_model_name", &machine_model_name_list)) {
    for (size_t i = 0; i < machine_model_name_list->GetSize(); ++i) {
      std::string model_name;
      if (!machine_model_name_list->GetString(i, &model_name) ||
          !entry->AddMachineModelName(model_name)) {
        LOG(WARNING) << "Malformed machine_model_name entry " << entry->id();
        return NULL;
      }
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* machine_model_version_value = NULL;
  if (value->GetDictionary(
          "machine_model_version", &machine_model_version_value)) {
    std::string version_op = "any";
    std::string version_string;
    std::string version_string2;
    machine_model_version_value->GetString(kOp, &version_op);
    machine_model_version_value->GetString("value", &version_string);
    machine_model_version_value->GetString("value2", &version_string2);
    if (!entry->SetMachineModelVersionInfo(
            version_op, version_string, version_string2)) {
      LOG(WARNING) << "Malformed machine_model_version entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  const base::DictionaryValue* gpu_count_value = NULL;
  if (value->GetDictionary("gpu_count", &gpu_count_value)) {
    std::string op;
    std::string int_value;
    std::string int_value2;
    gpu_count_value->GetString(kOp, &op);
    gpu_count_value->GetString("value", &int_value);
    gpu_count_value->GetString("value2", &int_value2);
    if (!entry->SetGpuCountInfo(op, int_value, int_value2)) {
      LOG(WARNING) << "Malformed gpu_count entry " << entry->id();
      return NULL;
    }
    dictionary_entry_count++;
  }

  bool direct_rendering;
  if (value->GetBoolean("direct_rendering", &direct_rendering)) {
    entry->SetDirectRenderingInfo(direct_rendering);
    dictionary_entry_count++;
  }

  if (top_level) {
    const base::ListValue* feature_value = NULL;
    if (value->GetList("features", &feature_value)) {
      std::vector<std::string> feature_list;
      for (size_t i = 0; i < feature_value->GetSize(); ++i) {
        std::string feature;
        if (feature_value->GetString(i, &feature)) {
          feature_list.push_back(feature);
        } else {
          LOG(WARNING) << "Malformed feature entry " << entry->id();
          return NULL;
        }
      }
      if (!entry->SetFeatures(
              feature_list, feature_map, supports_feature_type_all)) {
        LOG(WARNING) << "Malformed feature entry " << entry->id();
        return NULL;
      }
      dictionary_entry_count++;
    }
  }

  if (top_level) {
    const base::ListValue* exception_list_value = NULL;
    if (value->GetList("exceptions", &exception_list_value)) {
      for (size_t i = 0; i < exception_list_value->GetSize(); ++i) {
        const base::DictionaryValue* exception_value = NULL;
        if (!exception_list_value->GetDictionary(i, &exception_value)) {
          LOG(WARNING) << "Malformed exceptions entry " << entry->id();
          return NULL;
        }
        ScopedGpuControlListEntry exception(GetEntryFromValue(
            exception_value, false, feature_map, supports_feature_type_all));
        if (exception.get() == NULL) {
          LOG(WARNING) << "Malformed exceptions entry " << entry->id();
          return NULL;
        }
        // Exception should inherit vendor_id from parent, otherwise if only
        // device_ids are specified in Exception, the info will be incomplete.
        if (exception->vendor_id_ == 0 && entry->vendor_id_ != 0)
          exception->vendor_id_ = entry->vendor_id_;
        entry->AddException(exception);
      }
      dictionary_entry_count++;
    }
  }

  if (value->size() != dictionary_entry_count) {
    LOG(WARNING) << "Entry with unknown fields " << entry->id();
    return NULL;
  }

  // If GL_VERSION is specified, but no info about whether it's GL or GLES,
  // we use the default for the platform.  See GLType enum declaration.
  if (entry->gl_version_info_.get() != NULL && entry->gl_type_ == kGLTypeNone)
    entry->gl_type_ = GetDefaultGLType();

  return entry;
}

GpuControlList::GpuControlListEntry::GpuControlListEntry()
    : id_(0),
      disabled_(false),
      vendor_id_(0),
      multi_gpu_style_(kMultiGpuStyleNone),
      multi_gpu_category_(kMultiGpuCategoryPrimary),
      gl_type_(kGLTypeNone) {
}

GpuControlList::GpuControlListEntry::~GpuControlListEntry() { }

bool GpuControlList::GpuControlListEntry::SetId(uint32 id) {
  if (id != 0) {
    id_ = id;
    return true;
  }
  return false;
}

void GpuControlList::GpuControlListEntry::SetDisabled(bool disabled) {
  disabled_ = disabled;
}

bool GpuControlList::GpuControlListEntry::SetOsInfo(
    const std::string& os,
    const std::string& version_op,
    const std::string& version_string,
    const std::string& version_string2) {
  os_info_.reset(new OsInfo(os, version_op, version_string, version_string2));
  return os_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetVendorId(
    const std::string& vendor_id_string) {
  vendor_id_ = 0;
  return base::HexStringToUInt(vendor_id_string, &vendor_id_) &&
      vendor_id_ != 0;
}

bool GpuControlList::GpuControlListEntry::AddDeviceId(
    const std::string& device_id_string) {
  uint32 device_id = 0;
  if (base::HexStringToUInt(device_id_string, &device_id) && device_id != 0) {
    device_id_list_.push_back(device_id);
    return true;
  }
  return false;
}

bool GpuControlList::GpuControlListEntry::SetMultiGpuStyle(
    const std::string& multi_gpu_style_string) {
  MultiGpuStyle style = StringToMultiGpuStyle(multi_gpu_style_string);
  if (style == kMultiGpuStyleNone)
    return false;
  multi_gpu_style_ = style;
  return true;
}

bool GpuControlList::GpuControlListEntry::SetMultiGpuCategory(
    const std::string& multi_gpu_category_string) {
  MultiGpuCategory category =
      StringToMultiGpuCategory(multi_gpu_category_string);
  if (category == kMultiGpuCategoryNone)
    return false;
  multi_gpu_category_ = category;
  return true;
}

bool GpuControlList::GpuControlListEntry::SetGLType(
    const std::string& gl_type_string) {
  GLType gl_type = StringToGLType(gl_type_string);
  if (gl_type == kGLTypeNone)
    return false;
  gl_type_ = gl_type;
  return true;
}

bool GpuControlList::GpuControlListEntry::SetDriverVendorInfo(
    const std::string& vendor_value) {
  driver_vendor_info_ = vendor_value;
  return !driver_vendor_info_.empty();
}

bool GpuControlList::GpuControlListEntry::SetDriverVersionInfo(
    const std::string& version_op,
    const std::string& version_style,
    const std::string& version_string,
    const std::string& version_string2) {
  driver_version_info_.reset(new VersionInfo(
      version_op, version_style, version_string, version_string2));
  return driver_version_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetDriverDateInfo(
    const std::string& date_op,
    const std::string& date_string,
    const std::string& date_string2) {
  driver_date_info_.reset(
      new VersionInfo(date_op, std::string(), date_string, date_string2));
  return driver_date_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetGLVersionInfo(
    const std::string& version_op,
    const std::string& version_string,
    const std::string& version_string2) {
  gl_version_info_.reset(new VersionInfo(
      version_op, std::string(), version_string, version_string2));
  return gl_version_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetGLVendorInfo(
    const std::string& vendor_value) {
  gl_vendor_info_ = vendor_value;
  return !gl_vendor_info_.empty();
}

bool GpuControlList::GpuControlListEntry::SetGLRendererInfo(
    const std::string& renderer_value) {
  gl_renderer_info_ = renderer_value;
  return !gl_renderer_info_.empty();
}

bool GpuControlList::GpuControlListEntry::SetGLExtensionsInfo(
    const std::string& extensions_value) {
  gl_extensions_info_ = extensions_value;
  return !gl_extensions_info_.empty();
}

bool GpuControlList::GpuControlListEntry::SetGLResetNotificationStrategyInfo(
    const std::string& op,
    const std::string& int_string,
    const std::string& int_string2) {
  gl_reset_notification_strategy_info_.reset(
      new IntInfo(op, int_string, int_string2));
  return gl_reset_notification_strategy_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetCpuBrand(
    const std::string& cpu_value) {
  cpu_brand_ = cpu_value;
  return !cpu_brand_.empty();
}

bool GpuControlList::GpuControlListEntry::SetPerfGraphicsInfo(
    const std::string& op,
    const std::string& float_string,
    const std::string& float_string2) {
  perf_graphics_info_.reset(new FloatInfo(op, float_string, float_string2));
  return perf_graphics_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetPerfGamingInfo(
    const std::string& op,
    const std::string& float_string,
    const std::string& float_string2) {
  perf_gaming_info_.reset(new FloatInfo(op, float_string, float_string2));
  return perf_gaming_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetPerfOverallInfo(
    const std::string& op,
    const std::string& float_string,
    const std::string& float_string2) {
  perf_overall_info_.reset(new FloatInfo(op, float_string, float_string2));
  return perf_overall_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::AddMachineModelName(
    const std::string& model_name) {
  if (model_name.empty())
    return false;
  machine_model_name_list_.push_back(model_name);
  return true;
}

bool GpuControlList::GpuControlListEntry::SetMachineModelVersionInfo(
    const std::string& version_op,
    const std::string& version_string,
    const std::string& version_string2) {
  machine_model_version_info_.reset(new VersionInfo(
      version_op, std::string(), version_string, version_string2));
  return machine_model_version_info_->IsValid();
}

bool GpuControlList::GpuControlListEntry::SetGpuCountInfo(
    const std::string& op,
    const std::string& int_string,
    const std::string& int_string2) {
  gpu_count_info_.reset(new IntInfo(op, int_string, int_string2));
  return gpu_count_info_->IsValid();
}

void GpuControlList::GpuControlListEntry::SetDirectRenderingInfo(bool value) {
  direct_rendering_info_.reset(new BoolInfo(value));
}

bool GpuControlList::GpuControlListEntry::SetFeatures(
    const std::vector<std::string>& feature_strings,
    const FeatureMap& feature_map,
    bool supports_feature_type_all) {
  size_t size = feature_strings.size();
  if (size == 0)
    return false;
  features_.clear();
  for (size_t i = 0; i < size; ++i) {
    int feature = 0;
    if (supports_feature_type_all && feature_strings[i] == "all") {
      for (FeatureMap::const_iterator iter = feature_map.begin();
           iter != feature_map.end(); ++iter)
        features_.insert(iter->second);
      continue;
    }
    if (!StringToFeature(feature_strings[i], &feature, feature_map)) {
      features_.clear();
      return false;
    }
    features_.insert(feature);
  }
  return true;
}

void GpuControlList::GpuControlListEntry::AddException(
    ScopedGpuControlListEntry exception) {
  exceptions_.push_back(exception);
}

bool GpuControlList::GpuControlListEntry::GLVersionInfoMismatch(
    const std::string& gl_version) const {
  if (gl_version.empty())
    return false;

  if (gl_version_info_.get() == NULL && gl_type_ == kGLTypeNone)
    return false;

  std::vector<std::string> segments;
  base::SplitString(gl_version, ' ', &segments);
  std::string number;
  GLType gl_type = kGLTypeNone;
  if (segments.size() > 2 &&
      segments[0] == "OpenGL" && segments[1] == "ES") {
    bool full_match = RE2::FullMatch(segments[2], "([\\d.]+).*", &number);
    DCHECK(full_match);

    gl_type = kGLTypeGLES;
    if (segments.size() > 3 &&
        StartsWithASCII(segments[3], "(ANGLE", false)) {
      gl_type = kGLTypeANGLE;
    }
  } else {
    number = segments[0];
    gl_type = kGLTypeGL;
  }

  if (gl_type_ != kGLTypeNone && gl_type_ != gl_type)
    return true;
  if (gl_version_info_.get() != NULL && !gl_version_info_->Contains(number))
    return true;
  return false;
}

// static
GpuControlList::GpuControlListEntry::MultiGpuStyle
GpuControlList::GpuControlListEntry::StringToMultiGpuStyle(
    const std::string& style) {
  if (style == kMultiGpuStyleStringOptimus)
    return kMultiGpuStyleOptimus;
  if (style == kMultiGpuStyleStringAMDSwitchable)
    return kMultiGpuStyleAMDSwitchable;
  if (style == kMultiGpuStyleStringAMDSwitchableIntegrated)
    return kMultiGpuStyleAMDSwitchableIntegrated;
  if (style == kMultiGpuStyleStringAMDSwitchableDiscrete)
    return kMultiGpuStyleAMDSwitchableDiscrete;
  return kMultiGpuStyleNone;
}

// static
GpuControlList::GpuControlListEntry::MultiGpuCategory
GpuControlList::GpuControlListEntry::StringToMultiGpuCategory(
    const std::string& category) {
  if (category == kMultiGpuCategoryStringPrimary)
    return kMultiGpuCategoryPrimary;
  if (category == kMultiGpuCategoryStringSecondary)
    return kMultiGpuCategorySecondary;
  if (category == kMultiGpuCategoryStringActive)
    return kMultiGpuCategoryActive;
  if (category == kMultiGpuCategoryStringAny)
    return kMultiGpuCategoryAny;
  return kMultiGpuCategoryNone;
}

// static
GpuControlList::GpuControlListEntry::GLType
GpuControlList::GpuControlListEntry::StringToGLType(
    const std::string& gl_type) {
  if (gl_type == kGLTypeStringGL)
    return kGLTypeGL;
  if (gl_type == kGLTypeStringGLES)
    return kGLTypeGLES;
  if (gl_type == kGLTypeStringANGLE)
    return kGLTypeANGLE;
  return kGLTypeNone;
}

// static
GpuControlList::GpuControlListEntry::GLType
GpuControlList::GpuControlListEntry::GetDefaultGLType() {
#if defined(OS_CHROMEOS)
  return kGLTypeGL;
#elif defined(OS_LINUX) || defined(OS_OPENBSD)
  return kGLTypeGL;
#elif defined(OS_MACOSX)
  return kGLTypeGL;
#elif defined(OS_WIN)
  return kGLTypeANGLE;
#elif defined(OS_ANDROID)
  return kGLTypeGLES;
#else
  return kGLTypeNone;
#endif
}

void GpuControlList::GpuControlListEntry::LogControlListMatch(
    const std::string& control_list_logging_name) const {
  static const char kControlListMatchMessage[] =
      "Control list match for rule #%u in %s.";
  VLOG(1) << base::StringPrintf(kControlListMatchMessage, id_,
                                control_list_logging_name.c_str());
}

bool GpuControlList::GpuControlListEntry::Contains(
    OsType os_type, const std::string& os_version,
    const GPUInfo& gpu_info) const {
  DCHECK(os_type != kOsAny);
  if (os_info_.get() != NULL && !os_info_->Contains(os_type, os_version))
    return false;
  if (vendor_id_ != 0) {
    std::vector<GPUInfo::GPUDevice> candidates;
    switch (multi_gpu_category_) {
      case kMultiGpuCategoryPrimary:
        candidates.push_back(gpu_info.gpu);
        break;
      case kMultiGpuCategorySecondary:
        candidates = gpu_info.secondary_gpus;
        break;
      case kMultiGpuCategoryAny:
        candidates = gpu_info.secondary_gpus;
        candidates.push_back(gpu_info.gpu);
        break;
      case kMultiGpuCategoryActive:
        if (gpu_info.gpu.active)
          candidates.push_back(gpu_info.gpu);
        for (size_t ii = 0; ii < gpu_info.secondary_gpus.size(); ++ii) {
          if (gpu_info.secondary_gpus[ii].active)
            candidates.push_back(gpu_info.secondary_gpus[ii]);
        }
      default:
        break;
    }

    GPUInfo::GPUDevice gpu;
    gpu.vendor_id = vendor_id_;
    bool found = false;
    if (device_id_list_.empty()) {
      for (size_t ii = 0; ii < candidates.size(); ++ii) {
        if (gpu.vendor_id == candidates[ii].vendor_id) {
          found = true;
          break;
        }
      }
    } else {
      for (size_t ii = 0; ii < device_id_list_.size(); ++ii) {
        gpu.device_id = device_id_list_[ii];
        for (size_t jj = 0; jj < candidates.size(); ++jj) {
          if (gpu.vendor_id == candidates[jj].vendor_id &&
              gpu.device_id == candidates[jj].device_id) {
            found = true;
            break;
          }
        }
      }
    }
    if (!found)
      return false;
  }
  switch (multi_gpu_style_) {
    case kMultiGpuStyleOptimus:
      if (!gpu_info.optimus)
        return false;
      break;
    case kMultiGpuStyleAMDSwitchable:
      if (!gpu_info.amd_switchable)
        return false;
      break;
    case kMultiGpuStyleAMDSwitchableDiscrete:
      if (!gpu_info.amd_switchable)
        return false;
      // The discrete GPU is always the primary GPU.
      // This is guaranteed by GpuInfoCollector.
      if (!gpu_info.gpu.active)
        return false;
      break;
    case kMultiGpuStyleAMDSwitchableIntegrated:
      if (!gpu_info.amd_switchable)
        return false;
      // Assume the integrated GPU is the first in the secondary GPU list.
      if (gpu_info.secondary_gpus.size() == 0 ||
          !gpu_info.secondary_gpus[0].active)
        return false;
      break;
    case kMultiGpuStyleNone:
      break;
  }
  if (StringMismatch(gpu_info.driver_vendor, driver_vendor_info_))
    return false;
  if (driver_version_info_.get() != NULL && !gpu_info.driver_version.empty()) {
    if (!driver_version_info_->Contains(gpu_info.driver_version))
      return false;
  }
  if (driver_date_info_.get() != NULL && !gpu_info.driver_date.empty()) {
    if (!driver_date_info_->Contains(gpu_info.driver_date, '-'))
      return false;
  }
  if (GLVersionInfoMismatch(gpu_info.gl_version))
    return false;
  if (StringMismatch(gpu_info.gl_vendor, gl_vendor_info_))
    return false;
  if (StringMismatch(gpu_info.gl_renderer, gl_renderer_info_))
    return false;
  if (StringMismatch(gpu_info.gl_extensions, gl_extensions_info_))
    return false;
  if (gl_reset_notification_strategy_info_.get() != NULL &&
      !gl_reset_notification_strategy_info_->Contains(
          gpu_info.gl_reset_notification_strategy))
    return false;
  if (!machine_model_name_list_.empty()) {
    if (gpu_info.machine_model_name.empty())
      return false;
    bool found_match = false;
    for (size_t ii = 0; ii < machine_model_name_list_.size(); ++ii) {
      if (RE2::FullMatch(gpu_info.machine_model_name,
                         machine_model_name_list_[ii])) {
        found_match = true;
        break;
      }
    }
    if (!found_match)
      return false;
  }
  if (machine_model_version_info_.get() != NULL &&
      (gpu_info.machine_model_version.empty() ||
       !machine_model_version_info_->Contains(gpu_info.machine_model_version)))
    return false;
  if (gpu_count_info_.get() != NULL &&
      !gpu_count_info_->Contains(gpu_info.secondary_gpus.size() + 1))
    return false;
  if (direct_rendering_info_.get() != NULL &&
      !direct_rendering_info_->Contains(gpu_info.direct_rendering))
    return false;
  if (!cpu_brand_.empty()) {
    base::CPU cpu_info;
    if (StringMismatch(cpu_info.cpu_brand(), cpu_brand_))
      return false;
  }

  for (size_t i = 0; i < exceptions_.size(); ++i) {
    if (exceptions_[i]->Contains(os_type, os_version, gpu_info) &&
        !exceptions_[i]->NeedsMoreInfo(gpu_info))
      return false;
  }
  return true;
}

bool GpuControlList::GpuControlListEntry::NeedsMoreInfo(
    const GPUInfo& gpu_info) const {
  // We only check for missing info that might be collected with a gl context.
  // If certain info is missing due to some error, say, we fail to collect
  // vendor_id/device_id, then even if we launch GPU process and create a gl
  // context, we won't gather such missing info, so we still return false.
  if (!driver_vendor_info_.empty() && gpu_info.driver_vendor.empty())
    return true;
  if (driver_version_info_.get() && gpu_info.driver_version.empty())
    return true;
  if (!gl_vendor_info_.empty() && gpu_info.gl_vendor.empty())
    return true;
  if (!gl_renderer_info_.empty() && gpu_info.gl_renderer.empty())
    return true;
  for (size_t i = 0; i < exceptions_.size(); ++i) {
    if (exceptions_[i]->NeedsMoreInfo(gpu_info))
      return true;
  }
  return false;
}

GpuControlList::OsType GpuControlList::GpuControlListEntry::GetOsType() const {
  if (os_info_.get() == NULL)
    return kOsAny;
  return os_info_->type();
}

uint32 GpuControlList::GpuControlListEntry::id() const {
  return id_;
}

bool GpuControlList::GpuControlListEntry::disabled() const {
  return disabled_;
}

const std::set<int>& GpuControlList::GpuControlListEntry::features() const {
  return features_;
}

void GpuControlList::GpuControlListEntry::GetFeatureNames(
    base::ListValue* feature_names,
    const FeatureMap& feature_map,
    bool supports_feature_type_all) const {
  DCHECK(feature_names);
  if (supports_feature_type_all && features_.size() == feature_map.size()) {
    feature_names->AppendString("all");
    return;
  }
  for (FeatureMap::const_iterator iter = feature_map.begin();
       iter != feature_map.end(); ++iter) {
    if (features_.count(iter->second) > 0)
      feature_names->AppendString(iter->first);
  }
}

// static
bool GpuControlList::GpuControlListEntry::StringToFeature(
    const std::string& feature_name, int* feature_id,
    const FeatureMap& feature_map) {
  FeatureMap::const_iterator iter = feature_map.find(feature_name);
  if (iter != feature_map.end()) {
    *feature_id = iter->second;
    return true;
  }
  return false;
}

GpuControlList::GpuControlList()
    : max_entry_id_(0),
      needs_more_info_(false),
      supports_feature_type_all_(false),
      control_list_logging_enabled_(false) {
}

GpuControlList::~GpuControlList() {
  Clear();
}

bool GpuControlList::LoadList(
    const std::string& json_context,
    GpuControlList::OsFilter os_filter) {
  scoped_ptr<base::Value> root(base::JSONReader::Read(json_context));
  if (root.get() == NULL || !root->IsType(base::Value::TYPE_DICTIONARY))
    return false;

  base::DictionaryValue* root_dictionary =
      static_cast<base::DictionaryValue*>(root.get());
  DCHECK(root_dictionary);
  return LoadList(*root_dictionary, os_filter);
}

bool GpuControlList::LoadList(const base::DictionaryValue& parsed_json,
                              GpuControlList::OsFilter os_filter) {
  std::vector<ScopedGpuControlListEntry> entries;

  parsed_json.GetString("version", &version_);
  std::vector<std::string> pieces;
  if (!ProcessVersionString(version_, '.', &pieces))
    return false;

  const base::ListValue* list = NULL;
  if (!parsed_json.GetList("entries", &list))
    return false;

  uint32 max_entry_id = 0;
  for (size_t i = 0; i < list->GetSize(); ++i) {
    const base::DictionaryValue* list_item = NULL;
    bool valid = list->GetDictionary(i, &list_item);
    if (!valid || list_item == NULL)
      return false;
    ScopedGpuControlListEntry entry(GpuControlListEntry::GetEntryFromValue(
        list_item, true, feature_map_, supports_feature_type_all_));
    if (entry.get() == NULL)
      return false;
    if (entry->id() > max_entry_id)
      max_entry_id = entry->id();
    entries.push_back(entry);
  }

  Clear();
  OsType my_os = GetOsType();
  for (size_t i = 0; i < entries.size(); ++i) {
    OsType entry_os = entries[i]->GetOsType();
    if (os_filter == GpuControlList::kAllOs ||
        entry_os == kOsAny || entry_os == my_os)
      entries_.push_back(entries[i]);
  }
  max_entry_id_ = max_entry_id;
  return true;
}

std::set<int> GpuControlList::MakeDecision(
    GpuControlList::OsType os,
    std::string os_version,
    const GPUInfo& gpu_info) {
  active_entries_.clear();
  std::set<int> features;

  needs_more_info_ = false;
  std::set<int> possible_features;

  if (os == kOsAny)
    os = GetOsType();
  if (os_version.empty())
    os_version = base::SysInfo::OperatingSystemVersion();

  for (size_t i = 0; i < entries_.size(); ++i) {
    if (entries_[i]->Contains(os, os_version, gpu_info)) {
      bool needs_more_info = entries_[i]->NeedsMoreInfo(gpu_info);
      if (!entries_[i]->disabled()) {
        if (control_list_logging_enabled_)
          entries_[i]->LogControlListMatch(control_list_logging_name_);
        MergeFeatureSets(&possible_features, entries_[i]->features());
        if (!needs_more_info)
          MergeFeatureSets(&features, entries_[i]->features());
      }
      if (!needs_more_info)
        active_entries_.push_back(entries_[i]);
    }
  }

  if (possible_features.size() > features.size())
    needs_more_info_ = true;

  return features;
}

void GpuControlList::GetDecisionEntries(
    std::vector<uint32>* entry_ids, bool disabled) const {
  DCHECK(entry_ids);
  entry_ids->clear();
  for (size_t i = 0; i < active_entries_.size(); ++i) {
    if (disabled == active_entries_[i]->disabled())
      entry_ids->push_back(active_entries_[i]->id());
  }
}

void GpuControlList::GetReasons(base::ListValue* problem_list,
                                const std::string& tag) const {
  DCHECK(problem_list);
  for (size_t i = 0; i < active_entries_.size(); ++i) {
    GpuControlListEntry* entry = active_entries_[i].get();
    if (entry->disabled())
      continue;
    base::DictionaryValue* problem = new base::DictionaryValue();

    problem->SetString("description", entry->description());

    base::ListValue* cr_bugs = new base::ListValue();
    for (size_t j = 0; j < entry->cr_bugs().size(); ++j)
      cr_bugs->Append(new base::FundamentalValue(entry->cr_bugs()[j]));
    problem->Set("crBugs", cr_bugs);

    base::ListValue* webkit_bugs = new base::ListValue();
    for (size_t j = 0; j < entry->webkit_bugs().size(); ++j) {
      webkit_bugs->Append(new base::FundamentalValue(entry->webkit_bugs()[j]));
    }
    problem->Set("webkitBugs", webkit_bugs);

    base::ListValue* features = new base::ListValue();
    entry->GetFeatureNames(features, feature_map_, supports_feature_type_all_);
    problem->Set("affectedGpuSettings", features);

    DCHECK(tag == "workarounds" || tag == "disabledFeatures");
    problem->SetString("tag", tag);

    problem_list->Append(problem);
  }
}

size_t GpuControlList::num_entries() const {
  return entries_.size();
}

uint32 GpuControlList::max_entry_id() const {
  return max_entry_id_;
}

std::string GpuControlList::version() const {
  return version_;
}

GpuControlList::OsType GpuControlList::GetOsType() {
#if defined(OS_CHROMEOS)
  return kOsChromeOS;
#elif defined(OS_WIN)
  return kOsWin;
#elif defined(OS_ANDROID)
  return kOsAndroid;
#elif defined(OS_LINUX) || defined(OS_OPENBSD)
  return kOsLinux;
#elif defined(OS_MACOSX)
  return kOsMacosx;
#else
  return kOsUnknown;
#endif
}

void GpuControlList::Clear() {
  entries_.clear();
  active_entries_.clear();
  max_entry_id_ = 0;
}

// static
GpuControlList::NumericOp GpuControlList::StringToNumericOp(
    const std::string& op) {
  if (op == "=")
    return kEQ;
  if (op == "<")
    return kLT;
  if (op == "<=")
    return kLE;
  if (op == ">")
    return kGT;
  if (op == ">=")
    return kGE;
  if (op == "any")
    return kAny;
  if (op == "between")
    return kBetween;
  return kUnknown;
}

void GpuControlList::AddSupportedFeature(
    const std::string& feature_name, int feature_id) {
  feature_map_[feature_name] = feature_id;
}

void GpuControlList::set_supports_feature_type_all(bool supported) {
  supports_feature_type_all_ = supported;
}

}  // namespace gpu

