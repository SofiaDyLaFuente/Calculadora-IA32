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
    global multiplicacao

multiplicacao:
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
    jmp .ler_n2_16             ; pula para a função que le o segundo número de 16 bits   

.ler_n1_32:
    call read_number32         ; chama função de ler número de 32 bits 
    mov [ebp-4], eax           ; copia o número lido em EAX para a variável local na pilha
    push len_num2              ; empilha tamanho do numero n2
    push msg_num2              ; empilha ponteiro para a string 
    call print_string          ; chama a função de printar string 
    jmp .ler_n2_32             ; pula para a função que le o segundo número de 32 bits   

.ler_n2_16:
    call read_number16         ; chama função de ler número de 16 bits  
    mov [ebp-8], eax           ; copia o número lido em EAX para a variável local na pilha
    jmp .multiplica_16         ; pula para a função de multiplicação de dois números de 16 bits

.ler_n2_32:
    call read_number32         ; chama função de ler número de 32 bits  
    mov [ebp-8], eax           ; copia o segundo número lido em EAX para a variável local na pilha
    jmp .multiplica_32         ; pula para a função de multiplicação de dois números de 32 bits

.multiplica_16:
    mov ax, word [ebp-4]       ; copia o primeiro número da pilha para o registrador AX
    imul ax, word [ebp-8]      ; multiplica o segundo número com primeiro deixando o resultado em AX
    jo .overflow               ; se overflow, pula para mensagem de erro
    movsx eax, ax              ; estende o sinal de 16 bits para 32 bits
    mov [ebp-12], eax          ; armazena o resultado na variável local na pilha
    jmp .print_resultado       ; pula para a função de print do resultado

.multiplica_32:
    mov eax, [ebp-4]           ; copia o primeiro número da pilha local para o registrador EAX
    imul dword [ebp-8]         ; multiplica o segundo número com o primeiro deixando o resultado em EAX
    jo .overflow               ; se overflow, pula para mensagem de erro
    mov [ebp-12], eax          ; armazena o resultado na variável local na pilha
    jmp .print_resultado       ; pula para a função de print do resultado

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