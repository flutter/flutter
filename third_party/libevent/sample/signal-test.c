/*
 * Compile with:
 * cc -I/usr/local/include -o signal-test \
 *   signal-test.c -L/usr/local/lib -levent
 */

#include <sys/types.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/stat.h>
#ifndef WIN32
#include <sys/queue.h>
#include <unistd.h>
#include <sys/time.h>
#else
#include <windows.h>
#endif
#include <signal.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <event.h>

int called = 0;

static void
signal_cb(int fd, short event, void *arg)
{
	struct event *signal = arg;

	printf("%s: got signal %d\n", __func__, EVENT_SIGNAL(signal));

	if (called >= 2)
		event_del(signal);
	
	called++;
}

int
main (int argc, char **argv)
{
	struct event signal_int;
 
	/* Initalize the event library */
	event_init();

	/* Initalize one event */
	event_set(&signal_int, SIGINT, EV_SIGNAL|EV_PERSIST, signal_cb,
	    &signal_int);

	event_add(&signal_int, NULL);

	event_dispatch();

	return (0);
}

