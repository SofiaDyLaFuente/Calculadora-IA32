; ============================================================
; CALCULADORA.ASM
; Programa principal + funções de entrada/saída de dados.
;
; REGRAS DA ESPECIFICAÇÃO QUE ESTE ARQUIVO RESPEITA:
;   - O programa principal (_start) SÓ chama funções: nunca lê
;     teclado, nunca escreve na tela, nunca processa dado direto.
;   - As ÚNICAS variáveis globais são: nome_usuario, precisao,
;     opcao_menu, e os ponteiros/tamanhos das strings de
;     mensagem. TUDO mais (buffers de trabalho, resultados
;     intermediários) é variável LOCAL NA PILHA de cada função.
;   - Toda função recebe parâmetro pela pilha (nunca registrador).
;   - As funções de operação (SOMA, SUBTRACAO...) ficam cada
;     uma no seu próprio arquivo .asm e são só "extern" aqui.
;
; Compilar: nasm -f elf32 calculadora.asm -o calculadora.o
; ============================================================

extern soma
extern subtracao
extern multiplicacao
extern divisao
extern exponenciacao
extern mod_op                   ;"mod" sozinho é uma palavra reservada do NASM, por isso "mod_op"

section .data

; ###############################################################;
; Mensagens iniciais do programa.                                ;
; OBS: o número 10 no fim de uma string é o código ASCII de \n   ;
; (quebra de linha) — não tem relação nenhuma com "tamanho":     ;
; é só mais um byte de conteúdo, incluído de propósito.          ;
;                                                                ;
; IMPORTANTE: cada "len_X equ $ - msg_X" tem que vir LOGO DEPOIS ;
; do "db" correspondente, nunca depois de outras strings — senão ;
; "$" (endereço atual) já estará mais à frente e o tamanho       ;
; calculado vai incluir strings que não são a sua.               ;
; ###############################################################;

msg_bemvindo db "Bem-vindo. Digite seu nome:", 10
len_bemvindo equ $ - msg_bemvindo
msg_ola1 db "Hola, "
len_ola1 equ $ - msg_ola1
msg_ola2 db ", bem-vindo ao programa de CALC IA-32", 10
len_ola2 equ $ - msg_ola2
msg_precisao db "Vai trabalhar com 16 ou 32 bits (digite 0 para 16, e 1 para 32):", 10
len_precisao equ $ - msg_precisao

; Mensagens para o menu

msg_menu1 db "ESCOLHA UMA OPÇÃO: ", 10
len_menu1 equ $ - msg_menu1
msg_menu2 db "- 1: SOMA", 10
len_menu2 equ $ - msg_menu2
msg_menu3 db "- 2: SUBTRAÇÃO", 10
len_menu3 equ $ - msg_menu3
msg_menu4 db "- 3: MULTIPLICAÇÃO", 10
len_menu4 equ $ - msg_menu4
msg_menu5 db "- 4: DIVISÃO", 10
len_menu5 equ $ - msg_menu5
msg_menu6 db "- 5: EXPONENCIAÇÃO", 10
len_menu6 equ $ - msg_menu6
msg_menu7 db "- 6: MOD", 10
len_menu7 equ $ - msg_menu7
msg_menu8 db "- 7: SAIR", 10
len_menu8 equ $ - msg_menu8
 
; Mensagens usadas pelas OPERAÇÕES 

msg_num1        db "Digite o primeiro número:", 10
len_num1        equ $ - msg_num1
msg_num2        db "Digite o segundo número:", 10
len_num2        equ $ - msg_num2
msg_resultado   db "Resultado: "
len_resultado   equ $ - msg_resultado
msg_overflow    db "OCORREU OVERFLOW"
len_overflow    equ $ - msg_overflow
msg_enter       db "Pressione ENTER para continuar...", 10
len_enter       equ $ - msg_enter
newline         db 10 
len_newline     equ 1

section .bss

; ############################################################;
; ÚNICAS variáveis globais permitidas pela especificação:     ;
; "os ponteiros para os strings de texto das mensagens, uma   ;
; variável para o nome do usuário, uma para a precisão e uma  ;
; para a opção do menu".                                      ;
; ############################################################;

nome_usuario   resb 64          ; Nome do Usuário
precisao       resd 1           ; 0 = 16 bits, 1 = 32 bits (lida 1x, usada pra todas as operações)
opcao_menu     resd 1           ; Opção do menu escolhida

section .text 
    global _start

    ; Funções de E/S exportadas:
    ; podem ser chamadas a partir dos arquivos de operação
    global print_string
    global read_string
    global read_number16
    global read_number32
    global print_number

    ; Mensagens/variável de precisão exportadas também
    ; pelo mesmo motivo
    global msg_num1, len_num1, msg_num2, len_num2
    global msg_resultado, len_resultado
    global msg_overflow, len_overflow
    global newLine, len_newline
    global precisao

; ############################################################;
; _start: Ponto de entrada do programa (programa principal).  ;
; Função "especial" — não usa push ebp/mov ebp,esp porque não ;
; é chamada por ninguém (é o próprio SO que salta pra cá) e   ;
; nunca retorna (termina com sys_exit).                       ;
; Regra que ela cumpre: só chama funções, nunca faz E/S ou    ;
; processamento diretamente.                                  ;
; ############################################################;

_start:
    ; --- Saudação inicial e leitura do nome
    push len_bemvindo
    push msg_bemvindo
    call print_string

    push 64
    push nome_usuario
    call read_string    ; retorna em EAX quantos bytes foram lidos

    push len_ola1
    push msg_ola1
    call print_string

    push eax            ; tamanho do nome
    push nome_usuario
    call print_string

    push len_ola2
    push msg_ola2
    call print_string

    ; --- Pergunta a precisão (0 = 16 bits, 1 = 32 bits)
    push len_precisao
    push msg_precisao
    call print_string

    call read_number16
    mov [precisao], eax 

.menu_loop:
    call mostrar_menu

    call read_number16
    mov [opcao_menu], eax

    cmp dword [opcao_menu], 7
    je .sair 

    ; Despacha a operação escolhida (executar_operacao não faz E/S)
    push dword [opcao_menu]
    call executar_operacao

    ; Espera o usuário apertar ENTER antes de mostrar o menu de novo
    push len_enter
    push msg_enter
    call print_string

    sub esp, 32         ; reserva 32 bytes na pilha pra descartar o ENTER
    lea eax, [esp]      
    push 32
    call read_string
    add esp, 32         ; libera o espaço reservado

    jmp .menu_loop

.sair:
    call sys_exit_program

; ######################################################;
; mostrar_menu(): imprime as 8 linhas do menu de opções ;
; Sem parâmetroa, sem retorno de valor -> ret simples   ;
; ######################################################;

mostrar_menu:
    push ebp
    mov ebp, esp

    push len_menu1
    push msg_menu1
    call print_string

    push len_menu2
    push msg_menu2
    call print_string

    push len_menu3
    push msg_menu3
    call print_string

    push len_menu4
    push msg_menu4
    call print_string

    push len_menu5
    push msg_menu5
    call print_string

    push len_menu6
    push msg_menu6
    call print_string

    push len_menu7
    push msg_menu7
    call print_string

    push len_menu8
    push msg_menu8
    call print_string

    mov esp, ebp
    pop ebp
    ret