BITS 64

; Copyright (C) Joshua Hudson 2024

%include 'header.inc'

_start:
	xor	r15d, r15d
	pop	rax
	pop	rdi
	shl	rax, 3
	mov	rdx, rsp
	add	rdx, rax		; for the rest of main, RDX = envp
.opt	pop	rdi
	or	rdi, rdi
	jz	.envp
	cmp	[rdi], word '-i'
	je	.empty
	cmp	[rdi], word '-'
	je	.empty
	cmp	[rdi], word '-0'
	je	.envpz
	cmp	[rdi], word '-u'
	je	.unset
	cmp	[rdi], word '-C'
	je	.chdir
	cmp	[rdi], word '-S'
	je	.str
	cmp	[rdi], word '--'
	je	.noopt
	mov	rsi, rdi
	call	strlen0
	xchg	rax, rcx
	mov	rdi, rsi
	mov	al, '='
	repne	scasb
	je	.set
	jmp	.exec
.usage	xor	edi, edi
	mov	dil, 2
	lea	rsi, [rel usage]
	mov	r12b, usagelen
	jmp	.exit2

.noopt	cmp	[rdi + 2], byte 0
	jne	.usage
	pop	rsi
	or	rsi, rsi
	jz	.envp
	jmp	.exec

.unset	pop	rdi
	or	rdi, rdi
	jz	.usage
	mov	rsi, rdi
	call	strlen0
	xchg	rax, rcx
	dec	rcx
	call	findenv
	or	rdi, rdi
	jz	.opt
.uns2	mov	rdi, [rbp + 8]
	mov	[rbp], rdi
	add	rbp, 8
	or	rdi, rdi
	jnz	.uns2
	jmp	.opt

.set	mov	rcx, rdi
	sub	rcx, rsi
	dec	rcx
	call	findenv
	or	rdi, rdi
	jz	.setnew
	mov	[rbp], rsi
	jmp	.opt
.setnew	or	rdx, rdx
	jz	.unnul
	sub	rdx, 8			; Where the new env will go
	push	rdx
	mov	r8, rsp
.snlp	mov	rdi, [r8 + 8]
	mov	[r8], rdi
	add	r8, 8
	cmp	r8, rdx
	jb	.snlp
	mov	[rdx], rsi
	jmp	.opt
.unnul	push	rsi
	push	rsi
	mov	r8, rsp
.unlp	mov	rdi, [r8 + 16]
	mov	[r8], rdi
	add	r8, 8
	or	rdi, rdi
	jnz	.unlp
	mov	rdx, r8
	mov	[rdx], rsi
	xor	esi, esi
	mov	[rdx + 8], esi
	jmp	.opt

.empty	or	rdx, rdx
	jz	.opt
	lea	rsi, [rel pathdef]		; Save old PATH env in case new env lacks
	xor	ecx, ecx
	mov	cl, pathdeflen
	call	findenv
	mov	r15, rdi
	xor	edi, edi			; env points to end of list
	mov	[rdx], rdi
	jmp	.opt

.str	add	rdi, 2
	cmp	[rdi], byte 0
	jne	.strk
	pop	rdi
	or	rdi, rdi
	jz	.usage
.strk	push	rdi
	mov	rbp, rsp
	mov	rsi, rdi
.strtok	push	rsi
.strtkl	lodsb
	cmp	al, 0
	je	.srev
	cmp	al, ' '
	jne	.strtkl
	mov	[rsi - 1], byte 0
	jmp	.strtok
.srev	mov	r8, rsp			; the new arguments are currently on the stack backwards
.srevl	cmp	r8, rbp
	jae	.opt
	mov	rsi, [r8]
	mov	rdi, [rbp]
	mov	[r8], rdi
	mov	[rbp], rsi
	add	r8, 8
	sub	rbp, 8
	jmp	.srevl

.chdir	pop	rdi
	or	rdi, rdi
	jz	.usage
	mov	al, 80
	syscall
	test	eax, eax
	jz	.opt
	lea	r15, [rel cderror]
	mov	r12b, cderror_len
	jmp	.exit

.envp	lea	r12, [rel posteq]
	jmp	.envpx
.envpz	pop	rdi
	or	rdi, rdi
	jnz	.usage
	lea	r12, [rel postnop]
.envpx	mov	rbp, rdx		; Environment out routine uses rbp instead of rdx
	mov	rdi, [rbp]
	mov	rsi, rdi
.envl	mov	rdx, rdi
	mov	rdi, [rbp]
	or	rdi, rdi
	jz	.envlx
	cmp	rdi, rdx
	je	.wctg
	call	wspan
	mov	rdi, [rbp]
	mov	rsi, rdi
.wctg	call	strf0
	call	r12
	add	rbp, 8
	jmp	.envl
.envlx	call	wspan
	xor	edi, edi
	xor	eax, eax
	mov	al, 60
	syscall

