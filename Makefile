.PHONY: all test clean

COBC = cobc
COBFLAGS = -free -O2 -I copy

all: chain CBCHAIN.so embed

CBCHAIN.so: cbchain.cbl sha256.cbl copy/cbconst.cpy copy/cbrequest.cpy
	$(COBC) -b $(COBFLAGS) -o CBCHAIN.so cbchain.cbl sha256.cbl

chain: chain.cbl cbchain.cbl sha256.cbl copy/cbconst.cpy copy/cbrequest.cpy
	$(COBC) -x $(COBFLAGS) -o chain chain.cbl cbchain.cbl sha256.cbl

shatest: shatest.cbl sha256.cbl
	$(COBC) -x $(COBFLAGS) -o shatest shatest.cbl sha256.cbl

cbtest: cbtest.cbl cbchain.cbl sha256.cbl copy/cbconst.cpy copy/cbrequest.cpy
	$(COBC) -x $(COBFLAGS) -o cbtest cbtest.cbl cbchain.cbl sha256.cbl

embed: embed.c cbchain_api.c cbchain.h CBCHAIN.so
	$(COBC) -x -o embed embed.c cbchain_api.c -I.

test: shatest cbtest embed
	./shatest
	./cbtest
	COB_LIBRARY_PATH=. ./embed

clean:
	rm -f chain shatest cbtest embed CBCHAIN.so \
		chain.dat cbtest.dat cbdefault.dat cbpow.dat cembed.dat \
		*.o
