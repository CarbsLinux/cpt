# Carbs Packaging Tools
include config.mk

INSTALL_SH = ./tools/install.sh
CONTRIB = `find contrib -name 'cpt*' ! -name '*.*'`
SRC     = `find src -name 'cpt*' ! -name '*.*'`
BIN     = ${SRC} ${CONTRIB}
LIB        = src/cpt-lib
LIB_IN     = ${LIB:=.in}

all: src/cpt-lib
	test "${DOCS}" != yes || ${MAKE} -C docs all

src/cpt-lib: src/cpt-lib.in
	sed -e "s|@VERSION@|${VERSION}|g" \
		-e "s|@DOCSTRING@|Call functions from the library|g" < src/cpt-lib.in > $@
	chmod 755 $@

test: all tests/etc/cpt-hook
	shellspec
	cd src; find . ../contrib -name 'cpt*' ! -name '*.*' -exec shellcheck -e 2119 -x -f gcc {} +

tests/etc/cpt-hook:
	ln -s ../hook-file $@

CHANGELOG.md:
	fossil wiki export Changelog | sed '1cCHANGELOG\n=========' > CHANGELOG.md

dist: docs/cpt.info CHANGELOG.md
	mkdir "cpt-${VERSION}"
	cp -r ${DISTFILES} "cpt-${VERSION}"
	tar cf "cpt-${VERSION}.tar" "cpt-${VERSION}"
	xz -z "cpt-${VERSION}.tar"
	rm -rf -- "cpt-${VERSION}"

install: all
	test "${DOCS}" != yes || ${MAKE} -C docs install
	${INSTALL_SH} -Dm755 -t ${DESTDIR}${BINDIR} ${BIN}
	${INSTALL_SH} -Dm644 -t ${DESTDIR}${MAN1} man/*.1
	for man in ${CONTRIB}; do \
		./tools/tool2man.sh $$man > "${DESTDIR}${MAN1}/$${man##*/}.1"; \
		chmod 644 "${DESTDIR}${MAN1}/$${man##*/}.1"; \
	done

uninstall:
	test "${DOCS}" != yes || ${MAKE} -C docs uninstall
	for bin in ${BIN}; do \
		rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for man in man/*.1; do rm -f ${DESTDIR}${MAN1}/$${man##*/}; done
	for man in ${CONTRIB}; do rm -f ${DESTDIR}${MAN1}/$${man##*/}.1; done

clean:
	test "${DOCS}" != yes || ${MAKE} -C docs clean
	rm -rf src/cpt-lib "cpt-${VERSION}.tar.xz" coverage report
	rm -f tests/etc/cpt-hook

.PHONY: all dist clean install uninstall
