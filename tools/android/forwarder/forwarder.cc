// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "tools/android/common/adb_connection.h"
#include "tools/android/common/daemon.h"
#include "tools/android/common/net.h"

namespace {

const pthread_t kInvalidThread = static_cast<pthread_t>(-1);
volatile bool g_killed = false;

void CloseSocket(int fd) {
  if (fd >= 0) {
    int old_errno = errno;
    close(fd);
    errno = old_errno;
  }
}

class Buffer {
 public:
  Buffer()
      : bytes_read_(0),
        write_offset_(0) {
  }

  bool CanRead() {
    return bytes_read_ == 0;
  }

  bool CanWrite() {
    return write_offset_ < bytes_read_;
  }

  int Read(int fd) {
    int ret = -1;
    if (CanRead()) {
      ret = HANDLE_EINTR(read(fd, buffer_, kBufferSize));
      if (ret > 0)
        bytes_read_ = ret;
    }
    return ret;
  }

  int Write(int fd) {
    int ret = -1;
    if (CanWrite()) {
      ret = HANDLE_EINTR(write(fd, buffer_ + write_offset_,
                               bytes_read_ - write_offset_));
      if (ret > 0) {
        write_offset_ += ret;
        if (write_offset_ == bytes_read_) {
          write_offset_ = 0;
          bytes_read_ = 0;
        }
      }
    }
    return ret;
  }

 private:
  // A big buffer to let our file-over-http bridge work more like real file.
  static const int kBufferSize = 1024 * 128;
  int bytes_read_;
  int write_offset_;
  char buffer_[kBufferSize];

  DISALLOW_COPY_AND_ASSIGN(Buffer);
};

class Server;

struct ForwarderThreadInfo {
  ForwarderThreadInfo(Server* a_server, int a_forwarder_index)
      : server(a_server),
        forwarder_index(a_forwarder_index) {
  }
  Server* server;
  int forwarder_index;
};

struct ForwarderInfo {
  time_t start_time;
  int socket1;
  time_t socket1_last_byte_time;
  size_t socket1_bytes;
  int socket2;
  time_t socket2_last_byte_time;
  size_t socket2_bytes;
};

class Server {
 public:
  Server()
      : thread_(kInvalidThread),
        socket_(-1) {
    memset(forward_to_, 0, sizeof(forward_to_));
    memset(&forwarders_, 0, sizeof(forwarders_));
  }

  int GetFreeForwarderIndex() {
    for (int i = 0; i < kMaxForwarders; i++) {
      if (forwarders_[i].start_time == 0)
        return i;
    }
    return -1;
  }

  void DisposeForwarderInfo(int index) {
    forwarders_[index].start_time = 0;
  }

  ForwarderInfo* GetForwarderInfo(int index) {
    return &forwarders_[index];
  }

  void DumpInformation() {
    LOG(INFO) << "Server information: " << forward_to_;
    LOG(INFO) << "No.: age up(bytes,idle) down(bytes,idle)";
    int count = 0;
    time_t now = time(NULL);
    for (int i = 0; i < kMaxForwarders; i++) {
      const ForwarderInfo& info = forwarders_[i];
      if (info.start_time) {
        count++;
        LOG(INFO) << count << ": " << now - info.start_time << " up("
                  << info.socket1_bytes << ","
                  << now - info.socket1_last_byte_time << " down("
                  << info.socket2_bytes << ","
                  << now - info.socket2_last_byte_time << ")";
      }
    }
  }

  void Shutdown() {
    if (socket_ >= 0)
      shutdown(socket_, SHUT_RDWR);
  }

  bool InitSocket(const char* arg);

  void StartThread() {
    pthread_create(&thread_, NULL, ServerThread, this);
  }

  void JoinThread() {
    if (thread_ != kInvalidThread)
      pthread_join(thread_, NULL);
  }

 private:
  static void* ServerThread(void* arg);

  // There are 3 kinds of threads that will access the array:
  // 1. Server thread will get a free ForwarderInfo and initialize it;
  // 2. Forwarder threads will dispose the ForwarderInfo when it finishes;
  // 3. Main thread will iterate and print the forwarders.
  // Using an array is not optimal, but can avoid locks or other complex
  // inter-thread communication.
  static const int kMaxForwarders = 512;
  ForwarderInfo forwarders_[kMaxForwarders];

