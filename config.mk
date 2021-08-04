# Carbs Packaging Tools
VERSION = 6.1.1

# Installation paths
PREFIX    = /usr/local
BINDIR    = ${PREFIX}/bin
SHAREDIR  = ${PREFIX}/share
INFODIR   = ${SHAREDIR}/info
DOCDIR    = ${SHAREDIR}/doc
CPTDOC    = ${DOCDIR}/cpt
MANPREFIX = ${SHAREDIR}/man
MAN1      = ${MANPREFIX}/man1

EMACS     = emacs
MAKEINFO  = makeinfo

# Comment or change if you don't want to build/install the documentation
DOCS = yes
