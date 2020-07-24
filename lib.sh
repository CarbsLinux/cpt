#!/bin/sh -ef
# shellcheck source=/dev/null
#
# This is a simple package manager written in POSIX 'sh' for use
# in KISS Linux (https://k1ss.org).
#
# This script runs with '-ef' meaning:
# '-e': Abort on any non-zero exit code.
# '-f': Disable globbing globally.
#
# [1] Warnings related to word splitting and globbing are disabled.
# All word splitting in this script is *safe* and intentional.
#
# Dylan Araps.

version() {
    log "Carbs Packaging Tools" 3.0.0
    exit 0
}

out() {
    # Print a message as is.
    printf '%s\n' "$@"
}

log() {
    # Print a message prettily.
    #
    # All messages are printed to stderr to allow the user to hide build
    # output which is the only thing printed to stdout.
    #
    # '\033[1;32m'        Set text to color '2' and make it bold.
    # '\033[m':           Reset text formatting.
    # '${3:-->}':         If the 3rd argument is missing, set prefix to '->'.
    # '${2:+\033[1;3Xm}': If the 2nd argument exists, set text style of '$1'.
    printf '\033[1;33m%s \033[m%b%s\033[m %s\n' \
           "${3:-->}" "${2:+"\033[1;36m"}" "$1" "$2" >&2
}

die() {
    # Print a message and exit with '1' (error).
    log "$1" "$2" "!>"
    exit 1
}

warn() {
    # Print a warning message
    log "WARN" "$1" "${2:-!>}"
}

contains() {
    # Check if a "string list" contains a word.
    case " $1 " in *" $2 "*) return 0; esac; return 1
}

regesc() {
    # Escape special regular expression characters as
    # defined in POSIX BRE. '$.*[\^'
    printf '%s\n' "$1" | sed 's|\\|\\\\|g;s|\[|\\[|g;s|\$|\\$|g;s|\.|\\.|g;s|\*|\\*|g;s|\^|\\^|g'
}


prompt() {
    # If a CPT_NOPROMPT variable is set, continue.
    # This can be useful for installation scripts and
    # bootstrapping.
    [ "$CPT_PROMPT" = 0 ] && return 0

    # Ask the user for some input.
    [ "$1" ] && log "$1"
    log "Continue?: Press Enter to continue or Ctrl+C to abort here"

    # POSIX 'read' has none of the "nice" options like '-n', '-p'
    # etc etc. This is the most basic usage of 'read'.
    # '_' is used as 'dash' errors when no variable is given to 'read'.
    read -r _ || return 1
}

as_root() {
    # Simple function to run a command as root using either 'sudo',
    # 'doas' or 'su'. Hurrah for choice.
    [ "$uid" = 0 ] || log "Using '${su:-su}' (to become ${user:=root})"

    case ${su##*/} in
        sudo) sudo -E -u "$user" -- "$@" ;;
        doas) doas    -u "$user" -- "$@" ;;
        su)   su -pc "env USER=$user $* <&3" "$user" 3<&0 </dev/tty ;;
        *)    die "Invalid CPT_SU value: $su" ;;
    esac
}

pop() {
    # Remove an item from a "string list". This allows us
    # to remove a 'sed' call and reuse this code throughout.
    del=$1
    shift 2

    for i do [ "$i" = "$del" ] || printf %s " $i "; done
}

run_hook() {
    # If a fourth parameter 'root' is specified, source
    # the hook from a predefined location to avoid privilige
    # escalation through user scripts.
    [ "$4" ] && CPT_HOOK=$CPT_ROOT/etc/cpt-hook

    # This is not a misspelling, can be ignored safely.
    # shellcheck disable=2153
    [ -f "$CPT_HOOK" ] || return 0

    log "$2" "Running $1 hook"

    TYPE=${1:-null} PKG=${2:-null} DEST=${3:-null} . "$CPT_HOOK"
}

decompress() {
    case $1 in
        *.tar)      cat       ;;
        *.bz2)      bzip2 -cd ;;
        *.xz|*.txz) xz -dcT 0 ;;
        *.tgz|*.gz) gzip -cd  ;;
        *.zst)      zstd -cd  ;;
    esac < "$1"
}

sh256() {
    # This is a sha256sum function for outputting a standard
    # hash digest. sha256 on BSD systems require an '-r' flag
    # for outputting the same way with sha256sum, and still,
    # it outputs a single space between the hash and the file
    # whereas sha256sum outputs double spaces. It fallbacks to
    # openssl, but that is rarely ever needed.
    { sha256sum "$1" 2>/dev/null   ||
      sha256 -r "$1" 2>/dev/null   ||
      openssl dgst -r -sha256 "$1" ||
      die "No sha256 program could be run." ;} |

        while read -r hash _; do printf '%s  %s\n' "$hash" "$1"; done
}

pkg_isbuilt() (
    # Check if a package is built or not.
    repo_dir=$(pkg_find "$1")
    read -r ver rel < "$repo_dir/version"

    set +f
    for tarball in "$bin_dir/$1#$ver-$rel.tar."*; do
        [ -f "$tarball" ] && return 0
    done
    return 1
)

pkg_lint() {
    # Check that each mandatory file in the package entry exists.
    log "$1" "Checking repository files"

    repo_dir=$(pkg_find "$1")

    cd "$repo_dir" || die "'$repo_dir' not accessible"
    [ -f sources ] || die "$1" "Sources file not found"
    [ -x build ]   || die "$1" "Build file not found or not executable"
    [ -s version ] || die "$1" "Version file not found or empty"

    read -r _ release 2>/dev/null < version || die "Version file not found"
    [ "$release" ] || die "Release field not found in version file"

    [ "$2" ] || [ -f checksums ] || die "$pkg" "Checksums are missing"
}

pkg_find() {
    # Use a SEARCH_PATH variable so that we can get the sys_db into
    # the same variable as CPT_PATH. This makes it easier when we are
    # searching for executables instead of CPT_PATH.
    : "${SEARCH_PATH:=$CPT_PATH:$sys_db}"

    # Figure out which repository a package belongs to by
    # searching for directories matching the package name
    # in $CPT_PATH/*.
    query=$1 match=$2 type=$3 IFS=:; set --

    # Word splitting is intentional here.
    # shellcheck disable=2086
    for path in $SEARCH_PATH ; do
        set +f

        for path2 in "$path/"$query; do
            test "${type:--d}" "$path2" && set -f -- "$@" "$path2"
        done
    done

    unset IFS

    # A package may also not be found due to a repository not being
    # readable by the current user. Either way, we need to die here.
    [ "$1" ] || die "Package '$query' not in any repository"

    # Show all search results if called from 'cpt search', else
    # print only the first match.
    [ "$match" ] && printf '%s\n' "$@" || printf '%s\n' "$1"
}

