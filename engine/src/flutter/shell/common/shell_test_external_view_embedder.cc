#include "shell_test_external_view_embedder.h"

namespace flutter {

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::CancelFrame() {}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::BeginFrame(SkISize frame_size,
                                               GrContext* context,
                                               double device_pixel_ratio) {}

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
bool ShellTestExternalViewEmbedder::SubmitFrame(GrContext* context,
                                                SkCanvas* background_canvas) {
  return true;
}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::FinishFrame() {}

// |ExternalViewEmbedder|
void ShellTestExternalViewEmbedder::EndFrame(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  end_frame_call_back_();
}

// |ExternalViewEmbedder|
SkCanvas* ShellTestExternalViewEmbedder::GetRootCanvas() {
  return nullptr;
}

}  // namespace flutter
