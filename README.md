# shellcodeGen
It is shell script to generate shellcode easier.

## Useage Guide
```
./shellcode-gen.sh -o FILE_NAME [-s -a -r -k]
./shellcode-gen.sh -h
<options>
-o FILE_NAME : Essential. '*.s' file to create with shell code.
-s SYNTAX    : Optional. Specify syntax(att(default) or intel).
-a ARCH      : Optional. Specify architecture(64(default) or 32)
-r           : Optional. Run shell code by making it an executable file.
-k           : Optional. Keep the intermediate files.
-h           : Print this message and then exit.
<exit code>
0 : Success.
1 : Failure.
```

## Example
orw.s :
```
$ cat orw.s
.section .text
.global _start
_start:
pushq $0x67
movabsq $0x616c662f706d742f, %rax
pushq %rax
movq %rsp, %rdi
xorq %rsi, %rsi
xorq %rdx, %rdx
pushq $0x02
popq %rax
syscall

movq %rax, %rdi
leaq -0x30(%rsp), %rsi
pushq $0x30
popq %rdx
xorq %rax, %rax
syscall

movq $0x01, %rdi
movq %rdi, %rax
syscall
```

run :
```
$ ./shellcode-gen.sh -o orw.s
[------- ASSEMBLY WITH MACHINE CODE --------]

orw.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <_start>:
   0:	6a 67                	push   $0x67
   2:	48 b8 2f 74 6d 70 2f 	movabs $0x616c662f706d742f,%rax
   9:	66 6c 61 
   c:	50                   	push   %rax
   d:	48 89 e7             	mov    %rsp,%rdi
  10:	48 31 f6             	xor    %rsi,%rsi
  13:	48 31 d2             	xor    %rdx,%rdx
  16:	6a 02                	push   $0x2
  18:	58                   	pop    %rax
  19:	0f 05                	syscall
  1b:	48 89 c7             	mov    %rax,%rdi
  1e:	48 8d 74 24 d0       	lea    -0x30(%rsp),%rsi
  23:	6a 30                	push   $0x30
  25:	5a                   	pop    %rdx
  26:	48 31 c0             	xor    %rax,%rax
  29:	0f 05                	syscall
  2b:	48 c7 c7 01 00 00 00 	mov    $0x1,%rdi
  32:	48 89 f8             	mov    %rdi,%rax
  35:	0f 05                	syscall
[-------------------------------------------]

Do you want to make it into SHELL CODE? [Y/n]: y

bytes length : 55(0x37)

\x6A\x67\x48\xB8\x2F\x74\x6D\x70\x2F\x66\x6C\x61\x50\x48\x89\xE7\x48\x31\xF6\x48\x31\xD2\x6A\x02\x58\x0F\x05\x48\x89\xC7\x48\x8D\x74\x24\xD0\x6A\x30\x5A\x48\x31\xC0\x0F\x05\x48\xC7\xC7\x01\x00\x00\x00\x48\x89\xF8\x0F\x05
```