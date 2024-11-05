#!/bin/bash

# Caminhos e variáveis
MOUNT_POINT=~/fuse_mount
SOURCE_FILE=fuse_testing.c
OUTPUT_FILE=fuse_testing

# Função para verificar o sucesso de um comando
function check_success {
    if [ $? -eq 0 ]; then
        echo "[PASS] $1"
    else
        echo "[FAIL] $1"
        exit 1
    fi
}

echo "A iniciar o Benchmark do Sistema de ficheiros FUSE"

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
echo -e "\n-------------------------------------------------------------\n"
sleep 2  # Dá um tempo para o FUSE montar o sistema

# Teste 1: Criar um novo ficheiro
touch $MOUNT_POINT/test_file.txt
echo "Criação de test_file.txt. A verificar criação:"
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Criação do ficheiro test_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 2: Escrever no ficheiro criado
echo "Primeiro conteúdo de teste" > $MOUNT_POINT/test_file.txt
echo "Writing em test_file.txt. A verificar conteúdos:"
cat "$HOME/Desktop/fuse_main/test_file.txt"
cat "$HOME/Desktop/backup_fuse/test_file.txt"
check_success "Escrita no ficheiro test_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 3: Acrescentar conteúdo ao ficheiro
echo "Conteúdo adicional" >> $MOUNT_POINT/test_file.txt
echo "Writing de conteúdo adicional em test_file.txt. A verificar conteúdos:"
cat "$HOME/Desktop/fuse_main/test_file.txt"
cat "$HOME/Desktop/backup_fuse/test_file.txt"
check_success "Acréscimo de conteúdo ao ficheiro test_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 4: Ler o conteúdo do ficheiro
echo "Leitura do ficheiro test_file.txt:"
cat $MOUNT_POINT/test_file.txt
check_success "Leitura do ficheiro test_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 5: Redimensionar o ficheiro (truncate)
truncate -s 10 $MOUNT_POINT/test_file.txt
ls -l "$HOME/Desktop/fuse_main/test_file.txt"
cat "$HOME/Desktop/fuse_main/test_file.txt"
echo -e "\n"
ls -l "$HOME/Desktop/backup_fuse/test_file.txt"
cat "$HOME/Desktop/backup_fuse/test_file.txt"
echo -e "\n"
check_success "Truncar o ficheiro test_file.txt para 10 bytes"
echo -e "\n-------------------------------------------------------------\n"

# Teste 6: Renomear o ficheiro
echo "Renomear os ficheiros. Verificação de nome:"
mv $MOUNT_POINT/test_file.txt $MOUNT_POINT/renamed_file.txt
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Renomear test_file.txt para renamed_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 7: Excluir o ficheiro
echo "Remoção dos ficheiros. Verificação de ficheiros na diretoria:"
rm $MOUNT_POINT/renamed_file.txt
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Remover renamed_file.txt"
echo -e "\n-------------------------------------------------------------\n"

# Teste 8: Criar uma nova diretória
echo "Criação de uma nova diretoria. Verificação da nova diretoria:"
mkdir $MOUNT_POINT/test_directory
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Criar diretoria test_directory"
echo -e "\n-------------------------------------------------------------\n"

# Teste 9: Criar um ficheiro na nova diretoria
echo "Criação de um ficheiro na nova diretoria. Verificação de ficheiros:"
echo "Conteúdo do ficheiro na diretoria" > $MOUNT_POINT/test_directory/file_in_dir.txt
cat "$HOME/Desktop/fuse_main/test_directory/file_in_dir.txt"
cat "$HOME/Desktop/backup_fuse/test_directory/file_in_dir.txt"
check_success "Criar ficheiro file_in_dir.txt dentro de test_directory"
echo -e "\n-------------------------------------------------------------\n"

# Teste 10: Renomear a diretoria
echo "Renomeação da nova diretoria. Verificação de ficheiros:"
mv $MOUNT_POINT/test_directory $MOUNT_POINT/renamed_directory
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Renomear test_directory para renamed_directory"
echo -e "\n-------------------------------------------------------------\n"

# Teste 11: Remover o ficheiro dentro da diretoria antes de remover a diretoria
echo "Remoção ficheiro dentro da nova diretoria. Verificação da remoção:"
rm $MOUNT_POINT/renamed_directory/file_in_dir.txt
ls "$HOME/Desktop/fuse_main/renamed_directory"
ls "$HOME/Desktop/backup_fuse/renamed_directory"
check_success "Remover file_in_dir.txt dentro de renamed_directory"
echo -e "\n-------------------------------------------------------------\n"

# Teste 12: Remover a diretoria
rmdir $MOUNT_POINT/renamed_directory
ls "$HOME/Desktop/fuse_main"
ls "$HOME/Desktop/backup_fuse"
check_success "Remover renamed_directory"
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
