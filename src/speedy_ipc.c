/*
 * Copyright (C) 2001  Daemon Consulting Inc.
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include "speedy.h"

#ifdef ENOBUFS
#   define NO_BUFSPC(e) ((e) == ENOBUFS || (e) == ENOMEM)
#else
#   define NO_BUFSPC(e) ((e) == ENOMEM)
#endif

static char *get_fname(slotnum_t slotnum, int do_unlink) {
    char *fname = speedy_util_fname(slotnum, 'S');
    if (do_unlink)
	unlink(fname);
    return fname;
}

static void make_sockname(
    slotnum_t slotnum, struct sockaddr_un *sa, int do_unlink
)
{
    char *fname = get_fname(slotnum, do_unlink);
    speedy_bzero(sa, sizeof(*sa));
    sa->sun_family = AF_UNIX;
    if (strlen(fname)+1 > sizeof(sa->sun_path))
	DIE_QUIET("Socket path %s is too long", fname);
    strcpy(sa->sun_path, fname);
    speedy_free(fname);
}

static int make_sock() {
    int i, fd;

    for (i = 0; i < 300; ++i) {
	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd != -1)
	    return fd;
	else if (NO_BUFSPC(errno)) {
	    sleep(1);
	    speedy_util_time_invalidate();
	}
	else
	    break;
    }
    speedy_util_die("cannot create socket");
    return -1;
}

void speedy_ipc_cleanup(slotnum_t slotnum) {
    speedy_free(get_fname(slotnum, 1));
}

#ifdef SPEEDY_BACKEND

static int		listener;
static struct stat	listener_stbuf;
static PollInfo		listener_pi;

void speedy_ipc_listen(slotnum_t slotnum) {
    struct sockaddr_un sa;

    listener = -1;
    if (PREF_FD_LISTENER != -1) {
	int namelen = sizeof(sa);
	char *fname = get_fname(slotnum, 0);
	struct stat stbuf;

	if (getsockname(PREF_FD_LISTENER, (struct sockaddr *)&sa, &namelen) != -1 &&
	    sa.sun_family == AF_UNIX &&
	    strcmp(sa.sun_path, fname) == 0 &&
	    stat(fname, &stbuf) != -1 &&
	    stbuf.st_uid == speedy_util_geteuid())
	{
	    listener = PREF_FD_LISTENER;
	}
	speedy_free(fname);
    }
    if (listener == -1) {
	mode_t saved_umask = umask(077);
	listener = make_sock(PREF_FD_LISTENER);
	make_sockname(slotnum, &sa, 1);
	if (bind(listener, (struct sockaddr*)&sa, sizeof(sa)) == -1)
	    speedy_util_die("cannot bind socket");
	umask(saved_umask);
    }
    if (listen(listener, LISTEN_BACKLOG) == -1)
	speedy_util_die("cannot listen on socket");
    fstat(listener, &listener_stbuf);
    listener = speedy_util_pref_fd(listener, PREF_FD_LISTENER);
    speedy_poll_init(&listener_pi, listener);
}

static void ipc_unlisten() {
    close(listener);
    listener = -1;
    speedy_poll_free(&listener_pi);
}

void speedy_ipc_listen_fixfd(slotnum_t slotnum) {
    struct stat stbuf;

    /* Odd compiler bug - Solaris 2.7 plus gcc 2.95.2, can't put all of
     * this into one big "if" statment - returns false constantly.  Probably
     * has something to do with 64-bit values in st_dev/st_ino
     * 2.7 bug was found on sparc. Bug does not exist on Solaris-8/intel.
     */
#ifdef WANT_SOLARIS_BUG
    if ((fstat(listener, &stbuf) == -1) ||
	(stbuf.st_dev != listener_stbuf.st_dev) ||
	(stbuf.st_ino != listener_stbuf.st_ino))
#else
    int status, test1, test2;
    status = fstat(listener, &stbuf);
    test1 = stbuf.st_dev != listener_stbuf.st_dev;
    test2 = stbuf.st_ino != listener_stbuf.st_ino;
    if (status == -1 || test1 || test2)
#endif
    {
	ipc_unlisten();
	speedy_ipc_listen(slotnum);
    }
}

static void do_accept(int pref_fd) {
    struct sockaddr_un sa;
    int namelen, sock;

    namelen = sizeof(sa);
    sock = speedy_util_pref_fd(
	accept(listener, (struct sockaddr*)&sa, &namelen), pref_fd
    );
    if (sock == -1)
	speedy_util_die("accept failed");
}

static int accept_ready(int wakeup) {
    return speedy_poll_quickwait(&listener_pi, listener, SPEEDY_POLLIN, wakeup)
	> 0;
}

int speedy_ipc_accept(int wakeup) {
    if (accept_ready(wakeup)) {
	do_accept(PREF_FD_ACCEPT_I);
	dup2(PREF_FD_ACCEPT_I, PREF_FD_ACCEPT_O);
	do_accept(PREF_FD_ACCEPT_E);
	return 1;
    }
    return 0;
}

#endif /* SPEEDY_BACKEND */

#ifdef SPEEDY_FRONTEND

static int do_connect(slotnum_t slotnum, int fd) {
    struct sockaddr_un sa;

    make_sockname(slotnum, &sa, 0);
    return connect(fd, (struct sockaddr *)&sa, sizeof(sa)) != -1;
}

void speedy_ipc_connect_prepare(int *s, int *e) {
    *s = make_sock();
    *e = make_sock();
}

int speedy_ipc_connect(slotnum_t slotnum, int s, int e) {
    if (do_connect(slotnum, s) && do_connect(slotnum, e))
	return 1;
    close(s);
    close(e);
    return 0;
}

#endif /* SPEEDY_FRONTEND */
