# shellcheck disable=2091,2034
CPT_VERBOSE=1

Describe 'CPT Library'
    export CPT_COLOR=0
    Include ./src/cpt-lib
    Describe '--help'
        It 'prints usage information when called as a standalone script'
            When run script src/cpt-lib --help
            The word 1 of output should eq "usage:"
        End
    End
    Describe 'version()'
        VERSION=$(sed -n '/VERSION/s/.* //gp' config.mk)
        It 'prints version information'
            When run script src/cpt-lib version
            The line 1 of stdout should eq "Carbs Packaging Tools, version $VERSION"
        End
    End
    Describe 'text functions'
        Describe 'out()'
            It 'outputs a message with every argument triggering a newline'
                When call out Line1 Line2
                The output should eq "$(printf 'Line1\nLine2\n')"
            End
        End

        Describe 'log()'
            Parameters
                "#1" "-> hello " hello
                "#2" "-> hello world" hello world
                "#3" "hello test world" test world hello
            End
            It "prints a message prettily ($1)"
                When call log "$3" "$4" "$5"
                The stderr should eq "$2"
            End
        End

        Describe 'die()'
            It "exits the script by printing the given message"
                When run script src/cpt-lib die "Exiting"
                The stderr should eq "!> Exiting "
                The status should be failure
            End
        End

        Describe 'warn()'
            Parameters
                "#1" "WARNING notice " "notice"
                "#2" "WARNING package not found" "package" "not found"
                "#3" "!!! package not found" "package" "not found" "!!!"
            End
            It "displays a warning message ($1)"
                When call warn "$3" "$4" "$5"
                The stderr should eq "$2"
            End
        End

        Describe 'contains()'
            Parameters
                "#1" "foo bar" baz failure
                "#2" "foo bar baz" baz success
            End
            It "checks whether the given string list contains a word ($1)"
                When call contains "$2" "$3"
                The status should be "$4"
            End
        End

        Describe 'pop()'
            It "removes the first item from the following items"
                When call pop baz from foo bar baz
                The output should eq " foo  bar "
            End
        End

        Describe 'regesc()'
            Parameters
                "#1" '^[\\test$' '\^\[\\\\test\$'
                "#2" '\.*$' '\\\.\*\$'
            End
            It "escapes POSIX BRE sequences ($1)"
                When call regesc "$2"
                The output should eq "$3"
            End
        End

        Describe 'sepchar()'
            It 'seperates the output of given string'
                When call sepchar test
                The output should eq "$(printf 't\ne\ns\nt\n')"
            End
        End
    End


    Describe 'helper functions'
        Describe '_seq()'
            It 'counts to the given number'
                When call _seq 3
                The output should eq " 1  2  3 "
            End
        End

        Describe '_stat()'
            It 'outputs the owner of the given file'
               When call _stat LICENSE
               The output should eq "$(id -un)"
            End
        End

        Describe '_readlinkf()'
            mklink() { :> tests/testfile; ln -s testfile tests/testfile2 ;}
            rmlink() { rm tests/testfile tests/testfile2 ;}
            RPWD=$(cd -P .||:; printf %s "$PWD")
            BeforeEach mklink
            AfterEach  rmlink
            Parameters
                "#1" . "$RPWD"
                "#2" "./tests/testfile2" "$RPWD/tests/testfile"
            End
            It "outputs the real location of the given file [$1] ($2 -> $3)"
               When run _readlinkf "$2"
               The output should eq "$3"
            End
        End

        Describe 'sh256()'
            It 'outputs an sha256 digest of the given file using any valid system tool'
                # This should cover our bases for a long time.
                When call sh256 .editorconfig
                The output should eq "da42265df733ca05a08d77405c35aa3dd5b8b7fefcc2da915f508067a49351da  .editorconfig"
            End
        End
    End

    Describe 'system functions'
        Describe 'as_root()'
            as_root_env() { user=$1 as_root env ;}
            Parameters
                root
                "$(id -un)"
            End
            It "runs the given command as user: '$1'"
                When call as_root_env "$1"
                The output should not eq ""
                The stderr should not eq ""
                The status should be success
            End
        End
    End

    Describe 'version control functions'
        check_internet_connection() { ! curl -L git.carbslinux.org >/dev/null 2>&1 ;}
        Skip if "no internet connection" check_internet_connection
        Describe 'pkg_vcs_clone_git()'
            tmpfos=$$
            setup() { mkdir "/tmp/test_repository.$tmpfos" && cd "/tmp/test_repository.$tmpfos" || return ;}
            cleanup() { cd /tmp && rm -rf "test_repository.$tmpfos" ;}
            check_version() { [ "$1" = "$(sed -n '/^version=/s/.*=//p' configure)" ] ;}
            BeforeEach setup
            AfterEach cleanup
            It "clones the given git repository to the current directory"
                When call pkg_vcs_clone_git https://git.carbslinux.org/cpt
                The output should not eq ""
                The stderr should not eq ""
                The status should be success
                Assert [ ! -d test_repository ]
                Assert [ -f README.md ]
                Assert check_version Fossil
            End
            It "clones the given tag when asked for it"
                When call pkg_vcs_clone_git https://git.carbslinux.org/cpt @6.2.4
                The output should not eq ""
                The stderr should not eq ""
                The status should be success
                Assert [ ! -d test_repository ]
                Assert [ -f README.md ]
                Assert check_version 6.2.4
            End
        End
        Describe 'pkg_vcs_clone_fossil()'
            tmpfos=$$
            setup() { mkdir "/tmp/test_repository.$tmpfos" && cd "/tmp/test_repository.$tmpfos" || return ;}
            cleanup() { cd /tmp && rm -rf "test_repository.$tmpfos" ;}
            check_version() { [ "$1" = "$(sed -n '/^version=/s/.*=//p' configure)" ] ;}
            BeforeEach setup
            AfterEach cleanup
            It "clones the given fossil repository to the current directory"
                When call pkg_vcs_clone_fossil https://fossil.carbslinux.org/cpt
                The output should not eq ""
                The stderr should eq ""
                The status should be success
                Assert [ ! -d test_repository ]
                Assert [ -f README.md ]
                Assert check_version Fossil
            End
        End
    End
    Describe 'package functions'
        Describe 'run_hook()'
            CPT_HOOK=$PWD/tests/hook-file
            CPT_ROOT=$PWD/tests
            It "runs the given hook file"
                When call run_hook 1 test-package destination
                The stderr should eq "-> test-package Running 1 hook"
                The output should eq "$CPT_HOOK 1 test-package destination"
            End
            It "doesn't log 'running hook' if no package is given"
                When call run_hook 2 '' destination
                The stderr should eq "-> Running 2 hook"
                The output should eq "$CPT_HOOK 2 null destination"
            End
            It "returns with success even when the file doesn't exist"
                CPT_HOOK=$PWD/some-non-existent-file
                When call run_hook 4 thiswillnotrun
                The variable CPT_HOOK should not be exist
                The stderr should eq ""
                The status should be success
            End
        End
        Describe 'create_tmp()'
            After pkg_clean
            It 'creates cache directories'
                When call create_tmp
                The variable mak_dir should be a directory
            End
        End
        Describe 'pkg_get_base()'
        CPT_ROOT=$PWD/tests
        CPT_PATH=$PWD/tests/repository
        cpt_base=$PWD/tests/etc/cpt-base
            It 'returns packages defined in base'
                When call pkg_get_base nonl
                The output should eq "dummy-pkg contrib-dummy-pkg "
            End
        End
        Describe 'pkg_query_meta()'
        CPT_PATH=$PWD/tests/repository
            It 'queries package meta information'
                When call pkg_query_meta contrib-dummy-pkg description
                The output should eq "This is a dummy package"
            End
            It 'returns an error if there is no meta file'
                When call pkg_query_meta dummy-pkg description
                The status should be failure
            End
            It 'returns an error if the queried key is unavailable'
                When call pkg_query_meta contrib-dummy-pkg license
                The status should be failure
            End
            It "accepts full paths to the package location"
                When call pkg_query_meta "$PWD/tests/repository/contrib-dummy-pkg" description
                The output should eq "This is a dummy package"
                The status should be success
            End
        End
    End
End
