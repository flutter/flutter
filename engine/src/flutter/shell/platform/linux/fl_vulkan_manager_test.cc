// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>
#include <thread>

#include "flutter/shell/platform/linux/fl_compositor_vulkan.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_pixel_buffer_texture_vulkan.h"
#include "flutter/shell/platform/linux/fl_vulkan_manager.h"
#include "flutter/shell/platform/linux/fl_vulkan_snapshot_pool.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"

#define VK_NO_PROTOTYPES
#include <vulkan/vulkan.h>

TEST(FlVulkanManagerTest, UninitializedManagerRejectsAllocation) {
  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new();
  FlutterBackingStoreConfig config = {};
  config.size = {16, 16};
  FlutterBackingStore backing_store = {};
  EXPECT_FALSE(
      fl_vulkan_manager_create_backing_store(manager, &config, &backing_store));
}

class FlVulkanIntegrationTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    if (g_strcmp0(g_getenv("FLUTTER_TEST_VULKAN"), "1") != 0) {
      GTEST_SKIP() << "Set FLUTTER_TEST_VULKAN=1 with a Vulkan ICD to run";
    }
    manager = fl_vulkan_manager_new();
    g_autoptr(GError) error = nullptr;
    ASSERT_TRUE(fl_vulkan_manager_initialize(manager, &config, &error))
        << (error ? error->message : "");
    VkPhysicalDeviceProperties properties = {};
    proc<PFN_vkGetPhysicalDeviceProperties>("vkGetPhysicalDeviceProperties")(
        static_cast<VkPhysicalDevice>(config.physical_device), &properties);
    RecordProperty("vulkan_device", properties.deviceName);
  }

  ~FlVulkanIntegrationTest() override { g_clear_object(&manager); }

  template <typename T>
  T proc(const char* name) {
    return reinterpret_cast<T>(config.get_instance_proc_address_callback(
        nullptr, config.instance, name));
  }

  // Fill a real optimal-tiling image, mirroring the engine's final GENERAL
  // attachment layout. The manager must preserve these pixels across readback.
  void Clear(FlutterBackingStore* store, float red, float green, float blue) {
    VkDevice device = static_cast<VkDevice>(config.device);
    VkCommandPoolCreateInfo pool_info = {
        VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    pool_info.queueFamilyIndex = config.queue_family_index;
    VkCommandPool pool = VK_NULL_HANDLE;
    ASSERT_EQ(proc<PFN_vkCreateCommandPool>("vkCreateCommandPool")(
                  device, &pool_info, nullptr, &pool),
              VK_SUCCESS);
    VkCommandBufferAllocateInfo allocation = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    allocation.commandPool = pool;
    allocation.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocation.commandBufferCount = 1;
    VkCommandBuffer command;
    ASSERT_EQ(proc<PFN_vkAllocateCommandBuffers>("vkAllocateCommandBuffers")(
                  device, &allocation, &command),
              VK_SUCCESS);
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    ASSERT_EQ(
        proc<PFN_vkBeginCommandBuffer>("vkBeginCommandBuffer")(command, &begin),
        VK_SUCCESS);
    VkImageMemoryBarrier barrier = {VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    barrier.newLayout = VK_IMAGE_LAYOUT_GENERAL;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = reinterpret_cast<VkImage>(store->vulkan.image->image);
    barrier.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
    auto pipeline_barrier =
        proc<PFN_vkCmdPipelineBarrier>("vkCmdPipelineBarrier");
    pipeline_barrier(command, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                     VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0, nullptr,
                     1, &barrier);
    VkClearColorValue color = {{red, green, blue, 1.0f}};
    proc<PFN_vkCmdClearColorImage>("vkCmdClearColorImage")(
        command, barrier.image, VK_IMAGE_LAYOUT_GENERAL, &color, 1,
        &barrier.subresourceRange);
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_GENERAL;
    pipeline_barrier(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                     VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0,
                     nullptr, 0, nullptr, 1, &barrier);
    ASSERT_EQ(proc<PFN_vkEndCommandBuffer>("vkEndCommandBuffer")(command),
              VK_SUCCESS);
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    ASSERT_EQ(
        proc<PFN_vkQueueSubmit>("vkQueueSubmit")(
            static_cast<VkQueue>(config.queue), 1, &submit, VK_NULL_HANDLE),
        VK_SUCCESS);
    ASSERT_EQ(proc<PFN_vkQueueWaitIdle>("vkQueueWaitIdle")(
                  static_cast<VkQueue>(config.queue)),
              VK_SUCCESS);
    proc<PFN_vkDestroyCommandPool>("vkDestroyCommandPool")(device, pool,
                                                           nullptr);
  }

  FlutterBackingStore Create(size_t width, size_t height) {
    FlutterBackingStoreConfig size = {};
    size.size = {static_cast<double>(width), static_cast<double>(height)};
    FlutterBackingStore store = {};
    EXPECT_TRUE(fl_vulkan_manager_create_backing_store(manager, &size, &store));
    return store;
  }

  FlVulkanManager* manager = nullptr;
  FlutterVulkanRendererConfig config = {};
};

TEST_F(FlVulkanIntegrationTest, ReadbackSurvivesResizeAndCollection) {
  for (auto width : {17u, 101u}) {
    auto store = Create(width, 13);
    ASSERT_NE(store.vulkan.image, nullptr);
    Clear(&store, 1, 0, 0);
    size_t actual_width, actual_height;
    g_autoptr(GError) error = nullptr;
    g_autoptr(GBytes) pixels = fl_vulkan_backing_store_read_pixels(
        &store, &actual_width, &actual_height, &error);
    ASSERT_NE(pixels, nullptr) << (error ? error->message : "");
    fl_vulkan_manager_collect_backing_store(&store);
    EXPECT_EQ(actual_width, width);
    EXPECT_EQ(actual_height, 13u);
    EXPECT_EQ(g_bytes_get_size(pixels), width * 13u * 4u);
    const auto* bytes =
        static_cast<const uint8_t*>(g_bytes_get_data(pixels, nullptr));
    for (size_t i = 0; i < width * 13; i++) {
      EXPECT_EQ(bytes[i * 4], 255);
      EXPECT_EQ(bytes[i * 4 + 1], 0);
      EXPECT_EQ(bytes[i * 4 + 2], 0);
      EXPECT_EQ(bytes[i * 4 + 3], 255);
    }
  }
}

TEST_F(FlVulkanIntegrationTest, RejectInvalidDimensions) {
  for (double width : {0.0, -1.0, 1.5, double(UINT32_MAX),
                       std::numeric_limits<double>::quiet_NaN(),
                       std::numeric_limits<double>::infinity()}) {
    FlutterBackingStoreConfig invalid = {};
    invalid.size = {width, 16};
    FlutterBackingStore store = {};
    EXPECT_FALSE(
        fl_vulkan_manager_create_backing_store(manager, &invalid, &store));
  }
}

TEST_F(FlVulkanIntegrationTest, OutstandingImageKeepsDeviceAlive) {
  auto store = Create(17, 13);
  g_clear_object(&manager);
  Clear(&store, 0, 1, 0);
  size_t width, height;
  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) pixels =
      fl_vulkan_backing_store_read_pixels(&store, &width, &height, &error);
  ASSERT_NE(pixels, nullptr) << (error ? error->message : "");
  fl_vulkan_manager_collect_backing_store(&store);
  const auto* bytes =
      static_cast<const uint8_t*>(g_bytes_get_data(pixels, nullptr));
  EXPECT_EQ(bytes[0], 0);
  EXPECT_EQ(bytes[1], 255);
  EXPECT_EQ(bytes[2], 0);
  EXPECT_EQ(bytes[3], 255);
}

