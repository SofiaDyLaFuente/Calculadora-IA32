; ============================================================
; SOMA.ASM
; Implementa a operação de soma entre dois inteiros.
; Compilar: nasm -f elf32 soma.asm -o soma.o
; ============================================================

; IMPORTS
extern print_string
extern read_number16
extern read_number32
extern print_number

; MENSAGENS E VARIÁVEL DE PRECISÃO
extern msg_num1, len_num1
extern msg_num2, len_num2
extern msg_resultado, len_resultado
extern msg_overflow, len_overflow
extern newline, len_newline
extern precisao

section .text
    global soma                 ; Exporta 'soma' para calculadora.asm poder chamá-la

; ------------------------------------------------------------
; soma: sem parâmetros de entrada (ela lê tudo sozinha).       
; Sem valor de retorno (ela mesma imprime o resultado).   
;                                                         
; Variáveis locais (obrigatoriamente na pilha):           
;   [ebp-4]  = primeiro número lido                       
;   [ebp-8]  = segundo número lido                        
;   [ebp-12] = resultado da soma                          
; ------------------------------------------------------------

soma: 
    push ebp
    mov ebp, esp
    sub esp, 12                 ; Espaço pra 3 variáveis locais

    ; --- Primeiro número ---
    push len_num1
    push msg_num1
    call print_string

    cmp dword [precisao], 0
    je .ler16_a
    call read_number32
    jmp .guardou_a  

.ler16_a:
    call read_number16

.guardou_a: 
    mov [ebp-4], eax            ; Guarda o 1º número na variável local

    ; --- Segundo número ---
    push len_num2
    push msg_num2
    call print_string

    cmp dword [precisao], 0
    je .ler16_b
    call read_number32
    jmp .guardou_b

.ler16_b:
    call read_number16

.guardou_b:
    mov [ebp-8], eax            ; Guarda o 2º número na variável local

    ; .CALCULA                                           ;
    ; A conta em si. Cada operação troca só este bloco:  ;

    ; Caminho de 32 bits

    cmp dword [precisao], 0
    je .calcula16
    
    mov eax, [ebp-4]            ; EAX = num1 + num2 
    add eax, [ebp-8]            
    jo .overflow                ; overflow -> pula pra mensagem de erro
    mov [ebp-12], eax           ; guarda o resultado na variável local
    jmp .mostra 

.calcula16:
    ; Caminho de 16 bits
    mov ax, word [ebp-4]
    add ax, word [ebp-8]         ; seta OF se estourar os limites do int16
    jo .overflow
    movsx eax, ax                ; estende AX de volta pra 32 bits, pra print_number funcionar igual nos dois casos
    mov [ebp-12], eax

.mostra:
    
    ; MOSTRA O RESULTADO

    push len_resultado
    push msg_resultado
    call print_string 

    push dword [ebp-12]
    call print_number 

    push len_newline
    push newline 
    call print_string 

    jmp .fim 

.overflow:
    push len_overflow
    push msg_overflow
    call print_string

    ; POR FIM ENCERRA, NÃO HÁ NADA PRA LIMPAR ALÉM DO PRÓPRIO FRAME -> "RET" PURO
.fim: 
    mov esp, ebp
    pop ebp
    ret 