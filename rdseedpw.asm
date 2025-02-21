; Copyright (C) Joshua Hudson 2025

BITS 64

%include 'header.inc'

_start:
	xor	eax, eax
	mov	al, 7
	xor	ecx, ecx
	cpuid
	shr	ebx, 18
	test	bl, 1
	jz	.noseed
	sub	rsp, 24		; Output buffer on the stack
	mov	rdi, rsp
	xor	edx, edx
	mov	dl, 2
	lea	rbx, [rel alphabet]
.gl	mov	ecx, 100
.retry	rdseed	rax
	jc	.hrnd		; Got random bits
	loop	.retry
	lea	rsi, [rel rdseedunhealthy]
	mov	edx, rdunhealthylen
.pexit	xor	edi, edi
	mov	dil, 2
.eexit	xor	eax, eax
	inc	al
	syscall
	mov	dil, 1
	jmp	.exit
.noseed	mov	edx, nordseedlen
	lea	rsi, [rel nordseed]
	jmp	.pexit
.hrnd	mov	ecx, 11
.oloop	mov	rsi, rax	; Base64 encode the result
	and	eax, 63		; Last time around the loop leaves high 2 bits clear
	xlatb			; Can't actually do any better unless dl was 3 instead of 2
	stosb
	mov	rax, rsi
	shr	rax, 6
	loop	.oloop
	dec	dl
	jnz	.gl
	mov	al, 10
	stosb			; Newline at end of buffer
	mov	rsi, rsp
	mov	rdx, rdi
	sub	rdx, rsi
	xor	edi, edi
	inc	dil
	xor	eax, eax
	inc	al
	syscall
	mov	dil, 0
	test	rax, rax
	jns	.exit
	inc	dil
.exit	xor	eax, eax
	mov	al, 60
	syscall

; Don't like the symbol choices? Change it. It's your password, retype it how you want.
alphabet	db	'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqurstuvwxyz,.'
nordseed	db	'rdseed instruction missing', 10
nordseedlen	equ	$ - nordseed
rdseedunhealthy	db	'rdseed unhealthy', 10
rdunhealthylen	equ	$ - rdseedunhealthy
_eop:
