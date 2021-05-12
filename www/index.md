# Home

CPT is the package management toolset written for Carbs Linux. Its aim is to
provide a stable, powerful, and easily used library for package management that
complements the tools that come with it. It has the following features:

- **POSIX shell library** - with its shell library, it is really easy to create
  advanced scripts that wrap around the package manager and extend its
  functionality.
  
- **Powerful, but simple** - even with the multitudes of functionalities that
  CPT provides, the tools provided aim to be as "low-interaction" as possible
  and get out of your way. No user should spend countless hours on wiki pages
  just to understand the proper way of installing a "masked" package. If the
  user seeks to modify the build of a package, easy tools should be provided,
  but those tools should not be required for basic functionality.
  
- **Simple packaging system** - CPT has a easy to understand, simple, and static
  packaging system, that makes it really easy to write and maintain packages.
  Instead of complex `PKGBUILD` scripts or weird templates, packages are formed
  of multiple little files that are easily written and easily parsed, even
  without needing the help of the package manager itself.
  
- **Easy Repository Management** - CPT makes it easy to create or use multiple
  repositories at the same time. Repositories are added and prioritised by the
  `$CPT_PATH` variable, an environment value that is already familiar to many
  users with the `$PATH` variable.
  
- **Serve repositories with your method** - Package repositories can be served
  in a variety of formats, they can be either local, served with Git, Mercurial,
  or through the `rsync` method, with Fossil integration to be added soon.

<hr>

### Latest Release: 6.0.4 ([2021-05-12](/timeline?c=6.0.4))

- [Download](/uvlist?byage=1)
- [Changelog](/doc/trunk/CHANGELOG.md)
- [User Manual](https://carbslinux.org/docs/cpt)
