// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_dart_heap_profiler.h"

#if defined(FLUTTER_ENABLE_HEAPPROFD)

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

#include "flutter/fml/endianness.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/runtime/dart_heap_profiler.h"
#include "flutter/shell/platform/android/android_dart_heap_profiler_internal.h"
#include "perfetto/base/logging.h"
#include "perfetto/base/time.h"
#include "perfetto/ext/base/scoped_file.h"
#include "perfetto/ext/base/thread_task_runner.h"
#include "perfetto/ext/base/unix_socket.h"
#include "perfetto/ext/tracing/core/shared_memory_abi.h"
#include "perfetto/protozero/proto_utils.h"

namespace flutter {
namespace {

namespace hp = android_heap_profile_internal;

// Bionic's libc.so exports <execinfo.h> backtrace() starting in Android 13
// (API level 33).
constexpr int kMinBacktraceApiLevel = 33;
constexpr const char* kTracedProducerSocket = "/dev/socket/traced_producer";
constexpr uint16_t kMaxWriterId = 1023;
constexpr size_t kMaxFrameSize = 16 * 1024 * 1024;
constexpr uint32_t kInitialBackoffMs = 1000;
constexpr uint32_t kMaxBackoffMs = 30000;

// Perfetto IPCFrame wire-protocol field IDs.
constexpr uint32_t kIpcFrameRequestIdField = 2;
constexpr uint32_t kIpcFrameBindServiceField = 3;
constexpr uint32_t kIpcFrameBindServiceReplyField = 4;
constexpr uint32_t kIpcFrameInvokeMethodField = 5;
constexpr uint32_t kIpcFrameInvokeMethodReplyField = 6;

/// Android `DartHeapProfilerDelegate` and Perfetto `ProducerPort` client
/// running on a `perfetto::base::ThreadTaskRunner` that registers
/// `"android.heapprofd"` for `ProfilingManager` and streams `ProfilePacket`s
/// via `SharedMemoryABI`.
class TracedHeapProducer final
    : public DartHeapProfilerDelegate,
      public perfetto::base::UnixSocket::EventListener {
 public:
  TracedHeapProducer() = default;

  void Start() {
    task_runner_.emplace(
        perfetto::base::ThreadTaskRunner::CreateAndStart("io.flutter.heap"));
    task_runner_->PostTask([this]() { ConnectOnProducerThread(); });
  }

  // DartHeapProfilerDelegate:
  void OnDartVMInitialized() override {
    hp::ElfModuleScanner::RegisterMissingDartEhFrames();
  }

  void* OnSampleCreated(uintptr_t isolate_group_id,
                        std::string_view class_name,
                        size_t size) override {
    return aggregator_.RecordCurrentThreadAlloc(isolate_group_id, class_name,
                                                size);
  }

  void OnSampleDestroyed(void* sample_context) override {
    hp::HeapSampleAggregator::RecordFree(sample_context);
  }

 private:
  struct MovedChunk {
    uint32_t page = 0;
    uint32_t chunk = 0;
  };

  void ConnectOnProducerThread() {
    PERFETTO_DCHECK(task_runner_->RunsTasksOnCurrentThread());
    socket_ = perfetto::base::UnixSocket::Connect(
        kTracedProducerSocket, this, task_runner_->get(),
        perfetto::base::SockFamily::kUnix, perfetto::base::SockType::kStream);
  }

  void ScheduleReconnect() {
    const uint32_t delay_ms = backoff_ms_;
    backoff_ms_ = std::min(backoff_ms_ * 2, kMaxBackoffMs);
    task_runner_->PostDelayedTask([this]() { ConnectOnProducerThread(); },
                                  delay_ms);
  }

  // perfetto::base::UnixSocket::EventListener:
  void OnConnect(perfetto::base::UnixSocket* /*self*/,
                 bool connected) override {
    if (!connected) {
      socket_.reset();
      ScheduleReconnect();
      return;
    }
    backoff_ms_ = kInitialBackoffMs;
    rx_buffer_.clear();
    rx_buffer_.reserve(8192);

    protozero::HeapBuffered<protozero::Message> frame;
    frame->AppendVarInt(kIpcFrameRequestIdField, next_req_id_++);
    auto* bind = frame->BeginNestedMessage<protozero::Message>(
        kIpcFrameBindServiceField);
    bind->AppendString(/*service_name=*/1, "ProducerPort");
    bind->Finalize();
    SendFrame(frame.SerializeAsArray());
  }

  void OnDisconnect(perfetto::base::UnixSocket* /*self*/) override {
    StopSession(/*notify_service=*/false);
    socket_.reset();
    pending_shm_fd_.reset();
    shm_mapping_.reset();
    rx_buffer_.clear();
    service_id_ = 0;
    m_init_ = m_reg_ds_ = m_commit_ = m_async_cmd_ = m_reg_writer_ =
        m_unreg_writer_ = m_notify_stopped_ = 0;
    pending_id_ = 0;
    ScheduleReconnect();
  }

  void OnDataAvailable(perfetto::base::UnixSocket* self) override {
    std::array<uint8_t, 4096> chunk;
    for (;;) {
      perfetto::base::ScopedFile received_fd;
      const size_t n = self->Receive(chunk.data(), chunk.size(), &received_fd);
      if (received_fd) {
        pending_shm_fd_.reset(received_fd.release());
      }
      if (n == 0) {
        break;
      }
      rx_buffer_.insert(rx_buffer_.end(), chunk.begin(), chunk.begin() + n);
      if (!DrainBufferedFrames()) {
        self->Shutdown(/*notify=*/true);
        return;
      }
    }
  }

  bool DrainBufferedFrames() {
    size_t offset = 0;
    const std::span<const uint8_t> buf(rx_buffer_);
    while (buf.size() - offset >= 4) {
      std::array<uint8_t, 4> hdr_bytes = {};
      std::copy_n(buf.data() + offset, 4, hdr_bytes.data());
      const uint32_t frame_len =
          fml::LittleEndianToArch(std::bit_cast<uint32_t>(hdr_bytes));
      if (frame_len > kMaxFrameSize) {
        return false;
      }
      if (buf.size() - offset - 4 < frame_len) {
        break;
      }
      if (!HandleFrame(buf.subspan(offset + 4, frame_len))) {
        return false;
      }
      offset += 4 + frame_len;
    }
    if (offset > 0) {
      rx_buffer_.erase(rx_buffer_.begin(),
                       rx_buffer_.begin() + static_cast<ptrdiff_t>(offset));
    }
    return true;
  }

  bool SendFrame(std::span<const uint8_t> payload) {
    if (socket_ == nullptr || !socket_->is_connected()) {
      return false;
    }
    const auto header = std::bit_cast<std::array<uint8_t, 4>>(
        fml::LittleEndianToArch(static_cast<uint32_t>(payload.size())));
    return socket_->Send(header.data(), header.size()) &&
           socket_->Send(payload.data(), payload.size());
  }

  bool InvokeMethod(uint32_t method_id,
                    std::span<const uint8_t> args,
                    bool drop_reply = false) {
    if (method_id == 0) {
      return false;
    }
    protozero::HeapBuffered<protozero::Message> frame;
    frame->AppendVarInt(kIpcFrameRequestIdField, next_req_id_++);
    auto* inv = frame->BeginNestedMessage<protozero::Message>(
        kIpcFrameInvokeMethodField);
    inv->AppendVarInt(/*service_id=*/1, service_id_);
    inv->AppendVarInt(/*method_id=*/2, method_id);
    inv->AppendBytes(/*args_proto=*/3, args.data(), args.size());
    if (drop_reply) {
      inv->AppendVarInt(/*drop_reply=*/4, 1u);
    }
    inv->Finalize();
    return SendFrame(frame.SerializeAsArray());
  }

  void RecordMethodId(uint32_t mid, std::string_view name) {
    if (name == "InitializeConnection") {
      m_init_ = mid;
    } else if (name == "RegisterDataSource") {
      m_reg_ds_ = mid;
    } else if (name == "CommitData") {
      m_commit_ = mid;
    } else if (name == "GetAsyncCommand") {
      m_async_cmd_ = mid;
    } else if (name == "RegisterTraceWriter") {
      m_reg_writer_ = mid;
    } else if (name == "UnregisterTraceWriter") {
      m_unreg_writer_ = mid;
    } else if (name == "NotifyDataSourceStopped") {
      m_notify_stopped_ = mid;
    }
  }

  bool HandleBindServiceReply(std::span<const uint8_t> reply) {
    protozero::ProtoDecoder br(reply.data(), reply.size());
    bool ok = false;
    for (auto f = br.ReadField(); f.valid(); f = br.ReadField()) {
      if (f.id() == 1) {
        ok = f.as_bool();
      } else if (f.id() == 2) {
        service_id_ = f.as_uint32();
      } else if (f.id() == 3) {
        protozero::ProtoDecoder mi(f.data(), f.size());
        uint32_t mid = 0;
        std::string_view mname;
        for (auto mf = mi.ReadField(); mf.valid(); mf = mi.ReadField()) {
          if (mf.id() == 1) {
            mid = mf.as_uint32();
          } else if (mf.id() == 2) {
            mname = std::string_view(reinterpret_cast<const char*>(mf.data()),
                                     mf.size());
          }
        }
        RecordMethodId(mid, mname);
      }
    }
    if (!ok || service_id_ == 0) {
      return false;
    }

    protozero::HeapBuffered<protozero::Message> init_req;
    init_req->AppendVarInt(/*shared_memory_page_size_hint_bytes=*/1, 4096u);
    init_req->AppendVarInt(/*shared_memory_size_hint_bytes=*/2, 256 * 1024u);
    init_req->AppendString(/*producer_name=*/3, "flutter.dart_heap");
    init_req->AppendVarInt(/*smb_scraping_mode=*/4, 2u /* DISABLED */);
    if (!InvokeMethod(m_init_, init_req.SerializeAsArray())) {
      return false;
    }

    async_cmd_req_id_ = next_req_id_;
    if (!InvokeMethod(m_async_cmd_, {})) {
      return false;
    }

    protozero::HeapBuffered<protozero::Message> ds_req;
    auto* dsd = ds_req->BeginNestedMessage<protozero::Message>(1);
    dsd->AppendBytes(/*name=*/1, hp::kHeapprofdDataSourceName.data(),
                     hp::kHeapprofdDataSourceName.size());
    dsd->AppendVarInt(/*will_notify_on_stop=*/2, 1u);
    dsd->Finalize();
    return InvokeMethod(m_reg_ds_, ds_req.SerializeAsArray());
  }

  bool HandleFrame(std::span<const uint8_t> frame_bytes) {
    protozero::ProtoDecoder frame(frame_bytes.data(), frame_bytes.size());
    uint64_t req_id = 0;
    protozero::ConstBytes bind_reply{};
    protozero::ConstBytes invoke_reply{};
    for (auto f = frame.ReadField(); f.valid(); f = frame.ReadField()) {
      if (f.id() == kIpcFrameRequestIdField) {
        req_id = f.as_uint64();
      } else if (f.id() == kIpcFrameBindServiceReplyField) {
        bind_reply = f.as_bytes();
      } else if (f.id() == kIpcFrameInvokeMethodReplyField) {
        invoke_reply = f.as_bytes();
      }
    }
    if (bind_reply.data != nullptr) {
      return HandleBindServiceReply({bind_reply.data, bind_reply.size});
    }
    if (invoke_reply.data != nullptr && req_id == async_cmd_req_id_) {
      protozero::ProtoDecoder ir(invoke_reply.data, invoke_reply.size);
      for (auto f = ir.ReadField(); f.valid(); f = ir.ReadField()) {
        if (f.id() == 3) {
          HandleAsyncCommand({f.data(), f.size()});
        }
      }
    }
    return true;
  }

  void OnSetupTracing(std::span<const uint8_t> data) {
    uint32_t page_kb = 4;
    protozero::ProtoDecoder st(data.data(), data.size());
    for (auto sf = st.ReadField(); sf.valid(); sf = st.ReadField()) {
      if (sf.id() == 1) {
        page_kb = sf.as_uint32();
      }
    }
    if (!pending_shm_fd_.is_valid() || shm_mapping_ != nullptr) {
      return;
    }
    auto mapping = std::make_unique<fml::FileMapping>(
        pending_shm_fd_, std::initializer_list<fml::FileMapping::Protection>{
                             fml::FileMapping::Protection::kRead,
                             fml::FileMapping::Protection::kWrite});
    pending_shm_fd_.reset();
    if (mapping->IsValid() && mapping->GetMutableMapping() != nullptr &&
        mapping->GetSize() > 0) {
      shm_abi_.Initialize(mapping->GetMutableMapping(), mapping->GetSize(),
                          page_kb * 1024u,
                          perfetto::SharedMemoryABI::ShmemMode::kDefault);
      shm_mapping_ = std::move(mapping);
    }
  }

  void OnStartDataSource(uint64_t id) {
    if (id == 0 || id != pending_id_ || active_id_ != 0) {
      return;
    }
    active_id_ = id;
    active_session_ = pending_session_;
    pending_id_ = 0;
    packet_index_ = 0;
    next_chunk_id_ = 0;
    active_writer_id_ = next_writer_id_;
    next_writer_id_ = (next_writer_id_ % kMaxWriterId) + 1;

    if (m_reg_writer_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendVarInt(/*trace_writer_id=*/1, active_writer_id_);
      req->AppendVarInt(/*target_buffer=*/2, active_session_.target_buffer);
      InvokeMethod(m_reg_writer_, req.SerializeAsArray(), /*drop_reply=*/true);
    }

    aggregator_.Clear();
    hp::ElfModuleScanner::RegisterMissingDartEhFrames();
    sampling_interval_ = active_session_.sampling_interval;
    DartHeapProfiler::StartSampling(sampling_interval_);
  }

  void HandleAsyncCommand(std::span<const uint8_t> cmd_bytes) {
    protozero::ProtoDecoder cmd(cmd_bytes.data(), cmd_bytes.size());
    for (auto f = cmd.ReadField(); f.valid(); f = cmd.ReadField()) {
      switch (f.id()) {
        case 3:  // setup_tracing
          OnSetupTracing({f.data(), f.size()});
          break;
        case 6: {  // setup_data_source
          uint64_t id = 0;
          protozero::ConstBytes cfg{};
          protozero::ProtoDecoder sd(f.data(), f.size());
          for (auto sf = sd.ReadField(); sf.valid(); sf = sd.ReadField()) {
            if (sf.id() == 1) {
              id = sf.as_uint64();
            } else if (sf.id() == 2) {
              cfg = sf.as_bytes();
            }
          }
          hp::ParsedHeapprofdSession parsed =
              hp::ParseDataSourceConfig({cfg.data, cfg.size});
          if (parsed.matched && active_id_ == 0) {
            pending_id_ = id;
            pending_session_ = parsed;
          }
          break;
        }
        case 1: {  // start_data_source
          uint64_t id = 0;
          protozero::ProtoDecoder sd(f.data(), f.size());
          for (auto sf = sd.ReadField(); sf.valid(); sf = sd.ReadField()) {
            if (sf.id() == 1) {
              id = sf.as_uint64();
            }
          }
          OnStartDataSource(id);
          break;
        }
        case 5: {  // flush
          uint64_t flush_id = 0;
          protozero::ProtoDecoder fl(f.data(), f.size());
          for (auto ff = fl.ReadField(); ff.valid(); ff = fl.ReadField()) {
            if (ff.id() == 2) {
              flush_id = ff.as_uint64();
            }
          }
          if (flush_id != 0) {
            SendCommit({}, flush_id);
          }
          break;
        }
        case 2: {  // stop_data_source
          uint64_t id = 0;
          protozero::ProtoDecoder sp(f.data(), f.size());
          for (auto sf = sp.ReadField(); sf.valid(); sf = sp.ReadField()) {
            if (sf.id() == 1) {
              id = sf.as_uint64();
            }
          }
          if (id != 0 && id == active_id_) {
            StopSession(/*notify_service=*/true);
          } else if (id != 0 && m_notify_stopped_ != 0) {
            protozero::HeapBuffered<protozero::Message> req;
            req->AppendVarInt(1, id);
            InvokeMethod(m_notify_stopped_, req.SerializeAsArray(),
                         /*drop_reply=*/true);
          }
          break;
        }
        default:
          break;
      }
    }
  }

  perfetto::SharedMemoryABI::Chunk AcquireChunk(uint16_t packet_count,
                                                uint8_t flags) {
    if (shm_mapping_ == nullptr) {
      return perfetto::SharedMemoryABI::Chunk();
    }
    for (int attempt = 0; attempt < 200; ++attempt) {
      for (size_t p = 0; p < shm_abi_.num_pages(); ++p) {
        if (shm_abi_.is_page_free(p)) {
          shm_abi_.TryPartitionPage(p, perfetto::SharedMemoryABI::kPageDiv1);
        }
        if ((shm_abi_.GetFreeChunks(p) & 1u) != 0) {
          perfetto::SharedMemoryABI::ChunkHeader hdr{};
          hdr.chunk_id.store(next_chunk_id_++, std::memory_order_relaxed);
          hdr.writer_id.store(active_writer_id_, std::memory_order_relaxed);
          hdr.packets.store({packet_count, flags}, std::memory_order_relaxed);
          auto chunk = shm_abi_.TryAcquireChunkForWriting(p, 0, &hdr);
          if (chunk.is_valid()) {
            return chunk;
          }
        }
      }
      perfetto::base::SleepMicroseconds(500);
    }
    return perfetto::SharedMemoryABI::Chunk();
  }

  void WriteSerializedPacketToShm(std::span<const uint8_t> packet_bytes) {
    if (shm_mapping_ == nullptr || packet_bytes.empty()) {
      return;
    }
    const size_t max_payload = shm_abi_.page_size() -
                               sizeof(perfetto::SharedMemoryABI::PageHeader) -
                               sizeof(perfetto::SharedMemoryABI::ChunkHeader) -
                               perfetto::SharedMemoryABI::kPacketHeaderSize;

    size_t offset = 0;
    bool first = true;
    std::array<MovedChunk, 16> moved = {};
    size_t moved_count = 0;

    while (offset < packet_bytes.size()) {
      const size_t frag_len =
          std::min(max_payload, packet_bytes.size() - offset);
      const bool last = (offset + frag_len == packet_bytes.size());
      uint8_t flags = 0;
      if (!first) {
        flags |= perfetto::SharedMemoryABI::ChunkHeader::
            kFirstPacketContinuesFromPrevChunk;
      }
      if (!last) {
        flags |= perfetto::SharedMemoryABI::ChunkHeader::
            kLastPacketContinuesOnNextChunk;
      }

      auto chunk = AcquireChunk(/*packet_count=*/1, flags);
      if (!chunk.is_valid()) {
        break;
      }
      uint8_t* dst = chunk.payload_begin();
      protozero::proto_utils::WriteRedundantVarInt(
          static_cast<uint32_t>(frag_len), dst);
      std::copy_n(packet_bytes.data() + offset, frag_len,
                  dst + perfetto::SharedMemoryABI::kPacketHeaderSize);
      auto [page_idx, chunk_idx] = shm_abi_.GetPageAndChunkIndex(chunk);
      shm_abi_.ReleaseChunkAsComplete(std::move(chunk));

      moved[moved_count++] = {
          .page = static_cast<uint32_t>(page_idx),
          .chunk = static_cast<uint32_t>(chunk_idx),
      };
      if (moved_count == moved.size()) {
        SendCommit(moved, /*flush_req_id=*/0);
        moved_count = 0;
      }
      offset += frag_len;
      first = false;
    }
    if (moved_count > 0) {
      SendCommit(std::span<const MovedChunk>(moved.data(), moved_count),
                 /*flush_req_id=*/0);
    }
  }

  void SendCommit(std::span<const MovedChunk> chunks, uint64_t flush_req_id) {
    protozero::HeapBuffered<protozero::Message> req;
    for (const MovedChunk& c : chunks) {
      auto* msg =
          req->BeginNestedMessage<protozero::Message>(/*chunks_to_move=*/1);
      msg->AppendVarInt(/*page=*/1, c.page);
      msg->AppendVarInt(/*chunk=*/2, c.chunk);
      msg->AppendVarInt(/*target_buffer=*/3, active_session_.target_buffer);
      msg->Finalize();
    }
    if (flush_req_id != 0) {
      req->AppendVarInt(/*flush_request_id=*/3, flush_req_id);
    }
    InvokeMethod(m_commit_, req.SerializeAsArray(),
                 /*drop_reply=*/flush_req_id == 0);
  }

  void EmitDump() {
    PERFETTO_DCHECK(task_runner_->RunsTasksOnCurrentThread());
    hp::WriteHeapProfilePackets(
        aggregator_, sampling_interval_, &packet_index_,
        [this](auto&& fill_fn) {
          protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket> pkt;
          fill_fn(pkt.get());
          WriteSerializedPacketToShm(pkt.SerializeAsArray());
        });
  }

  void StopSession(bool notify_service) {
    const uint64_t stopped_id = active_id_;
    const uint16_t stopped_writer = active_writer_id_;
    DartHeapProfiler::StopSampling();
    if (notify_service && stopped_id != 0) {
      EmitDump();
    }
    aggregator_.Clear();
    active_id_ = 0;
    active_writer_id_ = 0;
    if (notify_service && stopped_id != 0) {
      if (stopped_writer != 0 && m_unreg_writer_ != 0) {
        protozero::HeapBuffered<protozero::Message> req;
        req->AppendVarInt(/*trace_writer_id=*/1, stopped_writer);
        InvokeMethod(m_unreg_writer_, req.SerializeAsArray(),
                     /*drop_reply=*/true);
      }
      if (m_notify_stopped_ != 0) {
        protozero::HeapBuffered<protozero::Message> req;
        req->AppendVarInt(1, stopped_id);
        InvokeMethod(m_notify_stopped_, req.SerializeAsArray(),
                     /*drop_reply=*/true);
      }
    }
  }

  std::optional<perfetto::base::ThreadTaskRunner> task_runner_;
  intptr_t sampling_interval_ = hp::kDefaultSamplingInterval;

  std::unique_ptr<perfetto::base::UnixSocket> socket_;
  std::vector<uint8_t> rx_buffer_;
  fml::UniqueFD pending_shm_fd_;
  std::unique_ptr<fml::FileMapping> shm_mapping_;
  perfetto::SharedMemoryABI shm_abi_;
  uint32_t next_chunk_id_ = 0;
  uint16_t next_writer_id_ = 1;
  uint16_t active_writer_id_ = 0;
  uint32_t backoff_ms_ = kInitialBackoffMs;

  uint64_t next_req_id_ = 1;
  uint64_t async_cmd_req_id_ = 0;
  uint32_t service_id_ = 0;
  uint32_t m_init_ = 0;
  uint32_t m_reg_ds_ = 0;
  uint32_t m_commit_ = 0;
  uint32_t m_async_cmd_ = 0;
  uint32_t m_reg_writer_ = 0;
  uint32_t m_unreg_writer_ = 0;
  uint32_t m_notify_stopped_ = 0;

  uint64_t pending_id_ = 0;
  hp::ParsedHeapprofdSession pending_session_;
  uint64_t active_id_ = 0;
  hp::ParsedHeapprofdSession active_session_;
  uint64_t packet_index_ = 0;
  hp::HeapSampleAggregator aggregator_;
};

}  // namespace

void InitializeAndroidDartHeapProfiler(int api_level) {
  if (api_level < kMinBacktraceApiLevel) {
    return;
  }
  static std::once_flag init_once;
  std::call_once(init_once, []() {
    auto producer = std::make_unique<TracedHeapProducer>();
    TracedHeapProducer* raw = producer.get();
    DartHeapProfiler::SetDelegate(std::move(producer));
    raw->Start();
  });
}

}  // namespace flutter

#else  // defined(FLUTTER_ENABLE_HEAPPROFD)

namespace flutter {

void InitializeAndroidDartHeapProfiler(int /*api_level*/) {}

}  // namespace flutter

#endif  // defined(FLUTTER_ENABLE_HEAPPROFD)
