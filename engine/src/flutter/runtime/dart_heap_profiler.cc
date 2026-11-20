// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_heap_profiler.h"

#include "flutter/fml/build_config.h"

#if defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)

#include <android/api-level.h>
#include <android/looper.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <span>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/memory/task_runner_checker.h"
#include "flutter/fml/platform/posix/unix_domain_socket_posix.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/runtime/dart_heap_profiler_internal.h"
#include "perfetto/ext/tracing/core/shared_memory_abi.h"
#include "perfetto/protozero/proto_utils.h"

namespace flutter {
namespace {

namespace hp = heap_profile_internal;

// Bionic's libc.so exports _Unwind_Backtrace starting in Android 11 (API 30).
constexpr int kMinUnwindApiLevel = 30;
constexpr std::string_view kTracedProducerSocket =
    "/dev/socket/traced_producer";
constexpr uint16_t kWriterId = 1;
constexpr size_t kMaxFrameSize = 16 * 1024 * 1024;
constexpr int64_t kInitialBackoffMs = 1000;
constexpr int64_t kMaxBackoffMs = 30000;

// Perfetto IPCFrame wire-protocol field IDs.
constexpr uint32_t kIpcFrameRequestIdField = 2;
constexpr uint32_t kIpcFrameBindServiceField = 3;
constexpr uint32_t kIpcFrameBindServiceReplyField = 4;
constexpr uint32_t kIpcFrameInvokeMethodField = 5;
constexpr uint32_t kIpcFrameInvokeMethodReplyField = 6;

constexpr std::array<uint8_t, 4> EncodeLittleEndianU32(uint32_t value) {
  return {
      static_cast<uint8_t>(value & 0xFFu),
      static_cast<uint8_t>((value >> 8) & 0xFFu),
      static_cast<uint8_t>((value >> 16) & 0xFFu),
      static_cast<uint8_t>((value >> 24) & 0xFFu),
  };
}

constexpr uint32_t DecodeLittleEndianU32(std::span<const uint8_t, 4> bytes) {
  return static_cast<uint32_t>(bytes[0]) |
         (static_cast<uint32_t>(bytes[1]) << 8) |
         (static_cast<uint32_t>(bytes[2]) << 16) |
         (static_cast<uint32_t>(bytes[3]) << 24);
}

/// RAII registration of a file descriptor on the current thread's `ALooper`.
class ScopedLooperFdWatch {
 public:
  using Callback = std::function<void(int events)>;

  ScopedLooperFdWatch(int fd, Callback callback)
      : looper_(::ALooper_forThread()),
        fd_(fd),
        callback_(std::move(callback)) {
    FML_DCHECK(looper_ != nullptr);
    constexpr int kEvents =
        ALOOPER_EVENT_INPUT | ALOOPER_EVENT_ERROR | ALOOPER_EVENT_HANGUP;
    const int added =
        ::ALooper_addFd(looper_, fd_, ALOOPER_POLL_CALLBACK, kEvents,
                        &ScopedLooperFdWatch::OnLooperEvent, this);
    registered_ = (added == 1);
  }

  ~ScopedLooperFdWatch() {
    if (registered_ && looper_ != nullptr) {
      ::ALooper_removeFd(looper_, fd_);
    }
  }

 private:
  static int OnLooperEvent(int /*fd*/, int events, void* data) {
    auto* self = static_cast<ScopedLooperFdWatch*>(data);
    self->callback_(events);
    return 1;
  }

  ALooper* looper_ = nullptr;
  int fd_ = -1;
  bool registered_ = false;
  Callback callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedLooperFdWatch);
};

/// Event-driven Perfetto `ProducerPort` client running on a background
/// `fml::Thread` (`ALooper`) that registers `"android.heapprofd"` and streams
/// `ProfilePacket`s via `fml::FileMapping` and `SharedMemoryABI`.
class TracedHeapProducer {
 public:
  static TracedHeapProducer& Instance() {
    static auto* instance = new TracedHeapProducer();
    return *instance;
  }

