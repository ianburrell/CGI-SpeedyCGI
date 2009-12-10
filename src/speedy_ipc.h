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

#define LISTEN_BACKLOG		2

void speedy_ipc_listen(slotnum_t slotnum);
void speedy_ipc_listen_fixfd(slotnum_t slotnum);
void speedy_ipc_unlisten();
int speedy_ipc_connect(slotnum_t slotnum, int s, int e);
void speedy_ipc_connect_prepare(int *s, int *e);
int speedy_ipc_accept_ready(int wakeup);
int speedy_ipc_accept(int wakeup);
void speedy_ipc_cleanup(slotnum_t slotnum);
