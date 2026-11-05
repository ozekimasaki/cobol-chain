#ifndef CBCHAIN_H
#define CBCHAIN_H

/* CBCHAIN 要求ブロック。COBOL の copy/cbrequest.cpy と同じ 736 バイト。 */

#include <stddef.h>
#include <stdio.h>
#include <string.h>

#define CB_REQUEST_BYTES 736

#define CB_OK 0
#define CB_ERR_NOT_FOUND 1
#define CB_ERR_EXISTS 2
#define CB_ERR_IO 3
#define CB_ERR_FORMAT 4
#define CB_ERR_ARGUMENT 5
#define CB_ERR_POW 6
#define CB_ERR_INDEX 7
#define CB_ERR_LINK 8
#define CB_ERR_HASH 9
#define CB_ERR_DIFFICULTY 10
#define CB_ERR_EMPTY 11
#define CB_ERR_RANGE 12
#define CB_ERR_FUNC 13

#define CB_FN_INIT 1
#define CB_FN_APPEND 2
#define CB_FN_GET 3
#define CB_FN_VERIFY 4
#define CB_FN_COUNT 5
#define CB_FN_LAST 6

#define CB_OPT_NONE 0
#define CB_OPT_REPLACE 1

typedef struct cb_request {
    char func[2];
    char options[2];
    char status[4];
    char fs[2];
    char detail[8];
    char path_len[4];
    char path[256];
    char data_len[4];
    char data[128];
    char difficulty[2];
    char max_nonce[10];
    char timestamp[14];
    char count[8];
    char index[8];
    char time[14];
    char prev[64];
    char blen[4];
    char bdata[128];
    char nonce[10];
    char hash[64];
} cb_request;

int cbchain_call(cb_request *request);

static inline void cb_put_u(char *dst, int width, unsigned long value) {
    char temp[32];
    snprintf(temp, sizeof temp, "%0*lu", width, value);
    memcpy(dst, temp, (size_t)width);
}

static inline unsigned long cb_get_u(const char *src, int width) {
    unsigned long value = 0;
    int i;
    for (i = 0; i < width; i++) {
        value = value * 10UL + (unsigned long)(src[i] - '0');
    }
    return value;
}

static inline void cb_request_clear(cb_request *request) {
    memset(request, ' ', sizeof *request);
    memset(request->func, '0', sizeof request->func);
    memset(request->options, '0', sizeof request->options);
    memset(request->status, '0', sizeof request->status);
    memset(request->fs, '0', sizeof request->fs);
    memset(request->detail, '0', sizeof request->detail);
    memset(request->path_len, '0', sizeof request->path_len);
    memset(request->data_len, '0', sizeof request->data_len);
    memset(request->difficulty, '0', sizeof request->difficulty);
    memset(request->max_nonce, '0', sizeof request->max_nonce);
    memset(request->count, '0', sizeof request->count);
    memset(request->index, '0', sizeof request->index);
    memset(request->blen, '0', sizeof request->blen);
    memset(request->nonce, '0', sizeof request->nonce);
}

static inline void cb_set_path(cb_request *request, const char *path) {
    size_t len = strlen(path);
    if (len > sizeof request->path) {
        len = sizeof request->path;
    }
    memset(request->path, ' ', sizeof request->path);
    memcpy(request->path, path, len);
    cb_put_u(request->path_len, (int)sizeof request->path_len, (unsigned long)len);
}

static inline void cb_set_data(cb_request *request, const char *data, size_t len) {
    if (len > sizeof request->data) {
        len = sizeof request->data;
    }
    memset(request->data, ' ', sizeof request->data);
    memcpy(request->data, data, len);
    cb_put_u(request->data_len, (int)sizeof request->data_len, (unsigned long)len);
}

static inline void cb_set_timestamp(cb_request *request, const char *timestamp) {
    memcpy(request->timestamp, timestamp, sizeof request->timestamp);
}

#endif