  void EnsureStarted() {
    std::call_once(start_once_, [this]() {
      thread_ = std::make_unique<fml::Thread>(
          fml::Thread::SetCurrentThreadName,
          fml::Thread::ThreadConfig("io.flutter.heapprofd",
                                    fml::Thread::ThreadPriority::kBackground));
      task_runner_ = thread_->GetTaskRunner();
      task_runner_->PostTask([this]() { ConnectOnProducerThread(); });
    });
  }

  void OnVmInitialized() {
    std::scoped_lock lock(vm_mutex_);
    vm_alive_ = true;
    Dart_RegisterHeapSamplingCallback(&OnDartSampleCreated,
                                      &OnDartSampleDestroyed);
    if (sampling_active_.load(std::memory_order_acquire)) {
      Dart_SetHeapSamplingPeriod(sampling_interval_);
      Dart_EnableHeapSampling();
    }
  }

  void OnVmCleanup() {
    std::scoped_lock lock(vm_mutex_);
    if (vm_alive_ && sampling_active_.load(std::memory_order_acquire)) {
      Dart_DisableHeapSampling();
    }
    vm_alive_ = false;
  }

 private:
  struct MovedChunk {
    uint32_t page = 0;
    uint32_t chunk = 0;
  };

  static void* OnDartSampleCreated(Dart_Isolate /*isolate*/,
                                   Dart_IsolateGroup group,
                                   const char* cls_name,
                                   intptr_t size) {
    TracedHeapProducer& self = Instance();
    if (!self.sampling_active_.load(std::memory_order_acquire)) {
      return nullptr;
    }
    return self.aggregator_.RecordCurrentThreadAlloc(group, cls_name, size);
  }

  static void OnDartSampleDestroyed(void* data) {
    hp::HeapSampleAggregator::RecordFree(data);
  }

  void ConnectOnProducerThread() {
    FML_DCHECK_TASK_RUNNER_IS_CURRENT(task_runner_);
    auto connected = fml::UnixDomainSocket::Connect(kTracedProducerSocket);
    if (!connected.has_value()) {
      ScheduleReconnect();
      return;
    }
    socket_ = std::move(*connected);
    rx_buffer_.clear();
    rx_buffer_.reserve(8192);

    protozero::HeapBuffered<protozero::Message> frame;
    frame->AppendVarInt(kIpcFrameRequestIdField, next_req_id_++);
    auto* bind = frame->BeginNestedMessage<protozero::Message>(
        kIpcFrameBindServiceField);
    bind->AppendString(/*service_name=*/1, "ProducerPort");
    bind->Finalize();
    if (!SendFrame(frame.SerializeAsArray())) {
      HandleDisconnect();
      return;
    }

    backoff_ms_ = kInitialBackoffMs;
    const int fd = socket_.fd().get();
    fd_watch_ = std::make_unique<ScopedLooperFdWatch>(
        fd, [this](int events) { OnSocketEvents(events); });
  }

  void ScheduleReconnect() {
    FML_DCHECK_TASK_RUNNER_IS_CURRENT(task_runner_);
    const auto delay = fml::TimeDelta::FromMilliseconds(backoff_ms_);
    backoff_ms_ = std::min(backoff_ms_ * 2, kMaxBackoffMs);
    task_runner_->PostDelayedTask([this]() { ConnectOnProducerThread(); },
                                  delay);
  }

  void HandleDisconnect() {
    FML_DCHECK_TASK_RUNNER_IS_CURRENT(task_runner_);
    // Post teardown if invoked from inside ScopedLooperFdWatch's callback so
    // the watch never destroys itself on its own call stack.
    const uint64_t conn_gen = ++connection_generation_;
    task_runner_->PostTask([this, conn_gen]() {
      if (conn_gen != connection_generation_) {
        return;
      }
      StopSession(/*notify_service=*/false);
      fd_watch_.reset();
      socket_.Reset();
      pending_shm_fd_.reset();
      shm_mapping_.reset();
      rx_buffer_.clear();
      service_id_ = 0;
      m_init_ = m_reg_ds_ = m_commit_ = m_async_cmd_ = m_reg_writer_ =
          m_notify_stopped_ = 0;
      pending_id_ = 0;
      ScheduleReconnect();
    });
  }

