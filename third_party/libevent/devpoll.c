/*
 * Copyright 2000-2004 Niels Provos <provos@citi.umich.edu>
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
 * 3. The name of the author may not be used to endorse or promote products
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
 */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/types.h>
#include <sys/resource.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#else
#include <sys/_libevent_time.h>
#endif
#include <sys/queue.h>
#include <sys/devpoll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>

#include "event.h"
#include "event-internal.h"
#include "evsignal.h"
#include "log.h"

/* due to limitations in the devpoll interface, we need to keep track of
 * all file descriptors outself.
 */
struct evdevpoll {
	struct event *evread;
	struct event *evwrite;
};

struct devpollop {
	struct evdevpoll *fds;
	int nfds;
	struct pollfd *events;
	int nevents;
	int dpfd;
	struct pollfd *changes;
	int nchanges;
};

static void *devpoll_init	(struct event_base *);
static int devpoll_add	(void *, struct event *);
static int devpoll_del	(void *, struct event *);
static int devpoll_dispatch	(struct event_base *, void *, struct timeval *);
static void devpoll_dealloc	(struct event_base *, void *);

const struct eventop devpollops = {
	"devpoll",
	devpoll_init,
	devpoll_add,
	devpoll_del,
	devpoll_dispatch,
	devpoll_dealloc,
	1 /* need reinit */
};

#define NEVENT	32000

static int
devpoll_commit(struct devpollop *devpollop)
{
	/*
	 * Due to a bug in Solaris, we have to use pwrite with an offset of 0.
	 * Write is limited to 2GB of data, until it will fail.
	 */
	if (pwrite(devpollop->dpfd, devpollop->changes,
		sizeof(struct pollfd) * devpollop->nchanges, 0) == -1)
		return(-1);

	devpollop->nchanges = 0;
	return(0);
}

static int
devpoll_queue(struct devpollop *devpollop, int fd, int events) {
	struct pollfd *pfd;

	if (devpollop->nchanges >= devpollop->nevents) {
		/*
		 * Change buffer is full, must commit it to /dev/poll before 
		 * adding more 
		 */
		if (devpoll_commit(devpollop) != 0)
			return(-1);
	}

	pfd = &devpollop->changes[devpollop->nchanges++];
	pfd->fd = fd;
	pfd->events = events;
	pfd->revents = 0;

	return(0);
}

static void *
devpoll_init(struct event_base *base)
{
	int dpfd, nfiles = NEVENT;
	struct rlimit rl;
	struct devpollop *devpollop;

	/* Disable devpoll when this environment variable is set */
	if (evutil_getenv("EVENT_NODEVPOLL"))
		return (NULL);

	if (!(devpollop = calloc(1, sizeof(struct devpollop))))
		return (NULL);

	if (getrlimit(RLIMIT_NOFILE, &rl) == 0 &&
	    rl.rlim_cur != RLIM_INFINITY)
		nfiles = rl.rlim_cur;

	/* Initialize the kernel queue */
	if ((dpfd = open("/dev/poll", O_RDWR)) == -1) {
                event_warn("open: /dev/poll");
		free(devpollop);
		return (NULL);
	}

	devpollop->dpfd = dpfd;

	/* Initialize fields */
	devpollop->events = calloc(nfiles, sizeof(struct pollfd));
	if (devpollop->events == NULL) {
		free(devpollop);
		close(dpfd);
		return (NULL);
	}
	devpollop->nevents = nfiles;

	devpollop->fds = calloc(nfiles, sizeof(struct evdevpoll));
	if (devpollop->fds == NULL) {
		free(devpollop->events);
		free(devpollop);
		close(dpfd);
		return (NULL);
	}
	devpollop->nfds = nfiles;

	devpollop->changes = calloc(nfiles, sizeof(struct pollfd));
	if (devpollop->changes == NULL) {
		free(devpollop->fds);
		free(devpollop->events);
		free(devpollop);
		close(dpfd);
		return (NULL);
	}

	evsignal_init(base);

	return (devpollop);
}

static int
devpoll_recalc(struct event_base *base, void *arg, int max)
{
	struct devpollop *devpollop = arg;

	if (max >= devpollop->nfds) {
		struct evdevpoll *fds;
		int nfds;

		nfds = devpollop->nfds;
		while (nfds <= max)
			nfds <<= 1;

		fds = realloc(devpollop->fds, nfds * sizeof(struct evdevpoll));
		if (fds == NULL) {
			event_warn("realloc");
			return (-1);
		}
		devpollop->fds = fds;
		memset(fds + devpollop->nfds, 0,
		    (nfds - devpollop->nfds) * sizeof(struct evdevpoll));
		devpollop->nfds = nfds;
	}

	return (0);
}

