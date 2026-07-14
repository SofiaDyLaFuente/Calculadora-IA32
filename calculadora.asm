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
msg_overflow    db "OCORREU OVERFLOW", 10
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
    global newline, len_newline
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
    push eax
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

; ################################################################;
; executar_operacao(opcao): DESPACHANTE PURO.                     ;
; Parâmetro: [ebp+8] = opção (1 a 6) — único parâmetro, 4 bytes.  ;
; Não lê teclado nem escreve na tela: só decide qual operação     ;
; chamar. Cada operação (em seu próprio arquivo) lê seus          ;
; próprios números e imprime seu próprio resultado.               ;
; Retorno: nenhum valor -> "ret 4" só limpa o parâmetro recebido. ;
; ################################################################;

executar_operacao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    cmp eax, 1
    je .soma
    cmp eax, 2
    je .subtracao
    cmp eax, 3
    je .multiplicacao
    cmp eax, 4
    je .divisao
    cmp eax, 5
    je .exponenciacao
    cmp eax, 6
    je .mod
    jmp .fim 

.soma:
    call soma
    jmp .fim
.subtracao:
    call subtracao
    jmp .fim 
.multiplicacao:
    call multiplicacao
    jmp .fim 
.divisao:
    call divisao
    jmp .fim 
.exponenciacao:
    call exponenciacao
    jmp .fim
.mod: 
    call mod_op
    jmp .fim 
.fim:
    mov esp, ebp
    pop ebp
    ret 4

; ################################################################;
; print_string(ptr, len): ÚNICA função de saída de texto de       ;
; todo o programa. Todo mundo (main e operações) usa esta.        ;
; Parâmetros:                                                     ;
;   [ebp+8]  = len (quantidade de bytes a escrever)               ;
;   [ebp+12] = ptr (endereço do início da string)                 ;
; Sem retorno de valor -> "ret 8" só limpa os 2 parâmetros.       ;
; ################################################################;

print_string:
    push ebp
    mov ebp, esp

    mov eax, 4              ; identificador da syscall sys_write
    mov ebx, 1              ; arg1 = 1 (stdout, a tela)
    mov ecx, [ebp+8]        ; arg2 = ponteiro pro texto
    mov edx, [ebp+12]       ; arg3 = quantidade de bytes
    int 80h                 ; chama o kernel

    mov esp, ebp
    pop ebp
    ret 8

; ################################################################;
; read_string(buffer, max_len): lê uma linha do teclado e guarda  ;
; no buffer indicado por quem chamou (o buffer é alocado na PILHA ;
; de quem chamou, nunca é global).                                ;
; Parâmetros:                                                     ;
;   [ebp+8]  = max_len (tamanho máximo do buffer)                 ;
;   [ebp+12] = buffer (endereço onde escrever o que foi lido)     ;
; Retorno: em EAX, quantidade de bytes lidos SEM contar o \n      ;
;          (o \n lido é substituído por um 0 no buffer).          ;
; ################################################################;

read_string:
    push ebp
    mov ebp, esp

    mov eax, 3              ; identificador da syscall sys_read
    mov ebx, 0              ; arg1 = 0 (stdin, o teclado)
    mov ecx, [ebp+8]        ; arg2 = buffer de destino
    mov edx, [ebp+12]       ; arg3 = tamanho máximo
    int 80h                 ; eax = quantidade de bytes lidos, incluindo o \n

    dec eax                 ; desconta o \n da contagem
    cmp eax, 0
    jl .fim                 ; se não leu nada além do \n, não faz nada mais
    mov ebx, [ebp+8]       
    add ebx, eax
    mov byte [ebx], 0       ; troca o \n por um terminador 0 (vai ser útil pro parser)

.fim:
    mov esp, ebp
    pop ebp
    ret 8

; ################################################################;
; read_number16(): lê uma linha do teclado e converte pra inteiro ;
; de 16 bits COM SINAL. O buffer de leitura é uma variável LOCAL  ;
; (alocada aqui na pilha, nunca global).                          ;
; Sem parâmetros de entrada.                                      ;
; Retorno: valor lido em EAX (sign-extended a partir de AX).      ;
; ################################################################;

read_number16:
    push ebp
    mov ebp, esp
    sub esp, 16             ; rerserva 16 bytes NA PILHA pro buffer de texto lido

    push 16
    lea eax, [ebp-16]       ; endereço do buffer local reservado
    push eax
    call read_string        ; lê a linha digitada pro buffer local

    lea eax, [ebp-16]
    push eax
    call parse_int_from_buffer  ; converte o texto lido em número (EAX)

    movsx eax, ax           ; garante que o valor é tratado como 16 bits com sinal

    mov esp, ebp
    pop ebp
    ret

