#include <unistd.h>
#include <algorithm>
#include <sstream>

#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "lib/fxl/logging.h"

namespace blink {

APKAssetProvider::APKAssetProvider(JNIEnv* env,
                                   jobject jassetManager,
                                   std::string directory)
    : directory_(std::move(directory)) {
  assetManager_ = AAssetManager_fromJava(env, jassetManager);
}

APKAssetProvider::~APKAssetProvider() = default;

bool APKAssetProvider::IsValid() const {
  return true;
}

bool APKAssetProvider::GetAsBuffer(const std::string& asset_name,
                                   std::vector<uint8_t>* data) const {
  std::stringstream ss;
  ss << directory_.c_str() << "/" << asset_name;
  AAsset* asset =
      AAssetManager_open(assetManager_, ss.str().c_str(), AASSET_MODE_BUFFER);
  if (!asset) {
    return false;
  }

  uint8_t* buffer = (uint8_t*)AAsset_getBuffer(asset);
  if (!buffer) {
    FXL_LOG(ERROR) << "Got null trying to acquire buffer for asset:" << asset;
    AAsset_close(asset);
    return false;
  }

  data->resize(AAsset_getLength(asset));
  std::copy(buffer, buffer + data->size(), data->begin());

  AAsset_close(asset);
  return true;
}

}  // namespace blink