TEST_F(FlVulkanIntegrationTest,
       RecursiveResolversPreserveQueueSynchronization) {
  auto get_instance = proc<PFN_vkGetInstanceProcAddr>("vkGetInstanceProcAddr");
  auto get_device = reinterpret_cast<PFN_vkGetDeviceProcAddr>(get_instance(
      static_cast<VkInstance>(config.instance), "vkGetDeviceProcAddr"));
  EXPECT_EQ(
      get_device(static_cast<VkDevice>(config.device), "vkQueueSubmit"),
      get_instance(static_cast<VkInstance>(config.instance), "vkQueueSubmit"));
  auto wait = reinterpret_cast<PFN_vkQueueWaitIdle>(
      get_device(static_cast<VkDevice>(config.device), "vkQueueWaitIdle"));
  std::thread worker([&] {
    for (int i = 0; i < 20; i++) {
      EXPECT_EQ(wait(static_cast<VkQueue>(config.queue)), VK_SUCCESS);
    }
  });
  for (int i = 0; i < 20; i++) {
    EXPECT_EQ(wait(static_cast<VkQueue>(config.queue)), VK_SUCCESS);
  }
  worker.join();
}

TEST_F(FlVulkanIntegrationTest, ComposeLayersAndClearFrame) {
  g_autoptr(FlCompositorVulkan) compositor =
      fl_compositor_vulkan_new(fl_engine_get_task_runner(engine));
  auto red = Create(8, 8);
  auto blue = Create(3, 3);
  Clear(&red, 1, 0, 0);
  Clear(&blue, 0, 0, 1);
  FlutterLayer background = {};
  background.type = kFlutterLayerContentTypeBackingStore;
  background.backing_store = &red;
  background.size = {8, 8};
  FlutterLayer foreground = background;
  foreground.backing_store = &blue;
  foreground.offset = {2, 3};
  foreground.size = {3, 3};
  const FlutterLayer* layers[] = {&background, &foreground};
  ASSERT_TRUE(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 2));
  fl_vulkan_manager_collect_backing_store(&red);
  fl_vulkan_manager_collect_backing_store(&blue);
  // Create the GTK texture on the main thread from the immutable readback.
  auto* klass = FL_COMPOSITOR_GET_CLASS(compositor);
  g_autoptr(GdkTexture) texture = klass->acquire_texture(
      FL_COMPOSITOR(compositor), nullptr, nullptr, 8, 8, FALSE);
  ASSERT_NE(texture, nullptr);
  uint32_t pixels[64];
  gdk_texture_download(texture, reinterpret_cast<guchar*>(pixels), 8 * 4);
  EXPECT_EQ(pixels[0], 0xffff0000u);
  EXPECT_EQ(pixels[3 * 8 + 2], 0xff0000ffu);
  EXPECT_EQ(pixels[7 * 8 + 7], 0xffff0000u);
  ASSERT_TRUE(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), nullptr, 0));
  g_autoptr(GdkTexture) cleared = klass->acquire_texture(
      FL_COMPOSITOR(compositor), nullptr, nullptr, 8, 8, FALSE);
  ASSERT_NE(cleared, nullptr);
  gdk_texture_download(cleared, reinterpret_cast<guchar*>(pixels), 8 * 4);
  EXPECT_EQ(pixels[0], 0u);
  EXPECT_EQ(pixels[3 * 8 + 2], 0u);
  // An already acquired texture remains valid after clearing the compositor.
  gdk_texture_download(texture, reinterpret_cast<guchar*>(pixels), 8 * 4);
  EXPECT_EQ(pixels[3 * 8 + 2], 0xff0000ffu);
}

