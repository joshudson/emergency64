BITS 64

; Copyright (C) Joshua Hudson 2023

%include 'header.inc'

_start:
	pop	rax
	cmp	rax, 3
	jne	.usage
	pop	rdi
	pop	rdi
	pop	rsi
	xor	eax, eax
	mov	al, 88
	syscall
	neg	eax
	jz	.ok
	push	rax
	lea	rsi, [error]
	mov	rdx, 7
.mxit	mov	edi, 2
	mov	rax, 1
	syscall
	pop	rax
.ok	xchg	eax, edi
.exit	mov	eax, 60
	syscall
.usage	xor	eax, eax
	mov	al, 14
	lea	rsi, [usage]
	mov	rdx, usageln
	jmp	.mxit

usage	db	'Usage: sln src dst', 10
usageln	equ	$ - usage
error	db	'Error!', 10

_eop:
