#include <memory>
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {
namespace testing {
namespace {
class MockPlatformViewAndroidJNI : public PlatformViewAndroidJNI {
 public:
  MOCK_METHOD2(FlutterViewHandlePlatformMessage,
               void(std::unique_ptr<flutter::PlatformMessage> message,
                    int responseId));
  MOCK_METHOD2(FlutterViewHandlePlatformMessageResponse,
               void(int responseId, std::unique_ptr<fml::Mapping> data));
  MOCK_METHOD3(FlutterViewUpdateSemantics,
               void(std::vector<uint8_t> buffer,
                    std::vector<std::string> strings,
                    std::vector<std::vector<uint8_t>> string_attribute_args));
  MOCK_METHOD2(FlutterViewUpdateCustomAccessibilityActions,
               void(std::vector<uint8_t> actions_buffer,
                    std::vector<std::string> strings));
  MOCK_METHOD0(FlutterViewOnFirstFrame, void());
  MOCK_METHOD0(FlutterViewOnPreEngineRestart, void());
  MOCK_METHOD2(SurfaceTextureAttachToGLContext,
               void(JavaLocalRef surface_texture, int textureId));
  MOCK_METHOD1(SurfaceTextureUpdateTexImage,
               void(JavaLocalRef surface_texture));
  MOCK_METHOD2(SurfaceTextureGetTransformMatrix,
               void(JavaLocalRef surface_texture, SkMatrix& transform));
  MOCK_METHOD1(SurfaceTextureDetachFromGLContext,
               void(JavaLocalRef surface_texture));
  MOCK_METHOD1(ImageTextureEntryAcquireLatestImage,
               JavaLocalRef(JavaLocalRef image_texture_entry));
  MOCK_METHOD1(ImageGetHardwareBuffer, JavaLocalRef(JavaLocalRef image));
  MOCK_METHOD1(ImageClose, void(JavaLocalRef image));
  MOCK_METHOD1(HardwareBufferClose, void(JavaLocalRef hardware_buffer));
  MOCK_METHOD8(FlutterViewOnDisplayPlatformView,
               void(int view_id,
                    int x,
                    int y,
                    int width,
                    int height,
                    int viewWidth,
                    int viewHeight,
                    MutatorsStack mutators_stack));
  MOCK_METHOD5(FlutterViewDisplayOverlaySurface,
               void(int surface_id, int x, int y, int width, int height));
  MOCK_METHOD0(FlutterViewBeginFrame, void());
  MOCK_METHOD0(FlutterViewEndFrame, void());
  MOCK_METHOD0(FlutterViewCreateOverlaySurface,
               std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>());
  MOCK_METHOD0(FlutterViewDestroyOverlaySurfaces, void());
  MOCK_METHOD1(FlutterViewComputePlatformResolvedLocale,
               std::unique_ptr<std::vector<std::string>>(
                   std::vector<std::string> supported_locales_data));
  MOCK_METHOD0(GetDisplayRefreshRate, double());
  MOCK_METHOD0(GetDisplayWidth, double());
  MOCK_METHOD0(GetDisplayHeight, double());
  MOCK_METHOD0(GetDisplayDensity, double());
  MOCK_METHOD1(RequestDartDeferredLibrary, bool(int loading_unit_id));
  MOCK_CONST_METHOD2(FlutterViewGetScaledFontSize,
                     double(double font_size, int configuration_id));
};

class MockPlatformMessageResponse : public PlatformMessageResponse {
 public:
  static fml::RefPtr<MockPlatformMessageResponse> Create() {
    return fml::AdoptRef(new MockPlatformMessageResponse());
  }
  MOCK_METHOD1(Complete, void(std::unique_ptr<fml::Mapping> data));
  MOCK_METHOD0(CompleteEmpty, void());
};
}  // namespace

TEST(AndroidShellHolder, Create) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(settings, jni);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
}

TEST(AndroidShellHolder, HandlePlatformMessage) {
  Settings settings;
  settings.enable_software_rendering = false;
  auto jni = std::make_shared<MockPlatformViewAndroidJNI>();
  auto holder = std::make_unique<AndroidShellHolder>(settings, jni);
  EXPECT_NE(holder.get(), nullptr);
  EXPECT_TRUE(holder->IsValid());
  EXPECT_NE(holder->GetPlatformView().get(), nullptr);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  holder->GetPlatformView()->NotifyCreated(window);
  EXPECT_TRUE(holder->GetPlatformMessageHandler());
  size_t data_size = 4;
  fml::MallocMapping bytes =
      fml::MallocMapping(static_cast<uint8_t*>(malloc(data_size)), data_size);
  fml::RefPtr<MockPlatformMessageResponse> response =
      MockPlatformMessageResponse::Create();
  auto message = std::make_unique<PlatformMessage>(
      /*channel=*/"foo", /*data=*/std::move(bytes), /*response=*/response);
  int response_id = 1;
  EXPECT_CALL(*jni,
              FlutterViewHandlePlatformMessage(::testing::_, response_id));
  EXPECT_CALL(*response, CompleteEmpty());
  holder->GetPlatformMessageHandler()->HandlePlatformMessage(
      std::move(message));
  holder->GetPlatformMessageHandler()
      ->InvokePlatformMessageEmptyResponseCallback(response_id);
}
}  // namespace testing
}  // namespace flutter
