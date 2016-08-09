// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/forwarder.h"

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "tools/android/forwarder2/socket.h"

namespace forwarder2 {
namespace {

const int kBufferSize = 32 * 1024;

}  // namespace


// Helper class to buffer reads and writes from one socket to another.
// Each implements a small buffer connected two one input socket, and
// one output socket.
//
//   socket_from_ ---> [BufferedCopier] ---> socket_to_
//
// These objects are used in a pair to handle duplex traffic, as in:
//
//                   -------> [BufferedCopier_1] --->
//                  |                                |
//      socket_1   *                                  * socket_2
//                  |                                |
//                   <------ [BufferedCopier_2] <----
//
// When a BufferedCopier is in the READING state (see below), it only listens
// to events on its input socket, and won't detect when its output socket
// disconnects. To work around this, its peer will call its Close() method
// when that happens.

class Forwarder::BufferedCopier {
 public:
  // Possible states:
  //    READING - Empty buffer and Waiting for input.
  //    WRITING - Data in buffer, and waiting for output.
  //    CLOSING - Like WRITING, but do not try to read after that.
  //    CLOSED  - Completely closed.
  //
  // State transitions are:
  //
  //   T01:  READING ---[receive data]---> WRITING
  //   T02:  READING ---[error on input socket]---> CLOSED
  //   T03:  READING ---[Close() call]---> CLOSED
  //
  //   T04:  WRITING ---[write partial data]---> WRITING
  //   T05:  WRITING ---[write all data]----> READING
  //   T06:  WRITING ---[error on output socket]----> CLOSED
  //   T07:  WRITING ---[Close() call]---> CLOSING
  //
  //   T08:  CLOSING ---[write partial data]---> CLOSING
  //   T09:  CLOSING ---[write all data]----> CLOSED
  //   T10:  CLOSING ---[Close() call]---> CLOSING
  //   T11:  CLOSING ---[error on output socket] ---> CLOSED
  //
  enum State {
    STATE_READING = 0,
    STATE_WRITING = 1,
    STATE_CLOSING = 2,
    STATE_CLOSED = 3,
  };

  // Does NOT own the pointers.
  BufferedCopier(Socket* socket_from, Socket* socket_to)
      : socket_from_(socket_from),
        socket_to_(socket_to),
        bytes_read_(0),
        write_offset_(0),
        peer_(NULL),
        state_(STATE_READING) {}

  // Sets the 'peer_' field pointing to the other BufferedCopier in a pair.
  void SetPeer(BufferedCopier* peer) {
    DCHECK(!peer_);
    peer_ = peer;
  }

  bool is_closed() const { return state_ == STATE_CLOSED; }

  // Gently asks to close a buffer. Called either by the peer or the forwarder.
  void Close() {
    switch (state_) {
      case STATE_READING:
        state_ = STATE_CLOSED;  // T03
        break;
      case STATE_WRITING:
        state_ = STATE_CLOSING;  // T07
        break;
      case STATE_CLOSING:
        break;  // T10
      case STATE_CLOSED:
        ;
    }
  }

  // Call this before select(). This updates |read_fds|,
  // |write_fds| and |max_fd| appropriately *if* the buffer isn't closed.
  void PrepareSelect(fd_set* read_fds, fd_set* write_fds, int* max_fd) {
    int fd;
    switch (state_) {
      case STATE_READING:
        DCHECK(bytes_read_ == 0);
        DCHECK(write_offset_ == 0);
        fd = socket_from_->fd();
        if (fd < 0) {
          ForceClose();  // T02
          return;
        }
        FD_SET(fd, read_fds);
        break;

      case STATE_WRITING:
      case STATE_CLOSING:
        DCHECK(bytes_read_ > 0);
        DCHECK(write_offset_ < bytes_read_);
        fd = socket_to_->fd();
        if (fd < 0) {
          ForceClose();  // T06
          return;
        }
        FD_SET(fd, write_fds);
        break;

      case STATE_CLOSED:
        return;
    }
    *max_fd = std::max(*max_fd, fd);
  }

