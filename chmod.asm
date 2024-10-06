BITS 64

; Copyright (C) Joshua Hudson 2023

%include 'header.inc'

_start:
	pop	rax
	cmp	rax, 3
	jne	.usage
	pop	rsi
	pop	rsi
	xor	ecx, ecx
	xor	eax, eax
.loop	lodsb
	cmp	al, 0
	je	.eos
	sub	al, '0'
	jb	.usage
	cmp	al, 8
	jae	.usage
	shl	ecx, 3
	or	ecx, eax
	jmp	.loop
.eos	mov	esi, ecx
	pop	rdi
	xor	eax, eax
	mov	al, 90
	syscall
	neg	eax
	jz	.ok
	push	rax
	lea	rsi, [rel error]
	mov	rdx, 7
.mxit	mov	edi, 2
	mov	rax, 1
	syscall
	pop	rax
.ok	xchg	eax, edi
	xor	eax, eax
	mov	al, 60
	syscall
.usage	xor	eax, eax
	mov	al, 14
	push	rax
	lea	rsi, [rel usage]
	mov	rdx, usageln
	jmp	.mxit

usage	db	'Usage: chmod nnnn file', 10
usageln	equ	$ - usage
error	db	'Error!', 10

_eop:
