;Copyright (C) Joshua Hudson 2024

BITS 64

__NR_read	equ	0
__NR_write	equ	1
__NR_open	equ	2
__NR_close	equ	3
__NR_mmap	equ	9
__NR_mprotect	equ	10
__NR_madvise	equ	28
__NR_nanosleep	equ	35
__NR_exit	equ	60
__NR_getdents64	equ	217
__NR_renameat2	equ	316
PT_GNU_STACK	equ	6474E551h
PT_GNU_PROPERTY	equ	6474E553h
NT_GNU_PROPERTY_TYPE_0	equ	5
EPERM		equ	1
ENOENT		equ	2
EIO		equ	5
ENOMEM		equ	12
EACCESS		equ	13
EBUSY		equ	16
EEXIST		equ	17
EXDEV		equ	18
ENOTDIR		equ	20
EINVAL		equ	22
ENAMETOOLONG	equ	36
ELOOP		equ	40
O_DIRECTORY	equ	10000h
O_PATH		equ	200000h
RENAME_NOREPLACE	equ	1
MAP_PRIVATE	equ	2
MAP_ANONYMOUS	equ	20h
MAP_FIXED_NR	equ	100000h
PROT_READ	equ	1
PROT_WRITE	equ	2
PROT_EXEC	equ	4
codesize	equ	1000h
;stacksize	equ	4 * 4096	; Does not actually work
stacksizedown	equ	30000h
stacksizeup	equ	30000h
opt_verbose	equ	100h
opt_dryrun	equ	200h
opt_lastopt	equ	8000h
dot		equ	runlookup.dgldot
rootdir		equ	symbols + 5
newline		equ	symbols + 4

ORG 0
base:
	db	7Fh, 'ELF'		; ELF magic
	db	2			; 64 bit
	db	1			; Little endian
	db	1			; ELF version 1
	db	3			; Linux
	db	0			; ABI definition (not used)
symbols	db	' => ', 10, '/', 0	; 7 bytes padding, used for our own use
	dw	3			; Relocatable
	dw	3Eh			; amd64
	dd	1			; Version
	dq	_start			; Entry point
	dq	program_header		; Program Header
	dq	0			; Section Header
	dd	0			; Flags
	dw	40h			; Size of ELF header
	dw	38h			; Size of a Program Header entry
	dw	1			; Number of Program Header entries
	dw	40h			; Size of a Section Header entry
	dw	0			; Number of Section Header entries
	db	0, 0			; Which section contains strings (repurposed)
program_header:
	dd	1			; LOAD
	dd	5			; R+X
	dq	0			; Offset
	dq	$$			; Virtual Address
	dq	0			; Don't care where in physical RAM
	dq	_eop - $$		; Size in file
	dq	_eop - $$		; Size in RAM
	dq	1000h			; Alignment Requirement (one page)
;	dd	PT_GNU_PROPERTY
;	dd	4			; R
;	dq	property_header		; offset
;	dq	1000h			; Virtual Address is ignored (I think)
;	dq	0			; Don't care where in physical ram
;	dq	_start - property_header; size in file
;	dq	_start - property_header; size in ram
;	dq	8			; Alignment requirement
;Can't get kernel to honor it; use measured kludge
;property_header:
;	dd	4			; Length of GNU below
;	dd	_start - .data		; Length of notes contents
;	dd	NT_GNU_PROPERTY_TYPE	; type
;	db	"GNU", 0
;.data	dd	1			; GNU_PROPERTY_STACK_SIZE
;	dd	.data2 - _start
;.data2	dq	stacksize		; Stack size itself
_start:
	cld
	lea	rax, [rel base]
	cmp	rax, rsp
	mov	eax, 1000h
	ja	.stack2
	lea	rbx, [rel base - 1000h]	; Program is below stack
	mov	rcx, rbx
	lea	rcx, [rel base + 3000h]
	lea	rdx, [rsp - stacksizedown]
	lea	rsi, [rsp + stacksizeup + 1000h]
	mov	edi, 0FFFh
	not	rdi
	and	rsi, rdi
	jmp	.stackc
