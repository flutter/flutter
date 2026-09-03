// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vm_init.h"

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/jvm_invoker.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Eq;
using ::testing::Return;

class MockJvmInvokerForVMInit : public JvmInvoker {
 public:
  MOCK_METHOD(bool, EnsureAttachedToThread, (), (override));
  MOCK_METHOD(void, DetachFromThread, (), (override));
  MOCK_METHOD(bool, HasPendingException, (), (const, override));
  MOCK_METHOD(void, ClearPendingException, (), (override));

  MOCK_METHOD(bool,
              InvokeVoidMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool,
              InvokeBooleanMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(int64_t,
              InvokeIntMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(double,
              InvokeDoubleMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::string,
              InvokeStringMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::vector<uint8_t>,
              InvokeBytesMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

// ---------------------------------------------------------------------------
// RenderingAPISelectionTests
// ---------------------------------------------------------------------------

TEST(AndroidVMInitTest, RenderingAPISelectionMatrix) {
  AndroidVMArgs args;

  // 1. Software rendering override
  args.enable_software_rendering = true;
  args.enable_impeller = true;
  args.api_level = 34;
  EXPECT_EQ(SelectRenderingAPI(args), AndroidRenderingAPI::kSoftware);

  // 2. Explicit Impeller OpenGLES request
  args.enable_software_rendering = false;
  args.requested_rendering_backend = "opengles";
  args.enable_impeller = true;
  EXPECT_EQ(SelectRenderingAPI(args), AndroidRenderingAPI::kImpellerOpenGLES);

  // 3. Explicit Impeller Vulkan request
  args.requested_rendering_backend = "vulkan";
  EXPECT_EQ(SelectRenderingAPI(args), AndroidRenderingAPI::kImpellerVulkan);

  // 4. Impeller Autoselect on modern Android (API 29+)
  args.requested_rendering_backend.clear();
  args.api_level = 29;
  args.enable_impeller = true;
  EXPECT_EQ(SelectRenderingAPI(args, /*is_vivante=*/false),
            AndroidRenderingAPI::kImpellerAutoselect);

  args.api_level = 34;
  EXPECT_EQ(SelectRenderingAPI(args, /*is_vivante=*/false),
            AndroidRenderingAPI::kImpellerAutoselect);

  // 5. Vivante GPU driver workaround -> fallback to SkiaOpenGLES
  EXPECT_EQ(SelectRenderingAPI(args, /*is_vivante=*/true),
            AndroidRenderingAPI::kSkiaOpenGLES);

  // 6. Legacy Android API level (<29) -> fallback to SkiaOpenGLES
  args.api_level = 28;
  EXPECT_EQ(SelectRenderingAPI(args, /*is_vivante=*/false),
            AndroidRenderingAPI::kSkiaOpenGLES);

  // 7. Impeller disabled explicitly -> fallback to SkiaOpenGLES
  args.api_level = 34;
  args.enable_impeller = false;
  EXPECT_EQ(SelectRenderingAPI(args, /*is_vivante=*/false),
            AndroidRenderingAPI::kSkiaOpenGLES);
}

// ---------------------------------------------------------------------------
// FontCollectionProviderTests
// ---------------------------------------------------------------------------

TEST(AndroidVMInitTest, InMemoryFontCollectionProviderOperations) {
  InMemoryFontCollectionProvider provider;

  EXPECT_FALSE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 0u);

  EXPECT_TRUE(provider.PrefetchDefaultFontManager());
  EXPECT_TRUE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 1u);

  EXPECT_TRUE(provider.PrefetchDefaultFontManager());
  EXPECT_EQ(provider.GetPrefetchCount(), 2u);

  provider.Reset();
  EXPECT_FALSE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 0u);

  provider.SetResult(false);
  EXPECT_FALSE(provider.PrefetchDefaultFontManager());
  EXPECT_FALSE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 1u);
}

TEST(AndroidVMInitTest, DefaultFontCollectionProviderOperations) {
  DefaultFontCollectionProvider provider;

  EXPECT_FALSE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 0u);

  EXPECT_TRUE(provider.PrefetchDefaultFontManager());
  EXPECT_TRUE(provider.IsPrefetched());
  EXPECT_EQ(provider.GetPrefetchCount(), 1u);
}

// ---------------------------------------------------------------------------
// AndroidAOTProviderTests
// ---------------------------------------------------------------------------

TEST(AndroidVMInitTest, InMemoryAOTProviderOperations) {
  InMemoryAndroidAOTProvider provider;

  EXPECT_EQ(provider.GetCreateCount(), 0u);
  EXPECT_EQ(provider.GetCollectCount(), 0u);

  FlutterEngineAOTDataSource source = {};
  source.type = kFlutterEngineAOTDataSourceTypeElfPath;
  source.elf_path = "/data/app/lib/arm64/libapp.so";

  FlutterEngineAOTData aot_data = nullptr;
  EXPECT_EQ(provider.CreateAOTData(&source, &aot_data), kSuccess);
  EXPECT_NE(aot_data, nullptr);
  EXPECT_EQ(provider.GetCreateCount(), 1u);
  EXPECT_EQ(provider.GetLastElfPath(), "/data/app/lib/arm64/libapp.so");

  EXPECT_EQ(provider.CollectAOTData(aot_data), kSuccess);
  EXPECT_EQ(provider.GetCollectCount(), 1u);

  // Error simulation
  provider.SetCreateResult(kInvalidArguments);
  FlutterEngineAOTData fail_data = nullptr;
  EXPECT_EQ(provider.CreateAOTData(&source, &fail_data), kInvalidArguments);

  EXPECT_EQ(provider.CreateAOTData(nullptr, &fail_data), kInvalidArguments);
  EXPECT_EQ(provider.CollectAOTData(nullptr), kInvalidArguments);
}

TEST(AndroidVMInitTest, DefaultAOTProviderArgumentValidation) {
  DefaultAndroidAOTProvider provider;
  FlutterEngineAOTData out_data = nullptr;

  EXPECT_EQ(provider.CreateAOTData(nullptr, &out_data), kInvalidArguments);
  EXPECT_EQ(provider.CreateAOTData(nullptr, nullptr), kInvalidArguments);
  EXPECT_EQ(provider.CollectAOTData(nullptr), kInvalidArguments);
}

// ---------------------------------------------------------------------------
// AndroidProjectArgsHolderTests
// ---------------------------------------------------------------------------

TEST(AndroidVMInitTest, AndroidProjectArgsHolderPopulation) {
  AndroidProjectArgsHolder holder;

  AndroidVMArgs vm_args;
  vm_args.command_line_args = {"--enable-checked-mode",
                               "--verify-entry-points"};
  vm_args.icu_data_path = "/data/flutter/icudtl.dat";
  vm_args.engine_caches_path = "/data/user/0/com.example/cache";
  vm_args.is_persistent_cache_read_only = true;
  vm_args.dart_old_gen_heap_size = 512;
  vm_args.log_tag = "custom_flutter_tag";

  const uint8_t mock_vm_data[] = {0x01, 0x02, 0x03, 0x04};
  const uint8_t mock_vm_instr[] = {0xAA, 0xBB, 0xCC, 0xDD};
  vm_args.aot_vm_snapshot_data = mock_vm_data;
  vm_args.aot_vm_snapshot_data_size = sizeof(mock_vm_data);
  vm_args.aot_vm_snapshot_instructions = mock_vm_instr;
  vm_args.aot_vm_snapshot_instructions_size = sizeof(mock_vm_instr);

  auto mock_aot_handle = reinterpret_cast<FlutterEngineAOTData>(0x5555);
  holder.Populate(vm_args, mock_aot_handle, nullptr);

  const FlutterProjectArgs* args = holder.GetProjectArgs();
  ASSERT_NE(args, nullptr);
  EXPECT_EQ(args->struct_size, sizeof(FlutterProjectArgs));

  // Verify command-line arguments: argv[0] == "flutter"
  EXPECT_EQ(args->command_line_argc, 3);
  ASSERT_NE(args->command_line_argv, nullptr);
  EXPECT_STREQ(args->command_line_argv[0], "flutter");
  EXPECT_STREQ(args->command_line_argv[1], "--enable-checked-mode");
  EXPECT_STREQ(args->command_line_argv[2], "--verify-entry-points");

  // Verify paths and config
  EXPECT_STREQ(args->icu_data_path, "/data/flutter/icudtl.dat");
  EXPECT_STREQ(args->persistent_cache_path, "/data/user/0/com.example/cache");
  EXPECT_TRUE(args->is_persistent_cache_read_only);
  EXPECT_EQ(args->dart_old_gen_heap_size, 512);
  EXPECT_STREQ(args->log_tag, "custom_flutter_tag");

  // Verify snapshot mappings and AOT handle
  EXPECT_EQ(args->aot_data, mock_aot_handle);
  EXPECT_EQ(args->vm_snapshot_data, mock_vm_data);
  EXPECT_EQ(args->vm_snapshot_data_size, sizeof(mock_vm_data));
  EXPECT_EQ(args->vm_snapshot_instructions, mock_vm_instr);
  EXPECT_EQ(args->vm_snapshot_instructions_size, sizeof(mock_vm_instr));

  // Verify default callbacks
  EXPECT_NE(args->vsync_callback, nullptr);
  EXPECT_NE(args->update_semantics_callback2, nullptr);
}

