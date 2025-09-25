const nubrew_db = ($nu.data-dir)/nubrew.sqlite3
const default_package_dir = ($nu.data-dir)/nubrew

export def --env "nubrew install" [
  repo:string
  package_name?:string
  --sparse-options:list = []
  --branch:string = "main"
] {
  let assumed_package_name = ($repo | path parse | get stem)
  let $package_name = (
    $package_name
    | default $assumed_package_name
  )
  let package_dir = [ $default_package_dir, $package_name ] | path join

  # There are currently three forms that the positional parameter can take:
  # 1. "nushell/nushell":  Use a GitHub repo
  # 2. "https://github.com/nushell/nushell": Specify the absolute repo
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

  $env.NU_LIB_DIRS ++= [ $package_dir ]

  kv set -u -t nubrew_packages $package_name {
    directory: $package_dir
    repo: $repo
  }
}

def "nubrew init" [] {
  use std-rfc/str

  r#'
  
  '#
}

export def "nubrew ls" {
  kv list -u -t nubrew_packages | rename package
}
