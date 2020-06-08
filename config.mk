# See LICENSE for copyright information

# Paths
PREFIX    = /usr/local
BINDIR    = ${PREFIX}/bin
SHAREDIR  = ${PREFIX}/share
DOCDIR    = ${SHAREDIR}/doc
KISSDOC   = ${DOCDIR}/kiss
MANPREFIX = ${SHAREDIR}/man
MAN1      = ${MANPREFIX}/man1

# Flags
CFLAGS  = -std=c99 -Wpedantic -Wall -Os
LDFLAGS = -s -static
LIBS    = -lc

# C compiler and linker
CC = cc
LD = ${CC}