pkg_list() {
    # List installed packages. As the format is files and
    # directories, this just involves a simple for loop and
    # file read.

    # Change directories to the database. This allows us to
    # avoid having to 'basename' each path. If this fails,
    # set '$1' to mimic a failed glob which indicates that
    # nothing is installed.
    cd "$sys_db" 2>/dev/null || set -- "$sys_db/"\*

    # Optional arguments can be passed to check for specific
    # packages. If no arguments are passed, list all. As we
    # loop over '$@', if there aren't any arguments we can
    # just set the directory contents to the argument list.
    [ "$1" ] || { set +f; set -f -- *; }

    # If the 'glob' above failed, exit early as there are no
    # packages installed.
    [ "$1" = "$sys_db/"\* ] && return 1

    # Loop over each package and print its name and version.
    for pkg do
        [ -d "$pkg" ] || { log "$pkg" "not installed"; return 1; }

        read -r version 2>/dev/null < "$pkg/version" || version=null
        printf '%s\n' "$pkg $version"
    done
}

pkg_cache() {
    read -r version release 2>/dev/null < "$(pkg_find "$1")/version"

    set +f; set -f -- "$bin_dir/$1#$version-$release.tar."*
    tar_file=$1

    [ -f "$tar_file" ]
}

pkg_sources() {
    # Download any remote package sources. The existence of local
    # files is also checked.
    log "$1" "Downloading sources"

    # Store each downloaded source in a directory named after the
    # package it belongs to. This avoid conflicts between two packages
    # having a source of the same name.
    mkdir -p "$src_dir/$1" && cd "$src_dir/$1"

    repo_dir=$(pkg_find "$1")

    while read -r src dest || [ "$src" ]; do
        # Comment.
        if [ -z "${src##\#*}" ]; then :

        # Remote source (cached).
        elif [ -f "${src##*/}" ]; then
            log "$1" "Found cached source '${src##*/}'"

        # Remote git repository.
        elif [ -z "${src##git+*}" ]; then
            # This is a checksums check, skip it.
            [ "$2" ] && continue

            # Since git is an optional dependency, make sure
            # it is available on the system.
            command -v git >/dev/null ||
                die "git must be installed in order to acquire ${src##git+}"

            mkdir -p "$mak_dir/$1/$dest"

            # Run in a subshell to keep the variables, path and
            # argument list local to each loop iteration.
            (
                repo_src=${src##git+}

                log "$1" "Cloning ${repo_src%[@#]*}"

                # Git has no option to clone a repository to a
                # specific location so we must do it ourselves
                # beforehand.
                cd "$mak_dir/$1/$dest" 2>/dev/null || die

                # Clear the argument list as we'll be overwriting
                # it below based on what kind of checkout we're
                # dealing with.
                set -- "$repo_src"

                # If a branch was given, shallow clone it directly.
                # This speeds things up as we don't have to grab
                # a lot of unneeded commits.
                [ "${src##*@*}" ] ||
                    set -- -b "${src##*@}" "${repo_src%@*}"

                # Maintain compatibility with older versions of
                # cpt by shallow cloning all branches. This has
                # the added benefit of allowing checkouts of
                # specific commits in specific branches.
                [ "${src##*#*}" ] ||
                    set -- --no-single-branch "${repo_src%#*}"

                # Always do a shallow clone as we will unshallow it if
                # needed later (when a commit is desired).
                git clone --depth=1 "$@" .

            ) || die "$1" "Failed to clone $src"

        # Remote source.
        elif [ -z "${src##*://*}" ]; then
            log "$1" "Downloading $src"

            curl "$src" -fLo "${src##*/}" || {
                rm -f "${src##*/}"
                die "$1" "Failed to download $src"
            }

        # Local source.
        elif [ -f "$repo_dir/$src" ]; then
            log "$1" "Found local file '$src'"

        else
            die "$1" "No local file '$src'"
        fi
    done < "$repo_dir/sources"
}

pkg_extract() {
    # Extract all source archives to the build directory and copy over
    # any local repository files.
    log "$1" "Extracting sources"

    repo_dir=$(pkg_find "$1")

    while read -r src dest || [ "$src" ]; do
        mkdir -p "$mak_dir/$1/$dest" && cd "$mak_dir/$1/$dest"

        case $src in
            # Git repository with supplied commit hash.
            git+*\#*)
                log "Checking out ${src##*#}"

                # A commit was requested, unshallow the repository.
                # This will convert it to a regular repository with
                # full history.
                git fetch --unshallow

                # Try to checkout the repository. If we fail here,
                # the requested commit doesn't exist.
                git -c advice.detachedHead=false checkout "${src##*#}" ||
                    die "Commit hash ${src##*#} doesn't exist"
            ;;

            # Git repository, comment or blank line.
            git+*|\#*|'') continue ;;

            # Only 'tar' an 'zip' archives are currently supported for
            # extraction. Other filetypes are simply copied to '$mak_dir'
            # which allows for manual extraction.
            *://*.tar|*://*.tar.??|*://*.tar.???|*://*.tar.????|*://*.tgz|*://*.txz)

                decompress "$src_dir/$1/${src##*/}" > .ktar

                "$tar" xf .ktar || die "$1" "Couldn't extract ${src##*/}"

                # We now list the contents of the tarball so we can do our
                # version of 'strip-components'.
                "$tar" tf .ktar |
                    while read -r file; do printf '%s\n' "${file%%/*}"; done |

                    # Do not repeat files.
                    uniq |

                    # For every directory in the base we move each file
                    # inside it to the upper directory.
                    while read -r dir ; do

                        # Skip if we are not dealing with a directory here.
                        # This way we don't remove files on the upper directory
                        # if a tar archive doesn't need directory stripping.
                        [ -d "${dir#.}" ] || continue

                        # Change into the directory in a subshell so we don't
                        # need to cd back to the upper directory.
                        (
                            cd "$dir"

                            # We use find because we want to move hidden files
                            # as well.
                            #
                            # Skip the file if it has the same name as the directory.
                            # We will deal with it later.
                            #
                            # Word splitting is intentional here.
                            # shellcheck disable=2046
                            find . \( ! -name . -prune \) ! -name "$dir" \
                                 -exec mv -f {} .. \;

                            # If a file/directory with the same name as the directory
                            # exists, append a '.cptbak' to it and move it to the
                            # upper directory.
                            ! [ -e "$dir" ] || mv "$dir" "../${dir}.cptbak"
                        )
                        rmdir "$dir"

                        # If a backup file exists, move it into the original location.
                        ! [ -e "${dir}.cptbak" ] || mv "${dir}.cptbak" "$dir"
                done

                # Clean up the temporary tarball.
                rm -f .ktar
            ;;

            *://*.zip)
                unzip "$src_dir/$1/${src##*/}" ||
                    die "$1" "Couldn't extract ${src##*/}"

            ;;

            *)
                # Local file.
                if [ -f "$repo_dir/$src" ]; then
                    cp -f "$repo_dir/$src" .

                # Remote file.
                elif [ -f "$src_dir/$1/${src##*/}" ]; then
                    cp -f "$src_dir/$1/${src##*/}" .

                else
                    die "$1" "Local file $src not found"
                fi
            ;;
        esac
    done < "$repo_dir/sources"
}

