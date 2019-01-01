/*
 * linux/arch/arm64/lib/sha1.S
 *
 * Copyright (C) 2014 Linaro Ltd <ard.biesheuvel@linaro.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/linkage.h>
#include <asm/assembler.h>

	.text

	k		.req	w1

	res		.req	w2
	xres		.req	x2

	wA		.req	w3
	wB		.req	w4
	wC		.req	w5
	wD		.req	w6
	wE		.req	w7

	tmp		.req	w16
	xtmp		.req	x16

	.macro		sha1_choose, out, b, c, d
	eor		\out, \c, \d
	and		\out, \out, \b
	eor		\out, \out, \d
	.endm

	.macro		sha1_parity, out, b, c, d
	eor		\out, \b, \c
	eor		\out, \out, \d
	.endm

	.macro		sha1_majority, out, b, c, d
	eor		tmp, \b, \c
	and		\out, \b, \c
	and		tmp, tmp, \d
	add		\out, \out, tmp
	.endm

	.macro		mix_state, st0, st1, st4, st6, st7
	extr		xtmp, \st7, \st6, #32
	eor		\st0, \st0, \st1
	eor		xtmp, xtmp, \st4
	eor		xtmp, xtmp, \st0
	ror		res, tmp, #(32 - 1)
	lsr		xtmp, xtmp, #32
	ror		tmp, tmp, #(32 - 1)
	orr		\st0, xres, xtmp, lsl #32
	.endm

	.macro		sha1_round, func, r, h, a, b, c, d, e
	sha1_\func	res, \b, \c, \d
	add		res, res, \e
	ror		\e, \a, #(32 - 5)
	.ifc		\h, h
	add		xres, xres, x\r, lsr #32
	.else
	add		res, res, w\r
	.endif
	add		\e, \e, k
	ror		\b, \b, #2
	add		\e, \e, res
	.endm

	/*
	 * void sha_transform(__u32 *digest, const char *data, __u32 *array)
	 */
