## What is this?

This is a pack of x64 emergency tools designed to supplement klibc tools.

The extreme small size of the binary tools is benefical as these don't cost much even if added to the initial ramdisk.

I mostly leave them lying around on /boot/efi except for flushbuf and dropbuf which go into /boot (long story).

## To build

Have `nasm`, type `make`

## To install

That's a matter of opinion. Most of these can go into `/usr/lib/klib/bin` if you want but there's already a
`mv` so this one should be installed as `mv.static` (which it is).

## The tools

### chmod

Changes the permissions of a given file. Accepts the new permission bits in octal and a single file name

### dropbuf

Tells the kernel to drop the read-ahead cache of a block device. Accepts a device name.

### env

displays exported environment variables, or runs a program in an altered environment.

Options:\
`-S`: split the next argument into multiple arguments by spaces. This works even if the `-S` itself got joined.\
`-`: by itself (no option character), clears the environment list\
`-i`: clears the environment list\
`-u NAME`: clears `NAME` from the environment
`NAME=value`: sets `NAME` to `value` in the environment
`-C dir`: changes to this directory
`-0`: outputs environment separated by nulls

If a program name is given, that program is executed, otherwise the resulting environment is output.\
Thus, running `env` with no options outputs the environment it received.

### flushbuf

Accepts a file or a device, flushes the write-behind buffer to disk using the `fdatasync()` system call.

### mv

Moves a file from one location on the disk to another location on the same disk.

### ren

Performs a pattern-match rename. This is mostly a port (read: rebuild from the ground up) of the DOS ren command,
with a few idiosyncracies of how `*` works removed so as to correspond to modern expectations.

Expects two arguments, possibly with wildcards, encased in single quotes.

Note that `ren '/path/to/*.TXT' '*.txt'` results in files called `/path/to/*.txt`; if you want to move them to .
you should do `ren '/path/to/*.TXT' './*.txt'`.

Options:\
`-f` force: allows replacing an existing file; caution of two source files map to the same destionation, one will be lost\
`-v` verbose: outputs a line to standard output for every successful rename\
`-D` dry-run: doesn't actually perform the system call; for use with `-v` to see what it would do

### rmdir

Removes an empty directory. Expects a single directory.

### sln

Creates a symbolic link; the first argument is the contents of the symbolic link and the second is the name to create.
This is exactly the `symlink()` system call, no prepreocessing. The *point* of this tool is it's completely staticly
linked, so if you're in the state of I broke libc mid upgrade you can actually fix it (sometimes) by creating symbolic
links under `/lib` from where binaries are looking for libc to where a plausibly working libc happens to reside.

### unlink

Removes a file system node other than a directory. Expects a single path. This is exactly the `unlink()` system call,
and is the counterpart to `sln`.

## "FAQ"

### Why so many ways to move files?

They're subtly different. The version of `mv` in `klibc`, the version of `mv` here, and the version of `ren`
here fill different purposes. In a running system you would do `ren`'s job with a string processing loop,
but when you're dealing with a degenerate system you don't always get such luxuries.

### Isn't consolidation a good thing?

Yes. But monoculture is a bad thing. Having a few oddballs lying around can spare you when everything goes wrong.

### Isn't this a waste of disk space?

It's 36kb on the EFI partition. It costs you nothing because an EFI partition has a minimum size that we can
calculate. For modern SSDs with 4K sectors, it's 16MB, and the boot tools only take up 6mb of that. To top it
off, most systems create a 100MB EFI partition by default.

### Why does ren alone have an error code decode?

Because this tool is fundamentally larger than the others and benefits from it. I found this to be much much
easier to use than either standard tool `rename` or `mmv` so it potentially has its place on a normal install.

### History

`flushbuf` and `dropbuf` came first as fixes to a Linux kernel gaffe (while `/dev/sda` and `/dev/sda1`
overlap, their caches don't). If you look hard enough on stackexchange you can find a CC-BY-SA licensed
version of the `flushbuf` binary that hasn't been made PIC.

Then [this](https://askubuntu.com/q/1483230/287855) question appeared on stackexchange and I encountered it while
it had no good answers yet and I got very annoyed discovering the klibc tools had no chmod. My original plan
was to use `uudecode` to provide an emergency chmod to fix the orignal one, but it proved unnecessary.

And then there was this noise about dropping 32 bit binary support from kernel (which didn't happen) which
led me to looking to replace my remaining 32 bit emergency tools from asmutils with 64 bit equivalents, and
I found a few missing.
