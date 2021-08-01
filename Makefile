# Carbs Packaging Tools
-include config.mk

INSTALL_SH = ./tools/install.sh
CONTRIB = `find contrib -name 'cpt*' ! -name '*.*'`
SRC     = `find src -name 'cpt*' ! -name '*.*'`
BIN     = ${SRC} ${CONTRIB}

all: src/cpt-lib
	@if ! [ -e config.mk ]; then echo "Please run './configure'"; exit 1; fi
	@test "${DOCS}" != yes || ${MAKE} -C docs all

src/cpt-lib: src/cpt-lib.in
	sed -n '/^Copyright/{s,^,        ",;s,$$," \\,;p}' LICENSE | \
	sed -e '/@LICENSE@/r /dev/stdin' \
		-e '/@LICENSE@/d' \
		-e "s|@VERSION@|${VERSION}|g" \
		-e "s|@DOCSTRING@|Call functions from the library|g" src/cpt-lib.in > $@
	chmod 755 $@

shellspec: all tests/etc/cpt-hook
	shellspec

shellcheck: all
	cd src; find . ../contrib -name 'cpt*' ! -name '*.*' -exec shellcheck -e 2119 -x -f gcc {} +

test: shellspec shellcheck

tests/etc/cpt-hook:
	ln -s ../hook-file $@

dist: docs/cpt.info
	@if ! [ -e config.mk ]; then echo "Please run './configure'"; exit 1; fi
	./tools/mkdist.sh "${VERSION}"

install: all
	test "${DOCS}" != yes || ${MAKE} -C docs install
	[ -f docs/cpt.info ] && \
		${INSTALL_SH} -Dm644 docs/cpt.info ${DESTDIR}${INFODIR}/cpt.info
	[ -f docs/cpt.txt ] && \
		${INSTALL_SH} -Dm644 docs/cpt.txt  ${DESTDIR}${DOCDIR}/cpt.txt
	${INSTALL_SH} -Dm644 CHANGELOG.md  ${DESTDIR}${DOCDIR}/CHANGELOG
	${INSTALL_SH} -Dm755 -t ${DESTDIR}${BINDIR} ${BIN}
	${INSTALL_SH} -Dm644 -t ${DESTDIR}${MAN1} man/*.1
	for man in ${CONTRIB}; do \
		./tools/tool2man.sh $$man > "${DESTDIR}${MAN1}/$${man##*/}.1"; \
		chmod 644 "${DESTDIR}${MAN1}/$${man##*/}.1"; \
	done

uninstall:
	for bin in ${BIN}; do \
		rm -f ${DESTDIR}${BINDIR}/$${bin##*/}; done
	for man in man/*.1; do rm -f ${DESTDIR}${MAN1}/$${man##*/}; done
	for man in ${CONTRIB}; do rm -f ${DESTDIR}${MAN1}/$${man##*/}.1; done
	rm -rf ${DESTDIR}${DOCDIR}
	rm -f  ${DESTDIR}${INFODIR}/cpt.info

clean:
	${MAKE} -C docs clean
	rm -rf src/cpt-lib "cpt-${VERSION}.tar.xz" coverage report
	rm -f tests/etc/cpt-hook

allclean: clean
	rm -f config.mk

.PHONY: all dist allclean clean install uninstall shellspec shellcheck test
