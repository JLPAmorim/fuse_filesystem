#include <stdio.h>
#include <stdlib.h>
#include <leveldb/c.h>

int main() {
    leveldb_t *db;
    leveldb_options_t *options;
    leveldb_readoptions_t *read_options;
    leveldb_iterator_t *it;
    char *err = NULL;

    options = leveldb_options_create();
    leveldb_options_set_create_if_missing(options, 1);
    db = leveldb_open(options, "/home/joao/Desktop/leveldb_backup", &err);

    if (err != NULL) {
        printf("Erro ao abrir LevelDB: %s\n", err);
        leveldb_free(err);
        return 1;
    }

    // Cria um iterador para a base de dados
    read_options = leveldb_readoptions_create();
    it = leveldb_create_iterator(db, read_options);

    printf("Entradas no LevelDB:\n");
    for (leveldb_iter_seek_to_first(it); leveldb_iter_valid(it); leveldb_iter_next(it)) {
        // Obter chave
        size_t key_len;
        const char *key = leveldb_iter_key(it, &key_len);

        // Obter valor associado à chave diretamente do iterador
        size_t value_len;
        const char *value = leveldb_iter_value(it, &value_len);

        // Exibir chave e valor
        printf("Chave: %.*s | Valor: %.*s\n", (int)key_len, key, (int)value_len, value);
    }

    // Limpar e fechar a base de dados e o iterador
    leveldb_iter_destroy(it);
    leveldb_readoptions_destroy(read_options);
    leveldb_close(db);
    leveldb_options_destroy(options);

    return 0;
}