  // Call this after a select() call to operate over the buffer.
  void ProcessSelect(const fd_set& read_fds, const fd_set& write_fds) {
    int fd;
    int ret;
    // With FORTIFY_SOURCE, FD_ISSET is implemented as a function that takes a
    // non-const fd_set*. Make a copy of the passed arguments so we can safely
    // take a reference.
    fd_set read_fds_copy = read_fds;
    fd_set write_fds_copy = write_fds;
    switch (state_) {
      case STATE_READING:
        fd = socket_from_->fd();
        if (fd < 0) {
          state_ = STATE_CLOSED;  // T02
          return;
        }
        if (!FD_ISSET(fd, &read_fds_copy))
          return;

        ret = socket_from_->NonBlockingRead(buffer_, kBufferSize);
        if (ret <= 0) {
          ForceClose();  // T02
          return;
        }
        bytes_read_ = ret;
        write_offset_ = 0;
        state_ = STATE_WRITING;  // T01
        break;

      case STATE_WRITING:
      case STATE_CLOSING:
        fd = socket_to_->fd();
        if (fd < 0) {
          ForceClose();  // T06 + T11
          return;
        }
        if (!FD_ISSET(fd, &write_fds_copy))
          return;

        ret = socket_to_->NonBlockingWrite(buffer_ + write_offset_,
                                           bytes_read_ - write_offset_);
        if (ret <= 0) {
          ForceClose();  // T06 + T11
          return;
        }

        write_offset_ += ret;
        if (write_offset_ < bytes_read_)
          return;  // T08 + T04

        write_offset_ = 0;
        bytes_read_ = 0;
        if (state_ == STATE_CLOSING) {
          ForceClose();  // T09
          return;
        }
        state_ = STATE_READING;  // T05
        break;

      case STATE_CLOSED:
        ;
    }
  }

 private:
  // Internal method used to close the buffer and notify the peer, if any.
  void ForceClose() {
    if (peer_) {
      peer_->Close();
      peer_ = NULL;
    }
    state_ = STATE_CLOSED;
  }

  // Not owned.
  Socket* socket_from_;
  Socket* socket_to_;

  int bytes_read_;
  int write_offset_;
  BufferedCopier* peer_;
  State state_;
  char buffer_[kBufferSize];

  DISALLOW_COPY_AND_ASSIGN(BufferedCopier);
};

Forwarder::Forwarder(scoped_ptr<Socket> socket1,
                     scoped_ptr<Socket> socket2)
    : socket1_(socket1.Pass()),
      socket2_(socket2.Pass()),
      buffer1_(new BufferedCopier(socket1_.get(), socket2_.get())),
      buffer2_(new BufferedCopier(socket2_.get(), socket1_.get())) {
  buffer1_->SetPeer(buffer2_.get());
  buffer2_->SetPeer(buffer1_.get());
}

Forwarder::~Forwarder() {
  DCHECK(thread_checker_.CalledOnValidThread());
}

void Forwarder::RegisterFDs(fd_set* read_fds, fd_set* write_fds, int* max_fd) {
  DCHECK(thread_checker_.CalledOnValidThread());
  buffer1_->PrepareSelect(read_fds, write_fds, max_fd);
  buffer2_->PrepareSelect(read_fds, write_fds, max_fd);
}

void Forwarder::ProcessEvents(const fd_set& read_fds, const fd_set& write_fds) {
  DCHECK(thread_checker_.CalledOnValidThread());
  buffer1_->ProcessSelect(read_fds, write_fds);
  buffer2_->ProcessSelect(read_fds, write_fds);
}

bool Forwarder::IsClosed() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return buffer1_->is_closed() && buffer2_->is_closed();
}

void Forwarder::Shutdown() {
  DCHECK(thread_checker_.CalledOnValidThread());
  buffer1_->Close();
  buffer2_->Close();
}

}  // namespace forwarder2
