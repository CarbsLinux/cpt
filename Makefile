PREFIX    = /usr/local
BINDIR    = ${PREFIX}/bin
MANPREFIX = ${PREFIX}/share/man
MAN1      = ${MANPREFIX}/man1

install:
	install -Dm755 -t ${DESTDIR}${BINDIR} kiss
	install -Dm755 -t ${DESTDIR}${BINDIR} contrib/*
	install -Dm644 -t ${DESTDIR}${MAN1} kiss.1

uninstall:
	rm -f ${DESTDIR}${BINDIR}/kiss
	for bin in contrib/* ; do rm -f ${DESTDIR}${BINDIR}/$${bin##*/} ; done
	rm -f ${DESTDIR}${MAN1}/kiss.1
