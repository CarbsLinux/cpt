#!/bin/sh -e

out() { printf '%s\n' "$@" >&2 ;}
die() { printf '\033[1;31mERR: \033[m%s\n' "$@" >&2; exit 1;}

case "$1" in ''|-*)
    die "Run this script by calling 'make dist' from the" \
        "root repository directory"
esac

fossil stat >/dev/null 2>&1 || {
    printf '\033[1;31mERR: \033[m%s\n' \
        "Distribution tarballs can only be generated using the Fossil repository." \
        "Exiting..." >&2
    exit 1
}

basedir=cpt-$1
mkdir -p "$basedir"

fossil ls | while read -r file; do
    case "$file" in
        */*) mkdir -p "$basedir/${file%/*}"
    esac
    cp "$file" "$basedir/$file"
done

tar cf "$basedir.tar" "$basedir"
xz -z "$basedir.tar"
rm -rf -- "$basedir"
