SRC_ROOT=..

# shellcheck source=../config.rc
. ${SRC_ROOT}/config.rc

redo-ifchange cpt.in cpt-*

for lib in cpt-*; do
    sed -E -n "/^[^[:blank:]]+\(\)[[:blank:]]+[({]/s,^(.*)\(\).*\$,\1() { . \"\$CPT_LIBDIR/$lib\"; \1 \"\$@\";},p" "$lib"
done |

sed -e '/@AUTOLOADS@/r /dev/stdin' \
    -e '/@AUTOLOADS@/d' \
    cpt.in > "$3"
