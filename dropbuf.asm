BITS 64

; Copyright (C) Joshua Hudson 2023

%include 'header.inc'

_start:
	pop	rax
	cmp	rax, 2
	jne	.usage
	pop	rdi
	pop	rdi
	xor	rsi, rsi
	xor	eax, eax
	mov	al, 2
	syscall
	test	rax, rax
	jl	.errn
	xchg	rax, rdi
	mov	esi, 1261h
	xor	edx, edx
	xor	eax, eax
	mov	al, 16
	syscall
.errn	neg	eax
	jz	.ok
.error	push	rax
	lea	rsi, [rel error]
	mov	rdx, 7
.mxit	mov	edi, 2
	xor	eax, eax
	inc	eax
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

usage	db	'Usage: dropbuf device', 10
usageln	equ	$ - usage
error	db	'Error!', 10

_eop:
