// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_heap_profiler.h"

#include "flutter/fml/build_config.h"

#if defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)

#include <android/api-level.h>
#include <errno.h>
#include <poll.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#include <atomic>
#include <cstring>
#include <mutex>
#include <thread>
#include <vector>

#include "flutter/runtime/dart_heap_profiler_internal.h"
#include "perfetto/ext/tracing/core/shared_memory_abi.h"
#include "perfetto/protozero/proto_utils.h"

namespace flutter {
namespace {

namespace hp = heap_profile_internal;

// Bionic's libc.so exports _Unwind_Backtrace starting in Android 11 (API 30).
constexpr int kMinUnwindApiLevel = 30;
constexpr char kTracedProducerSocket[] = "/dev/socket/traced_producer";
constexpr uint16_t kWriterId = 1;

// Perfetto IPCFrame / ProducerPort wire-protocol field numbers.
constexpr uint32_t kIpcFrameRequestIdField = 2;
constexpr uint32_t kIpcFrameBindServiceField = 3;
constexpr uint32_t kIpcFrameBindServiceReplyField = 4;
constexpr uint32_t kIpcFrameInvokeMethodField = 5;
constexpr uint32_t kIpcFrameInvokeMethodReplyField = 6;

bool SendAll(int fd, const void* buf, size_t len) {
  const auto* p = static_cast<const uint8_t*>(buf);
  while (len > 0) {
    const ssize_t n = send(fd, p, len, MSG_NOSIGNAL);
    if (n < 0) {
      if (errno == EINTR) {
        continue;
      }
      return false;
    }
    p += n;
    len -= static_cast<size_t>(n);
  }
  return true;
}

/// Lightweight Perfetto `ProducerPort` client that connects directly to
/// `/dev/socket/traced_producer`, registers `"android.heapprofd"`, and streams
/// `ProfilePacket`s via `SharedMemoryABI`.
class DirectTracedHeapProducer {
 public:
  static DirectTracedHeapProducer& Instance() {
    static auto* instance = new DirectTracedHeapProducer();
    return *instance;
  }

  void EnsureStarted() {
    std::call_once(start_once_, [this]() {
      std::thread([this]() { RunReconnectLoop(); }).detach();
    });
  }

  void OnVmInitialized() {
    std::lock_guard<std::mutex> lock(vm_mutex_);
    vm_alive_ = true;
    Dart_RegisterHeapSamplingCallback(&OnDartSampleCreated,
                                      &OnDartSampleDestroyed);
    if (sampling_active_.load(std::memory_order_acquire)) {
      Dart_SetHeapSamplingPeriod(sampling_interval_);
      Dart_EnableHeapSampling();
    }
  }

  void OnVmCleanup() {
    std::lock_guard<std::mutex> lock(vm_mutex_);
    if (vm_alive_ && sampling_active_.load(std::memory_order_acquire)) {
      Dart_DisableHeapSampling();
    }
    vm_alive_ = false;
  }

 private:
  struct MovedChunk {
    uint32_t page;
    uint32_t chunk;
  };

  static void* OnDartSampleCreated(Dart_Isolate /*isolate*/,
                                   Dart_IsolateGroup group,
                                   const char* cls_name,
                                   intptr_t size) {
    DirectTracedHeapProducer& self = Instance();
    if (!self.sampling_active_.load(std::memory_order_acquire)) {
      return nullptr;
    }
    return self.aggregator_.RecordCurrentThreadAlloc(group, cls_name, size);
  }

  static void OnDartSampleDestroyed(void* data) {
    hp::HeapSampleAggregator::RecordFree(data);
  }

  void RunReconnectLoop() {
    uint32_t backoff_ms = 1000;
    for (;;) {
      if (ConnectAndServe()) {
        backoff_ms = 1000;
      }
      CleanupConnection();
      struct timespec ts{static_cast<time_t>(backoff_ms / 1000),
                         static_cast<long>((backoff_ms % 1000) * 1000000L)};
      nanosleep(&ts, nullptr);
      if (backoff_ms < 30000) {
        backoff_ms *= 2;
      }
    }
  }

