#include "cbchain.h"

#include <stdio.h>
#include <string.h>

static int expect_status(const cb_request *request, unsigned long want, const char *step) {
    unsigned long status = cb_get_u(request->status, 4);
    if (status == want) {
        return 0;
    }
    fprintf(stderr, "NG %s status=%lu want=%lu detail=%lu fs=%.2s\n",
        step, status, want, cb_get_u(request->detail, 8), request->fs);
    return 1;
}

int main(void) {
    cb_request request;
    int failed = 0;

    if (sizeof(cb_request) != CB_REQUEST_BYTES) {
        fprintf(stderr, "NG sizeof=%zu\n", sizeof(cb_request));
        return 1;
    }

    memset(&request, 0, sizeof request);
    if (cbchain_call(&request) < 0) {
        fprintf(stderr, "NG cob_call failed\n");
        return 1;
    }
    failed += expect_status(&request, CB_ERR_FUNC, "zeroed");

    cb_request_clear(&request);
    cb_set_path(&request, "cembed.dat");
    cb_put_u(request.func, 2, CB_FN_INIT);
    cb_put_u(request.options, 2, CB_OPT_REPLACE);
    cb_put_u(request.difficulty, 2, 1);
    cb_set_data(&request, "GENESIS / C API", strlen("GENESIS / C API"));
    cb_set_timestamp(&request, "20261105130000");
    cbchain_call(&request);
    failed += expect_status(&request, CB_OK, "init");

    cb_request_clear(&request);
    cb_set_path(&request, "cembed.dat");
    cb_put_u(request.func, 2, CB_FN_APPEND);
    cb_set_data(&request, "from C", 6);
    cb_set_timestamp(&request, "20261105130001");
    cbchain_call(&request);
    failed += expect_status(&request, CB_OK, "append");
    if (cb_get_u(request.index, 8) != 1 || memcmp(request.bdata, "from C", 6) != 0) {
        fprintf(stderr, "NG append payload\n");
        failed += 1;
    }

    cb_request_clear(&request);
    cb_set_path(&request, "cembed.dat");
    cb_put_u(request.func, 2, CB_FN_VERIFY);
    cbchain_call(&request);
    failed += expect_status(&request, CB_OK, "verify");
    if (cb_get_u(request.count, 8) != 2) {
        fprintf(stderr, "NG count=%lu\n", cb_get_u(request.count, 8));
        failed += 1;
    }

    if (failed == 0) {
        printf("EMBED OK\n");
        return 0;
    }
    fprintf(stderr, "EMBED NG %d\n", failed);
    return 1;
}
