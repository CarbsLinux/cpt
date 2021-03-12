#!/bin/sh -e
# Convert 'contrib' scripts to manual pages.

# This script basically converts some of the comments inside scripts to manual
# page format. The intention behind this utility is to generate manual pages for
# contrib scripts without much hassle.

# Syntax:
# Every line starts with two hashes and a space ('## '). If the line ends with a
# colon (':'), it is assumed to be a section header. Subsections follow the same
# convention, but uses three hashes instead of two. If the line ends with two
# colons ('::'), the last colon will be removed.
#
# An empty '## ' line will
# start a new paragraph (.Pp).  Otherwise, mdoc(7) syntax is used as is.
# Headers are generated using the script's name, and the docstring is used from
# the line following the shebang.
#
# 'See also' section is pregenerated and only points the user to cpt(1). Others
# can be added with the following line and format:
#     ## see: cpt-fork.1 this-manpage.5

case "$1" in
    --help|-h|'')
        printf 'usage: %s [file]\n' "${0##*/}" >&2
        exit 1
esac

out() { printf '%s\n' "$@"; }

file=$1
filename=${file##*/}
see=''
date=$(date "+%b %d, %Y")
docstr=$(sed -n '2s/# //p' "$file" | tr '[:upper:]' '[:lower:]')

out \
    ".Dd $date" \
    ".Dt $filename 1" \
    ".Sh NAME" \
    ".Nm $filename" \
    ".Nd $docstr"

while read -r line; do
    case $line in
        '##'*::)
            line=${line%:} line=${line#'##'} line=${line#'#'} line=${line#' '}
            out "$line"
            ;;
        '###'*:)
            line=${line%:}
            out ".Ss ${line#'### '}"
            ;;
        '## see':*)
            line=${line##*:}
            see=$line
            ;;
        '##'*:)
            line=${line%:}
            out ".Sh ${line#'## '}"
            ;;
        '##'|'###')
            out ".Pp"
            ;;
        '##'*)
            line=${line#'##'} line=${line#'#'} line=${line# }
            out "$line"
            ;;
    esac
done < "$file"

out ".Sh AUTHOR" ".An Cem Keylan Aq Mt cem@ckyln.com"
out ".Sh LICENSE" "See LICENSE for copyright information."
out ".Sh SEE ALSO" ".Xr cpt 1"
[ "$see" ] &&
    for man in $see; do
        out ".Xr ${man%.[0-9]} ${man##*.}"
    done
out ".Pp"
out "The full documentation of cpt is available as an info page."
out "If either" ".Ic info" or ".Ic texinfo"
out "package is installed on your system, you can run"
out ".Bd -literal -offset indent" "info cpt" ".Ed"
out .Pp "to learn more about the package manager."