.stack2	lea	rbx, [rsp - stacksizedown - 1000h]
	lea	rcx, [rsp + stacksizeup + 1000h]
	mov	edi, 0FFFh
	not	rdi
	and	rcx, rdi
	lea	rdx, [rel base]
	sub	rdx, rcx
	mov	rsi, [rel base + 3000h]
.stackc	mov	rdi, 00007F0000000000h	; Effective top; VVAR and VDSO live somewhere above this
	sub	rdi, rsi
	jnc	.stack_not_super
	xor	edi, edi		; Super virtual address is enabled
.stack_not_super:			; One of the other two will work
	cmp	rbx, rdx
	ja	.low1
	mov	rax, rcx
	mov	rbx, rdx
.low1	cmp	rbx, rdi
	ja	.low2
	mov	rax, rsi
	mov	rbx, rdi
.low2	add	rbx, rax

	push	rbx			; Allocate buffer base
	mov	esi, 8192
	mov	rdi, rax
	call	mmap_common
	pop	rbx
	cmp	rax, rdi
	jne	oom
	mov	r15, rax		; Buffer base pointer remains in r15 for the rest of the program

	mov	r8, RENAME_NOREPLACE << 32
	pop	rdi			; argc
	pop	rdi			; program name
	or	rdi, rdi
	jz	.usage
.nxt	pop	rdi
	or	rdi, rdi
	jz	.usage
	test	r8, opt_lastopt
	jnz	.noopt
	cmp	[rdi], byte '-'
	jne	.noopt
	mov	rsi, rdi
	inc	rsi
.nxopt	lodsb
	cmp	al, 'f'
	je	.optf
	cmp	al, 'D'
	je	.optD
	cmp	al, 'v'
	je	.optv
	cmp	al, '-'
	je	.opt_
	cmp	al, 0
	je	.nxt
.usage	lea	rsi, [rel usage]
	mov	edx, usagelen
	mov	edi, 2
	call	write
	mov	dil, 2
	jmp	exit
.optf	mov	r8d, r8d		; Clears RENAME_NOREPLACE
	jmp	.nxopt
.optD	or	r8, opt_dryrun
	jmp	.nxopt
.optv	or	r8, opt_verbose
	jmp	.nxopt
.opt_	or	r8, opt_lastopt
	jmp	.nxopt
.noopt	pop	rsi
	or	rsi, rsi
	jz	.usage
	pop	rax
	or	rax, rax
	jnz	.usage
	xor	eax, eax
	lea	rcx, [r15 + 4096]
	push	rbx	; Stretchy array end
	push	rcx	; Stretchy array tripwire
	push	rax	; reserve one slot for handles
	push	r8	; exit code and operations
	push	rsi	; dst arg
	push	rdi	; src arg
	call	split
	push	rdi
	mov	rdi, rsi
	call	split
	pop	rsi
	push	rdi	; dst file pattern
	push	rsi	; src file pattern
	mov	rbp, rsp

	;Stack at this point:
	;[rbp]: src file pattern
	;[rbp + 8]: dst file pattern
	;[rbp + 16]: src directory
	;[rbp + 24]: dst directory
	;[rbp + 32]: exit code & options
	;[rbp + 36]: renameat2 flags
	;[rbp + 40]: dst dir handle
	;[rbp + 44]: src dir handle
	;[rbp + 48]: stretchy array tripwire
	;[rbp + 56]: stretchy array end
	lea	rbx, [rel dot]
	mov	rdx, [rsp + 16]
	cmp	rdx, rsi
	jne	.nfixs
	mov	[rsp + 16], rbx
	mov	rdx, rbx
.nfixs	cmp	[rsp + 24], rdi
	jne	runlookup
	mov	[rsp + 24], rdx ; If dst not given, same as src, not necessarily current

	; Check if target directory exists, if not so, bail now