  bool OpenSocketAndBind() {
    sock_fd_ = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (sock_fd_ < 0) {
      return false;
    }
    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, kTracedProducerSocket,
                 sizeof(addr.sun_path) - 1);
    if (connect(sock_fd_, reinterpret_cast<struct sockaddr*>(&addr),
                sizeof(addr)) != 0) {
      return false;
    }
    protozero::HeapBuffered<protozero::Message> frame;
    frame->AppendVarInt(kIpcFrameRequestIdField, next_req_id_++);
    auto* bind = frame->BeginNestedMessage<protozero::Message>(
        kIpcFrameBindServiceField);
    bind->AppendString(/*service_name=*/1, "ProducerPort");
    bind->Finalize();
    return SendFrame(frame.SerializeAsArray());
  }

  int ComputePollTimeoutMs() {
    if (active_id_ == 0 || next_dump_ns_ == 0) {
      return -1;
    }
    const uint64_t now = hp::GetMonotonicCoarseNs();
    if (now >= next_dump_ns_) {
      EmitDump(/*flush_req_id=*/0);
      next_dump_ns_ =
          now +
          static_cast<uint64_t>(active_session_.dump_interval_ms) * 1000000ULL;
    }
    const uint64_t rem_ns = next_dump_ns_ - now;
    return static_cast<int>((rem_ns + 999999ULL) / 1000000ULL);
  }

  ssize_t ReceiveWithOptionalFd(uint8_t* buf, size_t cap) {
    char cmsg_buf[CMSG_SPACE(sizeof(int))]{};
    struct iovec iov{buf, cap};
    struct msghdr msg{};
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsg_buf;
    msg.msg_controllen = sizeof(cmsg_buf);

    const ssize_t n = recvmsg(sock_fd_, &msg, MSG_CMSG_CLOEXEC);
    if (n <= 0) {
      return n;
    }
    for (struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg); cmsg != nullptr;
         cmsg = CMSG_NXTHDR(&msg, cmsg)) {
      if (cmsg->cmsg_level == SOL_SOCKET && cmsg->cmsg_type == SCM_RIGHTS &&
          cmsg->cmsg_len >= CMSG_LEN(sizeof(int))) {
        int fd = -1;
        std::memcpy(&fd, CMSG_DATA(cmsg), sizeof(int));
        if (pending_shm_fd_ >= 0) {
          close(pending_shm_fd_);
        }
        pending_shm_fd_ = fd;
      }
    }
    return n;
  }

