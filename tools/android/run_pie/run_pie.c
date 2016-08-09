// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <sys/prctl.h>
#include <unistd.h>

// This is a wrapper to run position independent executables on Android ICS,
// where the linker doesn't support PIE. This requires the PIE binaries to be
// built with CFLAGS +=-fvisibility=default -fPIE, and LDFLAGS += -rdynamic -pie
// such that the main() symbol remains exported and can be dlsym-ed.

#define ERR_PREFIX "[PIE Loader] "

typedef int (*main_t)(int, char**);


int main(int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: %s path_to_pie_executable [args]\n", argv[0]);
    return -1;
  }

  // Shift left the argv[]. argv is what /proc/PID/cmdline prints out. In turn
  // cmdline is what Android "ps" prints out. In turn "ps" is what many scripts
  // look for to decide which processes to kill / killall.
  int i;
  char* next_argv_start = argv[0];
  for (i = 1; i < argc; ++i) {
    const size_t argv_len = strlen(argv[i]) + 1;
    memcpy(argv[i - 1], argv[i], argv_len);
    next_argv_start += argv_len;
    argv[i] = next_argv_start;
  }
  argv[argc - 1] = NULL;  // The last argv must be a NULL ptr.

  // Set also the proc name accordingly (/proc/PID/comm).
  prctl(PR_SET_NAME, (long) argv[0]);

  // dlopen should not fail, unless:
  // - The target binary does not exists:
  // - The dependent .so libs cannot be loaded.
  // In both cases, just bail out with an explicit error message.
  void* handle = dlopen(argv[0], RTLD_NOW);
  if (handle == NULL) {
    printf(ERR_PREFIX "dlopen() failed: %s.\n", dlerror());
    return -1;
  }

  main_t pie_main = (main_t) dlsym(handle, "main");
  if (pie_main) {
    return pie_main(argc - 1, argv);
  }

  // If we reached this point dlsym failed, very likely because the target
  // binary has not been compiled with the proper CFLAGS / LDFLAGS.
  // At this point the most sensible thing to do is running that normally
  // via exec and hope that the target binary wasn't a PIE.
  execv(argv[0], argv);

  // exevc is supposed to never return, unless it fails.
  printf(ERR_PREFIX "Both dlsym() and the execv() fallback failed.\n");
  perror("execv");
  return -1;
}