ENTRY(sha_transform)
	/* load input into state array */
	ldp		x8, x9, [x1]
	ldp		x10, x11, [x1, #16]
	ldp		x12, x13, [x1, #32]
	ldp		x14, x15, [x1, #48]

	/* load digest input */
	ldr		wA, [x0]
	ldp		wB, wC, [x0, #4]
	ldp		wD, wE, [x0, #12]

	/* endian-reverse the input on LE builds */
CPU_LE( rev32		x8, x8		)
CPU_LE( rev32		x9, x9		)
CPU_LE( rev32		x10, x10	)
CPU_LE( rev32		x11, x11	)
CPU_LE( rev32		x12, x12	)
CPU_LE( rev32		x13, x13	)
CPU_LE( rev32		x14, x14	)
CPU_LE( rev32		x15, x15	)

	/* round 1 */
	ldr		k, =0x5a827999
	sha1_round	choose,  8, l, wA, wB, wC, wD, wE
	sha1_round	choose,  8, h, wE, wA, wB, wC, wD
	sha1_round	choose,  9, l, wD, wE, wA, wB, wC
	sha1_round	choose,  9, h, wC, wD, wE, wA, wB
	sha1_round	choose, 10, l, wB, wC, wD, wE, wA
	sha1_round	choose, 10, h, wA, wB, wC, wD, wE
	sha1_round	choose, 11, l, wE, wA, wB, wC, wD
	sha1_round	choose, 11, h, wD, wE, wA, wB, wC
	sha1_round	choose, 12, l, wC, wD, wE, wA, wB
	sha1_round	choose, 12, h, wB, wC, wD, wE, wA
	sha1_round	choose, 13, l, wA, wB, wC, wD, wE
	sha1_round	choose, 13, h, wE, wA, wB, wC, wD
	sha1_round	choose, 14, l, wD, wE, wA, wB, wC
	sha1_round	choose, 14, h, wC, wD, wE, wA, wB
	sha1_round	choose, 15, l, wB, wC, wD, wE, wA
	sha1_round	choose, 15, h, wA, wB, wC, wD, wE

	mix_state	x8, x9, x12, x14, x15
	sha1_round	choose,  8, l, wE, wA, wB, wC, wD
	sha1_round	choose,  8, h, wD, wE, wA, wB, wC
	mix_state	x9, x10, x13, x15, x8
	sha1_round	choose,  9, l, wC, wD, wE, wA, wB
	sha1_round	choose,  9, h, wB, wC, wD, wE, wA

	/* round 2 */
	ldr		k, =0x6ed9eba1
	mix_state	x10, x11, x14, x8, x9
	sha1_round	parity, 10, l, wA, wB, wC, wD, wE
	sha1_round	parity, 10, h, wE, wA, wB, wC, wD
	mix_state	x11, x12, x15, x9, x10
	sha1_round	parity, 11, l, wD, wE, wA, wB, wC
	sha1_round	parity, 11, h, wC, wD, wE, wA, wB
	mix_state	x12, x13, x8, x10, x11
	sha1_round	parity, 12, l, wB, wC, wD, wE, wA
	sha1_round	parity, 12, h, wA, wB, wC, wD, wE
	mix_state	x13, x14, x9, x11, x12
	sha1_round	parity, 13, l, wE, wA, wB, wC, wD
	sha1_round	parity, 13, h, wD, wE, wA, wB, wC
	mix_state	x14, x15, x10, x12, x13
	sha1_round	parity, 14, l, wC, wD, wE, wA, wB
	sha1_round	parity, 14, h, wB, wC, wD, wE, wA
	mix_state	x15, x8, x11, x13, x14
	sha1_round	parity, 15, l, wA, wB, wC, wD, wE
	sha1_round	parity, 15, h, wE, wA, wB, wC, wD
	mix_state	x8, x9, x12, x14, x15
	sha1_round	parity,  8, l, wD, wE, wA, wB, wC
	sha1_round	parity,  8, h, wC, wD, wE, wA, wB
	mix_state	x9, x10, x13, x15, x8
	sha1_round	parity,  9, l, wB, wC, wD, wE, wA
	sha1_round	parity,  9, h, wA, wB, wC, wD, wE
	mix_state	x10, x11, x14, x8, x9
	sha1_round	parity, 10, l, wE, wA, wB, wC, wD
	sha1_round	parity, 10, h, wD, wE, wA, wB, wC
	mix_state	x11, x12, x15, x9, x10
	sha1_round	parity, 11, l, wC, wD, wE, wA, wB
	sha1_round	parity, 11, h, wB, wC, wD, wE, wA

	/* round 3 */
	ldr		k, =0x8f1bbcdc
	mix_state	x12, x13, x8, x10, x11
	sha1_round	majority, 12, l, wA, wB, wC, wD, wE
	sha1_round	majority, 12, h, wE, wA, wB, wC, wD
	mix_state	x13, x14, x9, x11, x12
	sha1_round	majority, 13, l, wD, wE, wA, wB, wC
	sha1_round	majority, 13, h, wC, wD, wE, wA, wB
	mix_state	x14, x15, x10, x12, x13
	sha1_round	majority, 14, l, wB, wC, wD, wE, wA
	sha1_round	majority, 14, h, wA, wB, wC, wD, wE
	mix_state	x15, x8, x11, x13, x14
	sha1_round	majority, 15, l, wE, wA, wB, wC, wD
	sha1_round	majority, 15, h, wD, wE, wA, wB, wC
	mix_state	x8, x9, x12, x14, x15
	sha1_round	majority,  8, l, wC, wD, wE, wA, wB
	sha1_round	majority,  8, h, wB, wC, wD, wE, wA
	mix_state	x9, x10, x13, x15, x8
	sha1_round	majority,  9, l, wA, wB, wC, wD, wE
	sha1_round	majority,  9, h, wE, wA, wB, wC, wD
	mix_state	x10, x11, x14, x8, x9
	sha1_round	majority, 10, l, wD, wE, wA, wB, wC
	sha1_round	majority, 10, h, wC, wD, wE, wA, wB
	mix_state	x11, x12, x15, x9, x10
	sha1_round	majority, 11, l, wB, wC, wD, wE, wA
	sha1_round	majority, 11, h, wA, wB, wC, wD, wE
	mix_state	x12, x13, x8, x10, x11
	sha1_round	majority, 12, l, wE, wA, wB, wC, wD
	sha1_round	majority, 12, h, wD, wE, wA, wB, wC
	mix_state	x13, x14, x9, x11, x12
	sha1_round	majority, 13, l, wC, wD, wE, wA, wB
	sha1_round	majority, 13, h, wB, wC, wD, wE, wA

	/* round 4 */
	ldr		k, =0xca62c1d6
	mix_state	x14, x15, x10, x12, x13
	sha1_round	parity, 14, l, wA, wB, wC, wD, wE
	sha1_round	parity, 14, h, wE, wA, wB, wC, wD
	mix_state	x15, x8, x11, x13, x14
	sha1_round	parity, 15, l, wD, wE, wA, wB, wC
	sha1_round	parity, 15, h, wC, wD, wE, wA, wB
	mix_state	x8, x9, x12, x14, x15
	sha1_round	parity,  8, l, wB, wC, wD, wE, wA
	sha1_round	parity,  8, h, wA, wB, wC, wD, wE
	mix_state	x9, x10, x13, x15, x8
	sha1_round	parity,  9, l, wE, wA, wB, wC, wD
	sha1_round	parity,  9, h, wD, wE, wA, wB, wC
	mix_state	x10, x11, x14, x8, x9
	sha1_round	parity, 10, l, wC, wD, wE, wA, wB
	sha1_round	parity, 10 ,h, wB, wC, wD, wE, wA
	mix_state	x11, x12, x15, x9, x10
	sha1_round	parity, 11, l, wA, wB, wC, wD, wE
	sha1_round	parity, 11, h, wE, wA, wB, wC, wD
	mix_state	x12, x13, x8, x10, x11
	sha1_round	parity, 12, l, wD, wE, wA, wB, wC
	sha1_round	parity, 12, h, wC, wD, wE, wA, wB
	mix_state	x13, x14, x9, x11, x12
	sha1_round	parity, 13, l, wB, wC, wD, wE, wA
	sha1_round	parity, 13, h, wA, wB, wC, wD, wE
	mix_state	x14, x15, x10, x12, x13
	sha1_round	parity, 14, l, wE, wA, wB, wC, wD
	sha1_round	parity, 14, h, wD, wE, wA, wB, wC
	mix_state	x15, x8, x11, x13, x14

	/* reload digest input */
	ldr		w8, [x0]
	ldp		w9, w10, [x0, #4]
	ldp		w11, w12, [x0, #12]

	sha1_round	parity, 15, l, wC, wD, wE, wA, wB
	sha1_round	parity, 15, h, wB, wC, wD, wE, wA

	/* add this round's output to digest */
	add		wA, wA, w8
	add		wB, wB, w9
	add		wC, wC, w10
	add		wD, wD, w11
	add		wE, wE, w12

	/* store digest */
	str		wA, [x0]
	stp		wB, wC, [x0, #4]
	stp		wD, wE, [x0, #12]
	ret
ENDPROC(sha_transform)

	/*
	 * void sha_init(__u32 *buf)
	 */
ENTRY(sha_init)
	ldr	w1, =0x67452301
	ldr	w2, =0xefcdab89
	ldr	w3, =0x98badcfe
	ldr	w4, =0x10325476
	ldr	w5, =0xc3d2e1f0
	str	w1, [x0]
	stp	w2, w3, [x0, #4]
	stp	w4, w5, [x0, #12]
	ret
ENDPROC(sha_init)
