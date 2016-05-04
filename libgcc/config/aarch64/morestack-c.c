/* AArch64 support for -fsplit-stack.
 * Copyright (C) 2019 Free Software Foundation, Inc.
 *
 * This file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 3, or (at your option) any
 * later version.
 *
 * This file is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * Under Section 7 of GPL version 3, you are granted additional
 * permissions described in the GCC Runtime Library Exception, version
 * 3.1, as published by the Free Software Foundation.
 *
 * You should have received a copy of the GNU General Public License and
 * a copy of the GCC Runtime Library Exception along with this program;
 * see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#ifndef inhibit_libc

#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include "generic-morestack.h"

#define INITIAL_STACK_SIZE  0x4000
#define BACKOFF             0x1000

void __generic_morestack_set_initial_sp (void *sp, size_t len);
void *__morestack_get_guard (void);
void __morestack_set_guard (void *);
void *__morestack_make_guard (void *stack, size_t size);
void __morestack_load_mmap (void);

/* split-stack area position from thread pointer.  */
static inline void *
ss_pointer (void)
{
#define SS_OFFSET	(-8)
  return (void*) ((uintptr_t) __builtin_thread_pointer() + SS_OFFSET);
}

/* Initialize the stack guard when the program starts or when a new
   thread.  This is called from a constructor using ctors section.  */
void
__stack_split_initialize (void)
{
  register uintptr_t* sp __asm__ ("sp");
  uintptr_t *ss = ss_pointer ();
  *ss = (uintptr_t)sp - INITIAL_STACK_SIZE;
  __generic_morestack_set_initial_sp (sp, INITIAL_STACK_SIZE);
}

/* Return current __private_ss.  */
void *
__morestack_get_guard (void)
{
  void **ss = ss_pointer ();
  return *ss;
}

/* Set __private_ss to ptr.  */
void
__morestack_set_guard (void *ptr)
{
  void **ss = ss_pointer ();
  *ss = ptr;
}

/* Return the stack guard value for given stack.  */
void *
__morestack_make_guard (void *stack, size_t size)
{
  return (void*)((uintptr_t) stack - size + BACKOFF);
}

/* Make __stack_split_initialize a high priority constructor.  */
static void (*const ctors []) 
  __attribute__ ((used, section (".ctors.65535"), aligned (sizeof (void *))))
  = { __stack_split_initialize, __morestack_load_mmap };

#endif /* !defined (inhibit_libc) */
