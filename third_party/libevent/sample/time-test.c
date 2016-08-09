/*
 * Compile with:
 * cc -I/usr/local/include -o time-test time-test.c -L/usr/local/lib -levent
 */

#include <sys/types.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/stat.h>
#ifndef WIN32
#include <sys/queue.h>
#include <unistd.h>
#endif
#include <time.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <event.h>
#include <evutil.h>

int lasttime;

static void
timeout_cb(int fd, short event, void *arg)
{
	struct timeval tv;
	struct event *timeout = arg;
	int newtime = time(NULL);

	printf("%s: called at %d: %d\n", __func__, newtime,
	    newtime - lasttime);
	lasttime = newtime;

	evutil_timerclear(&tv);
	tv.tv_sec = 2;
	event_add(timeout, &tv);
}

int
main (int argc, char **argv)
{
	struct event timeout;
	struct timeval tv;
 
	/* Initalize the event library */
	event_init();

	/* Initalize one event */
	evtimer_set(&timeout, timeout_cb, &timeout);

	evutil_timerclear(&tv);
	tv.tv_sec = 2;
	event_add(&timeout, &tv);

	lasttime = time(NULL);
	
	event_dispatch();

	return (0);
}

