export def "nubrew install" [
  package_spec_url_or_repo:string
  --sparse-dir:string = ""
  --branch:string = "main"
  --install-to:directory = "."
  --fetch-blobs = false
] {
  let install_dir = $install_to

  # There are currently three forms that the positional parameter can take:
  # 1. "nushell/nushell":  Use a GitHub repo
  # 2. "https://github.com/nushell/nushell": Specify the absolute repo
  # 3. "https://example.com/path/to/spec.nuon": A nuon with a record providing the correct parameters
  #
  # The third is not yet implemented
  #
  let repo = if ($package_spec_url_or_repo | str starts-with "http://") {
    $package_spec_url_or_repo
  } else {
    "https://github.com/"
    | url parse
    | merge { path: $package_spec_url_or_repo }
    | url join
  }

  mkdir $install_dir
  git -C $install_dir init
  git -C $install_dir remote add origin $repo
  if $sparse_dir != "" {
    git -C $install_dir sparse-checkout set --no-cone --sparse-index $sparse_dir
  }

  # TODO: Build a run-external command without the --filter if --fetch-blobs is true
  git -C $install_dir fetch --depth 1 --filter=blob:none origin $branch

  git -C $install_dir checkout $branch
}