  void OnSocketEvents(int events) {
    FML_DCHECK_TASK_RUNNER_IS_CURRENT(task_runner_);
    if (!socket_.is_valid()) {
      return;
    }
    if ((events & ALOOPER_EVENT_INPUT) != 0) {
      std::array<uint8_t, 4096> chunk;
      fml::UniqueFD received_fd;
      const ssize_t n = socket_.Receive(chunk, &received_fd);
      if (n <= 0) {
        HandleDisconnect();
        return;
      }
      if (received_fd.is_valid()) {
        pending_shm_fd_ = std::move(received_fd);
      }
      rx_buffer_.insert(rx_buffer_.end(), chunk.begin(),
                        chunk.begin() + static_cast<size_t>(n));
      if (!DrainBufferedFrames()) {
        HandleDisconnect();
        return;
      }
    }
    if ((events & (ALOOPER_EVENT_ERROR | ALOOPER_EVENT_HANGUP)) != 0) {
      HandleDisconnect();
    }
  }

  bool DrainBufferedFrames() {
    size_t offset = 0;
    const std::span<const uint8_t> buf(rx_buffer_);
    while (buf.size() - offset >= 4) {
      const uint32_t frame_len =
          DecodeLittleEndianU32(buf.subspan(offset, 4).first<4>());
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
    const auto header =
        EncodeLittleEndianU32(static_cast<uint32_t>(payload.size()));
    return socket_.Send(header) && socket_.Send(payload);
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
    dsd->AppendVarInt(/*handles_incremental_state_clear=*/4, 1u);
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

  void ScheduleContinuousDump(uint64_t session_gen, uint32_t delay_ms) {
    task_runner_->PostDelayedTask(
        [this, session_gen]() {
          if (active_id_ == 0 || session_gen != session_generation_) {
            return;
          }
          EmitDump(/*flush_req_id=*/0);
          if (active_session_.dump_interval_ms > 0) {
            ScheduleContinuousDump(session_gen,
                                   active_session_.dump_interval_ms);
          }
        },
        fml::TimeDelta::FromMilliseconds(delay_ms));
  }

  void OnStartDataSource(uint64_t id) {
    if (id == 0 || id != pending_id_ || active_id_ != 0) {
      return;
    }
    active_id_ = id;
    active_session_ = pending_session_;
    pending_id_ = 0;
    packet_index_ = 0;
    prev_dump_mono_ns_ = hp::GetMonotonicCoarseNs();
    const uint64_t session_gen = ++session_generation_;

    if (m_reg_writer_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendVarInt(/*trace_writer_id=*/1, kWriterId);
      req->AppendVarInt(/*target_buffer=*/2, active_session_.target_buffer);
      InvokeMethod(m_reg_writer_, req.SerializeAsArray(), /*drop_reply=*/true);
    }

    aggregator_.Clear();
    {
      std::scoped_lock lock(vm_mutex_);
      sampling_interval_ = active_session_.sampling_interval;
      sampling_active_.store(true, std::memory_order_release);
      if (vm_alive_) {
        Dart_SetHeapSamplingPeriod(sampling_interval_);
        Dart_EnableHeapSampling();
      }
    }

    if (active_session_.dump_interval_ms > 0) {
      const uint32_t first_ms = active_session_.dump_phase_ms > 0
                                    ? active_session_.dump_phase_ms
                                    : active_session_.dump_interval_ms;
      ScheduleContinuousDump(session_gen, first_ms);
    }
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
          bool match = false;
          protozero::ProtoDecoder fl(f.data(), f.size());
          for (auto ff = fl.ReadField(); ff.valid(); ff = fl.ReadField()) {
            if (ff.id() == 1 && ff.as_uint64() == active_id_ &&
                active_id_ != 0) {
              match = true;
            } else if (ff.id() == 2) {
              flush_id = ff.as_uint64();
            }
          }
          if (match) {
            EmitDump(flush_id);
          } else {
            SendCommit({}, flush_id);
          }
          break;
        }
        case 7:  // clear_incremental_state
          aggregator_.MarkAllDirty();
          break;
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
          hdr.writer_id.store(kWriterId, std::memory_order_relaxed);
          hdr.packets.store({packet_count, flags}, std::memory_order_relaxed);
          auto chunk = shm_abi_.TryAcquireChunkForWriting(p, 0, &hdr);
          if (chunk.is_valid()) {
            return chunk;
          }
        }
      }
      std::this_thread::sleep_for(std::chrono::microseconds(500));
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

