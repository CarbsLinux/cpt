# See LICENSE for copyright information
include config.mk

SRC = bin/kiss-readlink.c bin/kiss-stat.c
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
	mkdir -p ${DESTDIR}${BINDIR}
	cp -f kiss ${BIN} ${DESTDIR}${BINDIR}
	chmod 755 ${DESTDIR}${BINDIR}/kiss
	for bin in ${BIN}; do chmod 755 ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for bin in contrib/* ; do \
		cp -f $${bin} ${DESTDIR}${BINDIR}/$${bin##*/}; \
		chmod 755 ${DESTDIR}${BINDIR}/$${bin##*/} ; done
	mkdir -p ${DESTDIR}${MAN1}
	for man in man/*.1 ; do cp -f $${man} ${DESTDIR}${MAN1}/$${man##*/}; \
		chmod 644 ${DESTDIR}${MAN1}/$${man##*/} ; done
	mkdir -p ${DESTDIR}${KISSDOC}
	for doc in doc/*; do cp -f $${doc} ${DESTDIR}${KISSDOC}/$${doc##*/}; \
		chmod 644 ${DESTDIR}${KISSDOC}/$${doc##*/} ; done


uninstall:
	rm -f ${DESTDIR}${BINDIR}/kiss
	rm -f ${DESTDIR}${BINDIR}/kiss-stat
	rm -f ${DESTDIR}${BINDIR}/kiss-readlink
	for bin in ${BIN}; do rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for bin in contrib/*; do rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	rm -f ${DESTDIR}${MAN1}/kiss.1 ${DESTDIR}${MAN1}/kiss.1
	rm -f ${DESTDIR}${MAN1}/kiss-contrib.1 ${DESTDIR}${MAN1}/kiss-contrib.1
	rm -rf ${DESTDIR}${KISSDOC}


.PHONY: all install uninstall clean
