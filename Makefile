all: chmod dropbuf env flushbuf mv ren rmdir sln unlink

clean:
	rm -f chmod dropbuf env flushbuf mv ren rmdir sln unlink

# Assembly-only tools

chmod: chmod.asm
	nasm -f bin -o chmod chmod.asm
	chmod +x chmod

dropbuf: dropbuf.asm
	nasm -f bin -o dropbuf dropbuf.asm
	chmod +x dropbuf

env: env.asm
	nasm -f bin -o env env.asm
	chmod +x env

flushbuf: flushbuf.asm
	nasm -f bin -o flushbuf flushbuf.asm
	chmod +x flushbuf

mv: mv.asm
	nasm -f bin -o mv mv.asm
	chmod +x mv

ren: ren.asm
	nasm -f bin -o ren ren.asm
	chmod +x ren

rmdir: rmdir.asm
	nasm -f bin -o rmdir rmdir.asm
	chmod +x rmdir

sln: sln.asm
	nasm -f bin -o sln sln.asm
	chmod +x sln

unlink: unlink.asm
	nasm -f bin -o unlink unlink.asm
	chmod +x unlink

