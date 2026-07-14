; ============================================================
; STUBS.ASM (TEMPORÁRIO)
; Versões vazias das operações que ainda não foram implementadas,
; só pra permitir montar e linkar o programa AGORA e testar a
; SOMA de ponta a ponta, sem esperar todas as 6 operações
; ficarem prontas.
;
; DELETE ESTE ARQUIVO quando subtracao.asm, multiplicacao.asm,
; divisao.asm, exponenciacao.asm e mod_op.asm estiverem prontos
; de verdade — senão eles vão dar erro de "símbolo duplicado"
; no linker (porque esses nomes já existiriam aqui também).
;
; Compilar: nasm -f elf32 stubs.asm -o stubs.o
; ============================================================

extern print_string

section .data
    msg_wip     db "(operacao ainda nao implementada)", 10
    len_wip     equ $ - msg_wip

section .text
    global subtracao
    global multiplicacao
    global divisao
    global exponenciacao
    global mod_op

subtracao:
    push len_wip
    push msg_wip
    call print_string
    ret

multiplicacao:
    push len_wip
    push msg_wip
    call print_string
    ret

divisao:
    push len_wip
    push msg_wip
    call print_string
    ret

exponenciacao:
    push len_wip
    push msg_wip
    call print_string
    ret

mod_op:
    push len_wip
    push msg_wip
    call print_string
    ret