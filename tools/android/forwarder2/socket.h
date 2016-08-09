// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_SOCKET_H_
#define TOOLS_ANDROID_FORWARDER2_SOCKET_H_

#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/un.h>

#include <string>
#include <vector>

#include "base/basictypes.h"

namespace forwarder2 {

// Wrapper class around unix socket api.  Can be used to create, bind or
// connect to both Unix domain sockets and TCP sockets.
// TODO(pliard): Split this class into TCPSocket and UnixDomainSocket.
class Socket {
 public:
  Socket();
  ~Socket();

  bool BindUnix(const std::string& path);
  bool BindTcp(const std::string& host, int port);
  bool ConnectUnix(const std::string& path);
  bool ConnectTcp(const std::string& host, int port);

  // Just a wrapper around unix socket shutdown(), see man 2 shutdown.
  void Shutdown();

  // Just a wrapper around unix socket close(), see man 2 close.
  void Close();
  bool IsClosed() const { return socket_ < 0; }

  int fd() const { return socket_; }

  bool Accept(Socket* new_socket);

  // Returns the port allocated to this socket or zero on error.
  int GetPort();

  // Just a wrapper around unix read() function.
  // Reads up to buffer_size, but may read less then buffer_size.
  // Returns the number of bytes read.
  int Read(void* buffer, size_t buffer_size);

  // Non-blocking version of Read() above. This must be called after a
  // successful call to select(). The socket must also be in non-blocking mode
  // before calling this method.
  int NonBlockingRead(void* buffer, size_t buffer_size);

  // Wrapper around send().
  int Write(const void* buffer, size_t count);

  // Same as NonBlockingRead() but for writing.
  int NonBlockingWrite(const void* buffer, size_t count);

  // Calls Read() multiple times until num_bytes is written to the provided
  // buffer. No bounds checking is performed.
  // Returns number of bytes read, which can be different from num_bytes in case
  // of errror.
  int ReadNumBytes(void* buffer, size_t num_bytes);

  // Calls Write() multiple times until num_bytes is written. No bounds checking
  // is performed. Returns number of bytes written, which can be different from
  // num_bytes in case of errror.
  int WriteNumBytes(const void* buffer, size_t num_bytes);

  // Calls WriteNumBytes for the given std::string. Note that the null
  // terminator is not written to the socket.
  int WriteString(const std::string& buffer);

  bool has_error() const { return socket_error_; }

  // |event_fd| must be a valid pipe file descriptor created from the
  // PipeNotifier and must live (not be closed) at least as long as this socket
  // is alive.
  void AddEventFd(int event_fd);

  // Returns whether Accept() or Connect() was interrupted because the socket
  // received an external event fired through the provided fd.
  bool DidReceiveEventOnFd(int fd) const;

  bool DidReceiveEvent() const;

  static pid_t GetUnixDomainSocketProcessOwner(const std::string& path);

 private:
  enum EventType {
    READ,
    WRITE
  };

  union SockAddr {
    // IPv4 sockaddr
    sockaddr_in addr4;
    // IPv6 sockaddr
    sockaddr_in6 addr6;
    // Unix Domain sockaddr
    sockaddr_un addr_un;
  };

  struct Event {
    int fd;
    bool was_fired;
  };

  bool SetNonBlocking();

  // If |host| is empty, use localhost.
  bool InitTcpSocket(const std::string& host, int port);
  bool InitUnixSocket(const std::string& path);
  bool BindAndListen();
  bool Connect();

  bool Resolve(const std::string& host);
  bool InitSocketInternal();
  void SetSocketError();

  // Waits until either the Socket or the |exit_notifier_fd_| has received an
  // event.
  bool WaitForEvent(EventType type, int timeout_secs);

  int socket_;
  int port_;
  bool socket_error_;

  // Family of the socket (PF_INET, PF_INET6 or PF_UNIX).
  int family_;

  SockAddr addr_;

  // Points to one of the members of the above union depending on the family.
  sockaddr* addr_ptr_;
  // Length of one of the members of the above union depending on the family.
  socklen_t addr_len_;

  // Used to listen for external events (e.g. process received a SIGTERM) while
  // blocking on I/O operations.
  std::vector<Event> events_;

  DISALLOW_COPY_AND_ASSIGN(Socket);
};

}  // namespace forwarder

#endif  // TOOLS_ANDROID_FORWARDER2_SOCKET_H_
