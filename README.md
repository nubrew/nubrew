# nubrew

Nubrew is an experimental package manager for Nushell modules and source files. It heavily relies on Git to install and update packages.

## Current Features

- Install a package from a Git repository
- Utilize sparse checkout to install only the files needed to run the module itself
- Uses the `kv` module from Nushell's (currently) `std-rfc` library to track module installations. This is currently used to list installed modules (`nubrew ls`)
  but is planned to be extended to update modules via the appropriate `git update` and remove modules as well.
- Automatically adds Nubrew-installed packages to the Nushell library path (`NU_LIB_DIRS`) at startup

## Installation

Nubrew can install itself, but to do so, you'll need a (probably temporary) copy of it. The following formula will install Nubrew and clean up the temporary directory:

Due to the need for `use` to require a constant, you'll need to run the following in several distinct steps.

First, paste and run the following:

```nushell
let tempbrew = (mktemp -d)
git clone --depth 1 https://github.com/nubrew/nubrew $tempbrew
cd $tempbrew
```

Then paste and run the following:

```nushell
use . *
nubrew install nubrew/nubrew --module-root '/'
nubrew init # Creates an autoload file which populates the NU_LIB_DIRS during startup
cd ~
rm -r $tempbrew
```

## Import Nubrew

As with any module, Nubrew must be imported before use:

```nushell
use nubrew *
```

The preceeding command can be added to your startup config if desired. For instance:

```nushell
'use nubrew *' | save ($nu.default-config-dir | path join 'autoload/Load Nubrew.nu')
```

## Usage

In the simplest scenario, Nubrew can install a module with:

```nushell
nubrew install nubrew/sample-module
```








