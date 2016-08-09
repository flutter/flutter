// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char ** argv) {
  int i = fork();
  struct stat ft;
  time_t ct;

  if (i < 0) {
    printf("fork error");
    return 1;
  }
  if (i > 0)
    return 0;

  /* child (daemon) continues */
  int j;
  for (j = 0; j < sysconf(_SC_OPEN_MAX); j++)
    close(j);

  setsid(); /* obtain a new process group */

  while (1) {
    sleep(120);

    stat("/sdcard/host_heartbeat", &ft);
    time(&ct);
    if (ct - ft.st_mtime  > 120) {
      /* File was not touched for some time. */
      system("su -c reboot");
    }
  }

  return 0;
}
