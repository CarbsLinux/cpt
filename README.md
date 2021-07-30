Carbs Packaging Tools
=====================

    ##### ####  #####
    #   # #   #   #
    #     ####    #
    #   # #       #
    ##### #       #


Package management toolset for Carbs Linux. Forked from [KISS]. All usage
information can be obtained from the manual page. Refer to the [ChangeLog] to
learn what's new.


Dependencies
------------

To build and use cpt, you need the following software:

- rsync
- curl
- POSIX base utilities  [coreutils, busybox, sbase, etc.]
- pax
- Common compression utilities such as `gzip`, `bzip2`, `xz`, etc.


In order to build the documentation from source, you will need the following
software:

- GNU Texinfo (for generating `.info` pages)
- GNU Emacs   (for generating `.texi` and `.txt` pages)

However, distributed tarballs come with info pages, and `.texi` and `.txt` files
are committed directly into the repository, meaning that you don't need Texinfo
if you are using a tarball, and you don't need Emacs as long as you don't edit
the documentation.

You can also completely disable the build/installation of the documentation by
either passing `DOCS=no` to `make` or editing `config.mk` to disable it.


Installation
------------

In order to install CPT, you can run the following:

    ./configure
    make
    make install


Documentation
-------------

The documentation for each tool along with some examples can be found on
manpages installed with the package manager. User manual of CPT can be found
[online], or installed as both plain-text and as info pages. Without any
changes to the Makefile configuration those files can be found at:

- /usr/local/share/docs/cpt/cpt.txt
- /usr/local/share/info/cpt.info

[KISS]: https://github.com/kisslinux/kiss
[ChangeLog]: https://fossil.carbslinux.org/cpt/doc/trunk/CHANGELOG.md
[online]: https://carbslinux.org/docs/cpt