TEST_F(FlVulkanIntegrationTest, ExportSnapshotSurvivesReuseAndEngineTeardown) {
  auto store = Create(17, 13);
  Clear(&store, 1, 0, 0);
  g_autoptr(GError) error = nullptr;
  auto snapshot = fl_vulkan_backing_store_snapshot(&store, &error);
  if (!snapshot) {
    fl_vulkan_manager_collect_backing_store(&store);
    ASSERT_STRNE(g_getenv("FLUTTER_TEST_VULKAN_DMABUF"), "1")
        << (error ? error->message : "DMA-BUF unavailable");
    GTEST_SKIP() << "ICD cannot export a host-accessible DMA-BUF";
  }
  EXPECT_GE(snapshot->descriptor().planes[0].fd, 0);
  EXPECT_GE(snapshot->descriptor().planes[0].stride, 17u * 4);
  EXPECT_EQ(snapshot->descriptor().modifier, 0u);
  // Reuse and destroy the source before GTK even acquires the previous frame.
  Clear(&store, 0, 0, 1);
  auto blue = fl_vulkan_backing_store_snapshot(&store, &error);
  ASSERT_NE(blue, nullptr) << (error ? error->message : "");
  fl_vulkan_manager_collect_backing_store(&store);
  g_clear_object(&manager);
  bool imported = true;
  // No display forces import rejection and exercises immutable fallback.
  g_autoptr(GdkTexture) red_texture =
      snapshot->CreateTexture(nullptr, &imported, &error);
  ASSERT_NE(red_texture, nullptr) << (error ? error->message : "");
  EXPECT_FALSE(imported);
  g_autoptr(GdkTexture) blue_texture =
      blue->CreateTexture(nullptr, &imported, &error);
  ASSERT_NE(blue_texture, nullptr);
  snapshot.reset();
  blue.reset();
  uint32_t pixels[17 * 13];
  gdk_texture_download(red_texture, reinterpret_cast<guchar*>(pixels), 17 * 4);
  for (auto pixel : pixels)
    EXPECT_EQ(pixel, 0xffff0000u);
  gdk_texture_download(blue_texture, reinterpret_cast<guchar*>(pixels), 17 * 4);
  for (auto pixel : pixels)
    EXPECT_EQ(pixel, 0xff0000ffu);
}

