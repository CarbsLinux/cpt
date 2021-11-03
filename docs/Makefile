# Carbs Packaging Tools Documentation
-include ../config.mk
INSTALL_SH = ../tools/install.sh

all: cpt.txt cpt.texi cpt.info

config.org: ../config.mk
	printf '%s\n' '#+MACRO: version $(VERSION)' \
		          '#+MACRO: conf_dir (eval (concat "=$(SYSCONFDIR)/cpt/" $$1 "="))' \
		          '#+MACRO: data_dir (eval (concat "=$(DATAROOTDIR)/" $$1 "="))' > config.org

cpt.txt cpt.texi cpt.info: cpt.org config.org

.SUFFIXES: .info .texi .org .txt
.org.texi:
	rm -f $@
	${EMACS} $< --batch -f org-texinfo-export-to-texinfo

.texi.info:
	${MAKEINFO} $< -o $@

.org.txt:
	rm -f $@
	${EMACS} $< --batch -f org-ascii-export-to-ascii

clean:
	rm -f cpt.info

all-clean: clean
	rm -f cpt.texi cpt.txt config.org

.PHONY: all clean all-clean install uninstall