pkg_depends() {
    # Resolve all dependencies and generate an ordered list.
    # This does a depth-first search. The deepest dependencies are
    # listed first and then the parents in reverse order.
    contains "$deps" "$1" || {
        # Filter out non-explicit, aleady installed dependencies.
        # Only filter installed if called from 'pkg_build()'.
        [ "$pkg_build" ] && [ -z "$2" ] &&
            (pkg_list "$1" >/dev/null) && return

        # Recurse through the dependencies of the child packages.
        while read -r dep _ || [ "$dep" ]; do
            [ "${dep##\#*}" ] && pkg_depends "$dep"
        done 2>/dev/null < "$(pkg_find "$1")/depends" ||:

        # After child dependencies are added to the list,
        # add the package which depends on them.
        [ "$2" = explicit ] || deps="$deps $1 "
    }
}

pkg_order() {
    # Order a list of packages based on dependence and
    # take into account pre-built tarballs if this is
    # to be called from 'cpt i'.
    order=; redro=; deps=

    for pkg do case $pkg in
        *.tar.*) deps="$deps $pkg "  ;;
        *)       pkg_depends "$pkg" raw
    esac done

    # Filter the list, only keeping explicit packages.
    # The purpose of these two loops is to order the
    # argument list based on dependence.
    for pkg in $deps; do ! contains "$*" "$pkg" || {
        order="$order $pkg "
        redro=" $pkg $redro"
    } done

    deps=
}

pkg_strip() {
    # Strip package binaries and libraries. This saves space on the
    # system as well as on the tarballs we ship for installation.

    # Package has stripping disabled, stop here.
    [ -f "$mak_dir/$pkg/nostrip" ] && return

    log "$1" "Stripping binaries and libraries"

    find "$pkg_dir/$1" -type f | while read -r file; do
        case $(od -A o -t c -N 18 "$file") in
            # REL (object files (.o), static libraries (.a)).
            *177*E*L*F*0000020\ 001\ *|*\!*\<*a*r*c*h*\>*)
                strip -g -R .comment -R .note "$file"
            ;;

            # EXEC (static binaries).
            # DYN (shared libraries, dynamic binaries).
            # Shared libraries keep global symbols in a separate ELF section
            # called '.dynsym'. '--strip-all/-s' does not touch the dynamic
            # symbol entries which makes this safe to do.
            *177*E*L*F*0000020\ 00[23]\ *)
                strip -s -R .comment -R .note "$file"
            ;;
        esac
    done 2>/dev/null ||:
}

pkg_fixdeps() {
    # Dynamically look for missing runtime dependencies by checking
    # each binary and library with 'ldd'. This catches any extra
    # libraries and or dependencies pulled in by the package's
    # build suite.
    log "$1" "Checking for missing dependencies"

    # Go to the directory containing the built package to
    # simplify path building.
    cd "$pkg_dir/$1/$pkg_db/$1"

    # Make a copy of the depends file if it exists to have a
    # reference to 'diff' against.
    if [ -f depends ]; then
        cp -f depends "$mak_dir/d"
        dep_file=$mak_dir/d
    else
        dep_file=/dev/null
    fi

    # Generate a list of all installed manifests.
    pkg_name=$1
    set +f; set -f -- "$sys_db/"*/manifest

    # Get a list of binaries and libraries, false files
    # will be found, however it's faster to get 'ldd' to check
    # them anyway than to filter them out.
    find "$pkg_dir/$pkg_name/" -type f 2>/dev/null |

    while read -r file; do
        # Run 'ldd' on the file and parse each line. The code
        # then checks to see which packages own the linked
        # libraries and it prints the result.
        ldd "$file" 2>/dev/null | while read -r dep; do
            # Skip lines containing 'ldd'.
            [ "${dep##*ldd*}" ] || continue

            # Extract the file path from 'ldd' output, and
            # canonicalize the path.
            dep=${dep#* => }
            dep=${dep% *}
            dep=$(cpt-readlink "$dep")

            # Figure out which package owns the file.
            own=$("$grep" -lFx "${dep#$CPT_ROOT}" "$@")

            # If the package wasn't found, retry by removing
            # the '/usr' prefix.
            if [ -z "$own" ] && [ -z "${dep##$CPT_ROOT/usr*}" ]; then
                own=$("$grep" -lFx "${dep#$CPT_ROOT/usr}" "$@")
                dep=${dep#/usr}
            fi

            # Extract package name from 'grep' match.
            own=${own%/*}
            own=${own##*/}

            case $own in "$pkg_name"|"$pkg_name-bin"|"") continue ; esac
            printf 'Found %s (%s) in (%s)\n' "$own" "$dep" \
                   "${file##$pkg_dir/$pkg_name}" >/dev/tty

            printf '%s\n' "$own"
        done ||:
    done >> depends

    # Remove duplicate entries from the new depends file.
    # This removes duplicate lines looking *only* at the
    # first column.
    sort -uk1,1 -o depends depends 2>/dev/null ||:

    # Display a diff of the new dependencies against the old ones.
    diff -U 3 "$dep_file" depends 2>/dev/null ||:

    # Remove the depends file if it is empty.
    [ -s depends ] || rm -f depends
}

pkg_manifest() (
    # Generate the package's manifest file. This is a list of each file
    # and directory inside the package. The file is used when uninstalling
    # packages, checking for package conflicts and for general debugging.
    log "$1" "Generating manifest"

    # This function runs as a sub-shell to avoid having to 'cd' back to the
    # prior directory before being able to continue.
    cd "${2:-$pkg_dir}/$1"

    # find: Print all files and directories and append '/' to directories.
    # sort: Sort the output in *reverse*. Directories appear *after* their
    #       contents.
    # sed:  Remove the first character in each line (./dir -> /dir) and
    #       remove all lines which only contain '.'.
    find . -type d -exec printf '%s/\n' {} + -o -print |
        sort -r | sed '/^\.\/$/d;ss.ss' > "${2:-$pkg_dir}/$1/$pkg_db/$1/manifest"
)

pkg_etcsums() (
    # This function runs as a sub-shell to avoid having to 'cd' back to the
    # prior directory before being able to continue.
    cd "$pkg_dir/$1/etc" 2>/dev/null || return 0; cd ..

    # Generate checksums for each configuration file in the package's
    # /etc/ directory for use in "smart" handling of these files.
    log "$1" "Generating etcsums"


    find etc -type f | while read -r file; do
        sh256 "$file"
    done > "$pkg_dir/$1/$pkg_db/$1/etcsums"
)

pkg_tar() {
    # Create a tarball from the built package's files.
    # This tarball also contains the package's database entry.
    log "$1" "Creating tarball"

    # Read the version information to name the package.
    read -r version release < "$(pkg_find "$1")/version"

    # Create a tarball from the contents of the built package.
    "$tar" cf - -C "$pkg_dir/$1" . |
        case $CPT_COMPRESS in
            bz2) bzip2 -z ;;
            xz)  xz -zT 0 ;;
            gz)  gzip -6  ;;
            zst) zstd -3  ;;
            *)   gzip -6  ;;  # Fallback to gzip
        esac \
    > "$bin_dir/$1#$version-$release.tar.$CPT_COMPRESS"

    log "$1" "Successfully created tarball"

    run_hook post-package "$1" "$bin_dir/$1#$version-$release.tar.$CPT_COMPRESS"
}

