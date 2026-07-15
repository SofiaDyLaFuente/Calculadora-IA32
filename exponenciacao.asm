extern precisao
extern read_number16
extern read_number32
extern print_number
extern print_string
extern msg_num1
extern len_num1
extern msg_num2
extern len_num2
extern msg_resultado
extern len_resultado
extern len_newline
extern newline
extern msg_overflow
extern len_overflow

section .text
    global exponenciacao


exponenciacao:
    push ebp                   ; salva o EBP da função chamadora
    mov ebp, esp               ; copia o endereço do topo da pilha para o registrador EBP
    sub esp, 12                ; reserva espaço na pilha para variáveis locais
    push len_num1              ; empilha tamanho do numero n1
    push msg_num1              ; empilha ponteiro para a string 
    call print_string          ; chama a função de printar string 
    cmp dword [precisao], 0    ; compara a precisão com 0 para decidir se o numero é de 16 bits ou de 32 bits
    je .ler_n1_16              ; se for 0, é numero de 16 bits então pula para ler_n1_16
    jmp .ler_n1_32             ; senão, é número de 32 bits, então pula para ler_n1_32

.ler_n1_16:
    call read_number16         ; chama função de ler número de 16 bits  
    mov [ebp-4], eax           ; copia o número lido em EAX para a variável local na pilha
    push len_num2              ; empilha tamanho do numero n2
    push msg_num2              ; empilha ponteiro para a string 
    call print_string          ; chama a função de printar string 
    jmp .ler_n2_16             ; pula para a função que le o segundo número de 16 bits (expoente)

.ler_n1_32:
    call read_number32         ; chama função de ler número de 32 bits 
    mov [ebp-4], eax           ; copia o número lido em EAX para a variável local na pilha
    push len_num2              ; empilha tamanho do numero n2
    push msg_num2              ; empilha ponteiro para a string 
    call print_string          ; chama a função de printar string 
    jmp .ler_n2_32             ; pula para a função que le o segundo número de 32 bits (expoente)

.ler_n2_16:
    call read_number16         ; chama função de ler número de 16 bits  
    mov [ebp-8], eax           ; copia o número lido em EAX para a variável local na pilha
    jmp .expoente_16           ; pula para a verificação do expoente de 16 bits

.ler_n2_32:
    call read_number32         ; chama função de ler número de 32 bits  
    mov [ebp-8], eax           ; copia o segundo número lido em EAX para a variável local na pilha
    jmp .expoente_32           ; pula para a verificação do expoente de 32 bits

.expoente_16:
    cmp dword [ebp-8],  0      ; compara o expoente com 0 para decidir se é um número válido
    jl .overflow               ; se o expoente for negativo, printa overflow
    mov word [ebp-12], 1       ; inicia o resultado como 1
    cmp dword [ebp-8], 0       ; compara de novo o expoente com 0 (qualquer número elevado a 0 = 1)
    je .print_resultado        ; se for igual a zero, pula para a função print do resultado
    mov ebx, [ebp-8]           ; pega o valor do expoente e coloca em EBX
    jmp .loop_16               ; pula para o loop_16 

.loop_16:
    mov ax, word [ebp-12]      ; copia o resultado da pilha para o registrador AX
    imul word [ebp-4]          ; multiplica o resultado com a base
    jo .overflow               ; se overflow, pula para mensagem de erro
    mov [ebp-12], ax           ; copia o valor de AX para o resultado na pilha
    sub ebx, 1                 ; faz contador = contador - 1
    cmp ebx, 0                 ; compara o expoente com 0
    jne .loop_16               ; enquanto não for igual a 0, volta no loop 
    movsx eax, word [ebp-12]   ; move o valor do resultado para EAX estendendo o sinal de 16 bits para 32 bits
    mov [ebp-12], eax          ; atualiza o valor da pilha com o valor de EAX
    jmp .print_resultado       ; pula para a função de printar o resultado

.expoente_32:
    cmp dword [ebp-8], 0       ; compara o expoente com 0 para decidir se é um número válido
    jl .overflow               ; se o expoente for negativo, printa overflow
    mov dword [ebp-12], 1      ; inicia o resultado como 1
    cmp dword [ebp-8], 0       ; compara de novo o expoente com 0 (qualquer número elevado a 0 = 1)
    je .print_resultado        ; se for igual a zero, pula para a função print do resultado
    mov ebx, [ebp-8]           ; pega o valor do expoente e coloca em EBX
    jmp .loop_32               ; pula para o loop_32

.loop_32:
    mov eax, [ebp-12]          ; copia o resultado da pilha para o registrador EAX
    imul dword [ebp-4]         ; multiplica o resultado com a base
    jo .overflow               ; se overflow, pula para mensagem de erro
    mov [ebp-12], eax          ; copia o valor de EAX para o resultado na pilha
    sub ebx, 1                 ; faz contador = contador - 1
    cmp ebx, 0                 ; compara o expoente com 0
    jne .loop_32               ; enquanto não for igual a 0, volta no loop 
    jmp .print_resultado       ; se for 0, chegamos no fim então pula para a função de printar o resultado

.overflow:
    push len_overflow          ; empilha tamanho da mensagem
    push msg_overflow          ; empilha ponteiro para string
    call print_string          ; chama função de print string
    mov eax, 1                 ; sys_exit
    int 0x80                   ; chama o kernel

.print_resultado:
    push len_resultado         ; empilha o parâmetro resultado
    push msg_resultado         ; empilha ponteiro para a string 
    call print_string          ; chama a função de printar string 
    push dword [ebp-12]        ; empilha o valor do resultado
    call print_number          ; chama função de printar número
    push len_newline           ; empilha 1 byte
    push newline               ; empilha o caracter de quebra de linha
    call print_string          ; chama a função de printar string
    mov esp, ebp               ; apaga o frame de pilha
    pop ebp                    ; desempilha
    ret                        ; retorna