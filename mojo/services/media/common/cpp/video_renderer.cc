// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "mojo/services/media/common/cpp/timeline.h"
#include "mojo/services/media/common/cpp/video_renderer.h"

namespace mojo {
namespace media {

VideoRenderer::VideoRenderer()
    : renderer_binding_(this),
      control_point_binding_(this),
      timeline_consumer_binding_(this) {}

VideoRenderer::~VideoRenderer() {}

void VideoRenderer::Bind(InterfaceRequest<MediaRenderer> renderer_request) {
  renderer_binding_.Bind(renderer_request.Pass());
}

Size VideoRenderer::GetSize() {
  return converter_.GetSize();
}

void VideoRenderer::GetRgbaFrame(uint8_t* rgba_buffer,
                                 const Size& rgba_buffer_size,
                                 int64_t reference_time) {
  MaybeApplyPendingTimelineChange(reference_time);
  MaybePublishEndOfStream();

  int64_t presentation_time = current_timeline_function_(reference_time);

  // Discard empty and old packets. We keep one packet around even if it's old,
  // so we can show an old frame instead of no frame when we starve.
  while (packet_queue_.size() > 1 &&
         packet_queue_.front()->packet()->pts < presentation_time) {
    // TODO(dalesat): Add hysteresis.
    packet_queue_.pop();
  }

  // TODO(dalesat): Detect starvation.

  if (packet_queue_.empty()) {
    memset(rgba_buffer, 0,
           rgba_buffer_size.width * rgba_buffer_size.height * 4);
  } else {
    converter_.ConvertFrame(rgba_buffer, rgba_buffer_size.width,
                            rgba_buffer_size.height,
                            packet_queue_.front()->payload(),
                            packet_queue_.front()->payload_size());
  }
}

void VideoRenderer::GetSupportedMediaTypes(
    const GetSupportedMediaTypesCallback& callback) {
  VideoMediaTypeSetDetailsPtr video_details = VideoMediaTypeSetDetails::New();
  video_details->min_width = 1;
  video_details->max_width = std::numeric_limits<uint32_t>::max();
  video_details->min_height = 1;
  video_details->max_height = std::numeric_limits<uint32_t>::max();
  MediaTypeSetPtr supported_type = MediaTypeSet::New();
  supported_type->medium = MediaTypeMedium::VIDEO;
  supported_type->details = MediaTypeSetDetails::New();
  supported_type->details->set_video(video_details.Pass());
  supported_type->encodings = Array<String>::New(1);
  supported_type->encodings[0] = MediaType::kVideoEncodingUncompressed;
  Array<MediaTypeSetPtr> supported_types = Array<MediaTypeSetPtr>::New(1);
  supported_types[0] = supported_type.Pass();
  callback.Run(supported_types.Pass());
}

void VideoRenderer::SetMediaType(MediaTypePtr media_type) {
  MOJO_DCHECK(media_type);
  MOJO_DCHECK(media_type->details);
  const VideoMediaTypeDetailsPtr& details = media_type->details->get_video();
  MOJO_DCHECK(details);

  converter_.SetMediaType(media_type);
}

void VideoRenderer::GetPacketConsumer(
    InterfaceRequest<MediaPacketConsumer> packet_consumer_request) {
  MediaPacketConsumerBase::Bind(packet_consumer_request.Pass());
}

void VideoRenderer::GetTimelineControlPoint(
    InterfaceRequest<MediaTimelineControlPoint> control_point_request) {
  control_point_binding_.Bind(control_point_request.Pass());
}

void VideoRenderer::OnPacketSupplied(
    std::unique_ptr<SuppliedPacket> supplied_packet) {
  MOJO_DCHECK(supplied_packet);
  if (supplied_packet->packet()->end_of_stream) {
    end_of_stream_pts_ = supplied_packet->packet()->pts;
  }

  // Discard empty packets so they don't confuse the selection logic.
  if (supplied_packet->payload() == nullptr) {
    return;
  }

  packet_queue_.push(std::move(supplied_packet));
}

void VideoRenderer::OnFlushRequested(const FlushCallback& callback) {
  while (!packet_queue_.empty()) {
    packet_queue_.pop();
  }
  callback.Run();
}

void VideoRenderer::OnFailure() {
  // TODO(dalesat): Report this to our owner.
  if (renderer_binding_.is_bound()) {
    renderer_binding_.Close();
  }

  if (control_point_binding_.is_bound()) {
    control_point_binding_.Close();
  }

  if (timeline_consumer_binding_.is_bound()) {
    timeline_consumer_binding_.Close();
  }

  MediaPacketConsumerBase::OnFailure();
}

void VideoRenderer::GetStatus(uint64_t version_last_seen,
                              const GetStatusCallback& callback) {
  if (version_last_seen < status_version_) {
    CompleteGetStatus(callback);
  } else {
    pending_status_callbacks_.push_back(callback);
  }
}

void VideoRenderer::GetTimelineConsumer(
    InterfaceRequest<TimelineConsumer> timeline_consumer_request) {
  timeline_consumer_binding_.Bind(timeline_consumer_request.Pass());
}

void VideoRenderer::Prime(const PrimeCallback& callback) {
  SetDemand(2);
  callback.Run();  // TODO(dalesat): Wait until we get packets.
}

void VideoRenderer::SetTimelineTransform(
    TimelineTransformPtr timeline_transform,
    const SetTimelineTransformCallback& callback) {
  MOJO_DCHECK(timeline_transform);
  MOJO_DCHECK(timeline_transform->reference_delta != 0);

  if (timeline_transform->subject_time != kUnspecifiedTime &&
      end_of_stream_pts_ != kUnspecifiedTime) {
    end_of_stream_pts_ = kUnspecifiedTime;
    end_of_stream_published_ = false;
  }

  int64_t reference_time =
      timeline_transform->reference_time == kUnspecifiedTime
          ? Timeline::local_now()
          : timeline_transform->reference_time;
  int64_t subject_time = timeline_transform->subject_time == kUnspecifiedTime
                             ? current_timeline_function_(reference_time)
                             : timeline_transform->subject_time;

  // Eject any previous pending change.
  ClearPendingTimelineFunction(false);

  // Queue up the new pending change.
  pending_timeline_function_ = TimelineFunction(
      reference_time, subject_time, timeline_transform->reference_delta,
      timeline_transform->subject_delta);

  set_timeline_transform_callback_ = callback;
}

void VideoRenderer::ClearPendingTimelineFunction(bool completed) {
  pending_timeline_function_ =
      TimelineFunction(kUnspecifiedTime, kUnspecifiedTime, 1, 0);
  if (!set_timeline_transform_callback_.is_null()) {
    set_timeline_transform_callback_.Run(completed);
    set_timeline_transform_callback_.reset();
  }
}

void VideoRenderer::MaybeApplyPendingTimelineChange(int64_t reference_time) {
  if (pending_timeline_function_.reference_time() == kUnspecifiedTime ||
      pending_timeline_function_.reference_time() > reference_time) {
    return;
  }

  current_timeline_function_ = pending_timeline_function_;
  pending_timeline_function_ =
      TimelineFunction(kUnspecifiedTime, kUnspecifiedTime, 1, 0);

  if (!set_timeline_transform_callback_.is_null()) {
    set_timeline_transform_callback_.Run(true);
    set_timeline_transform_callback_.reset();
  }

  SendStatusUpdates();
}

void VideoRenderer::MaybePublishEndOfStream() {
  if (!end_of_stream_published_ && end_of_stream_pts_ != kUnspecifiedTime &&
      current_timeline_function_(Timeline::local_now()) >= end_of_stream_pts_) {
    end_of_stream_published_ = true;
    SendStatusUpdates();
  }
}

void VideoRenderer::SendStatusUpdates() {
  ++status_version_;

  std::vector<GetStatusCallback> pending_status_callbacks;
  pending_status_callbacks_.swap(pending_status_callbacks);

  for (const GetStatusCallback& pending_status_callback :
       pending_status_callbacks) {
    CompleteGetStatus(pending_status_callback);
  }
}

void VideoRenderer::CompleteGetStatus(const GetStatusCallback& callback) {
  MediaTimelineControlPointStatusPtr status =
      MediaTimelineControlPointStatus::New();
  status->timeline_transform =
      TimelineTransform::From(current_timeline_function_);
  status->end_of_stream =
      end_of_stream_pts_ != kUnspecifiedTime &&
      current_timeline_function_(Timeline::local_now()) >= end_of_stream_pts_;
  callback.Run(status_version_, status.Pass());
}

}  // namespace media
}  // namespace mojo
