#!/bin/bash

# Caminhos e variáveis
MOUNT_POINT=~/fuse_mount
OUTPUT_FILE=fuse_testingv2
LEVELDB_EXEC=leveldb

# Função para verificar o sucesso de um comando
function check_success {
    if [ $? -eq 0 ]; then
        echo "[PASS] $1"
    else
        echo "[FAIL] $1"
        exit 1
    fi
}

echo -e "A iniciar o Benchmark do Sistema de ficheiros FUSE\n"

# Passo 1: Desmontar o FUSE, se montado
if mountpoint -q "$MOUNT_POINT"; then
    fusermount3 -u "$MOUNT_POINT"
    check_success "Desmontagem de $MOUNT_POINT"
fi

# Passo 2: Remover e recriar a diretoria fuse_mount
rm -rf "$MOUNT_POINT"
check_success "Remover $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"
check_success "Criação da diretoria $MOUNT_POINT"

# Passo 3: Montar o FUSE
./"$OUTPUT_FILE" "$MOUNT_POINT" &
FUSE_PID=$!
check_success "Montar o sistema de ficheiros FUSE em $MOUNT_POINT"
sleep 3  # Aumenta o tempo de espera para garantir que o FUSE esteja montado

# Teste 1: Criar um novo ficheiro
echo -e "\nCriação de test_file.txt..."
touch $MOUNT_POINT/test6.txt
sync  # Garante que o sistema de arquivos seja atualizado
ls "$HOME/Desktop/fuse_main"
./"$LEVELDB_EXEC"
check_success "Verificação da criação de test_file.txt no LevelDB"
echo -e "\n-------------------------------------------------------------\n"
sleep 3

# Teste 2: Escrever num ficheiro
echo "Primeiro conteúdo de teste" > $MOUNT_POINT/test6.txt
sync  # Garante que a escrita seja atualizada no FUSE e no LevelDB
echo "Writing em test_file.txt. A verificar conteúdos:"
cat "$HOME/Desktop/fuse_main/test6.txt"
./"$LEVELDB_EXEC"
check_success "Escrita na diretoria principal e no LevelDB"
echo -e "\n-------------------------------------------------------------\n"

# Desmontar o sistema de ficheiros FUSE
fusermount3 -u "$MOUNT_POINT"
check_success "Desmontagem final de $MOUNT_POINT"
echo -e "\n-------------------------------------------------------------\n"

# Remover a diretoria fuse_mount (opcional)
rm -rf "$MOUNT_POINT"
check_success "Remoção de $MOUNT_POINT após desmontagem"
echo "Benchmark do Sistema de ficheiros FUSE Concluído"
echo -e "\n"