; ################################################################;
; read_number32(): igual ao read_number16, mas sem truncar/       ;
; estender pra 16 bits — mantém o valor inteiro de 32 bits.       ;
; ################################################################;

read_number32:
    push ebp
    mov ebp, esp
    sub esp, 16

    push 16
    lea eax, [ebp-16]
    push eax
    call read_string

    lea eax, [ebp-16]
    push eax 
    call parse_int_from_buffer
    mov esp, ebp
    pop ebp
    ret

; ################################################################;
; print_number(valor): converte um inteiro com sinal              ;
; (em complemento de 2) pra ASCII e imprime na tela usando        ;
; print_string. O buffer de conversão é LOCAL (na pilha).         ;
; Parâmetro:                                                      ;
;   [ebp+8] = valor a imprimir                                    ;
; ################################################################;

print_number:
    push ebp
    mov ebp, esp
    sub esp, 16             ; Reserva 16 bytes NA PILHA pro buffer de conversão
    push ebx
    push ecx 
    push edx 
    push edi

    mov eax, [ebp+8]        ; Valor a converter
    lea edi, [ebp-1]        ; Começa a escrever do FIM do buffer local pro início
    mov byte [edi], 0       ; Terminador da string resultante
    mov ebx, 10             ; Base decimal
    xor ecx, ecx            ; ECX = 1 se o valor é negativo

    cmp eax, 0
    jge .conv
    mov ecx, 1
    neg eax                 ; Trabalha só com o valor absoluto

.conv:
    cmp eax, 0
    jne .loop
    dec edi
    mov byte [edi], '0'     ; Caso especial: Valor é exatamente 0
    jmp .checa_sinal 

.loop:
    cmp eax, 0
    je .checa_sinal
    xor edx, edx
    div ebx                 ; EAX = EAX/10, EDX = resto (dígito das unidades)
    add dl, '0'             ; Converte o dígito para ASCII
    dec edi     
    mov [edi], dl           ; Escreve o dígito, de trás pra frente
    jmp .loop 

.checa_sinal:
    cmp ecx, 1
    jne .print 
    dec edi 
    mov byte [edi], '-'    ; Adiciona o sinal de negativo se necessário

.print:
    lea eax, [ebp-1]       ; eax = posição do terminador (fim da string útil)
    sub eax, edi           ; eax = comprimento = (posição do terminador - início da string)
    push eax
    push edi 
    call print_string      ; Imprime o número já convertido

    pop edi 
    pop edx 
    pop ecx 
    pop ebx 
    mov esp, ebp
    pop ebp
    ret 4


; ################################################################;
; Função auxiliar interna:                                          
; parse_int_from_buffer(buffer): converte uma string ASCII        ;
; terminada em 0 (ou \n) pra inteiro com sinal em EAX.            ;
; Trata o sinal de '-' no início da string.                       ;
; Parâmetro:                                                      ;
;   [ebp+8] = buffer (endereço da string a converter)             ;
; ################################################################;

parse_int_from_buffer:
    push ebp
    mov ebp, esp
    push ebx
    push ecx 
    push edx 

    xor eax, eax        ; EAX = acumulador do valor inicial
    xor ebx, ebx        ; EBX = 1 se o número é negativo, 0 caso contrário
    mov ecx, [ebp+8]    ; ECX = ponteiro andante pela string

    mov dl, [ecx]       ; DL = primeiro caractere da string
    cmp dl, '-'         
    jne .loop           ; Se não é '-', vai direto pro loop de dígitos
    mov ebx, 1          ; Encontrou o '-' no ínicio -> número negativo
    inc ecx             ; Avança, o '-' não é dígito

.loop:
    mov dl, [ecx]
    cmp dl, 0
    je .fim             ; Terminador -> acabou a string
    cmp dl, 10  
    je .fim             ; \n também marca o fim
    cmp dl, '0'
    jl .fim             ; Qualquer coisa fora de '0-9' encerra a leitura
    cmp dl, '9'
    jg .fim

    sub dl, '0'         ; Converte o caractere ASCII pro dígito numérico
    imul eax, eax, 10   ; Desloca o acumulador uma casa decimal -> acumulador *= 10
    movzx edx, dl       ; Estende DL (8 bits) para EDX (32 bits) sem sinal
    add eax, edx        ; acumulador += o novo dígito
    inc ecx 
    jmp .loop 

.fim:
    cmp ebx, 1
    jne .semsinal       ; Aplica o sinal negativo, se necessário
    neg eax

.semsinal:
    pop edx
    pop ecx
    pop ebx 
    mov esp, ebp
    pop ebp 
    ret 4

; ################################################################;
; sys_exit_program(): encerra o processo (syscall sys_exit).      ;
; Não retorna — não precisa de "ret".                             ;
; ################################################################;

sys_exit_program:
    mov eax, 1          ; Identificador da syscall sys_exit
    xor ebx, ebx
    int 80h