# See LICENSE for copyright information
include config.mk

SRC = bin/cpt-readlink.c bin/cpt-stat.c
OBJ = ${SRC:.c=.o}
BIN = ${SRC:.c=}

all: ${BIN}

.c.o:
	${CC} ${CFLAGS} -c -o $@ $<

${BIN}: ${OBJ}
	${CC} ${LDFLAGS} -o $@ $< ${LIBS}

clean:
	rm -f ${BIN} ${OBJ}

install: all
	install -Dm755 ${DESTDIR}${BINDIR}/cpt-lib lib.sh
	install -Dm755 ${DESTDIR}${BINDIR}/cpt     cpt
	for bin in tools/* ${BIN} contrib/*; do \
		install -Dm755 ${DESTDIR}${BINDIR}/$${bin##*/} $${bin}; done
	for man in man/*.1; do install -Dm644 ${DESTDIR}${MAN1}/$${man##*/} $${man}; done
	for doc in doc/*; do install -Dm644 ${DESTDIR}${CPTDOC}/$${doc##*/} $${doc}; done

uninstall:
	rm -f ${DESTDIR}${BINDIR}/cpt \
		${DESTDIR}${BINDIR}/cpt-lib
	for bin in ${BIN} tools/* contrib/*; do \
		rm -f ${DESTDIR}${BINDIR}/$${bin}; done
	rm -f ${DESTDIR}${MAN1}/kiss.1 ${DESTDIR}${MAN1}/kiss.1
	rm -f ${DESTDIR}${MAN1}/kiss-contrib.1 ${DESTDIR}${MAN1}/kiss-contrib.1
	rm -rf ${DESTDIR}${CPTDOC}


.PHONY: all install uninstall clean