runlookup:
	mov	rdi, [rsp + 24]
	cmp	[rdi], byte 0
	jne	.have1
	lea	rdi, [rel rootdir]
.have1	mov	esi, O_DIRECTORY | O_PATH
	xor	eax, eax
	mov	al, __NR_open
	syscall
	or	eax, eax
	js	.direrr
	mov	[rbp + 40], eax		; Keep handle for renameat2

	; Open source directory for enumeration
	mov	rdi, [rbp + 16]
	cmp	[rdi], byte 0
	jne	.have2
	lea	rdi, [rel rootdir]
.have2	mov	esi, O_DIRECTORY
	xor	eax, eax
	mov	al, __NR_open
	syscall
	or	eax, eax
	js	.direrr
	mov	[rbp + 44], eax		; Keep handle for renameat2

	lea	r14, [r15 + 4096]	; r14 = pointer to nametable start
.getdents64:
	mov	edi, [rbp + 44]
	mov	rsi, r15
	mov	rdx, 2048
	xor	eax, eax
	mov	al, __NR_getdents64
	syscall
	or	eax, eax
	jz	.lastdent
	js	.gderr
.gdent	xchg	eax, ecx
	add	rcx, rsi
.gdloop	push	rcx
	push	rsi
	add	rsi, 19
	db	066h, 081h, 03eh	; cmp [rsi], word
.dgldot	db	".", 0
	je	.nom
	cmp	[rsi], word ".."
	jne	.chk
	cmp	[rsi + 2], byte 0
	je	.nom
.chk	push	rsi
	call	trymatch
	pop	rsi
	jc	.nom
	; We have a match with rsi and 2048
	call	checktripwire
	mov	rdi, r14
	call	strcpy
	lea	rsi, [r15 + 2048]
	call	strcpy
	mov	r14, rdi
.nom	pop	rsi
	pop	rcx
	movzx	rax, word [rsi + 16]
	add	rsi, rax
	cmp	rsi, rcx
	je	.getdents64
	jmp	.gdloop
.gderr	mov	rdi, [rbp + 24]
.direrr	call	perror
	mov	dil, 1
	jmp	exit

.noents	mov	rdi, [rbp]
	mov	eax, -ENOENT
	jmp	.direrr
.renameat2err:
	mov	rdi, r13
	cmp	eax, -ENOENT
	jne	.renameat2err_dst
	mov	rdi, r12
.renameat2err_dst:
	call	perror
	mov	[rbp + 28], byte 1
	jmp	.resume
.lastdent:
	lea	rdi, [r15 + 4096]
	cmp	r14, rdi
	je	.noents
.op	mov	r12, rdi
	mov	al, 0
	xor	ecx, ecx
	dec	ecx
	repne	scasb
	mov	r13, rdi
	repne	scasb
	push	rdi
;%define FORCE_DRYRUN
%ifndef FORCE_DRYRUN
	test	[rbp + 33], byte opt_dryrun >> 8
	jnz	.dry
	mov	edi, [rbp + 44]
	mov	rsi, r12
	mov	edx, [rbp + 40]
	mov	r10, r13
	mov	r8d, [rbp + 36]
	mov	eax, __NR_renameat2
	syscall
	or	eax, eax
	js	.renameat2err
%endif
.dry	test	[rbp + 33], byte opt_verbose >> 8
	jz	.resume
	xor	ebx, ebx
	inc	ebx
	mov	rdi, r12
	call	pname
	lea	rsi, [rel symbols]
	mov	edx, 4
	call	write
	mov	rdi, r13
	call	pname
	lea	rsi, [rel newline]
	xor	edx, edx
	inc	edx
	call	write
.resume	pop	rdi
	cmp	rdi, r14
	jl	.op
	mov	dil, [rbp + 32]
exit	xor	eax, eax
	mov	al, __NR_exit
	syscall

split:	push	rsi
	mov	rsi, rdi
	xor	ecx, ecx
