# Nome dos executáveis
FUSE_EXEC = fuse_testingv2
FUSE_EXEC_OLD = fuse_testing
LEVELDB_EXEC = leveldb

# Diretório de montagem do FUSE
MOUNT_POINT = ~/fuse_mount

# Compilador e flags
CC = gcc
CFLAGS = -Wall -D_FILE_OFFSET_BITS=64
LDFLAGS_FUSE = -lfuse3 -lleveldb  # Inclui LevelDB para os executáveis FUSE
LDFLAGS_LEVELDB = -lleveldb

# Alvos principais
all: $(FUSE_EXEC) $(FUSE_EXEC_OLD) $(LEVELDB_EXEC)

# Compila fuse_testingv2.c com suporte a FUSE e LevelDB
$(FUSE_EXEC): fuse_testingv2.c
	$(CC) $(CFLAGS) fuse_testingv2.c -o $(FUSE_EXEC) $(LDFLAGS_FUSE)

# Compila fuse_testing.c com suporte a FUSE
$(FUSE_EXEC_OLD): fuse_testing.c
	$(CC) $(CFLAGS) fuse_testing.c -o $(FUSE_EXEC_OLD) $(LDFLAGS_FUSE)

# Compila leveldb.c com suporte a LevelDB
$(LEVELDB_EXEC): leveldb.c
	$(CC) $(CFLAGS) leveldb.c -o $(LEVELDB_EXEC) $(LDFLAGS_LEVELDB)

# Desmonta e remove a diretoria de montagem do FUSE se estiver montado
unmount:
	@if mountpoint -q $(MOUNT_POINT); then \
		echo "Desmontando o sistema de arquivos FUSE em $(MOUNT_POINT)"; \
		fusermount3 -u $(MOUNT_POINT); \
		rm -rf $(MOUNT_POINT); \
	else \
		echo "$(MOUNT_POINT) não está montado."; \
	fi

# Cria a diretoria de montagem e monta o FUSE
mount: all
	@mkdir -p $(MOUNT_POINT)
	@if ! mountpoint -q $(MOUNT_POINT); then \
		echo "Montando o sistema de arquivos FUSE em $(MOUNT_POINT)"; \
		./$(FUSE_EXEC) $(MOUNT_POINT) & \
	else \
		echo "$(MOUNT_POINT) já está montado."; \
	fi

clean:
	rm -f $(FUSE_EXEC) $(FUSE_EXEC_OLD) $(LEVELDB_EXEC)

