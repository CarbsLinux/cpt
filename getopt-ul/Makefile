include ../config.mk

getopt: getopt.c
	${CC} -include config.h ${CFLAGS} ${LDFLAGS} -o getopt getopt.c

clean:
	rm -f getopt

install:
	install -Dm755 getopt ${DESTDIR}${BINDIR}/getopt

uninstall:
	rm -f ${DESTDIR}${BINDIR}/getopt

.PHONY: all install uninstall clean