.exec	mov	rdi, rsi
	push	rdi			; for the rest of main, RSP = argv
.s0	lodsb
	cmp	al, 0
	je	.execvp
	cmp	al, '/'
	je	.execve
	jmp	.s0
.execve	mov	rdi, [rsp]
	mov	rsi, rsp
	xor	eax, eax
	mov	al, 59
	syscall
	lea	r15, [rel execerror]
	mov	r12b, execerror_len
	;jmp	.exit
.exit	mov	rsi, rdi
	call	strlen0
	dec	rax
	xchg	rax, rdx
	xor	edi, edi
	mov	dil, 2
	xor	eax, eax
	inc	eax
	syscall
	xor	eax, eax
	inc	eax
	mov	rsi, r15
.exit2	xor	edx, edx
	mov	dl, r12b
	xor	eax, eax
	inc	eax
	syscall
	xor	eax, eax
	mov	al, 60
	mov	dil, 127
	syscall
.execvp	lea	rsi, [rel pathdef]
	xor	ecx, ecx
	mov	cl, pathdeflen
	call	findenv
	or	rdi, rdi
	jnz	.hpath
	or	r15, r15		; Saved path from - if any
	jz	.execve
	mov	rdi, r15
.hpath	mov	rbp, rdi
	add	rbp, 5
	mov	rdi, [rsp]
	call	strlen0
	xchg	rax, r14
.spe	lea	r15, [rel finderror]
	mov	r12b, finderror_len
	mov	rdi, [rsp]
	cmp	[rbp], byte 0
	je	.exit
	cmp	[rbp], byte ':'
	jne	.dupl
	mov	rsi, rsp		; Current directory in PATH (rdi already set)
	xor	eax, eax
	mov	al, 59
	syscall
	inc	rbp
	jmp	.spe
.dupl	mov	rsi, rbp
	mov	r11, rsi
.spel	lodsb
	cmp	al, 0
	je	.erc1
	cmp	al, ':'
	je	.erc2
	jmp	.spel
.erc2	mov	rbp, rsi
	jmp	.erc
.erc1	mov	rbp, rsi
	dec	rbp
.erc	mov	rax, rsi
	sub	rax, r11
	dec	rax
	mov	rcx, rax		; Actual length
	add	rax, r14
	cmp	rax, 1023
	ja	.spe			; Too big, can't use this entry
	add	rax, 17			; Reserve space for exec path on stack
	not	rax
	or	rax, 15			; with alignment
	not	rax
	mov	r13, rsp
	sub	rsp, rax		; build exec path
	mov	rdi, rsp
	mov	rsi, r11
	rep	movsb
	cmp	[rdi - 1], byte '/'
	je	.hslash
	mov	al, '/'
	stosb
.hslash	mov	rsi, [r13]
	mov	rcx, r14
	rep	movsb
	mov	rdi, rsp
	mov	rsi, r13
	xor	eax, eax
	mov	al, 59
	syscall
	mov	rsp, r13
	jmp	.spe

findenv	xor	edi, edi
	or	rdx, rdx
	jz	.nom
	mov	rbp, rdx
.find	mov	rdi, [rbp]
	or	rdi, rdi
	je	.nom
	push	rcx
	push	rsi
	repe	cmpsb
	pop	rsi
	pop	rcx
	je	.match
.nope	add	rbp, 8
	jmp	.find
.match	cmp	[rdi], byte '='
	jne	.nope
	mov	rdi, [rbp]
.nom	ret

wspan	sub	rdx, rsi
	jz	.ret
	xor	edi, edi
	inc	edi
.loop	mov	eax, edi
	syscall
	test	rax, rax
	js	.error
	add	rsi, rax
	sub	rdx, rax
	ja	.loop
.ret	ret
.error	inc	edi
	lea	rsi, [stdouterror]
	xor	edx, edx
	mov	dl, stdouterror_len
	mov	eax, edi
	inc	edi
	syscall
	mov	dil, 2
	xor	eax, eax
	mov	al, 60
	syscall

strlen0	push	rdi
	call	strf0
	pop	rax
	sub	rax, rdi
	neg	rax
	ret

strf0	xor	ecx, ecx
	dec	rcx
	mov	al, 0
	repne	scasb
	ret

posteq	mov	[rdi - 1], byte 10
postnop	ret

pathdef		db	"PATH"
pathdeflen	equ	$ - pathdef
cderror		db	": can't enter", 10
cderror_len	equ	$ - cderror
execerror	db	": can't exec", 10
execerror_len	equ	$ - execerror
finderror	db	": can't find executable", 10
finderror_len	equ	$ - finderror
stdouterror	db	"can't write to stdout", 10
stdouterror_len	equ	$ - stdouterror
usage		db	"Usage: env [-S] [-[i]] {NAME=value|-u NAME|-C dir}* [{-0|program args}]", 10
usagelen	equ	$ - usage
_eop:
