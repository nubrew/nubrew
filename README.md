# Nubrew

Nubrew is an experimental package manager for Nushell modules and source files. It heavily relies on Git to install and update packages.

## Current Features

- Install a package from a Git repository
- Utilize sparse checkout to install only the files needed to run the module itself
- Uses the `kv` module from Nushell's (currently) `std-rfc` library to track module installations. This is currently used to list installed modules (`nubrew ls`)
  but is planned to be extended to update modules via the appropriate `git update` and remove modules as well.
- Automatically adds Nubrew-installed packages to the Nushell library path (`NU_LIB_DIRS`) at startup

## Non-Goals

- There is no support for installing or managing Nushell plugins.
- There is no testing framework for Nushell modules/packages.

## Installation

Nubrew can install itself, but to do so, you'll need a (probably temporary) copy of it. The following formula
will install Nubrew and clean up the temporary directory:

Due to the `use` command's requirement for a constant path, you'll need to run the following in several distinct steps.

First, paste and run the following:

```nushell
let tempbrew = (mktemp -d)
git clone --depth 1 https://github.com/nubrew/nubrew $tempbrew
cd $tempbrew
```

Then paste and run the following:

```nushell
use ./nubrew *                  # Import the temporary Nubrew
nubrew install nubrew/nubrew    # Install the permanent Nubrew
nubrew init                     # Creates an autoload file which populates the NU_LIB_DIRS during startup
cd ~
rm -r $tempbrew                 # Remove the temporary Nubrew
```

## Import Nubrew

As with any Nushell module, Nubrew must be imported before use:

```nushell
use nubrew *
```

The preceeding command can be added to your startup config if desired. For instance:

```nushell
'use nubrew *' | save ($nu.default-config-dir | path join 'autoload/Load Nubrew.nu')
```

## Usage

In the simplest scenario, Nubrew can install a package with:

```nushell
nubrew install <github_user>/<github_repo>
```

For example, a working sample can be installed via:

```nushell
nubrew install nubrew/simple-package-example
```

Once installed, any modules in the root of that package can be imported immediately:

```nushell
use sample-module
# => Hello, Module
```

It is also possible to override the package name:

```nushell
nubrew install nubrew/simple-package-example mysample
use sample-module
# => Hello, Module
```

Note that the *module* directory does not change - It is defined by the module author in the repository. Only the Nubrew *package* name changes.

### Fully-qualified Git repo

A fully-qualified repo name (including domain) can also be specified:

```nushell
nubrew install https://github.com/nubrew/simple-package-example mysample
```

### Specify Branch

If a non-mainline branch of the package is desired, you can use the `--branch` flag:

```nushell
nubrew install nubrew/nubrew --branch <branch>
```

### Specifying a different module root

Nushell modules can take the form `<directory>/mod.nu`, in which case the `<directory>` becomes the module name
to be imported (`use`'d). It can be necessary to provide a different "root" (parent) in some cases.

For example, examine [this sample repo](https://github.com/nubrew/module-root-example) and note that
the `mod.nu` is in the root directory of the repo. In this case, you can specify that the module should
be imported directly from the Nubrew packages directory by using the `--module-root` flag:

```nushell
nubrew install nubrew/module-root-example --module-root='/'
```

In some cases, you may even want to add multiple module roots. For instance, the [nu_scripts repository](https://github.com/nushell/nu_scripts) includes multiple modules in a mono-repo.

You can specify specific module roots as a list (BUT DON'T - See the next section first):

```nushell
nubrew install nushell/nu-scripts --module-root [ themes, themes/nu-themes ]
```

This would make both the theme *module* importable using `use themes`, but it would also add the themes themselves to the library path so you could, for example, `source 3024-day.nu` to load a theme directly.

### Sparse Options

But installing the entire `nu_scripts` repo takes a lot of space, and it even includes screenshots of the theme previews. A minimum of around 200MB is required in a normal Git clone, even with `--depth 1`.

This is one of the main drivers behind the design of Nubrew. By using Git sparse checkouts, we can specify *only* the directories we want from the mono-repo, and we can even *exclude* subdirectories (such as the
theme screenshots) that we don't.

For example, to install the same `themes` module and `nu-themes` as above:

```nushell
nubrew install nushell/nu_scripts 'nu_scripts-themes' --sparse-options [ '--no-cone', '--sparse-index', 'themes', '!screenshots' ] --module-root [ themes, themes/nu-themes ]
```

The `--sparse-options` is used to include *only* the `themes` directory, but to *exclude* its `screenshots` subdirectory.

The resulting package is a much more reasonable 4.6MB on the local drive.

You can refer to the Git documentation on sparse checkout for more options, but the above example will probably suffice for 
most use-cases. Keep in mind that you can include and exclude multiple directories from a mono-repository, allowing your 
package to install multiple modules at one time.

### Package Specification Records/Files

Nubrew accepts a record as pipeline input. This record contains the following keys that take the place of
their corresponding arguments:

* `repo`
* `package-name`
* `sparse-options`
* `branch`
* `module-root`

This allows a package author to pre-define how their package should be installed by Nubrew. For instance:

```nushell
http get https://raw.github.com/nubrew/module-root-example/main/nubrew.nuon
| nubrew install
```

All arguments will be read from the `nubrew.nuon` in the repository.

### Updating Packages

In theory, a simple `git pull` inside the package directory will update to the latest and greatest. As a future feature,
`nubrew update <package>` may run this automatically.

### Removing Packages

1. Delete the package directory found under `($nu.data-dir)/nubrew-packages`.
2. Remove the metadata for the package. This can be done manually using:

   ```nushell
   kv drop -u -t nubrew_packages <package-name>
   ```

   Note that this command *may* return an error depending on your configuration. This is due to a non-critical bug in `std-rfc/kv`,
   but the metadata should still be removed, which you can confirm using `kv list -u -t nubrew_packages`

As with updates, `nubrew rm` is a likely future feature, assuming Nubrew gains traction.

