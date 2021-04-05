# Carbs Packaging Tools
VERSION = 6.0.2

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

# Files to be added into the distribution tarball
DISTFILES = \
    .build.yml \
    .dir-locals.el \
    .editorconfig \
    .fossil-settings \
    .gitignore \
    .shellspec \
    CHANGELOG.md \
    LICENSE \
    Makefile \
    README.md \
    config.mk \
    contrib \
    cpt-base \
    docs \
    man \
    spec \
    src \
    tests \
    tools
