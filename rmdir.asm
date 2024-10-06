BITS 64

; Copyright (C) Joshua Hudson 2024

%include 'header.inc'

_start:
	pop	rax
	cmp	rax, 2
	jne	.usage
	pop	rdi
	pop	rdi
	mov	eax, 84
	syscall
	test	rax, rax
	jl	.errn
	xchg	rax, rdi
	jmp	.exit
.errn	neg	eax
	jz	.ok
.error	push	rax
	lea	rsi, [rel error]
	mov	rdx, 7
.mxit	mov	edi, 2
	mov	rax, 1
	syscall
	pop	rax
.ok	xchg	eax, edi
.exit	xor	eax, eax
	mov	al, 60
	syscall
.usage	xor	eax, eax
	mov	al, 14
	push	rax
	lea	rsi, [rel usage]
	mov	rdx, usageln
	jmp	.mxit

usage	db	'Usage: rmdir dir', 10
usageln	equ	$ - usage
error	db	'Error!', 10

_eop:
