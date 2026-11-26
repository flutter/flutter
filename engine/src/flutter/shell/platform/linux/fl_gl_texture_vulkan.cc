// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gl_texture_vulkan.h"

#include <epoxy/gl.h>
#include <unistd.h>
#include <algorithm>
#include <vector>

#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"

namespace {
constexpr VkFormat kFormat = VK_FORMAT_R8G8B8A8_UNORM;
constexpr EGLint kAbgr8888 = 0x34324241;

struct Slot {
  flutter::FlVulkanDeviceContext ctx;
  EGLDisplay display;
  EGLImageKHR egl_image = EGL_NO_IMAGE_KHR;
  VkImage image = VK_NULL_HANDLE;
  VkDeviceMemory memory = VK_NULL_HANDLE;
  VkCommandPool pool = VK_NULL_HANDLE;
  VkCommandBuffer command = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;
  uint32_t width, height;
  bool sampled = false;

  Slot(flutter::FlVulkanDeviceContext context,
       EGLDisplay display,
       uint32_t width,
       uint32_t height)
      : ctx(std::move(context)),
        display(display),
        width(width),
        height(height) {}
#define PROC(name) \
  reinterpret_cast<PFN_vk##name>(ctx.get_proc(ctx.device, "vk" #name))
  ~Slot() {
    if (egl_image != EGL_NO_IMAGE_KHR)
      eglDestroyImageKHR(display, egl_image);
    PROC(DestroyFence)(ctx.device, fence, nullptr);
    PROC(DestroyCommandPool)(ctx.device, pool, nullptr);
    PROC(DestroyImage)(ctx.device, image, nullptr);
    PROC(FreeMemory)(ctx.device, memory, nullptr);
  }

  bool Initialize() {
    if (!width || !height || width > ctx.max_image_dimension ||
        height > ctx.max_image_dimension)
      return false;
    uint64_t linear = 0;
    VkImageDrmFormatModifierListCreateInfoEXT modifiers = {
        VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT};
    modifiers.drmFormatModifierCount = 1;
    modifiers.pDrmFormatModifiers = &linear;
    VkExternalMemoryImageCreateInfo external = {
        VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO};
    external.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
    external.pNext = &modifiers;
    VkImageCreateInfo info = {VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
    info.pNext = &external;
    info.imageType = VK_IMAGE_TYPE_2D;
    info.format = kFormat;
    info.extent = {width, height, 1};
    info.mipLevels = info.arrayLayers = 1;
    info.samples = VK_SAMPLE_COUNT_1_BIT;
    info.tiling = VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT;
    info.usage =
        VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    if (PROC(CreateImage)(ctx.device, &info, nullptr, &image) != VK_SUCCESS)
      return false;
    VkMemoryRequirements req;
    PROC(GetImageMemoryRequirements)(ctx.device, image, &req);
    VkMemoryDedicatedAllocateInfo dedicated = {
        VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO};
    dedicated.image = image;
    VkExportMemoryAllocateInfo export_info = {
        VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO};
    export_info.pNext = &dedicated;
    export_info.handleTypes = external.handleTypes;
    VkMemoryAllocateInfo alloc = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
    alloc.pNext = &export_info;
    alloc.allocationSize = req.size;
    for (; alloc.memoryTypeIndex < ctx.memory.memoryTypeCount;
         alloc.memoryTypeIndex++) {
      if ((req.memoryTypeBits & (1u << alloc.memoryTypeIndex)) &&
          (ctx.memory.memoryTypes[alloc.memoryTypeIndex].propertyFlags &
           VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
        break;
    }
    if (alloc.memoryTypeIndex == ctx.memory.memoryTypeCount ||
        PROC(AllocateMemory)(ctx.device, &alloc, nullptr, &memory) !=
            VK_SUCCESS ||
        PROC(BindImageMemory)(ctx.device, image, memory, 0) != VK_SUCCESS)
      return false;
    VkImageSubresource sub = {VK_IMAGE_ASPECT_MEMORY_PLANE_0_BIT_EXT, 0, 0};
    VkSubresourceLayout layout;
    PROC(GetImageSubresourceLayout)(ctx.device, image, &sub, &layout);
    if (layout.rowPitch > INT32_MAX || layout.offset > INT32_MAX)
      return false;
    VkMemoryGetFdInfoKHR fd_info = {VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR};
    fd_info.memory = memory;
    fd_info.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
    int fd = -1;
    if (PROC(GetMemoryFdKHR)(ctx.device, &fd_info, &fd) != VK_SUCCESS)
      return false;
    const EGLint attrs[] = {EGL_WIDTH,
                            static_cast<EGLint>(width),
                            EGL_HEIGHT,
                            static_cast<EGLint>(height),
                            EGL_LINUX_DRM_FOURCC_EXT,
                            kAbgr8888,
                            EGL_DMA_BUF_PLANE0_FD_EXT,
                            fd,
                            EGL_DMA_BUF_PLANE0_OFFSET_EXT,
                            static_cast<EGLint>(layout.offset),
                            EGL_DMA_BUF_PLANE0_PITCH_EXT,
                            static_cast<EGLint>(layout.rowPitch),
                            EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT,
                            0,
                            EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT,
                            0,
                            EGL_NONE};
    egl_image = eglCreateImageKHR(display, EGL_NO_CONTEXT,
                                  EGL_LINUX_DMA_BUF_EXT, nullptr, attrs);
    close(fd);
    if (egl_image == EGL_NO_IMAGE_KHR)
      return false;
    VkCommandPoolCreateInfo pool_info = {
        VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    pool_info.queueFamilyIndex = ctx.queue_family;
    if (PROC(CreateCommandPool)(ctx.device, &pool_info, nullptr, &pool) !=
        VK_SUCCESS)
      return false;
    VkCommandBufferAllocateInfo cmd = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    cmd.commandPool = pool;
    cmd.commandBufferCount = 1;
    VkFenceCreateInfo fi = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    return PROC(AllocateCommandBuffers)(ctx.device, &cmd, &command) ==
               VK_SUCCESS &&
           PROC(CreateFence)(ctx.device, &fi, nullptr, &fence) == VK_SUCCESS;
  }

  // Only the raster thread submits. Wait before handing the image to the
  // other API, including before the first EGL write discards its contents.
  bool TransferOwnership(bool to_gl) {
    if (PROC(ResetCommandPool)(ctx.device, pool, 0) != VK_SUCCESS ||
        PROC(ResetFences)(ctx.device, 1, &fence) != VK_SUCCESS)
      return false;
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    if (PROC(BeginCommandBuffer)(command, &begin) != VK_SUCCESS)
      return false;
    VkImageMemoryBarrier barrier = {VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    barrier.image = image;
    barrier.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
    barrier.oldLayout =
        to_gl ? (sampled ? VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
                         : VK_IMAGE_LAYOUT_UNDEFINED)
              : VK_IMAGE_LAYOUT_GENERAL;
    barrier.newLayout = to_gl ? VK_IMAGE_LAYOUT_GENERAL
                              : VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    barrier.srcQueueFamilyIndex =
        to_gl ? ctx.queue_family : VK_QUEUE_FAMILY_FOREIGN_EXT;
    barrier.dstQueueFamilyIndex =
        to_gl ? VK_QUEUE_FAMILY_FOREIGN_EXT : ctx.queue_family;
    barrier.srcAccessMask = to_gl && sampled ? VK_ACCESS_SHADER_READ_BIT : 0;
    barrier.dstAccessMask = to_gl ? 0 : VK_ACCESS_SHADER_READ_BIT;
    PROC(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                             VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, nullptr,
                             0, nullptr, 1, &barrier);
    if (PROC(EndCommandBuffer)(command) != VK_SUCCESS)
      return false;
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    return ctx.submit(ctx.queue, 1, &submit, fence) == VK_SUCCESS &&
           PROC(WaitForFences)(ctx.device, 1, &fence, VK_TRUE, UINT64_MAX) ==
               VK_SUCCESS;
  }
#undef PROC
};

bool CopyGL(const Slot& slot, GLuint source) {
  GLint old_read, old_draw, old_texture;
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &old_read);
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &old_draw);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &old_texture);
  GLboolean scissor = glIsEnabled(GL_SCISSOR_TEST);
  GLuint texture = 0, fb[2] = {};
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, slot.egl_image);
  glGenFramebuffers(2, fb);
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb[0]);
  glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, source, 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fb[1]);
  glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, texture, 0);
  const GLenum draw_status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
  const GLenum read_status = glCheckFramebufferStatus(GL_READ_FRAMEBUFFER);
  bool complete = draw_status == GL_FRAMEBUFFER_COMPLETE &&
                  read_status == GL_FRAMEBUFFER_COMPLETE;
  if (!complete)
    flutter_linux_gtk4_dbg("vulkan-gl-texture",
                           "incomplete draw=%x read=%x error=%x", draw_status,
                           read_status, glGetError());
  if (complete) {
    glDisable(GL_SCISSOR_TEST);
    glBlitFramebuffer(0, 0, slot.width, slot.height, 0, 0, slot.width,
                      slot.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    const GLenum err = glGetError();
    complete = err == GL_NO_ERROR;
    if (!complete)
      flutter_linux_gtk4_dbg("vulkan-gl-texture", "blit error=%x", err);
    glFinish();
    if (scissor)
      glEnable(GL_SCISSOR_TEST);
  }
  glBindFramebuffer(GL_READ_FRAMEBUFFER, old_read);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, old_draw);
  glBindTexture(GL_TEXTURE_2D, old_texture);
  glDeleteFramebuffers(2, fb);
  glDeleteTextures(1, &texture);
  return complete;
}
// A permanent driver failure can recur on every raster callback.
bool WarnFrameFailure(FlTextureGL* texture, const char* reason) {
  static const GQuark key =
      g_quark_from_static_string("fl-gl-vulkan-frame-error");
  if (!g_object_get_qdata(G_OBJECT(texture), key)) {
    g_object_set_qdata(G_OBJECT(texture), key, GINT_TO_POINTER(1));
    g_warning("Cannot deliver OpenGL plugin texture to Vulkan: %s", reason);
  }
  return false;
}
using Slots = std::vector<std::shared_ptr<Slot>>;
}  // namespace