pkg_build() {
    # Build packages and turn them into packaged tarballs. This function
    # also checks checksums, downloads sources and ensure all dependencies
    # are installed.
    pkg_build=1

    log "Resolving dependencies"

    for pkg do contains "$explicit" "$pkg" || {
        pkg_depends "$pkg" explicit

        # Mark packages passed on the command-line
        # separately from those detected as dependencies.
        explicit="$explicit $pkg "
    } done

    [ "$pkg_update" ] || explicit_build=$explicit

    # If an explicit package is a dependency of another explicit
    # package, remove it from the explicit list as it needs to be
    # installed as a dependency.
    # shellcheck disable=2086
    for pkg do
        contains "$deps" "$pkg" && explicit=$(pop "$pkg" from $explicit)
    done

    # See [1] at top of script.
    # shellcheck disable=2046,2086
    set -- $deps $explicit

    log "Building: $*"

    # Only ask for confirmation if more than one package needs to be built.
    [ $# -gt 1 ] || [ "$pkg_update" ] && { prompt || exit 0 ;}

    log "Checking for pre-built dependencies"

    for pkg do pkg_lint "$pkg"; done

    # Install any pre-built dependencies if they exist in the binary
    # directory and are up to date.
    for pkg do ! contains "$explicit_build" "$pkg" && pkg_cache "$pkg" && {
        log "$pkg" "Found pre-built binary, installing"
        (CPT_FORCE=1 cpt-install "$tar_file")

        # Remove the now installed package from the build list.
        # See [1] at top of script.
        # shellcheck disable=2046,2086
        set -- $(pop "$pkg" from "$@")
    } done

    for pkg do pkg_sources "$pkg"; done

    pkg_verify "$@"

    # Finally build and create tarballs for all passed packages and
    # dependencies.
    for pkg do
        log "$pkg" "Building package ($((in = in + 1))/$#)"

        pkg_extract "$pkg"
        repo_dir=$(pkg_find "$pkg")

        read -r build_version _ < "$repo_dir/version"

        # Install built packages to a directory under the package name
        # to avoid collisions with other packages.
        mkdir -p "$pkg_dir/$pkg/$pkg_db"

        # Move to the build directory.
        cd "$mak_dir/$pkg"

        log "$pkg" "Starting build"

        run_hook pre-build "$pkg" "$pkg_dir/$pkg"

        # Call the build script, log the output to the terminal
        # and to a file. There's no PIPEFAIL in POSIX shelll so
        # we must resort to tricks like killing the script ourselves.
        { "$repo_dir/build" "$pkg_dir/$pkg" "$build_version" "$sys_arch" 2>&1 || {
            log "$pkg" "Build failed"
            log "$pkg" "Log stored to $log_dir/$pkg-$time-$pid"
            run_hook build-fail "$pkg" "$pkg_dir/$pkg"
            pkg_clean
            kill 0
        } } | tee "$log_dir/$pkg-$time-$pid"

        # Delete the log file if the build succeeded to prevent
        # the directory from filling very quickly with useless logs.
        [ "$CPT_KEEPLOG" = 1 ] || rm -f "$log_dir/$pkg-$time-$pid"

        # Copy the repository files to the package directory.
        # This acts as the database entry.
        cp -LRf "$repo_dir" "$pkg_dir/$pkg/$pkg_db/"

        # We never ever want this. Let's end the endless conflicts
        # and remove it. This will be the only exception for a
        # specific removal of this kind.
        find "$pkg_dir/$pkg" -name charset.alias -exec rm -f {} +

        log "$pkg" "Successfully built package"

        run_hook post-build "$pkg" "$pkg_dir/$pkg"

        # Create the manifest file early and make it empty.
        # This ensures that the manifest is added to the manifest.
        : > "$pkg_dir/$pkg/$pkg_db/$pkg/manifest"

        # If the package contains '/etc', add a file called
        # 'etcsums' to the manifest. See comment directly above.
        [ -d "$pkg_dir/$pkg/etc" ] &&
            : > "$pkg_dir/$pkg/$pkg_db/$pkg/etcsums"

        pkg_strip    "$pkg"
        pkg_fixdeps  "$pkg"
        pkg_manifest "$pkg"
        pkg_etcsums  "$pkg"
        pkg_tar      "$pkg"

        # Install only dependencies of passed packages.
        # Skip this check if this is a package update.
        contains "$explicit" "$pkg" && [ -z "$pkg_update" ] && continue

        log "$pkg" "Needed as a dependency or has an update, installing"

        (CPT_FORCE=1 cpt-install "$pkg")
    done

    # End here as this was a system update and all packages have been installed.
    [ "$pkg_update" ] && return

    log "Successfully built package(s)"

    # Turn the explicit packages into a 'list'.
    # See [1] at top of script.
    # shellcheck disable=2046,2086
    set -- $explicit

    # Only ask for confirmation if more than one package needs to be installed.
    [ $# -gt 1 ] && prompt "Install built packages? [$*]" && {
        cpt-install "$@"
        return
    }

    log "Run 'cpt i $*' to install the package(s)"
}

pkg_checksums() {
    # Generate checksums for packages.
    repo_dir=$(pkg_find "$1")

    while read -r src _ || [ "$src" ]; do
        # Comment.
        if [ -z "${src##\#*}" ]; then
            continue

        # File is local to the package.
        elif [ -f "$repo_dir/$src" ]; then
            src_path=$repo_dir/${src%/*}

        # File is remote and was downloaded.
        elif [ -f "$src_dir/$1/${src##*/}" ]; then
            src_path=$src_dir/$1

        # File is a git repository.
        elif [ -z "${src##git+*}" ]; then
            printf 'git  %s\n' "$src"
            continue

        # Die here if source for some reason, doesn't exist.
        else
            die "$1" "Couldn't find source '$src'"
        fi

        # An easy way to get 'sha256sum' to print with the 'basename'
        # of files is to 'cd' to the file's directory beforehand.
        (cd "$src_path" && sh256 "${src##*/}") ||
            die "$1" "Failed to generate checksums"
    done < "$repo_dir/sources"
}

pkg_verify() {
    # Verify all package checksums. This is achieved by generating
    # a new set of checksums and then comparing those with the old
    # set.
    for pkg do pkg_checksums "$pkg" | diff - "$(pkg_find "$pkg")/checksums" || {
        log "$pkg" "Checksum mismatch"

        # Instead of dying above, log it to the terminal. Also define a
        # variable so we *can* die after all checksum files have been
        # checked.
        mismatch="$mismatch$pkg "
    } done

    [ -z "$mismatch" ] || die "Checksum mismatch with: ${mismatch% }"
}

pkg_conflicts() {
    # Check to see if a package conflicts with another.
    log "$1" "Checking for package conflicts"

    # Filter the tarball's manifest and select only files
    # and any files they resolve to on the filesystem
    # (/bin/ls -> /usr/bin/ls).
    while read -r file; do
        case $file in */) continue; esac

        # Use $CPT_ROOT in filename so that we follow its symlinks.
        file=$CPT_ROOT/${file#/}

        # We will only follow the symlinks of the directories, so we
        # reserve the directory name in this 'dirname' value. cpt-readlink
        # functions in a similar fashion to 'readlink -f', it makes sure
        # every component except for the first one to be available on
        # the directory structure. If we cannot find it in the system,
        # we don't need to make this much more complex by trying so
        # hard to find it. Simply use the original directory name.
        dirname="$(cpt-readlink "${file%/*}" 2>/dev/null)" ||
            dirname="${file%/*}"


        # Combine the dirname and file values, and print them into the
        # temporary manifest to be parsed.
        printf '%s/%s\n' "${dirname#$CPT_ROOT}" "${file##*/}"

    done < "$tar_dir/$1/$pkg_db/$1/manifest" > "$CPT_TMPDIR/$pid-m"

    p_name=$1

    # Generate a list of all installed package manifests
    # and remove the current package from the list.
    # shellcheck disable=2046,2086
    set -- $(set +f; pop "$sys_db/$p_name/manifest" from "$sys_db"/*/manifest)

    [ -s "$CPT_TMPDIR/$pid-m" ] || return 0

    # In rare cases where the system only has one package installed
    # and you are reinstalling that package, grep will try to read from
    # standard input if we continue here.
    #
    # Also, if we don't have any packages installed grep will give an
    # error. This will not cause the installation to fail, but we don't
    # need to check for conflicts if that's the case anyway. If we have
    # only zero packages or one package, just stop wasting time and continue
    # with the installation.
    [ "$1" ] && [ -f "$1" ] || return 0

    # Store the list of found conflicts in a file as we will be using the
    # information multiple times. Storing it in the cache dir allows us
    # to be lazy as they'll be automatically removed on script end.
    "$grep" -Fxf "$CPT_TMPDIR/$pid-m" -- "$@" > "$CPT_TMPDIR/$pid-c" ||:


    # Enable alternatives automatically if it is safe to do so.
    # This checks to see that the package that is about to be installed
    # doesn't overwrite anything it shouldn't in '/var/db/cpt/installed'.
    "$grep" -q ":/var/db/cpt/installed/" "$CPT_TMPDIR/$pid-c" || choice_auto=1

    # Use 'grep' to list matching lines between the to
    # be installed package's manifest and the above filtered
    # list.
    if [ "$CPT_CHOICE" != 0 ] && [ "$choice_auto" = 1 ]; then

        # This is a novel way of offering an "alternatives" system.
        # It is entirely dynamic and all "choices" are created and
        # destroyed on the fly.
        #
        # When a conflict is found between two packages, the file
        # is moved to a directory called "choices" and its name
        # changed to store its parent package and its intended
        # location.
        #
        # The package's manifest is then updated to reflect this
        # new location.
        #
        # The 'cpt choices' command parses this directory and
        # offers you the CHOICE of *swapping* entries in this
        # directory for those on the filesystem.
        #
        # The choices command does the same thing we do here,
        # it rewrites manifests and moves files around to make
        # this work.
        #
        # Pretty nifty huh?
        while IFS=: read -r _ con; do
            printf '%s\n' "Found conflict $con"

            # Create the "choices" directory inside of the tarball.
            # This directory will store the conflicting file.
            mkdir -p "$tar_dir/$p_name/${cho_dir:=var/db/cpt/choices}"

            # Construct the file name of the "db" entry of the
            # conflicting file. (pkg_name>usr>bin>ls)
            con_name=$(printf %s "$con" | sed 's|/|>|g')

            # Move the conflicting file to the choices directory
            # and name it according to the format above.
            mv -f "$tar_dir/$p_name/$con" \
                  "$tar_dir/$p_name/$cho_dir/$p_name$con_name" 2>/dev/null || {
                log "File must be in ${con%/*} and not a symlink to it"
                log "This usually occurs when a binary is installed to"
                log "/sbin instead of /usr/bin (example)"
                log "Before this package can be used as an alternative,"
                log "this must be fixed in $p_name. Contact the maintainer"
                die "by checking 'git log' or by running 'cpt-maintainer'"
            }
        done < "$CPT_TMPDIR/$pid-c"

        # Rewrite the package's manifest to update its location
        # to its new spot (and name) in the choices directory.
        pkg_manifest "$p_name" "$tar_dir" 2>/dev/null

    elif [ -s "$CPT_TMPDIR/$pid-c" ]; then
        log "Package '$p_name' conflicts with another package" "" "!>"
        log "Run 'CPT_CHOICE=1 cpt i $p_name' to add conflicts" "" "!>"
        die "as alternatives."
    fi
}

pkg_swap() {
    # Swap between package alternatives.
    pkg_list "$1" >/dev/null

    alt=$(printf %s "$1$2" | sed 's|/|>|g')
    cd "$sys_db/../choices"

    [ -f "$alt" ] || [ -h "$alt" ] ||
        die "Alternative '$1 $2' doesn't exist"

    if [ -f "$2" ]; then
        # Figure out which package owns the file we are going to swap for
        # another package's.
        #
        # Print the full path to the manifest file which contains
        # the match to our search.
        pkg_owns=$(set +f; "$grep" -lFx "$2" "$sys_db/"*/manifest) ||:

        # Extract the package name from the path above.
        pkg_owns=${pkg_owns%/*}
        pkg_owns=${pkg_owns##*/}

        [ "$pkg_owns" ] ||
            die "File '$2' exists on filesystem but isn't owned"

        log "Swapping '$2' from '$pkg_owns' to '$1'"

        # Convert the current owner to an alternative and rewrite
        # its manifest file to reflect this. We then resort this file
        # so no issues arise when removing packages.
        cp  -Pf "$CPT_ROOT/$2" "$pkg_owns>${alt#*>}"
        sed "s#^$(regesc "$2")#${PWD#$CPT_ROOT}/$pkg_owns>${alt#*>}#" \
            "../installed/$pkg_owns/manifest" |
            sort -r -o "../installed/$pkg_owns/manifest"
    fi

    # Convert the desired alternative to a real file and rewrite
    # the manifest file to reflect this. The reverse of above.
    mv -f "$alt" "$CPT_ROOT/$2"
    sed "s#^${PWD#$CPT_ROOT}/$(regesc "$alt")#$2#" "../installed/$1/manifest" |
        sort -r -o "../installed/$1/manifest"
}

pkg_etc() {
    [ -d "$tar_dir/$pkg_name/etc" ] || return 0

    (cd "$tar_dir/$pkg_name"

    # Create all directories beforehand.
    find etc -type d | while read -r dir; do
        mkdir -p "$CPT_ROOT/$dir"
    done

    # Handle files in /etc/ based on a 3-way checksum check.
    find etc ! -type d | while read -r file; do
        { sum_new=$(sh256 "$file")
          sum_sys=$(cd "$CPT_ROOT/"; sh256 "$file")
          sum_old=$("$grep" "$file$" "$mak_dir/c"); } 2>/dev/null ||:

        log "$pkg_name" "Doing 3-way handshake for $file"
        printf '%s\n' "Previous: ${sum_old:-null}"
        printf '%s\n' "System:   ${sum_sys:-null}"
        printf '%s\n' "New:      ${sum_new:-null}"

        # Use a case statement to easily compare three strings at
        # the same time. Pretty nifty.
        case ${sum_old:-null}${sum_sys:-null}${sum_new} in
            # old = Y, sys = X, new = Y
            "${sum_new}${sum_sys}${sum_old}")
                log "Skipping $file"
                continue
            ;;

            # old = X, sys = X, new = X
            # old = X, sys = Y, new = Y
            # old = X, sys = X, new = Y
            "${sum_old}${sum_old}${sum_old}"|\
            "${sum_old:-null}${sum_sys}${sum_sys}"|\
            "${sum_sys}${sum_old}"*)
                log "Installing $file"
                new=
            ;;

            # All other cases.
            *)
                warn "($pkg_name) saving /$file as /$file.new" "->"
                new=.new
            ;;
        esac

        cp -fPp "$file"  "$CPT_ROOT/${file}${new}"
        chown root:root "$CPT_ROOT/${file}${new}" 2>/dev/null
    done) ||:
}

