CHANGELOG
=========

List of important changes will be in this file. The format is based on [Keep a Changelog], and
this project _somewhat_ adheres to [Semantic Versioning].

[Keep a Changelog]:    https://keepachangelog.com/en/1.0.0/
[Semantic Versioning]: https://semver.org/spec/v2.0.0.html

1.20.0 - 2020-05-07
-------------------

### Added
- `KISS_NOPROMPT` can be specified in order to skip prompts

1.19.1 - 2020-05-07
-------------------

### Added
- Added `e|extension` to `kiss` which can be used to output kiss-extensions.

### Changed
- `kiss` no longer outputs the extensions when called with `kiss help`. The
  output was too large for an average terminal, and a user had to scroll up
  for actual package manager options. These can now be retrieved with `kiss e`.
- When called from a subshell, `kiss` disables colour escape sequences. This
  behaviour can be overriden by setting `KISS_COLOUR` environment variable.
  If set to 1, it will be enabled globally, if set to 0 it will be disabled
  globally.


1.19.0 - 2020-05-06
-------------------

### Added
- Added `kiss-reporevdepends` for finding all the packages on the repository that depends
  on the specified package.

### Changed
- Removed the `-p` flag from tar while installing packages. busybox ignores it and we
  don't need it.
- Replaced tar flags with keys for historical compatibility.
- `kiss` now decompresses a tarball once and uses the decompressed tarball for listing
  and extraction

### Fixed
- Fixed the output of docstrings in contrib scripts.
- `kiss` now ignores the binary programs in the repository for `kiss extensions`.


1.18.0 - 2020-05-04
-------------------

### Added
- Added editorconfig file since we now have 4 languages (roff, Makefile, sh, C) in the repository.
- Added `kiss-readlink` as a `readlink -f` replacement.
- Added `kiss-message` for checking package messages.
- Added this CHANGELOG

### Changed
- Made tar calls portable. `kiss` is no longer limited to busybox, bsdtar, or gnu tar!

### Removed
- Dropped the usage of `readlink` in `kiss`.

1.17.0 - 2020-05-03
-------------------

### Added
- Added `kiss-stat`, a simple C program for getting the owner name of a file/directory.

### Removed
- Removed the usage of `stat` calls, as they are not standardized.

### Changed
- `kiss` now doesn't report `Generating etcsums` if there isn't an `/etc` directory in the package

### Fixed
- `kiss` now uses `sys_db` instead of `pkg_db` when removing packages from the system.
- `kiss` now explicitly exits if prompt returns with a status of 1. This is for `ksh` compatibility.

1.16.3 - 2020-05-03
-------------------

### Fixed
- Fixed etcsum location.

1.16.2 - 2020-05-03
-------------------

### Added
- Added fallbacks for sha256sum. `kiss` now fallbacks to `sha256`, and `openssl`
  for hash checking, respectively.
- Added `kiss-changelog` and `kiss-which` entries to the `kiss-contrib.1` manual page.

### Fixed
- Fixed `kiss` not using the preferred `tar` program on decompression.
- Fixed `pkg_conflicts()` getting stuck when you reinstall the same single package on a system.
- Fixed `pkg_conflicts()` giving an error if no packages are installed on a system.

1.16.1 - 2020-05-01
-------------------

### Fixed
- Fixed `ksh` Ctrl+C interrupt signals.

1.16.0 - 2020-05-01
-------------------

### Added
- New message queue system implementation. If a package includes a file named
  `message` it will output its contents in a pretty way.
- Added `kiss-which`, a tool like `which` but for `kiss` packages.
- Added `kiss-changelog`, a tool for outputting the git log of a given package.

### Fixed
- Fixed colour outputting on `OpenBSD ksh`.
- Made compatibility fixes on the Makefile
- Fixed an installation issue where `kiss` would look for the manifest with the
  `$KISS_ROOT` variable

1.15.0 - 2020-04-30
-------------------

I have decided to revert to rsync installation method as it is faster and safer.
Now, rsync is not a huge dependency. Saving 500Kb is not worth it when you look
at the trade-off.

### REMOVED
- Removed the new installation method.

### Changed
- Reverted to `rsync` for installation.
- We are now forcing decompression to standard output while using `decompress()`
- `kiss` now accepts decompressed tar archives for package installation as well.

1.14.2/1.14.3 - 2020-04-27
--------------------------

### Fixed
- The new installation method now complies to the `$KISS_ROOT` value.


1.14.1 - 2020-04-27
-------------------

### Removed
- Removed the unnecessary `[ -d ]` from the path query.

### Fixed
- Fixed directory permissions in the new installation method.
- Added support for `$KISS_ROOT` to the new installation method.
- Added a check for symlinks that could overwrite a directory during installation.
- Whitespace cleanup.

1.14.0 - 2020-04-25
-------------------

This release removes `rsync` from `kiss` and implements its own installation
method.

### Added
- `kiss` now implements user scripts available in the `$PATH`. This can be used to
  call `kiss manifest` from `kiss` itself.
- `kiss` now displays a warning if the user has a `$KISS_ROOT` that ends with a `/`.
- `kiss` now uses its own new package installation method.

### Removed
- usage of rsync as an installation method.
- usage of `old_ifs`

1.13.1 - 2020-04-19
-------------------

### Removed
- Reverted and removed `kiss ss` changes.

1.13.0 - 2020-04-19
-------------------

### Added
- `kiss ss` for outputting a single location for scripting.

### Changed
- `kiss` now elevates permissions during checksum if the file isn't owned by us.
- Hide read error messages when `version` file cannot be found.
- Made the `pkg_fixdeps()` usage of `diff` portable.

### Fixed
- Fixed a shellcheck error.

1.12.3 - 2020-04-17
-------------------

### Changed
- Changed indentation style on decompression.

### Fixed
- `kiss-export` fallbacks to gzip if the compression method is unknown.
- `kiss-repodepends` now outputs the proper depends file.

1.12.2 - 2020-04-15
-------------------

### Added
- `kiss` can now decompress zip files.

### Changed
- `checksum`, `build`, `install`, and `remove` operations can now be done on the
  current package directory without arguments. So you can `cd` into a package an
  type `kiss b` to build that package.

### Fixed
- `kiss-export` now honours your `KISS_COMPRESS` value

1.12.1 - 2020-04-12
-------------------

### Fixed
- Fixed printing empty arguments in `kiss-outdated`.

1.12.0 - 2020-04-05
-------------------

### Added
- `kiss-cargolock-urlgen`: a tool that can read a Cargo.lock file to generate a list of urls.
- `kiss-cat`: a tool to concatanate package build files.
- Manual page for `kiss-contrib`.

### Changed
- `kiss-owns` now gives an error on directories.
- `kiss-link` can now take multiple file names and will create symbolic links of them all.
- Simplified `kiss-link`

### Fixed
- `kiss-cargo-urlgen`: Fixed an issue where if a package version contained a '-',
    it could lead to wrong url generation.

1.9.0 - 1.11.2 - 2020-04-04
---------------------------

### Added
- `kiss f` to fetch repositories without an update prompt.
- Support for submodules in the repository.
- Added a Makefile to standardize the installation.
- Zstd compression method.

### Changed
- Modified `kiss-chbuild` to fit Carbs Linux.
- Changed README to notify about forking status.
- `pkg_find()` now also checks for symlinks instead of just directories.
- `pkg_find()` now uses a `for` loop instead of `find`.
- Force C locale for faster grepping.
- Easily readable manual page.

### Fixed
- Compression method now fallbacks to gzip if unknown.
