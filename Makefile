# See LICENSE for copyright information
include config.mk

SRC = bin/cpt-readlink.c bin/cpt-stat.c
OBJ = ${SRC:.c=.o}
BIN = ${SRC:.c=}

all: ${BIN}
ifeq ($(SYSTEM_GETOPT),1)
else
	${MAKE} -C getopt-ul
endif

.c.o:
	${CC} ${CFLAGS} -c -o $@ $<

${BIN}: ${OBJ}
	${CC} ${LDFLAGS} -o $@ $< ${LIBS}

clean:
	rm -f ${BIN} ${OBJ}
	${MAKE} -C getopt-ul clean

install: all
	for bin in src/* ${BIN} contrib/*; do \
		install -Dm755 $${bin} ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for man in man/*.1; do install -Dm644 $${man} ${DESTDIR}${MAN1}/$${man##*/}; done
	for doc in doc/*; do install -Dm644 $${doc} ${DESTDIR}${CPTDOC}/$${doc##*/}; done
ifeq ($(SYSTEM_GETOPT),1)
else
	${MAKE} -C getopt-ul install
endif

uninstall:
	for bin in ${BIN} src/* contrib/*; do \
		rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for man in man/*; do rm -f ${DESTDIR}${MAN1}/$${man##*/}; done
	rm -rf ${DESTDIR}${CPTDOC}


.PHONY: all install uninstall clean
