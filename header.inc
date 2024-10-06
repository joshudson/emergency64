;*** ELF HEADER ***
ORG	0
db	0x7F, 'ELF'	; MAGIC
db	2		; 64 bit
db	1		; Little endian
db	1		; ELF version 1
db	3		; OS = Linux
db	0		; ABI definition not used for static linkage
db	0, 0, 0, 0, 0, 0, 0	; PADDING
dw	3		; Relocatable Executable Image
dw	0x3E		; amd64
dd	1		; Vesion of ELF
dq	_start		; Entry point
dq	0x40		; Program Header Table offset
dq	0		; Section Header Table offset (not used)
dd	0		; Flags
dw	0x40		; Size of ELF header
dw	0x38		; Size of a program header entry
dw	1		; Number of entries
dw	0x40		; Size of a section header entry
dw	0		; Number of entries
dw	0		; Which section contains strings
;*** Program Header ***
dd	1
dd	5		; R+X (no W)
dq	0		; Offset
dq	$$		; Virtual address = assembly address
dq	0		; Don't care where in RAM
dq	_eop - $$	; Size in file
dq	_eop - $$	; Size in RAM
dq	0x1000		; Align to page