  pthread_t thread_;
  int socket_;
  char forward_to_[40];

  DISALLOW_COPY_AND_ASSIGN(Server);
};

// Forwards all outputs from one socket to another socket.
void* ForwarderThread(void* arg) {
  ForwarderThreadInfo* thread_info =
      reinterpret_cast<ForwarderThreadInfo*>(arg);
  Server* server = thread_info->server;
  int index = thread_info->forwarder_index;
  delete thread_info;
  ForwarderInfo* info = server->GetForwarderInfo(index);
  int socket1 = info->socket1;
  int socket2 = info->socket2;
  int nfds = socket1 > socket2 ? socket1 + 1 : socket2 + 1;
  fd_set read_fds;
  fd_set write_fds;
  Buffer buffer1;
  Buffer buffer2;

  while (!g_killed) {
    FD_ZERO(&read_fds);
    if (buffer1.CanRead())
      FD_SET(socket1, &read_fds);
    if (buffer2.CanRead())
      FD_SET(socket2, &read_fds);

    FD_ZERO(&write_fds);
    if (buffer1.CanWrite())
      FD_SET(socket2, &write_fds);
    if (buffer2.CanWrite())
      FD_SET(socket1, &write_fds);

    if (HANDLE_EINTR(select(nfds, &read_fds, &write_fds, NULL, NULL)) <= 0) {
      LOG(ERROR) << "Select error: " << strerror(errno);
      break;
    }

    int now = time(NULL);
    if (FD_ISSET(socket1, &read_fds)) {
      info->socket1_last_byte_time = now;
      int bytes = buffer1.Read(socket1);
      if (bytes <= 0)
        break;
      info->socket1_bytes += bytes;
    }
    if (FD_ISSET(socket2, &read_fds)) {
      info->socket2_last_byte_time = now;
      int bytes = buffer2.Read(socket2);
      if (bytes <= 0)
        break;
      info->socket2_bytes += bytes;
    }
    if (FD_ISSET(socket1, &write_fds)) {
      if (buffer2.Write(socket1) <= 0)
        break;
    }
    if (FD_ISSET(socket2, &write_fds)) {
      if (buffer1.Write(socket2) <= 0)
        break;
    }
  }

  CloseSocket(socket1);
  CloseSocket(socket2);
  server->DisposeForwarderInfo(index);
  return NULL;
}

// Listens to a server socket. On incoming request, forward it to the host.
// static
void* Server::ServerThread(void* arg) {
  Server* server = reinterpret_cast<Server*>(arg);
  while (!g_killed) {
    int forwarder_index = server->GetFreeForwarderIndex();
    if (forwarder_index < 0) {
      LOG(ERROR) << "Too many forwarders";
      continue;
    }

    struct sockaddr_in addr;
    socklen_t addr_len = sizeof(addr);
    int socket = HANDLE_EINTR(accept(server->socket_,
                                     reinterpret_cast<sockaddr*>(&addr),
                                     &addr_len));
    if (socket < 0) {
      LOG(ERROR) << "Failed to accept: " << strerror(errno);
      break;
    }
    tools::DisableNagle(socket);

    int host_socket = tools::ConnectAdbHostSocket(server->forward_to_);
    if (host_socket >= 0) {
      // Set NONBLOCK flag because we use select().
      fcntl(socket, F_SETFL, fcntl(socket, F_GETFL) | O_NONBLOCK);
      fcntl(host_socket, F_SETFL, fcntl(host_socket, F_GETFL) | O_NONBLOCK);

      ForwarderInfo* forwarder_info = server->GetForwarderInfo(forwarder_index);
      time_t now = time(NULL);
      forwarder_info->start_time = now;
      forwarder_info->socket1 = socket;
      forwarder_info->socket1_last_byte_time = now;
      forwarder_info->socket1_bytes = 0;
      forwarder_info->socket2 = host_socket;
      forwarder_info->socket2_last_byte_time = now;
      forwarder_info->socket2_bytes = 0;

      pthread_t thread;
      pthread_create(&thread, NULL, ForwarderThread,
                     new ForwarderThreadInfo(server, forwarder_index));
    } else {
      // Close the unused client socket which is failed to connect to host.
      CloseSocket(socket);
    }
  }

  CloseSocket(server->socket_);
  server->socket_ = -1;
  return NULL;
}

// Format of arg: <Device port>[:<Forward to port>:<Forward to address>]
bool Server::InitSocket(const char* arg) {
  char* endptr;
  int local_port = static_cast<int>(strtol(arg, &endptr, 10));
  if (local_port < 0)
    return false;

  if (*endptr != ':') {
    snprintf(forward_to_, sizeof(forward_to_), "%d:127.0.0.1", local_port);
  } else {
    strncpy(forward_to_, endptr + 1, sizeof(forward_to_) - 1);
  }

  socket_ = socket(AF_INET, SOCK_STREAM, 0);
  if (socket_ < 0) {
    perror("server socket");
    return false;
  }
  tools::DisableNagle(socket_);

  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons(local_port);
  int reuse_addr = 1;
  setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR,
             &reuse_addr, sizeof(reuse_addr));
  tools::DeferAccept(socket_);
  if (HANDLE_EINTR(bind(socket_, reinterpret_cast<sockaddr*>(&addr),
                        sizeof(addr))) < 0 ||
      HANDLE_EINTR(listen(socket_, 5)) < 0) {
    perror("server bind");
    CloseSocket(socket_);
    socket_ = -1;
    return false;
  }

