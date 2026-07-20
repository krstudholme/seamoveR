.onLoad <- function(libname, pkgname) {
  packageStartupMessage(
    "seamoveR loaded. See the README to get started:\n",
    "  https://github.com/krstudholme/seamoveR#readme\n",
    "Supporting documents:\n",
    "  open_manual_gps()                 - ECCC Movebank Manual\n",
    "  open_attribute_dictionary_gps()   - ECCC Attribute Dictionary\n",
    "  copy_metadata_template_gps(path)  - Reference Data Template (Excel)"
  )
  if (interactive()) {
    check_seamoveR_version()
  }
}

check_seamoveR_version <- function() {
  tryCatch({
    installed_version <- as.character(utils::packageVersion("seamoveR"))

    old_timeout <- getOption("timeout")
    options(timeout = 2)
    on.exit(options(timeout = old_timeout), add = TRUE)

    desc_lines <- readLines(
      "https://raw.githubusercontent.com/krstudholme/seamoveR/main/DESCRIPTION",
      warn = FALSE
    )

    remote_version <- trimws(sub("^Version:", "", grep("^Version:", desc_lines, value = TRUE)))

    if (length(remote_version) == 1 &&
        package_version(remote_version) > package_version(installed_version)) {
      packageStartupMessage(
        "\nA newer version of seamoveR is available (",
        remote_version, " > ", installed_version, ").\n",
        "Update with: remotes::install_github('krstudholme/seamoveR')\n"
      )
    }
  }, condition = function(e) invisible(NULL))
}