// ---------------------------------------------------------------------------
// AndroidVMInitTests
// ---------------------------------------------------------------------------

TEST(AndroidVMInitTest, AndroidVMInitLifecycleAndDispatch) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForVMInit>();
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();

  AndroidVMInit vm_init(mock_invoker, font_provider, aot_provider);

  EXPECT_FALSE(vm_init.IsInitialized());
  EXPECT_EQ(vm_init.GetProjectArgs(), nullptr);
  EXPECT_FALSE(vm_init.GetVMArgs().has_value());

  AndroidVMArgs args;
  args.command_line_args = {"--enable-impeller=true"};
  args.aot_library_path = "/data/app/lib/arm64/libapp.so";
  args.icu_data_path = "/data/flutter/icudtl.dat";
  args.engine_caches_path = "/data/user/cache";
  args.api_level = 34;
  args.vm_service_uri = "http://127.0.0.1:12345/auth/";

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V", _))
      .WillOnce(Return(true));

  EXPECT_TRUE(vm_init.Init(args));
  EXPECT_TRUE(vm_init.IsInitialized());
  auto vm_args = vm_init.GetVMArgs();
  ASSERT_TRUE(vm_args.has_value());
  if (vm_args.has_value()) {
    EXPECT_EQ(vm_args.value(), args);
  }
  EXPECT_EQ(vm_init.GetSelectedRenderingAPI(),
            AndroidRenderingAPI::kImpellerAutoselect);

  const FlutterProjectArgs* project_args = vm_init.GetProjectArgs();
  ASSERT_NE(project_args, nullptr);
  EXPECT_STREQ(project_args->icu_data_path, "/data/flutter/icudtl.dat");
  EXPECT_NE(project_args->aot_data, nullptr);
  EXPECT_EQ(aot_provider->GetCreateCount(), 1u);
  EXPECT_EQ(aot_provider->GetLastElfPath(), "/data/app/lib/arm64/libapp.so");

  // Font prefetching
  EXPECT_TRUE(vm_init.PrefetchDefaultFontManager());
  EXPECT_TRUE(font_provider->IsPrefetched());
  EXPECT_EQ(font_provider->GetPrefetchCount(), 1u);

  // Dynamic VM Service URI update
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(vm_init.SetVmServiceUri("http://127.0.0.1:9999/new_auth/"));
  EXPECT_EQ(vm_init.GetVmServiceUri(), "http://127.0.0.1:9999/new_auth/");
}

TEST(AndroidVMInitTest, AOTCreationFailureHandling) {
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  aot_provider->SetCreateResult(kInvalidArguments);

  AndroidVMInit vm_init(nullptr, nullptr, aot_provider);

  AndroidVMArgs args;
  args.aot_library_path = "/nonexistent/path/libapp.so";

  EXPECT_FALSE(vm_init.Init(args));
  EXPECT_FALSE(vm_init.IsInitialized());
  EXPECT_EQ(vm_init.GetProjectArgs(), nullptr);
}

TEST(AndroidVMInitTest, MultithreadedConcurrentVMInitOperations) {
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();

  AndroidVMInit vm_init(nullptr, font_provider, aot_provider);

  AndroidVMArgs args;
  args.command_line_args = {"--multithread-test"};
  args.api_level = 34;

  EXPECT_TRUE(vm_init.Init(args));

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterationsPerThread = 50;
  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&, t]() {
      for (size_t i = 0; i < kIterationsPerThread; ++i) {
        EXPECT_TRUE(vm_init.IsInitialized());
        EXPECT_NE(vm_init.GetProjectArgs(), nullptr);
        EXPECT_TRUE(vm_init.PrefetchDefaultFontManager());
        std::string uri =
            "http://127.0.0.1:" + std::to_string(1000 + t * 100 + i);
        EXPECT_TRUE(vm_init.SetVmServiceUri(uri));
        std::string fetched_uri = vm_init.GetVmServiceUri();
        EXPECT_FALSE(fetched_uri.empty());
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(font_provider->GetPrefetchCount(),
            kThreadCount * kIterationsPerThread);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