pkg_remove() {
    # Remove a package and all of its files. The '/etc' directory
    # is handled differently and configuration files are *not*
    # overwritten.
    pkg_list "$1" >/dev/null || return

    # Make sure that nothing depends on this package.
    [ "$CPT_FORCE" = 1 ] || {
        log "$1" "Checking for reverse dependencies"

        (cd "$sys_db"; set +f; grep -lFx "$1" -- */depends) &&
            die "$1" "Can't remove package, others depend on it"
    }
    # Block being able to abort the script with 'Ctrl+C' during removal.
    # Removes all risk of the user aborting a package removal leaving
    # an incomplete package installed.
    trap '' INT

    if [ -x "$sys_db/$1/pre-remove" ]; then
        log "$1" "Running pre-remove script"
        "$sys_db/$1/pre-remove" ||:
    fi

    # Create a temporary list of all directories, so we don't accidentally
    # remove anything from packages that create empty directories for a
    # purpose (such as baselayout).
    manifest_list="$(set +f; pop "$sys_db/$1/manifest" from "$sys_db/"*/manifest)"
    # shellcheck disable=2086
    [ "$manifest_list" ] && grep -h '/$' $manifest_list | sort -ur > "$mak_dir/dirs"

    run_hook pre-remove "$1" "$sys_db/$1" root

    while read -r file; do
        # The file is in '/etc' skip it. This prevents the package
        # manager from removing user edited configuration files.
        [ "${file##/etc/*}" ] || continue

        if [ -d "$CPT_ROOT/$file" ]; then
            "$grep" -Fxq "$file" "$mak_dir/dirs" 2>/dev/null && continue
            rmdir "$CPT_ROOT/$file" 2>/dev/null || continue
        else
            rm -f "$CPT_ROOT/$file"
        fi
    done < "$sys_db/$1/manifest"

    # Reset 'trap' to its original value. Removal is done so
    # we no longer need to block 'Ctrl+C'.
    trap pkg_clean EXIT INT

    run_hook post-remove "$1" "$CPT_ROOT/" root

    log "$1" "Removed successfully"
}