const gchar* fl_gl_texture_check_vulkan_import(FlOpenGLManager* gl) {
  EGLDisplay display = fl_opengl_manager_get_display(gl);
  if (display == EGL_NO_DISPLAY ||
      !epoxy_has_egl_extension(display, "EGL_EXT_image_dma_buf_import") ||
      !epoxy_has_egl_extension(display,
                               "EGL_EXT_image_dma_buf_import_modifiers"))
    return "EGL DMA-BUF import with modifiers is unavailable";

  EGLDisplay previous = eglGetCurrentDisplay();
  EGLContext context = eglGetCurrentContext();
  EGLSurface draw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface read = eglGetCurrentSurface(EGL_READ);
  if (fl_opengl_manager_get_context(gl) == EGL_NO_CONTEXT ||
      !fl_opengl_manager_make_current(gl))
    return "Cannot bind the plugin render context";

  const gchar* reason = nullptr;
  if (epoxy_gl_version() < 30)
    reason = "GL 3.0 is required";
  else if (!epoxy_has_gl_extension("GL_OES_EGL_image"))
    reason = "GL_OES_EGL_image is unavailable";
  if (!eglMakeCurrent(previous == EGL_NO_DISPLAY ? display : previous, draw,
                      read, context))
    return "Cannot restore the previous EGL context";
  return reason;
}

bool fl_gl_texture_populate_vulkan(FlTextureGL* texture,
                                   FlOpenGLManager* gl,
                                   FlVulkanManager* vk,
                                   uint32_t width,
                                   uint32_t height,
                                   FlutterVulkanExternalTexture* output) {
  if (!fl_vulkan_manager_supports_gl_images(vk) ||
      !fl_opengl_manager_make_current(gl))
    return WarnFrameFailure(texture, "bridge or render context unavailable");
  struct Clear {
    FlOpenGLManager* gl;
    ~Clear() { fl_opengl_manager_clear_current(gl); }
  } clear{gl};
  auto display = eglGetCurrentDisplay();
  FlutterOpenGLTexture source = {};
  g_autoptr(GError) error = nullptr;
  if (!fl_texture_gl_populate(texture, width, height, &source, &error) ||
      source.target != GL_TEXTURE_2D || !source.name ||
      source.width > UINT32_MAX || source.height > UINT32_MAX)
    return false;
  // One pool per registered plugin texture. An engine-managed release can
  // drop its lease on any thread; only this raster callback mutates the pool.
  static const GQuark key = g_quark_from_static_string("fl-gl-vulkan-slots");
  auto* slots = static_cast<Slots*>(g_object_get_qdata(G_OBJECT(texture), key));
  if (!slots) {
    slots = new Slots;
    g_object_set_qdata_full(G_OBJECT(texture), key, slots, [](void* data) {
      delete static_cast<Slots*>(data);
    });
  }
  auto ctx = fl_vulkan_manager_get_device_context(vk);
  auto available =
      std::find_if(slots->begin(), slots->end(),
                   [](const auto& s) { return !s || s.use_count() == 1; });
  if (available == slots->end()) {
    if (slots->size() >= 3)
      return false;
    slots->emplace_back();
    available = std::prev(slots->end());
  }
  auto& slot = *available;
  if (!slot || slot->width != source.width || slot->height != source.height ||
      slot->ctx.device != ctx.device) {
    slot = std::make_shared<Slot>(ctx, display, source.width, source.height);
    if (!slot->Initialize()) {
      slot.reset();
      return WarnFrameFailure(texture, "DMA-BUF slot initialization failed");
    }
  }
  if (!slot->TransferOwnership(true) || !CopyGL(*slot, source.name) ||
      !slot->TransferOwnership(false)) {
    slot.reset();
    return WarnFrameFailure(texture, "ownership transfer or GL blit failed");
  }
  if (!slot->sampled) {
    flutter_linux_gtk4_dbg("vulkan-gl-texture", "path=dmabuf size=%zux%zu",
                           source.width, source.height);
  }
  slot->sampled = true;
  *output = {
      sizeof(*output),
      reinterpret_cast<uint64_t>(slot->image),
      kFormat,
      new std::shared_ptr<Slot>(slot),
      [](void* data) { delete static_cast<std::shared_ptr<Slot>*>(data); },
      source.width,
      source.height};
  return true;
}
