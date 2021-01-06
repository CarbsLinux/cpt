SRC_ROOT=..

# shellcheck source=../config.rc
. ${SRC_ROOT}/config.rc

redo-ifchange cpt.in cpt-*

cat cpt-* |
sed -e '/@AUTOLOADS@/r /dev/stdin' \
    -e '/CPT Library/,/@AUTOLOADS@/d' \
    cpt.in |
sed -e '/shellcheck source=lib-cpt/d'\
    -e '/# Local Variables:$/,/# End:$/d' > "$3"