TEST_F(FlVulkanIntegrationTest, SingleLayerSnapshotIsCachedAndCleared) {
  g_autoptr(FlCompositorVulkan) compositor =
      fl_compositor_vulkan_new(fl_engine_get_task_runner(engine));
  auto store = Create(17, 13);
  Clear(&store, 0, 1, 0);
  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &store;
  layer.size = {17, 13};
  const FlutterLayer* layers[] = {&layer};
  ASSERT_TRUE(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  Clear(&store, 1, 0, 0);
  fl_vulkan_manager_collect_backing_store(&store);
  auto* klass = FL_COMPOSITOR_GET_CLASS(compositor);
  g_autoptr(GdkTexture) texture = klass->acquire_texture(
      FL_COMPOSITOR(compositor), nullptr, nullptr, 17, 13, FALSE);
  ASSERT_NE(texture, nullptr);
  g_autoptr(GdkTexture) cached = klass->acquire_texture(
      FL_COMPOSITOR(compositor), nullptr, nullptr, 17, 13, FALSE);
  EXPECT_EQ(cached, texture);
  ASSERT_TRUE(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), nullptr, 0));
  g_autoptr(GdkTexture) cleared = klass->acquire_texture(
      FL_COMPOSITOR(compositor), nullptr, nullptr, 17, 13, FALSE);
  ASSERT_NE(cleared, nullptr);
  uint32_t pixels[17 * 13];
  gdk_texture_download(cleared, reinterpret_cast<guchar*>(pixels), 17 * 4);
  for (auto pixel : pixels)
    EXPECT_EQ(pixel, 0u);
  g_clear_object(&compositor);
  g_clear_object(&manager);
  gdk_texture_download(texture, reinterpret_cast<guchar*>(pixels), 17 * 4);
  for (auto pixel : pixels)
    EXPECT_EQ(pixel, 0xff00ff00u);
}

struct TestVulkanPixels {
  FlPixelBufferTexture parent;
};
struct TestVulkanPixelsClass {
  FlPixelBufferTextureClass parent;
};
G_DEFINE_TYPE(TestVulkanPixels,
              test_vulkan_pixels,
              fl_pixel_buffer_texture_get_type())