  bool ConnectAndServe() {
    if (!OpenSocketAndBind()) {
      return false;
    }
    std::vector<uint8_t> rx_buf;
    rx_buf.reserve(8192);

    for (;;) {
      struct pollfd pfd{sock_fd_, POLLIN, 0};
      const int pr = poll(&pfd, 1, ComputePollTimeoutMs());
      if (pr < 0) {
        if (errno == EINTR) {
          continue;
        }
        return false;
      }
      if (pr == 0) {
        continue;
      }
      if ((pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0 &&
          (pfd.revents & POLLIN) == 0) {
        return false;
      }

      uint8_t tmp[4096];
      const ssize_t n = ReceiveWithOptionalFd(tmp, sizeof(tmp));
      if (n <= 0) {
        if (n < 0 && errno == EINTR) {
          continue;
        }
        return false;
      }
      rx_buf.insert(rx_buf.end(), tmp, tmp + n);
      if (!DrainBufferedFrames(&rx_buf)) {
        return false;
      }
    }
  }

  bool DrainBufferedFrames(std::vector<uint8_t>* rx_buf) {
    size_t offset = 0;
    while (rx_buf->size() - offset >= 4) {
      uint32_t frame_len = 0;
      std::memcpy(&frame_len, rx_buf->data() + offset, 4);
      if (frame_len > 16 * 1024 * 1024) {
        return false;
      }
      if (rx_buf->size() - offset - 4 < frame_len) {
        break;
      }
      if (!HandleFrame(rx_buf->data() + offset + 4, frame_len)) {
        return false;
      }
      offset += 4 + frame_len;
    }
    if (offset > 0) {
      rx_buf->erase(rx_buf->begin(),
                    rx_buf->begin() + static_cast<ptrdiff_t>(offset));
    }
    return true;
  }

  bool SendFrame(const std::vector<uint8_t>& payload) {
    const auto len = static_cast<uint32_t>(payload.size());
    return SendAll(sock_fd_, &len, 4) &&
           SendAll(sock_fd_, payload.data(), payload.size());
  }

  bool InvokeMethod(uint32_t method_id,
                    const std::vector<uint8_t>& args,
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

  void RecordMethodId(uint32_t mid, protozero::ConstChars mname) {
    auto eq = [&](const char* s) {
      return mname.size == std::strlen(s) &&
             std::memcmp(mname.data, s, mname.size) == 0;
    };
    if (eq("InitializeConnection")) {
      m_init_ = mid;
    } else if (eq("RegisterDataSource")) {
      m_reg_ds_ = mid;
    } else if (eq("CommitData")) {
      m_commit_ = mid;
    } else if (eq("GetAsyncCommand")) {
      m_async_cmd_ = mid;
    } else if (eq("RegisterTraceWriter")) {
      m_reg_writer_ = mid;
    } else if (eq("NotifyDataSourceStopped")) {
      m_notify_stopped_ = mid;
    }
  }

  bool HandleBindServiceReply(const uint8_t* data, size_t len) {
    protozero::ProtoDecoder br(data, len);
    bool ok = false;
    for (auto f = br.ReadField(); f.valid(); f = br.ReadField()) {
      if (f.id() == 1) {
        ok = f.as_bool();
      } else if (f.id() == 2) {
        service_id_ = f.as_uint32();
      } else if (f.id() == 3) {
        protozero::ProtoDecoder mi(f.data(), f.size());
        uint32_t mid = 0;
        protozero::ConstChars mname{};
        for (auto mf = mi.ReadField(); mf.valid(); mf = mi.ReadField()) {
          if (mf.id() == 1) {
            mid = mf.as_uint32();
          } else if (mf.id() == 2) {
            mname = mf.as_string();
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
    dsd->AppendString(/*name=*/1, hp::kHeapprofdDataSourceName);
    dsd->AppendVarInt(/*will_notify_on_stop=*/2, 1u);
    dsd->AppendVarInt(/*handles_incremental_state_clear=*/4, 1u);
    dsd->Finalize();
    return InvokeMethod(m_reg_ds_, ds_req.SerializeAsArray());
  }

  bool HandleFrame(const uint8_t* data, size_t len) {
    protozero::ProtoDecoder frame(data, len);
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
      return HandleBindServiceReply(bind_reply.data, bind_reply.size);
    }
    if (invoke_reply.data != nullptr && req_id == async_cmd_req_id_) {
      protozero::ProtoDecoder ir(invoke_reply.data, invoke_reply.size);
      for (auto f = ir.ReadField(); f.valid(); f = ir.ReadField()) {
        if (f.id() == 3) {
          HandleAsyncCommand(f.data(), f.size());
        }
      }
    }
    return true;
  }

  void OnSetupTracing(const uint8_t* data, size_t len) {
    uint32_t page_kb = 4;
    protozero::ProtoDecoder st(data, len);
    for (auto sf = st.ReadField(); sf.valid(); sf = st.ReadField()) {
      if (sf.id() == 1) {
        page_kb = sf.as_uint32();
      }
    }
    if (pending_shm_fd_ >= 0 && shm_ptr_ == nullptr) {
      struct stat sb{};
      if (fstat(pending_shm_fd_, &sb) == 0 && sb.st_size > 0) {
        shm_size_ = static_cast<size_t>(sb.st_size);
        void* p = mmap(nullptr, shm_size_, PROT_READ | PROT_WRITE, MAP_SHARED,
                       pending_shm_fd_, 0);
        if (p != MAP_FAILED) {
          shm_ptr_ = static_cast<uint8_t*>(p);
          shm_abi_.Initialize(shm_ptr_, shm_size_, page_kb * 1024u,
                              perfetto::SharedMemoryABI::ShmemMode::kDefault);
        }
      }
      close(pending_shm_fd_);
      pending_shm_fd_ = -1;
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
    prev_dump_mono_ns_ = hp::GetMonotonicCoarseNs();

    if (m_reg_writer_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendVarInt(/*trace_writer_id=*/1, kWriterId);
      req->AppendVarInt(/*target_buffer=*/2, active_session_.target_buffer);
      InvokeMethod(m_reg_writer_, req.SerializeAsArray(), /*drop_reply=*/true);
    }

    aggregator_.Clear();
    {
      std::lock_guard<std::mutex> lock(vm_mutex_);
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
      next_dump_ns_ =
          prev_dump_mono_ns_ + static_cast<uint64_t>(first_ms) * 1000000ULL;
    } else {
      next_dump_ns_ = 0;
    }
  }

  void HandleAsyncCommand(const uint8_t* data, size_t len) {
    protozero::ProtoDecoder cmd(data, len);
    for (auto f = cmd.ReadField(); f.valid(); f = cmd.ReadField()) {
      switch (f.id()) {
        case 3:  // setup_tracing
          OnSetupTracing(f.data(), f.size());
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
              hp::ParseDataSourceConfig(cfg.data, cfg.size);
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
            SendCommit(/*chunks=*/nullptr, 0, flush_id);
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
    if (shm_ptr_ == nullptr) {
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
      struct timespec ts{0, 500000L};
      nanosleep(&ts, nullptr);
    }
    return perfetto::SharedMemoryABI::Chunk();
  }

  void WriteSerializedPacketToShm(const std::vector<uint8_t>& bytes) {
    if (shm_ptr_ == nullptr || bytes.empty()) {
      return;
    }
    const size_t max_payload = shm_abi_.page_size() -
                               sizeof(perfetto::SharedMemoryABI::PageHeader) -
                               sizeof(perfetto::SharedMemoryABI::ChunkHeader) -
                               perfetto::SharedMemoryABI::kPacketHeaderSize;

    size_t offset = 0;
    bool first = true;
    MovedChunk moved[16];
    size_t moved_n = 0;

    while (offset < bytes.size()) {
      const size_t frag_len = (bytes.size() - offset > max_payload)
                                  ? max_payload
                                  : (bytes.size() - offset);
      const bool last = (offset + frag_len == bytes.size());
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
      std::memcpy(dst + perfetto::SharedMemoryABI::kPacketHeaderSize,
                  bytes.data() + offset, frag_len);
      auto [page_idx, chunk_idx] = shm_abi_.GetPageAndChunkIndex(chunk);
      shm_abi_.ReleaseChunkAsComplete(std::move(chunk));

      moved[moved_n++] = {static_cast<uint32_t>(page_idx),
                          static_cast<uint32_t>(chunk_idx)};
      if (moved_n == 16) {
        SendCommit(moved, moved_n, 0);
        moved_n = 0;
      }
      offset += frag_len;
      first = false;
    }
    if (moved_n > 0) {
      SendCommit(moved, moved_n, 0);
    }
  }

  void SendCommit(const MovedChunk* chunks, size_t n, uint64_t flush_req_id) {
    protozero::HeapBuffered<protozero::Message> req;
    for (size_t i = 0; i < n; ++i) {
      auto* c =
          req->BeginNestedMessage<protozero::Message>(/*chunks_to_move=*/1);
      c->AppendVarInt(/*page=*/1, chunks[i].page);
      c->AppendVarInt(/*chunk=*/2, chunks[i].chunk);
      c->AppendVarInt(/*target_buffer=*/3, active_session_.target_buffer);
      c->Finalize();
    }
    if (flush_req_id != 0) {
      req->AppendVarInt(/*flush_request_id=*/3, flush_req_id);
    }
    InvokeMethod(m_commit_, req.SerializeAsArray(),
                 /*drop_reply=*/flush_req_id == 0);
  }

  void EmitDump(uint64_t flush_req_id) {
    hp::WriteHeapProfilePackets(
        aggregator_, sampling_interval_, &packet_index_, &prev_dump_mono_ns_,
        [this](auto&& fill_fn) {
          protozero::HeapBuffered<protozero::Message> pkt;
          pkt->AppendVarInt(hp::kTracePacketTrustedSeqIdField, kWriterId);
          fill_fn(pkt.get());
          WriteSerializedPacketToShm(pkt.SerializeAsArray());
        });
    if (flush_req_id != 0) {
      SendCommit(nullptr, 0, flush_req_id);
    }
  }

  void StopSession(bool notify_service) {
    const uint64_t stopped_id = active_id_;
    {
      std::lock_guard<std::mutex> lock(vm_mutex_);
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
    next_dump_ns_ = 0;
    if (notify_service && stopped_id != 0 && m_notify_stopped_ != 0) {
      protozero::HeapBuffered<protozero::Message> req;
      req->AppendVarInt(1, stopped_id);
      InvokeMethod(m_notify_stopped_, req.SerializeAsArray(),
                   /*drop_reply=*/true);
    }
  }

  void CleanupConnection() {
    StopSession(/*notify_service=*/false);
    if (shm_ptr_ != nullptr) {
      munmap(shm_ptr_, shm_size_);
      shm_ptr_ = nullptr;
      shm_size_ = 0;
    }
    if (pending_shm_fd_ >= 0) {
      close(pending_shm_fd_);
      pending_shm_fd_ = -1;
    }
    if (sock_fd_ >= 0) {
      close(sock_fd_);
      sock_fd_ = -1;
    }
    service_id_ = 0;
    m_init_ = m_reg_ds_ = m_commit_ = m_async_cmd_ = m_reg_writer_ =
        m_notify_stopped_ = 0;
    pending_id_ = 0;
  }

  std::once_flag start_once_;
  std::mutex vm_mutex_;
  bool vm_alive_ = false;
  std::atomic<bool> sampling_active_{false};
  intptr_t sampling_interval_ = hp::kDefaultSamplingInterval;

  int sock_fd_ = -1;
  int pending_shm_fd_ = -1;
  uint8_t* shm_ptr_ = nullptr;
  size_t shm_size_ = 0;
  perfetto::SharedMemoryABI shm_abi_;
  uint32_t next_chunk_id_ = 1;

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
  uint64_t next_dump_ns_ = 0;
  uint64_t packet_index_ = 0;
  hp::HeapSampleAggregator aggregator_;
};

}  // namespace

void DartHeapProfiler::OnDartVMInitialized() {
  if (android_get_device_api_level() < kMinUnwindApiLevel) {
    return;
  }
  DirectTracedHeapProducer& p = DirectTracedHeapProducer::Instance();
  p.OnVmInitialized();
  p.EnsureStarted();
}

void DartHeapProfiler::OnDartVMCleanup() {
  if (android_get_device_api_level() < kMinUnwindApiLevel) {
    return;
  }
  DirectTracedHeapProducer::Instance().OnVmCleanup();
}

}  // namespace flutter

#else  // defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)

namespace flutter {

void DartHeapProfiler::OnDartVMInitialized() {}

void DartHeapProfiler::OnDartVMCleanup() {}

}  // namespace flutter

#endif  // defined(FLUTTER_ENABLE_HEAPPROFD) && defined(FML_OS_ANDROID)
