# Trabalho 2 – Calculadora IA-32

**Disciplina:** Software Básico (CIC0104) \
**Curso:** Ciência da Computação – UnB \
**Trabalho:** Trabalho 2 – Calculadora em Assembly IA-32 \
**Professor:** Bruno Luiggi Macchiavello Espinoza \
**Sistema Operacional:** Linux (testado em Fedora, Ubuntu e WSL)  

**Alunos:**
- João Victor Pereira Vieira - 211036114
- Sofia Dy La Fuente Monteiro - 211055530

---

## Descrição

Este projeto implementa uma calculadora de inteiros com sinal em Assembly IA-32 (NASM), desenvolvida conforme a especificação do Trabalho 2 da disciplina de Software Básico. O programa permite ao usuário selecionar a precisão (16 ou 32 bits) e executar operações aritméticas, realizando verificação de overflow e tratamento de erros quando necessário.

O programa permite ao usuário escolher a precisão (16 ou 32 bits) e realizar as operações:
1. Soma  
2. Subtração  
3. Multiplicação  
4. Divisão  
5. Exponenciação (base ^ expoente)  
6. Módulo (resto da divisão inteira)  
7. Sair

Todas as operações suportam números negativos e verificam overflow.  
O programa é composto por múltiplos arquivos `.asm`, cada um contendo uma operação diferente, além do arquivo principal (`calculadora.asm`) que contém as funções de entrada/saída e o menu.

**Não** é utilizada a biblioteca `io.mac` – todas as entradas e saídas são feitas via chamadas de sistema (`int 0x80`) encapsuladas em funções próprias, conforme exigido na especificação.

---

## Estrutura dos arquivos

| Arquivo | Descrição |
| :--- | :--- |
| `calculadora.asm` | Programa principal (menu, leitura de nome/precisão, chamada das operações) e funções de E/S (`print_string`, `read_string`, `read_number16`, `read_number32`, `print_number`). |
| `soma.asm` | Soma de dois números com sinal. |
| `subtracao.asm` | Subtração de dois números com sinal. |
| `multiplicacao.asm` | Multiplicação de dois números com sinal com verificação de overflow. |
| `divisao.asm` | Divisão com extensão de sinal e tratamento de divisão por zero. |
| `exponenciacao.asm` | Exponenciação por multiplicações sucessivas com verificação de overflow. Expoente negativo tratado como overflow. |
| `mod_op.asm` | Módulo (resto da divisão inteira) com sinal. |
| `build.sh` | Script de compilação automatizada (monta todos os arquivos, gera stubs para funções faltantes e linka). |

---

## Pré-requisitos

- **NASM** (≥ 2.14) – montador para gerar os objetos `.o`.
- **GNU Binutils (ld)** – ligador para gerar o executável.
- **GCC** e Bibliotecas 32 bits (necessário para sistemas 64 bits).

### Instalação das dependências

#### Ubuntu / Debian / Linux Mint / WSL

```bash
sudo apt update
sudo apt install nasm binutils gcc libc6-dev-i386 -y
```

#### Fedora / RHEL / CentOS

```bash
sudo dnf install nasm binutils gcc glibc-devel.i686 -y
```

-----

## Compilação

O projeto inclui um script `build.sh` que automatiza a montagem e a linkagem dos arquivos Assembly. Além disso, o script verifica a implementação das operações e gera stubs temporários para funções ausentes, facilitando testes durante o desenvolvimento. Entretanto, na versão entregue deste trabalho, todas as operações estão implementadas.

### 1. Dê permissão de execução ao script

```bash
chmod +x build.sh
```

### 2. Execute o script

```bash
./build.sh
```
Ao final da compilação será gerado o executável `calculadora`.

### Compilação manual (alternativa ao Script)

```bash
nasm -f elf32 calculadora.asm -o calculadora.o
nasm -f elf32 soma.asm -o soma.o
nasm -f elf32 subtracao.asm -o subtracao.o
nasm -f elf32 multiplicacao.asm -o multiplicacao.o
nasm -f elf32 divisao.asm -o divisao.o
nasm -f elf32 exponenciacao.asm -o exponenciacao.o
nasm -f elf32 mod_op.asm -o mod_op.o
ld -m elf_i386 -o calculadora calculadora.o soma.o subtracao.o multiplicacao.o divisao.o exponenciacao.o mod_op.o
```

### Para executar o projeto

```bash
./calculadora
```

### Observações
- O projeto foi desenvolvido e testado em Linux (Fedora, Ubuntu e WSL).
- Todas as funções recebem parâmetros exclusivamente pela pilha, conforme a especificação.
- As variáveis locais são armazenadas na pilha, sem utilização de variáveis globais.
- A entrada e saída de dados são realizadas por chamadas de sistema (`int 0x80`), sem utilização da biblioteca `io.mac`.