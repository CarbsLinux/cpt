. ../config.rc

# Extensionless name of file
fn="${1%.*}"

case "$1" in
    all)  redo-ifchange info ;;
    info) redo-ifchange cpt.info ;;
    *.info)
        redo-ifchange "$fn.texi"
        $MAKEINFO "$fn.texi" -o "$3"
        ;;
    *.texi)
        [ -f "$fn.org" ] || exit 0
        redo-ifchange "$fn.org"
        cp "$fn.org" "$3.org"
        $EMACS "$3.org" --batch -f org-texinfo-export-to-texinfo
        rm -f "$3.org"
        mv "$3.texi" "$3"
        ;;
    *)
        echo "Unknown target $1"
        exit 99
esac

PHONY all info html