.nxt	lodsb
	cmp	al, 0
	je	.end
	cmp	al, '/'
	jne	.nxt
	lea	rcx, [rsi - 1]
	jmp	.nxt
.end	or	rcx, rcx
	jz	.nope
	mov	rdi, rcx
	mov	[rdi], byte 0
	inc	rdi
.nope	pop	rsi
	ret

;Input: rsi = filename, [rbp] = src pattern, [rbp + 8] = dst pattern; Output = [r15 + 2048] successful match string
;return CF clear on match, CF set on no match; trashes all registers other than r14, r15, rbp, and rsp
;This is the heart of the algorithm; match * and ? but there could be multiple * entries
trymatch:
	mov	r11, rsi		; save start of file name
	mov	rbx, [rbp]		; rbx = src pattern match
	mov	r8, [rbp + 8]		; r8 = dst pattern match
	lea	rdi, [r15 + 2048]	; rdi = output file
	mov	r9, rsp			; r9 = stopping point
	lea	r10, [rdi + 2046]	; Generation bailout point (should not happen)

.next0	mov	al, [rbx]
	cmp	al, '?'
	je	.matchq
	cmp	al, '*'
	je	.matchstar
	cmp	al, 0
	je	.matche
	mov	ah, [rsi]
	cmp	ah, al
	jne	.nomatch
	inc	rbx
	inc	rsi
	jmp	.next0
.matchq	call	.scan
	cmp	al, '?'
	jne	.invalid
	lodsb
	cmp	al, 0
	je	.nomatch
	stosb
	cmp	rdi, r10
	ja	.overflow
	inc	rbx
	jmp	.next0
.matche	call	.scan
	cmp	al, '*'
	je	.invalid
	cmp	al, '?'
	je	.invalid
	cmp	al, 0
	jne	.nomatch
	cmp	[rsi], byte 0
	jne	.nomatch
	stosb
.match	mov	rsp, r9
	clc
	ret
.matchstar:
	call	.scan
	cmp	al, '*'
	jne	.invalid
	inc	rbx
.exstar	push	rbx		; Start by matching 0 characters
	push	rsi
	push	rdi
	push	r8
	jmp	.next0
.nomatch:
	cmp	rsp, r9
	je	.nom
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbx
	lodsb			; Add 1 character to the * match amount
	stosb
	cmp	al, 0
	je	.stend
	cmp	rdi, r10
	ja	.overflow
	jmp	.exstar
.stend	cmp	[rbx + 1], byte 0
	jne	.nomatch	; * got to end of string and failed to pattern match
	jmp	.match
.nom	stc
.ret0	ret

.scan	mov	al, [r8]	; Write literals to output until destination character found
	inc	r8
	cmp	al, 0
	je	.ret0
	cmp	al, '?'
	je	.ret0
	cmp	al, '*'
	je	.ret0
	stosb
	cmp	rdi, r10
	jna	.scan
.overflow:
	mov	rdi, r11
	mov	eax, ENAMETOOLONG
	call	perrorg
	mov	rsp, r9
	mov	[rbp + 28], byte 1
	jmp	.nom
.invalid:
	mov	rdi, 2
	lea	rsi, [rel badpattern]
	mov	edx, badpatternlen
	call	write
	mov	dil, 2
	jmp	exit

mmap_common:
	xor	r9d, r9d
	xor	r8d, r8d
	dec	r8d
	mov	r10d, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NR
	xor	edx, edx
	mov	dl, PROT_READ | PROT_WRITE
	xor	eax, eax
	mov	al, __NR_mmap
	syscall
	ret

strcpy:	lodsb
	stosb
	cmp	al, byte 0
	jne	strcpy
	ret

checktripwire:
	cmp	r14, [rbp + 48]
	jbe	.ret
	push	rsi
	mov	rdi, [rbp + 48]
	add	rdi, 4096
	mov	al, -ENOMEM
	cmp	rdi, [rbp + 56]
	je	oom
	mov	[rbp + 48], rdi
	mov	esi, 4096
	call	mmap_common
	cmp	rax, rdi
	jne	oom
	pop	rsi
