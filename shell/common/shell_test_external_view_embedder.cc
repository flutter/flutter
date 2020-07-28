#include "shell_test_external_view_embedder.h"

namespace flutter {

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::CancelFrame() {}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {}

// |ExternalViewEmbedder|
PostPrerollResult ShellTestExternalViewEmbedder::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  FML_DCHECK(raster_thread_merger);
  return post_preroll_result_;
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> ShellTestExternalViewEmbedder::GetCurrentCanvases() {
  return {};
}

// |ExternalViewEmbedder|
SkCanvas* ShellTestExternalViewEmbedder::CompositeEmbeddedView(int view_id) {
  return nullptr;
}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::SubmitFrame(
    GrDirectContext* context,
    std::unique_ptr<SurfaceFrame> frame) {
  frame->Submit();
}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  end_frame_call_back_(should_resubmit_frame);
}

// |ExternalViewEmbedder|
SkCanvas* ShellTestExternalViewEmbedder::GetRootCanvas() {
  return nullptr;
}

}  // namespace flutter