  void EmitDump(uint64_t flush_req_id) {
    FML_DCHECK_TASK_RUNNER_IS_CURRENT(task_runner_);
    hp::WriteHeapProfilePackets(
        aggregator_, sampling_interval_, &packet_index_, &prev_dump_mono_ns_,
        [this](auto&& fill_fn) {
          protozero::HeapBuffered<protozero::Message> pkt;
          pkt->AppendVarInt(hp::proto_fields::kTracePacketTrustedSeqId,
                            kWriterId);
          fill_fn(pkt.get());
          WriteSerializedPacketToShm(pkt.SerializeAsArray());
        });
    if (flush_req_id != 0) {
      SendCommit({}, flush_req_id);
    }
  }

  void StopSession(bool notify_service) {
    const uint64_t stopped_id = active_id_;
    ++session_generation_;
    {
      std::scoped_lock lock(vm_mutex_);
      sampling_active_.store(false, std::memory_order_release);
      if (vm_alive_) {
        Dart_DisableHeapSampling();
      }
    }
    if (stopped_id != 0) {
      EmitDump(/*flush_req_id=*/0);
    }
    aggregator_.Clear();
    active_id_ = 0;
    if (notify_service && stopped_id != 0 && m_notify_stopped_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendVarInt(1, stopped_id);
      InvokeMethod(m_notify_stopped_, req.SerializeAsArray(),
                   /*drop_reply=*/true);
    }
  }

  std::once_flag start_once_;
  std::unique_ptr<fml::Thread> thread_;
  fml::RefPtr<fml::TaskRunner> task_runner_;

  std::mutex vm_mutex_;
  bool vm_alive_ = false;
  std::atomic<bool> sampling_active_{false};
  intptr_t sampling_interval_ = hp::kDefaultSamplingInterval;

  fml::UnixDomainSocket socket_;
  std::unique_ptr<ScopedLooperFdWatch> fd_watch_;
  std::vector<uint8_t> rx_buffer_;
  fml::UniqueFD pending_shm_fd_;
  std::unique_ptr<fml::FileMapping> shm_mapping_;
  perfetto::SharedMemoryABI shm_abi_;
  uint32_t next_chunk_id_ = 1;
  int64_t backoff_ms_ = kInitialBackoffMs;
  uint64_t connection_generation_ = 0;
  uint64_t session_generation_ = 0;

  uint64_t next_req_id_ = 1;
  uint64_t async_cmd_req_id_ = 0;
  uint32_t service_id_ = 0;
  uint32_t m_init_ = 0;
  uint32_t m_reg_ds_ = 0;
  uint32_t m_commit_ = 0;
  uint32_t m_async_cmd_ = 0;
  uint32_t m_reg_writer_ = 0;
  uint32_t m_notify_stopped_ = 0;

  uint64_t pending_id_ = 0;
  hp::ParsedHeapprofdSession pending_session_;
  uint64_t active_id_ = 0;
  hp::ParsedHeapprofdSession active_session_;
  uint64_t prev_dump_mono_ns_ = 0;
  uint64_t packet_index_ = 0;
  hp::HeapSampleAggregator aggregator_;
};

}  // namespace

void DartHeapProfiler::OnDartVMInitialized() {
  if (::android_get_device_api_level() < kMinUnwindApiLevel) {
    return;
  }
  TracedHeapProducer& producer = TracedHeapProducer::Instance();
  producer.OnVmInitialized();
  producer.EnsureStarted();
}

void DartHeapProfiler::OnDartVMCleanup() {
  if (::android_get_device_api_level() < kMinUnwindApiLevel) {
    return;
  }
  TracedHeapProducer::Instance().OnVmCleanup();
}

}  // namespace flutter

#else  // defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)

namespace flutter {

void DartHeapProfiler::OnDartVMInitialized() {}

void DartHeapProfiler::OnDartVMCleanup() {}

}  // namespace flutter

#endif  // defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)
