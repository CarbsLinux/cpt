PREFIX    = /usr/local
BINDIR    = ${PREFIX}/bin
MANPREFIX = ${PREFIX}/share/man
MAN1      = ${MANPREFIX}/man1
CC        = cc

all: kiss-stat

kiss-stat:
	${CC} -o kiss-stat bin/kiss-stat.c

clean:
	rm -f kiss-stat

install: all
	mkdir -p ${DESTDIR}${BINDIR}
	cp kiss ${DESTDIR}${BINDIR}/kiss
	chmod 755 ${DESTDIR}${BINDIR}/kiss
	cp kiss-stat ${DESTDIR}${BINDIR}/kiss-stat
	chmod 755 ${DESTDIR}${BINDIR}/kiss-stat
	for bin in contrib/* ; do cp $${bin} ${DESTDIR}${BINDIR}/$${bin##*/}; \
		chmod 755 ${DESTDIR}${BINDIR}/$${bin##*/} ; done

	mkdir -p ${DESTDIR}${MAN1}
	for man in man/*.1 ; do cp $${man} ${DESTDIR}${MAN1}/$${man##*/}; \
		chmod 644 ${DESTDIR}${MAN1}/$${man##*/} ; done


uninstall:
	rm -f ${DESTDIR}${BINDIR}/kiss
	rm -f ${DESTDIR}${BINDIR}/kiss-stat
	for bin in contrib/* ; do rm -f ${DESTDIR}${BINDIR}/$${bin##*/} ; done
	rm -f ${DESTDIR}${MAN1}/kiss.1 ${DESTDIR}${MAN1}/kiss.1
	rm -f ${DESTDIR}${MAN1}/kiss-contrib.1 ${DESTDIR}${MAN1}/kiss-contrib.1


.PHONY: all install uninstall clean