static int
devpoll_dispatch(struct event_base *base, void *arg, struct timeval *tv)
{
	struct devpollop *devpollop = arg;
	struct pollfd *events = devpollop->events;
	struct dvpoll dvp;
	struct evdevpoll *evdp;
	int i, res, timeout = -1;

	if (devpollop->nchanges)
		devpoll_commit(devpollop);

	if (tv != NULL)
		timeout = tv->tv_sec * 1000 + (tv->tv_usec + 999) / 1000;

	dvp.dp_fds = devpollop->events;
	dvp.dp_nfds = devpollop->nevents;
	dvp.dp_timeout = timeout;

	res = ioctl(devpollop->dpfd, DP_POLL, &dvp);

	if (res == -1) {
		if (errno != EINTR) {
			event_warn("ioctl: DP_POLL");
			return (-1);
		}

		evsignal_process(base);
		return (0);
	} else if (base->sig.evsignal_caught) {
		evsignal_process(base);
	}

	event_debug(("%s: devpoll_wait reports %d", __func__, res));

	for (i = 0; i < res; i++) {
		int which = 0;
		int what = events[i].revents;
		struct event *evread = NULL, *evwrite = NULL;

		assert(events[i].fd < devpollop->nfds);
		evdp = &devpollop->fds[events[i].fd];
   
                if (what & POLLHUP)
                        what |= POLLIN | POLLOUT;
                else if (what & POLLERR)
                        what |= POLLIN | POLLOUT;

		if (what & POLLIN) {
			evread = evdp->evread;
			which |= EV_READ;
		}

		if (what & POLLOUT) {
			evwrite = evdp->evwrite;
			which |= EV_WRITE;
		}

		if (!which)
			continue;

		if (evread != NULL && !(evread->ev_events & EV_PERSIST))
			event_del(evread);
		if (evwrite != NULL && evwrite != evread &&
		    !(evwrite->ev_events & EV_PERSIST))
			event_del(evwrite);

		if (evread != NULL)
			event_active(evread, EV_READ, 1);
		if (evwrite != NULL)
			event_active(evwrite, EV_WRITE, 1);
	}

	return (0);
}


static int
devpoll_add(void *arg, struct event *ev)
{
	struct devpollop *devpollop = arg;
	struct evdevpoll *evdp;
	int fd, events;

	if (ev->ev_events & EV_SIGNAL)
		return (evsignal_add(ev));

	fd = ev->ev_fd;
	if (fd >= devpollop->nfds) {
		/* Extend the file descriptor array as necessary */
		if (devpoll_recalc(ev->ev_base, devpollop, fd) == -1)
			return (-1);
	}
	evdp = &devpollop->fds[fd];

	/* 
	 * It's not necessary to OR the existing read/write events that we
	 * are currently interested in with the new event we are adding.
	 * The /dev/poll driver ORs any new events with the existing events
	 * that it has cached for the fd.
	 */

	events = 0;
	if (ev->ev_events & EV_READ) {
		if (evdp->evread && evdp->evread != ev) {
		   /* There is already a different read event registered */
		   return(-1);
		}
		events |= POLLIN;
	}

	if (ev->ev_events & EV_WRITE) {
		if (evdp->evwrite && evdp->evwrite != ev) {
		   /* There is already a different write event registered */
		   return(-1);
		}
		events |= POLLOUT;
	}

	if (devpoll_queue(devpollop, fd, events) != 0)
		return(-1);

	/* Update events responsible */
	if (ev->ev_events & EV_READ)
		evdp->evread = ev;
	if (ev->ev_events & EV_WRITE)
		evdp->evwrite = ev;

	return (0);
}

static int
devpoll_del(void *arg, struct event *ev)
{
	struct devpollop *devpollop = arg;
	struct evdevpoll *evdp;
	int fd, events;
	int needwritedelete = 1, needreaddelete = 1;

	if (ev->ev_events & EV_SIGNAL)
		return (evsignal_del(ev));

	fd = ev->ev_fd;
	if (fd >= devpollop->nfds)
		return (0);
	evdp = &devpollop->fds[fd];

	events = 0;
	if (ev->ev_events & EV_READ)
		events |= POLLIN;
	if (ev->ev_events & EV_WRITE)
		events |= POLLOUT;

	/*
	 * The only way to remove an fd from the /dev/poll monitored set is
	 * to use POLLREMOVE by itself.  This removes ALL events for the fd 
	 * provided so if we care about two events and are only removing one 
	 * we must re-add the other event after POLLREMOVE.
	 */

	if (devpoll_queue(devpollop, fd, POLLREMOVE) != 0)
		return(-1);

	if ((events & (POLLIN|POLLOUT)) != (POLLIN|POLLOUT)) {
		/*
		 * We're not deleting all events, so we must resubmit the
		 * event that we are still interested in if one exists.
		 */

		if ((events & POLLIN) && evdp->evwrite != NULL) {
			/* Deleting read, still care about write */
			devpoll_queue(devpollop, fd, POLLOUT);
			needwritedelete = 0;
		} else if ((events & POLLOUT) && evdp->evread != NULL) {
			/* Deleting write, still care about read */
			devpoll_queue(devpollop, fd, POLLIN);
			needreaddelete = 0;
		}
	}

	if (needreaddelete)
		evdp->evread = NULL;
	if (needwritedelete)
		evdp->evwrite = NULL;

	return (0);
}

static void
devpoll_dealloc(struct event_base *base, void *arg)
{
	struct devpollop *devpollop = arg;

	evsignal_dealloc(base);
	if (devpollop->fds)
		free(devpollop->fds);
	if (devpollop->events)
		free(devpollop->events);
	if (devpollop->changes)
		free(devpollop->changes);
	if (devpollop->dpfd >= 0)
		close(devpollop->dpfd);

	memset(devpollop, 0, sizeof(struct devpollop));
	free(devpollop);
}
