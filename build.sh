#!/bin/bash
# build.sh — monta todos os .asm, detecta operações ainda não
# implementadas (função não definida em nenhum .o) e gera um
# stub automático só pra elas, pra permitir linkar e testar o
# resto do programa mesmo com a equipe trabalhando em paralelo.
#
# Uso: ./build.sh

set -e   # para o script se qualquer comando falhar

mkdir -p objetos
rm -f objetos/*.o objetos/_stub_*.asm 2>/dev/null || true

echo "Montando arquivos..."
for arquivo in calculadora soma subtracao multiplicacao divisao exponenciacao mod_op; do
    if [ -f "${arquivo}.asm" ]; then
        nasm -f elf32 "${arquivo}.asm" -o "objetos/${arquivo}.o"
        echo "  OK: ${arquivo}.asm -> objetos/${arquivo}.o"
    else
        echo "  AVISO: ${arquivo}.asm nao encontrado, pulando."
    fi
done

echo ""
echo "Verificando simbolos das operacoes..."

# símbolo (nome da função) que cada operação precisa exportar
OPERACOES="soma subtracao multiplicacao divisao exponenciacao mod_op"

for simbolo in $OPERACOES; do
    # procura o símbolo já DEFINIDO (não apenas referenciado) em
    # algum dos .o já montados
    if nm objetos/*.o 2>/dev/null | grep -q " T ${simbolo}\$"; then
        echo "  OK: '${simbolo}' esta implementado."
    else
        echo "  AVISO: '${simbolo}' NAO esta implementado. Gerando stub temporario..."
        cat > "objetos/_stub_${simbolo}.asm" <<EOF
extern print_string
section .data
    _stub_msg db "(${simbolo} ainda nao implementada)", 10
    _stub_len equ \$ - _stub_msg
section .text
    global ${simbolo}
${simbolo}:
    push _stub_len
    push _stub_msg
    call print_string
    ret
EOF
        nasm -f elf32 "objetos/_stub_${simbolo}.asm" -o "objetos/_stub_${simbolo}.o"
    fi
done

echo ""
echo "Linkando..."
ld -m elf_i386 -o calculadora objetos/*.o

echo ""
echo "Pronto! Rode com: ./calculadora"