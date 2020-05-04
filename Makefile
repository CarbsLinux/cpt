PREFIX    = /usr/local
BINDIR    = ${PREFIX}/bin
MANPREFIX = ${PREFIX}/share/man
MAN1      = ${MANPREFIX}/man1
CC        = cc

all: kiss-stat kiss-readlink

kiss-stat:
	${CC} -o kiss-stat bin/kiss-stat.c

kiss-readlink:
	${CC} -o kiss-readlink bin/kiss-readlink.c

clean:
	rm -f kiss-stat kiss-readlink

install: all
	mkdir -p ${DESTDIR}${BINDIR}
	cp kiss kiss-stat kiss-readlink ${DESTDIR}${BINDIR}
	chmod 755 ${DESTDIR}${BINDIR}/kiss \
		${DESTDIR}${BINDIR}/kiss-stat \
		${DESTDIR}${BINDIR}/kiss-readlink
	for bin in contrib/* ; do \
		cp $${bin} ${DESTDIR}${BINDIR}/$${bin##*/}; \
		chmod 755 ${DESTDIR}${BINDIR}/$${bin##*/} ; done

	mkdir -p ${DESTDIR}${MAN1}
	for man in man/*.1 ; do cp $${man} ${DESTDIR}${MAN1}/$${man##*/}; \
		chmod 644 ${DESTDIR}${MAN1}/$${man##*/} ; done


uninstall:
	rm -f ${DESTDIR}${BINDIR}/kiss
	rm -f ${DESTDIR}${BINDIR}/kiss-stat
	rm -f ${DESTDIR}${BINDIR}/kiss-readlink
	for bin in contrib/* ; do rm -f ${DESTDIR}${BINDIR}/$${bin##*/} ; done
	rm -f ${DESTDIR}${MAN1}/kiss.1 ${DESTDIR}${MAN1}/kiss.1
	rm -f ${DESTDIR}${MAN1}/kiss-contrib.1 ${DESTDIR}${MAN1}/kiss-contrib.1


.PHONY: all install uninstall clean
