// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fcntl.h>
#include <inttypes.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <algorithm>
#include <memory>
#include <string>
#include <vector>

// This utility allows to read a file from the local file system through a
// network protocol. The protocol is the following request response protocol:
//
// Opening a new file:
// Request: O path_to_file\n
// Success: O
// Error: E
//
// Seeking on the last opened file:
// Request: S offset whence\n
// Success: 0
// Error: E
//
// Reading the last opened file at the current position:
// Request: R size\n
// Success: 0{size encoded on 4 bytes in network order}{content}
// Error: E

namespace {

// Display an error message and exit.
void error(const char* msg) {
  perror(msg);
  exit(1);
}

// Keep track of an active connection with a client.
class Connection {
 public:
  // Takes ownership of the given fd which is an opened socket to the client.
  explicit Connection(int fd)
      : fd_(fd), file_fd_(-1), buffer_size_(0), buffer_(nullptr, free) {}
  ~Connection() { Close(); }

  int fd() { return fd_; };

  void Close() {
    if (fd_ != -1) {
      close(fd_);
      fd_ = -1;
    }
    if (file_fd_ != -1) {
      close(file_fd_);
      file_fd_ = -1;
    }
  }

  // Returns whether this connection has some data to write to the client.
  bool NeedsWriting() { return write_buffer_.size() > 0; }

  // Try to write buffered data to the client. This should only be called when
  // the socket is writeable, otherwise this method may block.
  bool Write() {
    int nb_written = write(fd_, write_buffer_.data(), write_buffer_.size());
    if (nb_written <= 0) {
      Close();
      return false;
    }
    write_buffer_ = std::string(write_buffer_, nb_written);
    return true;
  }

  // Read any data available from the client, and send any responses if a full
  // request has been read. This should only be called when the socket is
  // readable, otherwise this method may block.
  bool Read() {
    char buffer[4096];
    int nb_read = read(fd_, buffer, sizeof(buffer));
    if (nb_read <= 0) {
      Close();
      return false;
    }
    read_buffer_ += std::string(buffer, nb_read);
    Respond();
    return true;
  }

 private:
  // Success message.
  const char kSuccess = 'O';
  // Error message.
  const char kError = 'E';

  // Read any available request in the read buffer and write the responses in
  // the write buffer.
  void Respond() {
    std::string::size_type eol_position = read_buffer_.find('\n');
    while (eol_position != std::string::npos) {
      std::string command(read_buffer_, 0, eol_position);
      read_buffer_ = std::string(read_buffer_, eol_position + 1);
      std::string argument(command, 2);
      switch (command[0]) {
        case 'O':
          OpenCommand(argument);
          break;
        case 'S':
          SeekCommand(argument);
          break;
        case 'R':
          ReadCommand(argument);
          break;
        default:
          write_buffer_ += kError;
      }
      eol_position = read_buffer_.find('\n');
    }
  }

  // Handle the open command.
  void OpenCommand(const std::string& file) {
    if (file_fd_ != -1) {
      close(file_fd_);
      file_fd_ = -1;
    }
    file_fd_ = open(file.c_str(), O_RDONLY);
    if (file_fd_ == -1) {
      perror("Unable to open file");
      write_buffer_ += kError;
      return;
    }
    write_buffer_ += kSuccess;
  }

  // Handle the seek command.
  void SeekCommand(const std::string& parameters) {
    if (file_fd_ == -1) {
      write_buffer_ += kError;
      return;
    }
    int32_t offset;
    int32_t whence;
    if (sscanf(parameters.c_str(), "%" SCNd32 " %" SCNd32, &offset, &whence) !=
        2) {
      write_buffer_ += kError;
      return;
    }
    if (lseek(file_fd_, offset, whence) == -1) {
      perror("Unable to seek");
      write_buffer_ += kError;
      return;
    }
    write_buffer_ += kSuccess;
  }

  // Handle the read command.
  void ReadCommand(const std::string& parameters) {
    if (file_fd_ == -1) {
      write_buffer_ += kError;
      return;
    }
    int32_t size;
    if (sscanf(parameters.c_str(), "%" SCNd32, &size) != 1) {
      write_buffer_ += kError;
      return;
    }
    if (size <= 0) {
      write_buffer_ += kError;
      return;
    }
    EnsureBufferCapacity(size);
    int32_t result = read(file_fd_, buffer_.get(), size);
    if (result < 0) {
      perror("Unable to read");
      close(file_fd_);
      file_fd_ = -1;
      write_buffer_ += kError;
      return;
    }
    write_buffer_ += kSuccess;
    int32_t size_to_send = htonl(result);
    static_assert(sizeof(size_to_send) == 4, "Must send size with 4 byte.");
    write_buffer_ += std::string(reinterpret_cast<char*>(&size_to_send), 4);
    write_buffer_ += std::string(buffer_.get(), result);
  }