.ret	ret

pname:	mov	rsi, rdi
	mov	al, 0
	xor	ecx, ecx
	dec	rcx
	repne	scasb
	mov	rdx, rdi
	dec	rdx
	sub	rdx, rsi
	mov	edi, ebx
write:	xor	eax, eax
	inc	eax
	syscall
	cmp	rax, 0
	jle	.oops
	add	rsi, rax
	sub	rdx, rax
	jnz	write
.oops	ret

oom:	xor	rsi, rsi
	call	perrorx
	mov	dil, 1
	jmp	exit

perror:	neg	eax
perrorg	push	rax
	xor	ebx, ebx
	mov	bl, 2
	call	pname
	pop	rax
perrorx	lea	rdi, [rel errortable]
	sub	rdi, 4
.next	add	rdi, 4
	mov	ah, [rdi]
	cmp	ah, al
	je	.msg
	cmp	ah, 0
	jne	.next
.msg	movzx	edx, byte [rdi + 1]
	movzx	eax, word [rdi + 2]
	test	rsi, rsi
	jnz	.msgc
	add	eax, 2
	sub	edx, 2
.msgc	lea	rsi, [rel base]
	add	rsi, rax
	mov	edi, 2
	jmp	write

errortable	db	ENAMETOOLONG, nametoolonglen
		dw	nametoolong
		db	EEXIST, fileexistslen
		dw	fileexists
		db	ENOENT, filenotfoundlen
		dw	filenotfound
		db	EXDEV, notsamedevlen
		dw	notsamedev
		db	EINVAL, invalidlen
		dw	invalid
		db	ENOTDIR, notdirlen
		dw	notdir
		db	ELOOP, symlinklooplen
		dw	symlinkloop
		db	EACCESS, accessdeniedlen
		dw	accessdenied
		db	EPERM, permdeniedlen
		dw	permdenied
		db	EBUSY, busylen
		dw	busy
		db	ENOMEM, enomemlen
		dw	enomem
		db	0, otherlen
		dw	other

busy		db	": in use", 10
busylen		equ	$ - busy
accessdenied	db	": access denied", 10
accessdeniedlen	equ	$ - accessdenied
nametoolong	db	": name too long", 10
nametoolonglen	equ	$ - nametoolong
fileexists	db	": file exists", 10
fileexistslen	equ	$ - fileexists
filenotfound	db	": no such file or directory", 10
filenotfoundlen	equ	$ - filenotfound
notsamedev	db	": not same device", 10
notsamedevlen	equ	$ - notsamedev
permdenied	db	": operation not permitted", 10
permdeniedlen	equ	$ - permdenied
readonlyfs	db	": read only filesystem", 10
readonlyfslen	db	$ - readonlyfs
diskerror	db	": disk error", 10
diskerrorlen	equ	$ - diskerror
invalid		db	": invalid move", 10
invalidlen	equ	$ - invalid
notdir		db	": not a directory", 10
notdirlen	equ	$ - notdir
symlinkloop	db	": symbolic link loop", 10
symlinklooplen	equ	$ - symlinkloop
enomem		db	": out of memory", 10
enomemlen	equ	$ - enomem
other		db	": error", 10
otherlen	equ	$ - other
badpattern	db	"srcpattern and dstpattern must contain the same * and ? in the same order.", 10
badpatternlen	equ	$ - badpattern
usage	db	"Copyright ", 0C2h, 0A9h, " Joshua Hudson 2024,2026 Licensed under GNU GPL v3", 10
	db	"Usage: ren [-fvD] [--] '[path/to/]srcpattern' '[path/to/]dstpattern'", 10
	db	"where srcpattern and dstpattern contain the same * and ? in the same order", 10
	db	" -f  clobber   -v  verbose   -D  dry run", 10
usagelen equ $ - usage
_eop:
