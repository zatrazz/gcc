# AArch64 support for -fsplit-stack.
# Copyright (C) 2019 Free Software Foundation, Inc.

# This file is part of GCC.

# GCC is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.

# GCC is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# Under Section 7 of GPL version 3, you are granted additional
# permissions described in the GCC Runtime Library Exception, version
# 3.1, as published by the Free Software Foundation.

# You should have received a copy of the GNU General Public License and
# a copy of the GCC Runtime Library Exception along with this program;
# see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
# <http://www.gnu.org/licenses/>.

/* Define an entry point visible from C.  */
#define ENTRY(name)						\
  .globl name;							\
  .type name,%function;						\
  .align 4;							\
  name##:

#define END(name)						\
  .size name,.-name

/* __morestack frame size.  */
#define MORESTACK_FRAMESIZE	112
/* Offset from __morestack frame where the new stack size is saved and
   passed to __generic_morestack.  */
#define NEWSTACK_SAVE		96

# Excess space needed to call ld.so resolver for lazy plt resolution.
# Go uses sigaltstack so this doesn't need to also cover signal frame size.
#define BACKOFF			0x1000
# Large excess allocated when calling non-split-stack code.
#define NON_SPLIT_STACK		0x100000

/* split-stack area position from thread pointer.  */
#define SPLITSTACK_PTR_TP	-8

	.text
ENTRY(__morestack_non_split)
	.cfi_startproc
# We use a cleanup to restore the TCB split stack field if an exception is
# through this code.
	sub	x10, x10, NON_SPLIT_STACK
	.cfi_endproc
END(__morestack_non_split)
# Fall through into __morestack

# This function is called with non-standard calling conventions, on entry
# x10 is the requested stack pointer.  The split-stack prologue is in the
# form:
#
# function:
#	mrs    x9, tpidr_el0
#	ldur   x9, [x9, #-8]
#	mov    x10, <required stack allocation>
#	movk   x10, #0x0, lsl #16
#	sub    x10, sp, x10
#	mov    x11, sp   	# if function has stacked arguments
#	adrp   x12, main_fn_entry
#	add    x12, x12, :lo12:.L2
#	cmp    x9, x10
#	b.lt   <main_fn_entry>
#	b      __morestack
# main_fn_entry:
#	[function prologue]
#
# The N bit is also restored to indicate that the function is called
# (so the prologue addition can set up the argument pointer correctly).

ENTRY(__morestack)
.LFB1:
	.cfi_startproc

#ifdef __PIC__
	.cfi_personality 0x9b,DW.ref.__gcc_personality_v0
	.cfi_lsda 0x1b,.LLSDA1
#else
	.cfi_personality 0x3,__gcc_personality_v0
	.cfi_lsda 0x3,.LLSDA1
#endif
	# Calculate requested stack size.
	sub	x10, sp, x10

	# Save parameters
	stp	x29, x30, [sp, -MORESTACK_FRAMESIZE]!
	.cfi_def_cfa_offset MORESTACK_FRAMESIZE
	.cfi_offset 29, -MORESTACK_FRAMESIZE
	.cfi_offset 30, -MORESTACK_FRAMESIZE+8
	add	x29, sp, 0
	.cfi_def_cfa_register 29
	# Adjust the requested stack size for the frame pointer save.
	stp	x0, x1, [x29, 16]
	stp	x2, x3, [x29, 32]
	add	x10, x10, BACKOFF
	stp	x4, x5, [x29, 48]
	stp	x6, x7, [x29, 64]
	stp 	x8, x12, [x29, 80]
	str	x10, [x29, 96]

	# void __morestack_block_signals (void)
	bl	__morestack_block_signals

	# void *__generic_morestack (size_t *pframe_size,
	#			     void *old_stack,
	#			     size_t param_size)
	# pframe_size: is the size of the required stack frame (the function
	#	       amount of space remaining on the allocated stack).
	# old_stack: points at the parameters the old stack
	# param_size: size in bytes of parameters to copy to the new stack.
	add	x0, x29, NEWSTACK_SAVE
	add	x1, x29, MORESTACK_FRAMESIZE
	mov	x2, 0
	bl	__generic_morestack

	# Start using new stack
	mov	sp, x0

	# Set __private_ss stack guard for the new stack.
	ldr	x9, [x29, NEWSTACK_SAVE]
	add	x0, x0, BACKOFF
	sub	x0, x0, x9
.LEHB0:
	mrs	x1, tpidr_el0
	str	x0, [x1, SPLITSTACK_PTR_TP]

	# void __morestack_unblock_signals (void)
	bl	__morestack_unblock_signals

	# Set up for a call to the target function.
	ldp	x0, x1, [x29, 16]
	ldp	x2, x3, [x29, 32]
	ldp	x4, x5, [x29, 48]
	ldp	x6, x7, [x29, 64]
	ldp	x8, x12, [x29, 80]
	add	x11, x29, MORESTACK_FRAMESIZE
	# Indicate __morestack was called.
	cmp	x12, 0
	blr	x12

	stp	x0, x1, [x29, 16]
	stp	x2, x3, [x29, 32]
	stp	x4, x5, [x29, 48]
	stp	x6, x7, [x29, 64]

	bl	__morestack_block_signals

	# void *__generic_releasestack (size_t *pavailable)
	add	x0, x29, NEWSTACK_SAVE
	bl	__generic_releasestack

	# Reset __private_ss stack guard to value for old stack
	ldr	x9, [x29, NEWSTACK_SAVE]
	add	x0, x0, BACKOFF
	sub	x0, x0, x9

	# Update TCB split stack field
.LEHE0:
	mrs	x1, tpidr_el0
	str	x0, [x1, SPLITSTACK_PTR_TP]

	bl __morestack_unblock_signals

	# Use old stack again.
	add	sp, x29, MORESTACK_FRAMESIZE

	ldp	x0, x1, [x29, 16]
	ldp	x2, x3, [x29, 32]
	ldp	x4, x5, [x29, 48]
	ldp	x6, x7, [x29, 64]
	ldp	x29, x30, [x29]

	.cfi_remember_state
	.cfi_restore 30
	.cfi_restore 29
	.cfi_def_cfa 31, 0

	ret

# This is the cleanup code called by the stack unwinder when
# unwinding through code between .LEHB0 and .LEHE0 above.
cleanup:
	.cfi_restore_state
	# Reuse the new stack allocation to save/restore the
	# exception header
	str	x0, [x29, NEWSTACK_SAVE]
	# size_t __generic_findstack (void *stack)
	add	x0, x29, MORESTACK_FRAMESIZE
	bl	__generic_findstack
	sub	x0, x29, x0
	add	x0, x0, BACKOFF
	# Restore split-stack guard value
	mrs	x1, tpidr_el0
	str	x0, [x1, SPLITSTACK_PTR_TP]
	ldr	x0, [x29, NEWSTACK_SAVE]
	b	_Unwind_Resume
        .cfi_endproc
END(__morestack)

	.section .gcc_except_table,"a",@progbits
	.align 4
.LLSDA1:
	# @LPStart format (omit)
        .byte   0xff
	# @TType format (omit)
        .byte   0xff
	# Call-site format (uleb128)
        .byte   0x1
	# Call-site table length
        .uleb128 .LLSDACSE1-.LLSDACSB1
.LLSDACSB1:
	# region 0 start
        .uleb128 .LEHB0-.LFB1
	# length
        .uleb128 .LEHE0-.LEHB0
	# landing pad
        .uleb128 cleanup-.LFB1
	# no action (ie a cleanup)
        .uleb128 0
.LLSDACSE1:


	.global __gcc_personality_v0
#ifdef __PIC__
	# Build a position independent reference to the personality function.
	.hidden DW.ref.__gcc_personality_v0
	.weak   DW.ref.__gcc_personality_v0
	.section .data.DW.ref.__gcc_personality_v0,"awG",@progbits,DW.ref.__gcc_personality_v0,comdat
	.type   DW.ref.__gcc_personality_v0, @object
	.align 3
DW.ref.__gcc_personality_v0:
	.size   DW.ref.__gcc_personality_v0, 8
	.quad   __gcc_personality_v0
#endif

	.section .note.GNU-stack,"",@progbits
	.section .note.GNU-split-stack,"",@progbits
	.section .note.GNU-no-split-stack,"",@progbits