  // Ensure that |buffer_| has the capacity needed to read from the local file.
  void EnsureBufferCapacity(size_t capacity) {
    if (buffer_size_ >= capacity) {
      return;
    }
    if (buffer_size_ == 0) {
      buffer_.reset(static_cast<char*>(malloc(capacity)));
      buffer_size_ = capacity;
      return;
    }
    buffer_.reset(static_cast<char*>(realloc(buffer_.release(), capacity)));
    buffer_size_ = capacity;
  }

  // File descriptor of the socket connected to the client.
  int fd_;
  // File descriptor of the current read file.
  int file_fd_;
  size_t buffer_size_;
  std::unique_ptr<char, decltype(free)*> buffer_;
  std::string write_buffer_;
  std::string read_buffer_;
};

}  // namespace

int main(int argc, char** argv) {
  // The port to bind to.
  int port = 0;
  if (argc > 1) {
    port = atoi(argv[1]);
  }
  // Setup the server socket.
  int server_socket, connected_socket;
  struct sockaddr_in server_address, client_address;
  server_socket = socket(AF_INET, SOCK_STREAM, 0);
  if (server_socket < 0) {
    error("Unable to open socket");
  }
  bzero(&server_address, sizeof(server_address));
  server_address.sin_family = AF_INET;
  server_address.sin_addr.s_addr = INADDR_ANY;
  server_address.sin_port = port;
  if (bind(server_socket, reinterpret_cast<struct sockaddr*>(&server_address),
           sizeof(server_address)) < 0) {
    error("Unable to bind socket");
  }
  socklen_t socket_size = sizeof(server_address);
  if (getsockname(server_socket,
                  reinterpret_cast<struct sockaddr*>(&server_address),
                  &socket_size) < 0) {
    perror("Unable to retrieve socket information");
  }
  // Print the port on the bound port on the standard output.
  printf("%d\n", ntohs(server_address.sin_port));

  // Start listening for client.
  listen(server_socket, 5);

  // Wait for the first client to connect.
  socket_size = sizeof(client_address);
  connected_socket =
      accept(server_socket, reinterpret_cast<struct sockaddr*>(&client_address),
             &socket_size);
  if (connected_socket < 0) {
    error("Unable to accept the intiial client");
  }

  // Keep track of active connections.
  std::vector<std::unique_ptr<Connection>> connections;
  connections.push_back(
      std::unique_ptr<Connection>(new Connection(connected_socket)));

  // Stop when all clients have disconnected.
  while (connections.size()) {
    // Prepate data to wait for any I/O to be ready.
    fd_set rset;
    fd_set wset;
    FD_ZERO(&rset);
    FD_ZERO(&wset);
    // Always wait for a new connection.
    FD_SET(server_socket, &rset);
    int max_fd = server_socket + 1;
    for (auto& c : connections) {
      // Always wait for a client sending data.
      FD_SET(c->fd(), &rset);
      // Wait for a client to be ready to receive data only if some data needs
      // to be sent.
      if (c->NeedsWriting()) {
        FD_SET(c->fd(), &wset);
      }
      max_fd = std::max(max_fd, c->fd() + 1);
    }
    // Wait for any I/O to be ready.
    select(max_fd, &rset, &wset, nullptr, nullptr);

    // Check if a client a connected.
    if (FD_ISSET(server_socket, &rset)) {
      int fd = accept(server_socket,
                      reinterpret_cast<struct sockaddr*>(&client_address),
                      &socket_size);
      if (fd >= 0) {
        connections.push_back(std::unique_ptr<Connection>(new Connection(fd)));
      }
    }

    // Check each connection.
    for (auto& c : connections) {
      if (FD_ISSET(c->fd(), &rset)) {
        if (!c->Read()) {
          // If a fatal error happen, delete the connection.
          c.reset();
        }
      }
      if (c && FD_ISSET(c->fd(), &wset)) {
        if (!c->Write()) {
          // If a fatal error happen, delete the connection.
          c.reset();
        }
      }
    }

    // Remove any deleted connection from the list of active connections.
    connections.erase(
        std::remove_if(connections.begin(), connections.end(),
                       [](const std::unique_ptr<Connection>& c) { return !c; }),
        connections.end());
  }
  return 0;
}
