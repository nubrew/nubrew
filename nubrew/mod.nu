use std-rfc/conversions *
use std-rfc/kv *

const nubrew_db = ($nu.data-dir)/nubrew.sqlite3
const default_package_dir = ($nu.data-dir)/nubrew-packages

export def --env "nubrew install" [
  repo:string
  package_name?:string
  --sparse-options:list = []
  --branch:string = "main"
  --module-root: oneof<list, string>          # The subdirectory within the nubrew packages directory that will be source'd or use'd. Defaults to the location of this package if not specified.
] {
  # If not specified, we'll assume the package name is simply the last part of the path
  let assumed_package_name = ($repo | path parse | get stem)
  let $package_name = (
    $package_name
    | default $assumed_package_name
  )

  # Packages are installed into a directory named after the package, inside the Nubrew default package directory
  let package_dir = [ $default_package_dir, $package_name ] | path join

  # There are currently three forms that the positional parameter can take:
  # 1. "nubrew/nubrew":  Use a GitHub repo
  # 2. "https://github.com/nubrew/nubrew": Specify the absolute repo
  # 3. "https://example.com/path/to/spec.nuon": A nuon with a record providing the correct parameters
  #
  # The third is not yet implemented
  #
  let repo = if ($repo | str starts-with "https://") or ($repo | str starts-with "git@github.com:") {
    $repo
  } else {
    "https://github.com/"
    | url parse
    | merge { path: $repo }
    | url join
  }

  git clone --depth=1 --filter=blob:none --no-checkout $repo $package_dir
  if $sparse_options != [] {
    git -C $package_dir sparse-checkout set ...$sparse_options
  }

  git -C $package_dir checkout $branch

  # Add modules to the NU_LIB_DIRS for easy access

  # If a string was provided (a single module root), then turn it into a list; otherwise keep it a list
  let module_root = ($module_root | into list)

  # Expand each item in the list to a fully-qualified path to be added to NU_LIB_DIRS (after install)
  let module_root_expanded = (
    $module_root | each {|mr|
      match $mr {
        '/' => $default_package_dir
        '.' => $package_dir
        null => $package_dir   # If not specified
        _ => ([ $package_dir, $mr] | path join)
      }
    }
  )

  $env.NU_LIB_DIRS ++= $module_root_expanded

  kv set -u -t nubrew_packages $package_name {
    directory: $package_dir
    repo: $repo
    module-root: $module_root_expanded
  }
}

export def "nubrew init" [] {
  use std-rfc/str

  r#'
    use std-rfc/kv *
    $env.NU_LIB_DIRS ++= (kv list -u -t nubrew_packages | get value | get module-root | flatten | uniq)
  '#
  | str unindent
  | save -f ($nu.default-config-dir | path join 'autoload/00.nubrew-set-lib-path.nu')
}

export def "nubrew ls" [] {
  kv list -u -t nubrew_packages | rename package
}