  if (local_port == 0) {
    socklen_t addrlen = sizeof(addr);
    if (getsockname(socket_, reinterpret_cast<sockaddr*>(&addr), &addrlen)
        != 0) {
      perror("get listen address");
      CloseSocket(socket_);
      socket_ = -1;
      return false;
    }
    local_port = ntohs(addr.sin_port);
  }

  printf("Forwarding device port %d to host %s\n", local_port, forward_to_);
  return true;
}

int g_server_count = 0;
Server* g_servers = NULL;

void KillHandler(int unused) {
  g_killed = true;
  for (int i = 0; i < g_server_count; i++)
    g_servers[i].Shutdown();
}

void DumpInformation(int unused) {
  for (int i = 0; i < g_server_count; i++)
    g_servers[i].DumpInformation();
}

}  // namespace

int main(int argc, char** argv) {
  printf("Android device to host TCP forwarder\n");
  printf("Like 'adb forward' but in the reverse direction\n");

  base::CommandLine command_line(argc, argv);
  base::CommandLine::StringVector server_args = command_line.GetArgs();
  if (tools::HasHelpSwitch(command_line) || server_args.empty()) {
    tools::ShowHelp(
        argv[0],
        "<Device port>[:<Forward to port>:<Forward to address>] ...",
        "  <Forward to port> default is <Device port>\n"
        "  <Forward to address> default is 127.0.0.1\n"
        "If <Device port> is 0, a port will by dynamically allocated.\n");
    return 0;
  }

  g_servers = new Server[server_args.size()];
  g_server_count = 0;
  int failed_count = 0;
  for (size_t i = 0; i < server_args.size(); i++) {
    if (!g_servers[g_server_count].InitSocket(server_args[i].c_str())) {
      printf("Couldn't start forwarder server for port spec: %s\n",
             server_args[i].c_str());
      ++failed_count;
    } else {
      ++g_server_count;
    }
  }

  if (g_server_count == 0) {
    printf("No forwarder servers could be started. Exiting.\n");
    delete [] g_servers;
    return failed_count;
  }

  if (!tools::HasNoSpawnDaemonSwitch(command_line))
    tools::SpawnDaemon(failed_count);

  signal(SIGTERM, KillHandler);
  signal(SIGUSR2, DumpInformation);

  for (int i = 0; i < g_server_count; i++)
    g_servers[i].StartThread();
  for (int i = 0; i < g_server_count; i++)
    g_servers[i].JoinThread();
  g_server_count = 0;
  delete [] g_servers;

  return 0;
}

