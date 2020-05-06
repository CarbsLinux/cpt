KISS PACKAGE MANAGER
--------------------

Package manager for Carbs Linux. Forked from [KISS]. All
usage information can be obtained from the manual page.
For changes please refer to the `CHANGELOG.md` file.

[KISS]: https://github.com/kisslinux/kiss

## Fork Notes

There are certain differences between KISS Linux `kiss` and
Carbs Linux `kiss`. Most importantly, you need a C compiler
and a C library (musl/bsd libc) to build this implementation
of it. Rest of the important changes can be found in the CHANGELOG.

This is _mostly_ a shell implementation rather than a pure one.

### Directory Structure

    /        -- kiss, README, Makefile, LICENSE, CHANGELOG
    bin/     -- for C programs.
    man/     -- for manual pages / documentation.
    contrib/ -- for Shell scripts that wrap around kiss.

### Contributing

Please see the [style and contribution guidelines].

[style and contribution guidelines]: https://github.com/carbslinux/contributing
