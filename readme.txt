Cada .asm de operação é montado separadamente em .o e depois todos são linkados juntos num único executável:

nasm -f elf32 calculadora.asm -o calculadora.o
nasm -f elf32 soma.asm -o soma.o
nasm -f elf32 subtracao.asm -o subtracao.o
nasm -f elf32 multiplicacao.asm -o multiplicacao.o
nasm -f elf32 divisao.asm -o divisao.o
nasm -f elf32 exponenciacao.asm -o exponenciacao.o
nasm -f elf32 mod.asm -o mod.o

ld -m elf_i386 -o calculadora calculadora.o soma.o subtracao.o multiplicacao.o divisao.o exponenciacao.o mod.o