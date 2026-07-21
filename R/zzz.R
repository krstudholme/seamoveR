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

      msg <- paste0(
        "\nA newer version of seamoveR is available (",
        remote_version, " > ", installed_version, ").\n",
        "Update with: remotes::install_github('krstudholme/seamoveR')\n"
      )

      news_bullets <- tryCatch({
        news_lines <- readLines(
          "https://raw.githubusercontent.com/krstudholme/seamoveR/main/NEWS.md",
          warn = FALSE
        )
        start <- grep(paste0("^# seamoveR ", remote_version, "\\b"), news_lines)
        if (length(start) > 0) {
          rest <- news_lines[(start[1] + 1):length(news_lines)]
          end <- which(grepl("^# seamoveR", rest))[1]
          bullets <- if (!is.na(end)) rest[seq_len(end - 1)] else rest
          bullets <- bullets[nzchar(trimws(bullets))]
          if (length(bullets) > 0) bullets else NULL
        } else {
          NULL
        }
      }, error = function(e) NULL)

      if (!is.null(news_bullets)) {
        msg <- paste0(msg, "\nWhat's new:\n", paste(news_bullets, collapse = "\n"), "\n")
      }

      packageStartupMessage(msg)

    }
  }, condition = function(e) invisible(NULL))
}
