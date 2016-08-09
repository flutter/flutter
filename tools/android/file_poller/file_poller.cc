// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// When run with 2 or more arguments the file_poller tool will open a port on
// the device, print it on its standard output and then start collect file
// contents.  The first argument is the polling rate in Hz, and the following
// arguments are file to poll.
// When run with the port of an already running file_poller, the tool will
// contact the first instance, retrieve the sample and print those on its
// standard output. This will also terminate the first instance.

#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/logging.h"

// Context containing the files to poll and the polling rate.
struct Context {
  size_t nb_files;
  int* file_fds;
  int poll_rate;
};

// Write from the buffer to the given file descriptor.
void safe_write(int fd, const char* buffer, int size) {
  const char* index = buffer;
  size_t to_write = size;
  while (to_write > 0) {
    int written = write(fd, index, to_write);
    if (written < 0)
      PLOG(FATAL);
    index += written;
    to_write -= written;
  }
}

// Transfer the content of a file descriptor to another.
void transfer_to_fd(int fd_in, int fd_out) {
  char buffer[1024];
  int n;
  while ((n = read(fd_in, buffer, sizeof(buffer))) > 0)
    safe_write(fd_out, buffer, n);
}

// Transfer the content of a file descriptor to a buffer.
int transfer_to_buffer(int fd_in, char* bufffer, size_t size) {
  char* index = bufffer;
  size_t to_read = size;
  int n;
  while (to_read > 0 && ((n = read(fd_in, index, to_read)) > 0)) {
    index += n;
    to_read -= n;
  }
  if (n < 0)
    PLOG(FATAL);
  return size - to_read;
}

// Try to open the file at the given path for reading. Exit in case of failure.
int checked_open(const char* path) {
  int fd = open(path, O_RDONLY);
  if (fd < 0)
    PLOG(FATAL);
  return fd;
}

void transfer_measurement(int fd_in, int fd_out, bool last) {
  char buffer[1024];
  if (lseek(fd_in, 0, SEEK_SET) < 0)
    PLOG(FATAL);
  int n = transfer_to_buffer(fd_in, buffer, sizeof(buffer));
  safe_write(fd_out, buffer, n - 1);
  safe_write(fd_out, last ? "\n" : " ", 1);
}

// Acquire a sample and save it to the given file descriptor.
void acquire_sample(int fd, const Context& context) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  char buffer[1024];
  int n = snprintf(buffer, sizeof(buffer), "%d.%06d ", tv.tv_sec, tv.tv_usec);
  safe_write(fd, buffer, n);

  for (int i = 0; i < context.nb_files; ++i)
    transfer_measurement(context.file_fds[i], fd, i == (context.nb_files - 1));
}

void poll_content(const Context& context) {
  // Create and bind the socket so that the port can be written to stdout.
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  struct sockaddr_in socket_info;
  socket_info.sin_family = AF_INET;
  socket_info.sin_addr.s_addr = htonl(INADDR_ANY);
  socket_info.sin_port = htons(0);
  if (bind(sockfd, (struct sockaddr*)&socket_info, sizeof(socket_info)) < 0)
    PLOG(FATAL);
  socklen_t size = sizeof(socket_info);
  getsockname(sockfd, (struct sockaddr*)&socket_info, &size);
  printf("%d\n", ntohs(socket_info.sin_port));
  // Using a pipe to ensure child is diconnected from the terminal before
  // quitting.
  int pipes[2];
  pipe(pipes);
  pid_t pid = fork();
  if (pid < 0)
    PLOG(FATAL);
  if (pid != 0) {
    close(pipes[1]);
    // Not expecting any data to be received.
    read(pipes[0], NULL, 1);
    signal(SIGCHLD, SIG_IGN);
    return;
  }

  // Detach from terminal.
  setsid();
  close(STDIN_FILENO);
  close(STDOUT_FILENO);
  close(STDERR_FILENO);
  close(pipes[0]);

  // Start listening for incoming connection.
  if (listen(sockfd, 1) < 0)
    PLOG(FATAL);

  // Signal the parent that it can now safely exit.
  close(pipes[1]);

  // Prepare file to store the samples.
  int fd;
  char filename[] = "/data/local/tmp/fileXXXXXX";
  fd = mkstemp(filename);
  unlink(filename);

  // Collect samples until a client connect on the socket.
  fd_set rfds;
  struct timeval timeout;
  do {
    acquire_sample(fd, context);
    timeout.tv_sec = 0;
    timeout.tv_usec = 1000000 / context.poll_rate;
    FD_ZERO(&rfds);
    FD_SET(sockfd, &rfds);
  } while (select(sockfd + 1, &rfds, NULL, NULL, &timeout) == 0);

  // Collect a final sample.
  acquire_sample(fd, context);

  // Send the result back.
  struct sockaddr_in remote_socket_info;
  int rfd = accept(sockfd, (struct sockaddr*)&remote_socket_info, &size);
  if (rfd < 0)
    PLOG(FATAL);
  if (lseek(fd, 0, SEEK_SET) < 0)
    PLOG(FATAL);
  transfer_to_fd(fd, rfd);
}

void content_collection(int port) {
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  // Connect to localhost.
  struct sockaddr_in socket_info;
  socket_info.sin_family = AF_INET;
  socket_info.sin_addr.s_addr = htonl(0x7f000001);
  socket_info.sin_port = htons(port);
  if (connect(sockfd, (struct sockaddr*)&socket_info, sizeof(socket_info)) <
      0) {
    PLOG(FATAL);
  }
  transfer_to_fd(sockfd, STDOUT_FILENO);
}

int main(int argc, char** argv) {
  if (argc == 1) {
    fprintf(stderr,
            "Usage: \n"
            " %s port\n"
            " %s rate FILE...\n",
            argv[0],
            argv[0]);
    exit(EXIT_FAILURE);
  }
  if (argc == 2) {
    // Argument is the port to connect to.
    content_collection(atoi(argv[1]));
  } else {
    // First argument is the poll frequency, in Hz, following arguments are the
    // file to poll.
    Context context;
    context.poll_rate = atoi(argv[1]);
    context.nb_files = argc - 2;
    context.file_fds = new int[context.nb_files];
    for (int i = 2; i < argc; ++i)
      context.file_fds[i - 2] = checked_open(argv[i]);
    poll_content(context);
  }
  return EXIT_SUCCESS;
}
