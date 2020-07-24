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
	install -Dm755 lib.sh ${DESTDIR}${BINDIR}/cpt-lib
	install -Dm755 cpt    ${DESTDIR}${BINDIR}/cpt
	for bin in tools/* ${BIN} contrib/*; do \
		install -Dm755 $${bin} ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for man in man/*.1; do install -Dm644 $${man} ${DESTDIR}${MAN1}/$${man##*/}; done
	for doc in doc/*; do install -Dm644 $${doc} ${DESTDIR}${CPTDOC}/$${doc##*/}; done

uninstall:
	rm -f ${DESTDIR}${BINDIR}/cpt \
		${DESTDIR}${BINDIR}/cpt-lib
	for bin in ${BIN} tools/* contrib/*; do \
		rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	rm -f ${DESTDIR}${MAN1}/kiss.1 ${DESTDIR}${MAN1}/kiss.1
	rm -f ${DESTDIR}${MAN1}/kiss-contrib.1 ${DESTDIR}${MAN1}/kiss-contrib.1
	rm -rf ${DESTDIR}${CPTDOC}


.PHONY: all install uninstall clean
