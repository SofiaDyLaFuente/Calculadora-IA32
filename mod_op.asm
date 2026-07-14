; ============================================================
; MOD_OP.ASM
; Operação de módulo (resto da divisão): lê os 2 números,
; calcula num1 % num2, imprime o resultado.
; Compilar: nasm -f elf32 mod_op.asm -o mod_op.o
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
extern newline, len_newline
extern precisao
 
section .data
    msg_div_zero    db "ERRO: DIVISAO POR ZERO (MOD)", 10
    len_div_zero    equ $ - msg_div_zero
 
section .text
    global mod_op
 
; ------------------------------------------------------------
; mod_op: sem parâmetros de entrada (lê tudo sozinha).
; Sem retorno de valor (imprime o resultado ela mesma).
;
; Variáveis locais:
;   [ebp-4]  = dividendo (num1)
;   [ebp-8]  = divisor   (num2)
;   [ebp-12] = resultado (RESTO da divisão, não o quociente)
; ------------------------------------------------------------
mod_op:
    push ebp
    mov ebp, esp
    sub esp, 12
 
    push len_num1
    push msg_num1
    call print_string               ; "Digite o primeiro numero:"
 
    cmp dword [precisao], 0
    je .ler16_a
    call read_number32
    jmp .guardou_a
.ler16_a:
    call read_number16
.guardou_a:
    mov [ebp-4], eax                ; Guarda o dividendo
 
    push len_num2
    push msg_num2
    call print_string               ; "Digite o segundo numero:"
 
    cmp dword [precisao], 0
    je .ler16_b
    call read_number32
    jmp .guardou_b
.ler16_b:
    call read_number16
.guardou_b:
    mov [ebp-8], eax                ; Guarda o divisor
 
    ; ========================================================
    ; .CALCULA
    ; Igual à divisão (mesmo IDIV, mesma checagem de zero e
    ; mesma bifurcação 16/32 bits), mas o resultado que nos
    ; interessa é o RESTO: fica em DX (16 bits) ou EDX (32
    ; bits), não em AX/EAX.
    ; ========================================================
    cmp dword [ebp-8], 0
    je .divisao_por_zero
 
    cmp dword [precisao], 0
    je .calcula16
 
    ; --- caminho de 32 bits ---
    mov eax, [ebp-4]
    cdq                             ; Estende o sinal de EAX pra EDX:EAX
    idiv dword [ebp-8]              ; EAX = quociente (descartado), EDX = resto
    mov [ebp-12], edx               ; Guarda o RESTO
    jmp .mostra
 
.calcula16:
    ; --- caminho de 16 bits ---
    mov ax, word [ebp-4]
    cwd                             ; Estende o sinal de AX pra DX:AX
    idiv word [ebp-8]               ; AX = quociente (descartado), DX = resto
    movsx eax, dx                   ; Estende o RESTO (DX) de volta pra 32 bits
    mov [ebp-12], eax
 
.mostra:

    ; MOSTRA RESULTADO
    
    push len_resultado
    push msg_resultado
    call print_string               ; "Resultado: "
 
    push dword [ebp-12]
    call print_number               ; Imprime o resto
 
    push len_newline
    push newline
    call print_string          
 
    jmp .fim
 
.divisao_por_zero:
    push len_div_zero
    push msg_div_zero
    call print_string               ; "ERRO: DIVISAO POR ZERO (MOD)"
 
.fim:
    mov esp, ebp
    pop ebp
    ret