/*
 * Copyright 2014 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include <ctype.h>
#include <dirent.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/*
 * This tool is essentially an extended version of ps with JSON output.
 * Its output is meant consumed by scripts / tools for gathering OS/ps stats.
 * Output units:
 *   All times are expressed in ticks.
 *   All memory counters are expressed in Kb.
 */

static void dump_time(void) {
  float uptime_secs = 0.0F;
  const long rate = sysconf(_SC_CLK_TCK);
  FILE *f = fopen("/proc/uptime", "r");
  if (!f)
    return;
  fscanf(f, "%f", &uptime_secs);
  fclose(f);
  const long ticks = (long) (rate * uptime_secs);
  printf("  \"time\": { \"ticks\": %ld, \"rate\": %ld}", ticks, rate);
}

static void dump_cpu_stats(void) {
  FILE *f = fopen("/proc/stat", "r");
  if (!f)
    return;
  printf("  \"cpu\":\n  [\n");

  bool terminate_prev_line = false;
  while (!feof(f)) {
    char line[256];
    char cpu[8];
    long unsigned t_usr = 0;
    long unsigned t_nice = 0;
    long unsigned t_sys = 0;
    long unsigned t_idle = 0;
    fgets(line, sizeof(line), f);

    /* Skip the total 'cpu ' line and the other irrelevant ones. */
    if (strncmp(line, "cpu", 3) != 0 || line[3] == ' ')
      continue;
    if (sscanf(line, "%s %lu %lu %lu %lu",
               cpu, &t_usr, &t_nice, &t_sys, &t_idle) != 5) {
      continue;
    }

    if (terminate_prev_line)
      printf(",\n");
    terminate_prev_line = true;
    printf("    {\"usr\": %lu, \"sys\": %lu, \"idle\": %lu}",
           t_usr + t_nice, t_sys, t_idle);
  }
  fclose(f);
  printf("\n  ]");
}

static void dump_mem_stats(void) {
  FILE *f = fopen("/proc/meminfo", "r");
  if (!f)
    return;
  printf("  \"mem\":\n  {\n");

  bool terminate_prev_line = false;
  while (!feof(f)) {
    char line[256];
    char key[32];
    long value = 0;

    fgets(line, sizeof(line), f);
    if (sscanf(line, "%s %lu %*s", key, &value) < 2)
      continue;

    if (terminate_prev_line)
      printf(",\n");
    terminate_prev_line = true;
    printf("    \"%s\": %lu", key, value);
  }
  fclose(f);
  printf("\n  }");
}

static void dump_proc_stats(void) {
  struct dirent *de;
  DIR *d = opendir("/proc");
  if (!d)
    return;

  const long kb_per_page = sysconf(_SC_PAGESIZE) / 1024;
  bool terminate_prev_line = false;
  printf("  \"processes\":\n  {\n");
  while ((de = readdir(d))) {
    if (!isdigit(de->d_name[0]))
      continue;
    const int pid = atoi(de->d_name);

    /* Don't print out ourselves (how civilized). */
    if (pid == getpid())
      continue;

    char cmdline[64];
    char fpath[32];
    FILE *f;

    /* Read full process path / package from cmdline. */
    sprintf(fpath, "/proc/%d/cmdline", pid);
    f = fopen(fpath, "r");
    if (!f)
      continue;
    cmdline[0] = '\0';
    fgets(cmdline, sizeof(cmdline), f);
    fclose(f);

    /* Read cpu/io/mem stats. */
    char proc_name[256];
    long num_threads = 0;
    long unsigned min_faults = 0;
    long unsigned maj_faults = 0;
    long unsigned utime = 0;
    long unsigned ktime = 0;
    long unsigned vm_rss = 0;
    long long unsigned start_time = 0;

    sprintf(fpath, "/proc/%d/stat", pid);
    f = fopen(fpath, "r");
    if (!f)
      continue;
    fscanf(f, "%*d %s %*c %*d %*d %*d %*d %*d %*u %lu %*u %lu %*u %lu %lu "
           "%*d %*d %*d %*d %ld %*d %llu %*u %ld", proc_name, &min_faults,
           &maj_faults, &utime, &ktime, &num_threads, &start_time, &vm_rss);
    fclose(f);

    /* Prefer the cmdline when available, since it contains the package name. */
    char const * const cmd = (strlen(cmdline) > 0) ? cmdline : proc_name;

    if (terminate_prev_line)
      printf(",\n");
    terminate_prev_line = true;
    printf("   \"%d\": {"
           "\"name\": \"%s\", "
           "\"n_threads\": %ld, "
           "\"start_time\": %llu, "
           "\"user_time\": %lu, "
           "\"sys_time\": %lu, "
           "\"min_faults\": %lu, "
           "\"maj_faults\": %lu, "
           "\"vm_rss\": %lu"
           "}",
           pid,
           cmd,
           num_threads,
           start_time,
           utime,
           ktime,
           min_faults,
           maj_faults,
           vm_rss * kb_per_page);
  }
  closedir(d);
  printf("\n  }");
}

int main()
{
  printf("{\n");

  dump_time();
  printf(",\n");

  dump_mem_stats();
  printf(",\n");

  dump_cpu_stats();
  printf(",\n");

  dump_proc_stats();
  printf("\n}\n");

  return 0;
}
