/*
 * Copyright (C) 2003  Sam Horrocks
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

typedef struct _CopyBuf {
    CircBuf	circ;
    int		maxsz;
    int		eof;
    int		rdfd;
    int		wrfd;
    int		write_err;
} CopyBuf;

#define speedy_cb_write_err(cb)	((cb)->write_err + 0)
#define speedy_cb_eof(cb)	((cb)->eof + 0)
#define speedy_cb_seteof(cb)	do { (cb)->eof = 1;} while (0)
#define speedy_cb_data_len(cb)	(speedy_circ_data_len(&(cb)->circ))
#define speedy_cb_free_len(cb)	((cb)->maxsz - speedy_cb_data_len(cb))
#define speedy_cb_canread(cb)	\
    (speedy_cb_free_len(cb) && !speedy_cb_eof(cb) && !speedy_cb_write_err(cb))
#define speedy_cb_canwrite(cb)	\
    (speedy_cb_data_len(cb) && !speedy_cb_write_err(cb))
#define speedy_cb_copydone(cb)	\
    ((speedy_cb_eof(cb) && !speedy_cb_data_len(cb)) || speedy_cb_write_err(cb))
#define speedy_cb_set_write_err(cb, e) \
    do {(cb)->write_err = (e);} while (0)
#define speedy_cb_setfd(cb, r, w) \
    do { (cb)->rdfd = (r); (cb)->wrfd = (w); } while (0)
	

void speedy_cb_init(
    CopyBuf *cb, int maxsz, int rdfd, int wrfd, const SpeedyBuf *contents
);
void speedy_cb_free(CopyBuf *cb);
void speedy_cb_read(CopyBuf *cb);
void speedy_cb_write(CopyBuf *cb);
int  speedy_cb_shift(CopyBuf *cb);