static void test_vulkan_pixels_class_init(TestVulkanPixelsClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels =
      [](FlPixelBufferTexture*, const uint8_t** bytes, uint32_t* width,
         uint32_t* height, GError**) -> gboolean {
    static const uint8_t pixels[] = {255, 0, 0,   255, 0,   255, 0,   255,
                                     0,   0, 255, 255, 255, 255, 255, 255};
    *bytes = pixels;
    *width = 2;
    *height = 2;
    return TRUE;
  };
}
static void test_vulkan_pixels_init(TestVulkanPixels*) {}

TEST_F(FlVulkanIntegrationTest, PixelBufferUploadRetainsDeviceUntilRelease) {
  g_autoptr(FlPixelBufferTexture) texture = FL_PIXEL_BUFFER_TEXTURE(
      g_object_new(test_vulkan_pixels_get_type(), nullptr));
  FlutterVulkanExternalTexture external = {};
  g_autoptr(GError) error = nullptr;
  ASSERT_TRUE(fl_pixel_buffer_texture_populate_vulkan(texture, manager, 100,
                                                      100, &external, &error))
      << (error ? error->message : "");
  EXPECT_EQ(external.width, 2u);
  EXPECT_EQ(external.height, 2u);
  EXPECT_EQ(external.format, uint32_t(VK_FORMAT_R8G8B8A8_UNORM));
  EXPECT_NE(external.image, 0u);
  ASSERT_NE(external.destruction_callback, nullptr);
  g_clear_object(&texture);
  g_clear_object(&manager);
  external.destruction_callback(external.user_data);
}

TEST_F(FlVulkanIntegrationTest, ExportPoolReusePreservesEarlierPixels) {
  auto store = Create(17, 13);
  auto pool = flutter::FlVulkanSnapshotPool::Create(
      fl_vulkan_manager_get_device_context(manager));
  Clear(&store, 1, 0, 0);
  g_autoptr(GError) error = nullptr;
  auto red = flutter::FlVulkanSnapshot::Create(
      pool, reinterpret_cast<VkImage>(store.vulkan.image->image), 17, 13,
      &error);
  if (!red) {
    fl_vulkan_manager_collect_backing_store(&store);
    ASSERT_STRNE(g_getenv("FLUTTER_TEST_VULKAN_DMABUF"), "1")
        << (error ? error->message : "DMA-BUF unavailable");
    GTEST_SKIP() << "ICD cannot export a host-accessible DMA-BUF";
  }
  bool imported = true;
  g_autoptr(GdkTexture) red_texture =
      red->CreateTexture(nullptr, &imported, &error);
  ASSERT_NE(red_texture, nullptr);
  const int fd = red->descriptor().planes[0].fd;
  red.reset();
  // The memory fallback copied the pixels, so the export slot is reusable even
  // though the old memory texture remains alive. Exercise foreign reacquisition
  // repeatedly and check earlier frames never change.
  for (size_t i = 0; i < 20; i++) {
    Clear(&store, 0, 0, 1);
    auto blue = flutter::FlVulkanSnapshot::Create(
        pool, reinterpret_cast<VkImage>(store.vulkan.image->image), 17, 13,
        &error);
    ASSERT_NE(blue, nullptr) << (error ? error->message : "");
    EXPECT_EQ(blue->descriptor().planes[0].fd, fd);
    g_autoptr(GdkTexture) blue_texture =
        blue->CreateTexture(nullptr, &imported, &error);
    ASSERT_NE(blue_texture, nullptr);
    uint32_t pixels[17 * 13];
    gdk_texture_download(blue_texture, reinterpret_cast<guchar*>(pixels),
                         17 * 4);
    for (auto pixel : pixels)
      EXPECT_EQ(pixel, 0xff0000ffu);
    gdk_texture_download(red_texture, reinterpret_cast<guchar*>(pixels),
                         17 * 4);
    for (auto pixel : pixels)
      EXPECT_EQ(pixel, 0xffff0000u);
  }
  EXPECT_EQ(pool->stats().allocations, 1u);
  EXPECT_EQ(pool->stats().reuses, 20u);
  fl_vulkan_manager_collect_backing_store(&store);
}
