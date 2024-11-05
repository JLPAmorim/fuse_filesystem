#define FUSE_USE_VERSION 31

#include <fuse3/fuse.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>
#include <fcntl.h>    // Para open, O_CREAT, etc.
#include <unistd.h>   // Para close, read, write, etc.

static const char *main_dir = "/home/joao/Desktop/fuse_main";
static const char *backup_dir = "/home/joao/Desktop/backup_fuse";

// Função para obter atributos de ficheiro e diretoria
static int my_fuse_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi) {
    char main_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);

    int res = stat(main_path, stbuf);
    if (res == -1) return -errno;
    return 0;
}

// Função para listar o conteúdo do diretoria
static int my_fuse_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                           off_t offset, struct fuse_file_info *fi, enum fuse_readdir_flags flags) {
    char main_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);

    DIR *dp = opendir(main_path);
    if (!dp) return -errno;

    struct dirent *de;
    while ((de = readdir(dp)) != NULL) {
        filler(buf, de->d_name, NULL, 0, FUSE_FILL_DIR_PLUS);
    }
    closedir(dp);
    return 0;
}

// Função para abrir ficheiros
static int my_fuse_open(const char *path, struct fuse_file_info *fi) {
    char main_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);

    int fd = open(main_path, O_RDONLY);
    if (fd == -1) return -errno;
    close(fd);
    return 0;
}

// Função para criar novos ficheiros com backup
static int my_fuse_create(const char *path, mode_t mode, struct fuse_file_info *fi) {
    char main_path[512], backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    // Cria o ficheiro na diretoria principal
    int fd_main = open(main_path, O_WRONLY | O_CREAT | O_TRUNC, mode);
    if (fd_main == -1) return -errno;
    close(fd_main);

    // Cria o ficheiro no diretoria de backup
    int fd_backup = open(backup_path, O_WRONLY | O_CREAT | O_TRUNC, mode);
    if (fd_backup == -1) return -errno;
    close(fd_backup);

    return 0;
}

// Função para leitura de ficheiros
static int my_fuse_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    char main_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);

    int fd = open(main_path, O_RDONLY);
    if (fd == -1) return -errno;

    if (lseek(fd, offset, SEEK_SET) == -1) {
        close(fd);
        return -errno;
    }

    ssize_t bytes_read = read(fd, buf, size);
    if (bytes_read == -1) bytes_read = -errno;

    close(fd);
    return bytes_read;
}

// Função para escrita de ficheiros com backup
static int my_fuse_write(const char *path, const char *buf, size_t len, off_t offset, struct fuse_file_info *fi) {
    char main_path[512], backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    // Escreve no ficheiro principal
    int fd_main = open(main_path, O_WRONLY | O_CREAT, 0666);
    if (fd_main == -1) return -errno;

    if (lseek(fd_main, offset, SEEK_SET) == -1) {
        close(fd_main);
        return -errno;
    }
    ssize_t written_main = write(fd_main, buf, len);
    if (written_main == -1) written_main = -errno;
    close(fd_main);

    // Escreve no ficheiro de backup
    int fd_backup = open(backup_path, O_WRONLY | O_CREAT, 0666);
    if (fd_backup == -1) return -errno;

    if (lseek(fd_backup, offset, SEEK_SET) == -1) {
        close(fd_backup);
        return -errno;
    }
    ssize_t written_backup = write(fd_backup, buf, len);
    if (written_backup == -1) written_backup = -errno;
    close(fd_backup);

    return written_main;
}

// Função para truncar ficheiros na diretoria principal e de backup
static int my_fuse_truncate(const char *path, off_t size, struct fuse_file_info *fi) {
    char main_path[512], backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    if (truncate(main_path, size) == -1) return -errno;
    if (truncate(backup_path, size) == -1) return -errno;

    return 0;
}

// Função para remover ficheiros da diretoria principal e de backup
static int my_fuse_unlink(const char *path) {
    char main_path[512];
    char backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    if (unlink(main_path) == -1) return -errno;
    if (unlink(backup_path) == -1) return -errno;

    return 0;
}

// Função para criar diretorias na diretoria principal e no backup
static int my_fuse_mkdir(const char *path, mode_t mode) {
    char main_path[512];
    char backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    if (mkdir(main_path, mode) == -1) return -errno;
    if (mkdir(backup_path, mode) == -1) return -errno;

    return 0;
}

// Função para remover diretorias
static int my_fuse_rmdir(const char *path) {
    char main_path[512];
    char backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(main_path), "%s%s", backup_dir, path);

    if (rmdir(main_path) == -1) return -errno;
    if (rmdir(backup_path) == -1) return -errno;

    return 0;
}

// Função para renomear ficheiros e diretorias
static int my_fuse_rename(const char *oldpath, const char *newpath, unsigned int flags) {
    char main_oldpath[512], main_newpath[512], backup_oldpath[512], backup_newpath[512];
    snprintf(main_oldpath, sizeof(main_oldpath), "%s%s", main_dir, oldpath);
    snprintf(main_newpath, sizeof(main_newpath), "%s%s", main_dir, newpath);
    snprintf(backup_oldpath, sizeof(backup_oldpath), "%s%s", backup_dir, oldpath);
    snprintf(backup_newpath, sizeof(backup_newpath), "%s%s", backup_dir, newpath);

    if (rename(main_oldpath, main_newpath) == -1) return -errno;
    if (rename(backup_oldpath, backup_newpath) == -1) return -errno;

    return 0;
}

// Função para atualizar as timestamps de ficheiros
static int my_fuse_utimens(const char *path, const struct timespec ts[2], struct fuse_file_info *fi) {
    char main_path[512];
    char backup_path[512];
    snprintf(main_path, sizeof(main_path), "%s%s", main_dir, path);
    snprintf(backup_path, sizeof(backup_path), "%s%s", backup_dir, path);

    if (utimensat(0, main_path, ts, 0) == -1) return -errno;
    if (utimensat(0, backup_path, ts, 0) == -1) return -errno;

    return 0;
}

// Estrutura de operações FUSE
static struct fuse_operations my_fuse_operations = {
    .getattr = my_fuse_getattr,
    .readdir = my_fuse_readdir,
    .open = my_fuse_open,
    .create = my_fuse_create,
    .read = my_fuse_read,
    .write = my_fuse_write,
    .truncate = my_fuse_truncate,
    .unlink = my_fuse_unlink,
    .mkdir = my_fuse_mkdir,
    .rmdir = my_fuse_rmdir,
    .rename = my_fuse_rename,
    .utimens = my_fuse_utimens,
};

int main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &my_fuse_operations, NULL);
}