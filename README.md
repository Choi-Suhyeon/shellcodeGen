# shellcodeGen
  This shell script facilitates the generation of shellcode. It assists in crafting shellcode effortlessly from a file with the extension 's', which contains code written in either att or intel syntax.

## Programs Used Within The Program
  Of course, there have been many more programs used, but the following are directly relevant to generating shellcode.

- as
- ld
- hexdump
- objdump
- objcopy

## Useage Guide
```
./shellcode-gen.sh -f TARGET_FILE_NAME [-o -a -t -s -r -k]
./shellcode-gen.sh -h
<options>
-h                  : Print this message and then exit.
-f TARGET_FILE_NAME : Specify the file with the extension 's' for generating shellcode.
-o OUTPUT_FILE_NAME : (Optional) Save the completed shellcode to the specified file.
-a ARCHITECTURE     : (Optional) Specify architecture(x86_64(default) or i386).
-t LITERAL_TYPE     : (Optional) Specify the literal type(str(default), arr, or all) of bytes of shellcode to output.
-s SYNTAX           : (Optional) Specify syntax(att(default) or intel).
-r                  : (Optional) Run shell code by making it an executable file.
-k                  : (Optional) Keep the intermediate files.
<exit code>
0 : Success.
1 : Failure.
```

## Example
orw.s :
```bash
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
```bash
$ ./shellcode-gen.sh -f orw.s -t all
[-------------------- ASSEMBLY WITH MACHINE CODE --------------------]

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

NOTE : Whitespace in C : 
  0x09(Horizontal Tab), 0x0A(Line Feed),       0x0B(Vertical Tab),
  0x0C(Form Feed),      0x0D(Carriage Return), 0x20(Space)

[-------------------------------------------------------------------]

Do you want to make it into SHELLCODE? [Y/n]: y

bytes length : 55 (0x37)

String Literal: 
\x6A\x67\x48\xB8\x2F\x74\x6D\x70\x2F\x66\x6C\x61\x50\x48\x89\xE7\x48\x31\xF6\x48\x31\xD2\x6A\x02\x58\x0F\x05\x48\x89\xC7\x48\x8D\x74\x24\xD0\x6A\x30\x5A\x48\x31\xC0\x0F\x05\x48\xC7\xC7\x01\x00\x00\x00\x48\x89\xF8\x0F\x05

Array Literal: 
0x6A, 0x67, 0x48, 0xB8, 0x2F, 0x74, 0x6D, 0x70, 0x2F, 0x66, 0x6C, 0x61, 0x50, 0x48, 0x89, 0xE7, 0x48, 0x31, 0xF6, 0x48, 0x31, 0xD2, 0x6A, 0x02, 0x58, 0x0F, 0x05, 0x48, 0x89, 0xC7, 0x48, 0x8D, 0x74, 0x24, 0xD0, 0x6A, 0x30, 0x5A, 0x48, 0x31, 0xC0, 0x0F, 0x05, 0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00, 0x48, 0x89, 0xF8, 0x0F, 0x05

```