pkg_install() {
    # Install a built package tarball.

    # Install can also take the full path to a tarball.
    # We don't need to check the repository if this is the case.
    if [ -f "$1" ] && [ -z "${1%%*.tar*}" ] ; then
        tar_file=$1
        pkg_name=${1##*/}
        pkg_name=${pkg_name%#*}

    else
        pkg_cache "$1" ||
            die "package has not been built, run 'cpt b pkg'"

        pkg_name=$1
    fi

    mkdir -p "$tar_dir/$pkg_name"
    log "$pkg_name" "Extracting $tar_file"

    # Extract the tarball to catch any errors before installation begins.
    decompress "$tar_file" | "$tar" xf - -C "$tar_dir/$pkg_name"

    [ -f "$tar_dir/$pkg_name/$pkg_db/$pkg_name/manifest" ] ||
        die "'${tar_file##*/}' is not a valid CPT package"

    # Ensure that the tarball's manifest is correct by checking that
    # each file and directory inside of it actually exists.
    [ "$CPT_FORCE" != 1 ] && log "$pkg_name" "Checking package manifest" &&
        while read -r line; do
            # Skip symbolic links
            [ -h "$tar_dir/$pkg_name/$line" ] ||
            [ -e "$tar_dir/$pkg_name/$line" ] || {
        log "File $line missing from tarball but mentioned in manifest" "" "!>"
        TARBALL_FAIL=1
        }
    done < "$tar_dir/$pkg_name/$pkg_db/$pkg_name/manifest"
    [ "$TARBALL_FAIL" ] && {
        log "You can still install this package by setting CPT_FORCE variable"
        die "$pkg_name" "Missing files in manifest"
    }

    log "$pkg_name" "Checking that all dependencies are installed"

    # Make sure that all run-time dependencies are installed prior to
    # installing the package.
    [ -f "$tar_dir/$pkg_name/$pkg_db/$pkg_name/depends" ] &&
    [ "$CPT_FORCE" != 1 ] &&
        while read -r dep dep_type || [ "$dep" ]; do
            [ "${dep##\#*}" ] || continue
            [ "$dep_type" ]   || pkg_list "$dep" >/dev/null ||
                install_dep="$install_dep'$dep', "
        done < "$tar_dir/$pkg_name/$pkg_db/$pkg_name/depends"

    [ "$install_dep" ] && die "$1" "Package requires ${install_dep%, }"

    run_hook pre-install "$pkg_name" "$tar_dir/$pkg_name" root

    pkg_conflicts "$pkg_name"

    log "$pkg_name" "Installing package incrementally"

    # Block being able to abort the script with Ctrl+C during installation.
    # Removes all risk of the user aborting a package installation leaving
    # an incomplete package installed.
    trap '' INT

    # If the package is already installed (and this is an upgrade) make a
    # backup of the manifest and etcsums files.
    cp -f "$sys_db/$pkg_name/manifest" "$mak_dir/m" 2>/dev/null ||:
    cp -f "$sys_db/$pkg_name/etcsums"  "$mak_dir/c" 2>/dev/null ||:

    # This is repeated multiple times. Better to make it a function.
    pkg_rsync() {
        rsync "--chown=$USER:$USER" --chmod=Du-s,Dg-s,Do-s \
              -WhHKa --no-compress --exclude /etc "${1:---}" \
              "$tar_dir/$pkg_name/" "$CPT_ROOT/"
    }

    # Install the package by using 'rsync' and overwrite any existing files
    # (excluding '/etc/').
    pkg_rsync --info=progress2
    pkg_etc

    # Remove any leftover files if this is an upgrade.
    "$grep" -vFxf "$sys_db/$pkg_name/manifest" "$mak_dir/m" 2>/dev/null |

    while read -r file; do
        file=$CPT_ROOT/$file

        # Skip deleting some leftover files.
        case $file in /etc/*) continue; esac

        # Remove files.
        if [ -f "$file" ] && [ ! -L "$file" ]; then
            rm -f "$file"

        # Remove file symlinks.
        elif [ -h "$file" ] && [ ! -d "$file" ]; then
            unlink "$file" ||:

        # Skip directory symlinks.
        elif [ -h "$file" ] && [ -d "$file" ]; then :

        # Remove directories if empty.
        elif [ -d "$file" ]; then
            rmdir "$file" 2>/dev/null ||:
        fi
    done ||:

    log "$pkg_name" "Verifying installation"
    { pkg_rsync; pkg_rsync; } ||:

    # Reset 'trap' to its original value. Installation is done so
    # we no longer need to block 'Ctrl+C'.
    trap pkg_clean EXIT INT

    if [ -x "$sys_db/$pkg_name/post-install" ]; then
        log "$pkg_name" "Running post-install script"
        "$sys_db/$pkg_name/post-install" ||:
    fi

    run_hook post-install "$pkg_name" "$sys_db/$pkg_name" root

    log "$pkg_name" "Installed successfully"
}

pkg_fetch() {
    log "Updating repositories"

    run_hook pre-fetch

    # Create a list of all repositories.
    # See [1] at top of script.
    # shellcheck disable=2046,2086
    { IFS=:; set -- $CPT_PATH; unset IFS; }

    # Update each repository in '$CPT_PATH'. It is assumed that
    # each repository is 'git' tracked.
    for repo do
        # Go to the root of the repository (if it exists).
        cd "$repo"
        cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null ||:

        if [ -d .git ]; then

            command -v git >/dev/null || {
                log "$repo" " "
                printf '%s\n' "Git is not installed, skipping."
                continue
            }

            [ "$(git remote 2>/dev/null)" ] || {
                log "$repo" " "
                printf '%s\n' "No remote, skipping."
                continue
            }

            contains "$repos" "$PWD" || {
                repos="$repos $PWD "

                # Display a tick if signing is enabled for this
                # repository.
                case $(git config merge.verifySignatures) in
                    true) log "$PWD" "[signed ✓] " ;;
                    *)    log "$PWD" " " ;;
                esac

                if [ -w "$PWD" ] && [ "$uid" != 0 ]; then
                    git fetch
                    git merge
                    git submodule update --remote --init -f

                else
                    [ "$uid" = 0 ] || log "$PWD" "Need root to update"

                    # Find out the owner of the repository and spawn
                    # git as this user below.
                    #
                    # This prevents 'git' from changing the original
                    # ownership of files and directories in the rare
                    # case that the repository is owned by a 3rd user.
                    (
                        user=$(cpt-stat "$PWD")      || user=root
                        id -u "$user" >/dev/null 2>&1 || user=root

                        [ "$user" = root ] ||
                            log "Dropping permissions to $user for pull"

                        git_cmd="git fetch && git merge && git submodule update --remote --init -f"
                        case $su in *su) git_cmd="'$git_cmd'"; esac

                        # Spawn a subshell to run multiple commands as
                        # root at once. This makes things easier on users
                        # who aren't using persist/timestamps for auth
                        # caching.
                        user=$user as_root sh -c "$git_cmd"
                    )
                fi
            }
        elif [ -f .rsync ]; then
            read -r remote < .rsync
            if [ -w "$PWD" ] && [ "$uid" != 0 ]; then
                rsync -acvzzC --include=core --delete "$remote/" "$PWD"
            else
                [ "$uid" = 0 ] || log "$PWD" "Need root to update"

                # Similar to the git update, we find the owner of
                # the repository and spawn rsync as that user.
                (
                    user=$(cpt-stat "$PWD")      || user=root
                    id -u "$user" >/dev/null 2>&1 || user=root

                    [ "$user" = root ] ||
                        log "Dropping permissions to $user for pull"

                    user=$user as_root rsync -acvzzC --include=core --delete "$remote/" "$PWD"
                )
            fi
        else
            log "$repo" " "
            printf '%s\n' "Not a remote repository, skipping."
        fi
    done

    run_hook post-fetch
}

pkg_updates(){
    # Check all installed packages for updates. So long as the installed
    # version and the version in the repositories differ, it's considered
    # an update.
    [ "$CPT_FETCH" = 0 ] || pkg_fetch

    log "Checking for new package versions"

    set +f

    for pkg in "$sys_db/"*; do
        pkg_name=${pkg##*/}

        # Read version and release information from the installed packages
        # and repository.
        read -r db_ver db_rel < "$pkg/version"
        read -r re_ver re_rel < "$(pkg_find "$pkg_name")/version"

        # Compare installed packages to repository packages.
        [ "$db_ver-$db_rel" != "$re_ver-$re_rel" ] && {
            printf '%s\n' "$pkg_name $db_ver-$db_rel ==> $re_ver-$re_rel"
            outdated="$outdated$pkg_name "
        }
    done

    set -f

    # If the download option is specified only download the outdated packages
    # and exit.
    [ "$download_only" = 1 ] && {
        log "Only sources for the packages will be acquired"
        prompt || exit 0

        for pkg in $outdated; do
            pkg_sources "$pkg"
        done

        exit 0
    }

    contains "$outdated" cpt && {
        log "Detected package manager update"
        log "The package manager will be updated first"

        prompt || exit 0

        pkg_build cpt
        cpt-install cpt

        log "Updated the package manager"
        log "Re-run 'cpt update' to update your system"

        exit 0
    }

    [ "$outdated" ] || {
        log "Everything is up to date"
        return
    }

    log "Packages to update: ${outdated% }"

    # Tell 'pkg_build' to always prompt before build.
    pkg_update=1

    # Build all packages requiring an update.
    # See [1] at top of script.
    # shellcheck disable=2046,2086
    {
        pkg_order $outdated
        pkg_build $order
    }

    log "Updated all packages"
}

pkg_clean() {
    # Clean up on exit or error. This removes everything related
    # to the build.
    [ "$CPT_DEBUG" != 1 ] || return

    # Block 'Ctrl+C' while cache is being cleaned.
    trap '' INT

    # Remove temporary items.
    rm -rf -- "$mak_dir" "$pkg_dir" "$tar_dir" \
       "$CPT_TMPDIR/$pid-c" "$CPT_TMPDIR/$pid-m"
}

main() {
    set -ef

    # Die here if the user has no set CPT_PATH. This is a rare occurance
    # as the environment variable should always be defined.
    [ "$CPT_PATH" ] || die "\$CPT_PATH needs to be set"

    # Set the location to the repository and package database.
    pkg_db=var/db/cpt/installed

    # The PID of the current shell process is used to isolate directories
    # to each specific CPT instance. This allows multiple package manager
    # instances to be run at once. Store the value in another variable so
    # that it doesn't change beneath us.
    pid=${CPT_PID:-$$}

    # Force the C locale to speed up things like 'grep' which disable unicode
    # etc when this is set. We don't need unicode and a speed up is always
    # welcome.
    export LC_ALL=C LANG=C

    # Catch errors and ensure that build files and directories are cleaned
    # up before we die. This occurs on 'Ctrl+C' as well as success and error.
    trap pkg_clean EXIT INT

    # Prefer GNU grep if installed as it is much much faster than busybox's
    # implementation. Very much worth it if you value performance over
    # POSIX correctness (grep quoted to avoid shellcheck false-positive).
    grep=$(command -v ggrep) || grep='grep'

    # Prefer libarchive tar or GNU tar if installed as they are  much
    # much faster than busybox's implementation. Very much worth it if
    # you value performance.
    tar=$(command -v bsdtar || command -v gtar) || tar=tar

    # Figure out which 'sudo' command to use based on the user's choice or
    # what is available on the system.
    su=${CPT_SU:-$(command -v sudo || command -v doas)} || su=su

    # Store the date and time of script invocation to be used as the name
    # of the log files the package manager creates uring builds.
    time=$(date '+%Y-%m-%d-%H:%M')

    # Make note of the user's current ID to do root checks later on.
    # This is used enough to warrant a place here.
    uid=$(id -u)

    # Make sure that the CPT_ROOT doesn't end with a '/'. This might
    # break some operations.
    [ -z "$CPT_ROOT" ] || [ "${CPT_ROOT##*/}" ] || {
        warn "Your CPT_ROOT variable shouldn't end with '/'"
        CPT_ROOT=${CPT_ROOT%/}
    }

    # Define an optional sys_arch variable in order to provide
    # information to build files with architectural information.
    sys_arch=$(uname -m 2>/dev/null) ||:

    # Define this variable but don't create its directory structure from
    # the get go. It will be created as needed by package installation.
    sys_db=$CPT_ROOT/$pkg_db

    # This allows for automatic setup of a CPT chroot and will
    # do nothing on a normal system.
    mkdir -p "$CPT_ROOT/" 2>/dev/null ||:

    # Set a value for CPT_COMPRESS if it isn't set.
    : "${CPT_COMPRESS:=gz}"

    # A temporary directory can be specified apart from the cache
    # directory in order to build in a user specified directory.
    # /tmp could be used in order to build on ram, useful on SSDs.
    # The user can specify CPT_TMPDIR for this.
    #
    # Create the required temporary directories and set the variables
    # which point to them.
    mkdir -p "${cac_dir:=${CPT_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/cpt}}" \
             "${CPT_TMPDIR:=$cac_dir}" \
             "${mak_dir:=$CPT_TMPDIR/build-$pid}" \
             "${pkg_dir:=$CPT_TMPDIR/pkg-$pid}" \
             "${tar_dir:=$CPT_TMPDIR/extract-$pid}" \
             "${src_dir:=$cac_dir/sources}" \
             "${log_dir:=$cac_dir/logs}" \
             "${bin_dir:=$cac_dir/bin}"

    # Disable color escape sequences if running in a subshell.
    # This behaviour can be changed by adding a CPT_COLOR
    # variable to the environment. If it is set to 1 it will
    # always enable color escapes, and if set to 0 it will
    # always disable color escapes.
    if [ "$CPT_COLOR" = 1 ]; then color=1
    elif [ "$CPT_COLOR" = 0 ] || ! [ -t 1 ]; then
        log() { printf '%s %s %s\n' "${3:-->}" "$1" "$2" >&2 ;}
    else color=1
    fi

}

main "$@"
