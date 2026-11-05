#include "cbchain.h"

#include <libcob.h>

static int cbchain_ready;

int cbchain_call(cb_request *request) {
    void *args[1];
    char *argv[] = { "cbchain", NULL };

    if (!cbchain_ready) {
        cob_init(1, argv);
        cbchain_ready = 1;
    }
    args[0] = request;
    return cob_call("CBCHAIN", 1, args);
}
