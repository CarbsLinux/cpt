#!/bin/sh -e
# Convert 'contrib' scripts to manual pages.

# This script basically converts some of the comments inside scripts to manual
# page format. The intention behind this utility is to generate manual pages for
# contrib scripts without much hassle.

case "$1" in
    --help|-h|'')
        printf 'usage: %s [file]\n' "${0##*/}" >&2
        exit 1
esac

out() { printf '%s\n' "$@"; }

file=$1
filename=${file##*/}
date=$(date "+%b %d, %Y")
docstr=$(sed -n '2s/# //p' $file)

out \
    ".Dd $date" \
    ".Dt $filename 1" \
    ".Sh NAME" \
    ".Nm $filename" \
    ".Nd $docstr"

while read -r line; do
    case $line in
        '###'*:)
            line=${line%:}
            out ".Ss ${line#'### '}"
            ;;
        '##'*:)
            line=${line%:}
            out ".Sh ${line#'## '}"
            ;;
        '##'|'###')
            out ".Pp"
            ;;
        '##'*)
            line=${line#'##'}
            line=${line#'#'}
            line=${line# }
            out "$line"
            ;;
    esac
done < "$file"

out ".Sh AUTHOR" ".An Cem Keylan Aq Mt cem@ckyln.com"
out ".Sh LICENSE" "See LICENSE for copyright information."
out ".Sh SEE ALSO" ".Xr cpt 1"
