// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_dart_heap_profiler.h"

#if defined(FLUTTER_ENABLE_HEAPPROFD)

#include <algorithm>
#include <array>
#include <atomic>
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
#include "perfetto/tracing/core/flush_flags.h"

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

/// Android `DartHeapProfilerDelegate` and Perfetto `ProducerPort` client
/// running on a `perfetto::base::ThreadTaskRunner` that registers
/// `"android.heapprofd"`, `"android.java_hprof"`, and
/// `"android.java_hprof.oom"` for `ProfilingManager` and streams
/// `ProfilePacket` and `HeapGraph` batches via `SharedMemoryABI`.
class TracedHeapProducer final
    : public DartHeapProfilerDelegate,
      public perfetto::base::UnixSocket::EventListener {
 public:
  TracedHeapProducer() { aggregator_.EndSession(); }

  void Start() {
    task_runner_.emplace(
        perfetto::base::ThreadTaskRunner::CreateAndStart("io.flutter.heap"));
    task_runner_->PostTask([this]() { ConnectOnProducerThread(); });
  }

  // DartHeapProfilerDelegate:
  void OnDartVMInitialized() override {
    vm_shutting_down_.store(false, std::memory_order_release);
    hp::ElfModuleScanner::RegisterMissingDartEhFrames();
  }

  void OnDartVMCleanup() override {
    vm_shutting_down_.store(true, std::memory_order_release);
  }

  void OnLowMemory() override {
    if (task_runner_.has_value()) {
      task_runner_->PostTask(
          [this]() { EmitSessionDump(FindStartedHeapprofd()); });
    }
  }

  void OnUnhandledOutOfMemory() override {
    if (task_runner_.has_value()) {
      task_runner_->PostTask([this]() { OnUnhandledOutOfMemoryOnProducer(); });
    }
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

  struct ActiveSession {
    uint64_t id = 0;
    hp::ParsedSessionConfig cfg;
    uint16_t writer_id = 0;
    uint64_t packet_index = 0;
    uint64_t dump_gen = 0;
    bool started = false;
    bool first_packet_on_sequence = true;
  };

  ActiveSession* FindSession(uint64_t id) {
    for (ActiveSession& s : sessions_) {
      if (s.id == id) {
        return &s;
      }
    }
    return nullptr;
  }

  ActiveSession* FindStartedHeapprofd() {
    for (ActiveSession& s : sessions_) {
      if (s.started && s.cfg.kind == hp::SessionKind::kHeapprofd) {
        return &s;
      }
    }
    return nullptr;
  }

  uint16_t AllocateWriterId() {
    const uint16_t id = next_writer_id_;
    next_writer_id_ = (next_writer_id_ % kMaxWriterId) + 1;
    return id;
  }

  void InvokeSingleIdMethod(uint32_t method_id, uint64_t id) {
    if (id == 0 || method_id == 0) {
      return;
    }
    protozero::HeapBuffered<protozero::Message> req;
    req->AppendVarInt(1, id);
    InvokeMethod(method_id, req.SerializeAsArray(), /*drop_reply=*/true);
  }

  void RegisterWriter(uint16_t writer_id, uint32_t target_buffer) {
    if (writer_id == 0 || m_reg_writer_ == 0) {
      return;
    }
    protozero::HeapBuffered<protozero::Message> req;
    req->AppendVarInt(/*trace_writer_id=*/1, writer_id);
    req->AppendVarInt(/*target_buffer=*/2, target_buffer);
    InvokeMethod(m_reg_writer_, req.SerializeAsArray(), /*drop_reply=*/true);
  }

  bool RegisterNamedDataSource(std::string_view name) {
    protozero::HeapBuffered<protozero::Message> req;
    auto* dsd = req->BeginNestedMessage<protozero::Message>(1);
    dsd->AppendBytes(/*name=*/1, name.data(), name.size());
    dsd->AppendVarInt(/*will_notify_on_stop=*/2, 1u);
    return InvokeMethod(m_reg_ds_, req.SerializeAsArray());
  }

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
    frame->AppendVarInt(/*request_id=*/2, next_req_id_++);
    frame->BeginNestedMessage<protozero::Message>(/*msg_bind_service=*/3)
        ->AppendString(/*service_name=*/1, "ProducerPort");
    SendFrame(frame.SerializeAsArray());
  }

  void OnDisconnect(perfetto::base::UnixSocket* /*self*/) override {
    if (FindStartedHeapprofd() != nullptr) {
      if (!vm_shutting_down_.load(std::memory_order_acquire)) {
        DartHeapProfiler::StartSampling(hp::kDefaultSamplingInterval);
      }
      aggregator_.EndSession();
    }
    sessions_.clear();
    socket_.reset();
    pending_shm_fd_.reset();
    shm_mapping_.reset();
    rx_buffer_.clear();
    service_id_ = 0;
    m_init_ = m_reg_ds_ = m_commit_ = m_async_cmd_ = m_reg_writer_ =
        m_unreg_writer_ = m_notify_stopped_ = m_activate_triggers_ = 0;
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
    frame->AppendVarInt(/*request_id=*/2, next_req_id_++);
    auto* inv =
        frame->BeginNestedMessage<protozero::Message>(/*msg_invoke_method=*/5);
    inv->AppendVarInt(/*service_id=*/1, service_id_);
    inv->AppendVarInt(/*method_id=*/2, method_id);
    inv->AppendBytes(/*args_proto=*/3, args.data(), args.size());
    if (drop_reply) {
      inv->AppendVarInt(/*drop_reply=*/4, 1u);
    }
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
    } else if (name == "ActivateTriggers") {
      m_activate_triggers_ = mid;
    }
  }

  bool HandleBindServiceReply(std::span<const uint8_t> reply) {
    // BindServiceReply: success=1, service_id=2, methods=3.
    protozero::TypedProtoDecoder<3, true> br(reply.data(), reply.size());
    service_id_ = br.at<2>().as_uint32();
    if (!br.at<1>().as_bool() || service_id_ == 0) {
      return false;
    }
    for (auto it = br.GetRepeated<protozero::ConstBytes>(3); it; ++it) {
      // MethodInfo: id=1, name=2.
      const protozero::ConstBytes raw = *it;
      protozero::TypedProtoDecoder<2, false> mi(raw.data, raw.size);
      RecordMethodId(mi.at<1>().as_uint32(), hp::View(mi.at<2>().as_string()));
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
    return InvokeMethod(m_async_cmd_, {}) &&
           RegisterNamedDataSource(hp::kHeapprofdDataSourceName) &&
           RegisterNamedDataSource(hp::kJavaHprofDataSourceName) &&
           RegisterNamedDataSource(hp::kJavaHprofOomDataSourceName);
  }

  bool HandleFrame(std::span<const uint8_t> frame_bytes) {
    // IPCFrame: request_id=2, bind_service_reply=4, invoke_method_reply=6.
    protozero::TypedProtoDecoder<8, false> frame(frame_bytes.data(),
                                                 frame_bytes.size());
    if (const auto br = frame.at<4>().as_bytes(); br.data != nullptr) {
      return HandleBindServiceReply({br.data, br.size});
    }
    if (const auto ir_raw = frame.at<6>().as_bytes();
        ir_raw.data != nullptr &&
        frame.at<2>().as_uint64() == async_cmd_req_id_) {
      protozero::TypedProtoDecoder<3, false> ir(ir_raw.data, ir_raw.size);
      if (const auto cmd = ir.at<3>().as_bytes(); cmd.data != nullptr) {
        HandleAsyncCommand({cmd.data, cmd.size});
      }
    }
    return true;
  }

  void OnSetupTracing(std::span<const uint8_t> data) {
    protozero::ProtoDecoder st(data.data(), data.size());
    const auto page_f = st.FindField(/*shared_buffer_page_size_kb=*/1);
    const uint32_t page_kb = page_f.valid() ? page_f.as_uint32() : 4u;
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

  void OnSetupDataSource(uint64_t id, std::span<const uint8_t> cfg_bytes) {
    if (id == 0 || FindSession(id) != nullptr) {
      return;
    }
    const hp::ParsedSessionConfig parsed = hp::ParseDataSourceConfig(cfg_bytes);
    if (!parsed.matched || (parsed.kind == hp::SessionKind::kHeapprofd &&
                            FindStartedHeapprofd() != nullptr)) {
      return;
    }
    sessions_.push_back(ActiveSession{.id = id, .cfg = parsed});
  }

  void ScheduleContinuousDump(uint64_t session_id,
                              uint64_t gen,
                              uint32_t delay_ms) {
    task_runner_->PostDelayedTask(
        [this, session_id, gen]() {
          ActiveSession* s = FindSession(session_id);
          if (s == nullptr || !s->started || s->dump_gen != gen) {
            return;
          }
          EmitSessionDump(s);
          if (s->cfg.dump_interval_ms > 0) {
            ScheduleContinuousDump(session_id, gen, s->cfg.dump_interval_ms);
          }
        },
        delay_ms);
  }

  void OnStartDataSource(uint64_t id) {
    ActiveSession* s = FindSession(id);
    if (s == nullptr || s->started ||
        (s->cfg.kind == hp::SessionKind::kHeapprofd &&
         FindStartedHeapprofd() != nullptr)) {
      return;
    }
    s->started = true;
    s->packet_index = 0;
    s->first_packet_on_sequence = true;
    ++s->dump_gen;
    s->writer_id = AllocateWriterId();
    RegisterWriter(s->writer_id, s->cfg.target_buffer);

    if (s->cfg.kind == hp::SessionKind::kHeapprofd) {
      aggregator_.BeginSession();
      hp::ElfModuleScanner::RegisterMissingDartEhFrames();
      if (!s->cfg.no_startup &&
          !vm_shutting_down_.load(std::memory_order_acquire)) {
        hp::HeapSampleAggregator::SeededBatch batch{.aggregator = &aggregator_};
        DartHeapProfiler::ReportSurvivingAllocations(
            &hp::HeapSampleAggregator::SeedSurvivingSampleCallback, &batch,
            /*force_gc=*/false);
        aggregator_.FinalizeSeededBatch(batch);
      }
      DartHeapProfiler::StartSampling(s->cfg.sampling_interval);
    } else {
      EmitSessionDump(s);
    }
    if (s->cfg.dump_interval_ms > 0) {
      ScheduleContinuousDump(s->id, s->dump_gen, s->cfg.dump_phase_ms);
    }
  }

  void OnFlushCommand(std::span<const uint8_t> flush_bytes) {
    // Flush: data_source_ids=1, request_id=2, flags=3.
    protozero::TypedProtoDecoder<3, true> fl(flush_bytes.data(),
                                             flush_bytes.size());
    ActiveSession* hp_session = FindStartedHeapprofd();
    bool has_ds_filter = false;
    bool matches_heapprofd = false;
    for (auto it = fl.GetRepeated<uint64_t>(1); it; ++it) {
      has_ds_filter = true;
      matches_heapprofd |= (hp_session != nullptr && *it == hp_session->id);
    }
    if (hp_session != nullptr && (!has_ds_filter || matches_heapprofd) &&
        perfetto::FlushFlags(fl.at<3>().as_uint64()).reason() !=
            perfetto::FlushFlags::Reason::kTraceStop) {
      EmitSessionDump(hp_session);
    }
    if (const uint64_t flush_id = fl.at<2>().as_uint64(); flush_id != 0) {
      SendCommit({}, /*target_buffer=*/0, flush_id);
    }
  }

  void OnStopDataSource(uint64_t id) {
    if (id == 0) {
      return;
    }
    for (auto it = sessions_.begin(); it != sessions_.end(); ++it) {
      if (it->id != id) {
        continue;
      }
      if (it->started) {
        if (it->cfg.kind == hp::SessionKind::kHeapprofd) {
          if (!vm_shutting_down_.load(std::memory_order_acquire)) {
            DartHeapProfiler::StartSampling(hp::kDefaultSamplingInterval);
          }
          EmitSessionDump(&(*it));
          aggregator_.EndSession();
        }
        InvokeSingleIdMethod(m_unreg_writer_, it->writer_id);
      }
      sessions_.erase(it);
      break;
    }
    InvokeSingleIdMethod(m_notify_stopped_, id);
  }

  void HandleAsyncCommand(std::span<const uint8_t> cmd_bytes) {
    protozero::ProtoDecoder cmd(cmd_bytes.data(), cmd_bytes.size());
    for (auto f = cmd.ReadField(); f.valid(); f = cmd.ReadField()) {
      switch (f.id()) {
        case 1:  // start_data_source
          OnStartDataSource(protozero::ProtoDecoder(f.data(), f.size())
                                .FindField(1)
                                .as_uint64());
          break;
        case 2:  // stop_data_source
          OnStopDataSource(protozero::ProtoDecoder(f.data(), f.size())
                               .FindField(1)
                               .as_uint64());
          break;
        case 3:  // setup_tracing
          OnSetupTracing({f.data(), f.size()});
          break;
        case 5:  // flush
          OnFlushCommand({f.data(), f.size()});
          break;
        case 6: {  // setup_data_source
          protozero::TypedProtoDecoder<2, false> sd(f.data(), f.size());
          const auto cfg = sd.at<2>().as_bytes();
          OnSetupDataSource(sd.at<1>().as_uint64(), {cfg.data, cfg.size});
          break;
        }
        default:
          break;
      }
    }
  }

  perfetto::SharedMemoryABI::Chunk AcquireChunk(uint16_t writer_id,
                                                uint16_t packet_count,
                                                uint8_t flags) {
    if (shm_mapping_ == nullptr || writer_id == 0) {
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
          hdr.writer_id.store(writer_id, std::memory_order_relaxed);
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

  void WriteSerializedPacketToShm(std::span<const uint8_t> packet_bytes,
                                  uint16_t writer_id,
                                  uint32_t target_buffer) {
    if (shm_mapping_ == nullptr || packet_bytes.empty() || writer_id == 0) {
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

      auto chunk = AcquireChunk(writer_id, /*packet_count=*/1, flags);
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
        SendCommit(moved, target_buffer, /*flush_req_id=*/0);
        moved_count = 0;
      }
      offset += frag_len;
      first = false;
    }
    if (moved_count > 0) {
      SendCommit({moved.data(), moved_count}, target_buffer,
                 /*flush_req_id=*/0);
    }
  }

  void SendCommit(std::span<const MovedChunk> chunks,
                  uint32_t target_buffer,
                  uint64_t flush_req_id) {
    protozero::HeapBuffered<protozero::Message> req;
    for (const MovedChunk& c : chunks) {
      auto* msg =
          req->BeginNestedMessage<protozero::Message>(/*chunks_to_move=*/1);
      msg->AppendVarInt(/*page=*/1, c.page);
      msg->AppendVarInt(/*chunk=*/2, c.chunk);
      msg->AppendVarInt(/*target_buffer=*/3, target_buffer);
    }
    if (flush_req_id != 0) {
      req->AppendVarInt(/*flush_request_id=*/3, flush_req_id);
    }
    InvokeMethod(m_commit_, req.SerializeAsArray(),
                 /*drop_reply=*/flush_req_id == 0);
  }

  void EmitSessionDump(ActiveSession* session) {
    PERFETTO_DCHECK(task_runner_->RunsTasksOnCurrentThread());
    if (session == nullptr || !session->started || session->writer_id == 0) {
      return;
    }
    const uint16_t writer_id = session->writer_id;
    const uint32_t target_buffer = session->cfg.target_buffer;
    auto emit = [this, writer_id, target_buffer](auto&& fill_fn) {
      protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket> pkt;
      fill_fn(pkt.get());
      WriteSerializedPacketToShm(pkt.SerializeAsArray(), writer_id,
                                 target_buffer);
    };

    if (session->cfg.kind == hp::SessionKind::kHeapprofd) {
      hp::WriteHeapProfilePackets(aggregator_, session->cfg.sampling_interval,
                                  /*from_startup=*/!session->cfg.no_startup,
                                  &session->first_packet_on_sequence,
                                  &session->packet_index, emit);
    } else {
      std::vector<hp::SurvivingObjectSample> surviving;
      if (!vm_shutting_down_.load(std::memory_order_acquire)) {
        DartHeapProfiler::ReportSurvivingAllocations(
            &hp::HeapSampleAggregator::CollectSurvivingSampleCallback,
            &surviving, /*force_gc=*/true);
      }
      hp::WriteDartHeapGraphPackets(surviving,
                                    &session->first_packet_on_sequence,
                                    &session->packet_index, emit);
    }
  }

  void OnUnhandledOutOfMemoryOnProducer() {
    PERFETTO_DCHECK(task_runner_->RunsTasksOnCurrentThread());
    EmitSessionDump(FindStartedHeapprofd());
    if (m_activate_triggers_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendBytes(/*trigger_names=*/1,
                       hp::kArtOutOfMemoryTriggerName.data(),
                       hp::kArtOutOfMemoryTriggerName.size());
      InvokeMethod(m_activate_triggers_, req.SerializeAsArray(),
                   /*drop_reply=*/true);
    }
  }

  std::optional<perfetto::base::ThreadTaskRunner> task_runner_;
  std::atomic<bool> vm_shutting_down_{false};

  std::unique_ptr<perfetto::base::UnixSocket> socket_;
  std::vector<uint8_t> rx_buffer_;
  fml::UniqueFD pending_shm_fd_;
  std::unique_ptr<fml::FileMapping> shm_mapping_;
  perfetto::SharedMemoryABI shm_abi_;
  uint32_t next_chunk_id_ = 0;
  uint16_t next_writer_id_ = 1;
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
  uint32_t m_activate_triggers_ = 0;

  std::vector<ActiveSession> sessions_;
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
    // Enable coarse background sampling from VM startup so surviving
    // pre-session Dart allocations can be reported via
    // Dart_ReportSurvivingAllocations on java_hprof / OOM / heapprofd dumps.
    DartHeapProfiler::StartSampling(hp::kDefaultSamplingInterval);
    raw->Start();
  });
}

}  // namespace flutter

#else  // defined(FLUTTER_ENABLE_HEAPPROFD)

namespace flutter {

void InitializeAndroidDartHeapProfiler(int /*api_level*/) {}

}  // namespace flutter

#endif  // defined(FLUTTER_ENABLE_HEAPPROFD)
