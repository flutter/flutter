/*
 * Copyright 2003 Niels Provos <provos@citi.umich.edu>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * Mon 03/10/2003 - Modified by Davide Libenzi <davidel@xmailserver.org>
 *
 *     Added chain event propagation to improve the sensitivity of
 *     the measure respect to the event loop efficency.
 *
 *
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#ifdef WIN32
#include <windows.h>
#else
#include <sys/socket.h>
#include <signal.h>
#include <sys/resource.h>
#endif
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <event.h>
#include <evutil.h>


static int count, writes, fired;
static int *pipes;
static int num_pipes, num_active, num_writes;
static struct event *events;

static void
read_cb(int fd, short which, void *arg)
{
	long idx = (long) arg, widx = idx + 1;
	u_char ch;

	count += read(fd, &ch, sizeof(ch));
	if (writes) {
		if (widx >= num_pipes)
			widx -= num_pipes;
		write(pipes[2 * widx + 1], "e", 1);
		writes--;
		fired++;
	}
}

static struct timeval *
run_once(void)
{
	int *cp, space;
	long i;
	static struct timeval ts, te;

	for (cp = pipes, i = 0; i < num_pipes; i++, cp += 2) {
		event_del(&events[i]);
		event_set(&events[i], cp[0], EV_READ | EV_PERSIST, read_cb, (void *) i);
		event_add(&events[i], NULL);
	}

	event_loop(EVLOOP_ONCE | EVLOOP_NONBLOCK);

	fired = 0;
	space = num_pipes / num_active;
	space = space * 2;
	for (i = 0; i < num_active; i++, fired++)
		write(pipes[i * space + 1], "e", 1);

	count = 0;
	writes = num_writes;
	{ int xcount = 0;
	gettimeofday(&ts, NULL);
	do {
		event_loop(EVLOOP_ONCE | EVLOOP_NONBLOCK);
		xcount++;
	} while (count != fired);
	gettimeofday(&te, NULL);

	if (xcount != count) fprintf(stderr, "Xcount: %d, Rcount: %d\n", xcount, count);
	}

	evutil_timersub(&te, &ts, &te);

	return (&te);
}

int
main (int argc, char **argv)
{
#ifndef WIN32
	struct rlimit rl;
#endif
	int i, c;
	struct timeval *tv;
	int *cp;

	num_pipes = 100;
	num_active = 1;
	num_writes = num_pipes;
	while ((c = getopt(argc, argv, "n:a:w:")) != -1) {
		switch (c) {
		case 'n':
			num_pipes = atoi(optarg);
			break;
		case 'a':
			num_active = atoi(optarg);
			break;
		case 'w':
			num_writes = atoi(optarg);
			break;
		default:
			fprintf(stderr, "Illegal argument \"%c\"\n", c);
			exit(1);
		}
	}

#ifndef WIN32
	rl.rlim_cur = rl.rlim_max = num_pipes * 2 + 50;
	if (setrlimit(RLIMIT_NOFILE, &rl) == -1) {
		perror("setrlimit");
		exit(1);
	}
#endif

	events = calloc(num_pipes, sizeof(struct event));
	pipes = calloc(num_pipes * 2, sizeof(int));
	if (events == NULL || pipes == NULL) {
		perror("malloc");
		exit(1);
	}

	event_init();

	for (cp = pipes, i = 0; i < num_pipes; i++, cp += 2) {
#ifdef USE_PIPES
		if (pipe(cp) == -1) {
#else
		if (evutil_socketpair(AF_UNIX, SOCK_STREAM, 0, cp) == -1) {
#endif
			perror("pipe");
			exit(1);
		}
	}

	for (i = 0; i < 25; i++) {
		tv = run_once();
		if (tv == NULL)
			exit(1);
		fprintf(stdout, "%ld\n",
			tv->tv_sec * 1000000L + tv->tv_usec);
	}

	exit(0);
}
