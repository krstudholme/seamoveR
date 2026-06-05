open_manual_gps <- function() {
  browseURL(
    system.file("manuals", "ECCC Movebank User Manual - GPS, GSM, Satellite.pdf", package = "seamoveR")
  )
}

open_attribute_dictionary_gps <- function() {
  browseURL(
    system.file("manuals", "ECCC Movebank Attribute Dictionary - GPS, GSM, Satellite.pdf", package = "seamoveR")
  )
}

copy_metadata_template_gps <- function(path = ".") {

  dest <- file.path(path, "metadata_template.xlsx")

  file.copy(
    system.file(
      "templates",
      "Movebank Reference Data Template - GPS, GSM, Satellite.xlsx",
      package = "seamoveR"
    ),
    to = dest,
    overwrite = FALSE
  )

  message("Template copied to: ", normalizePath(dest))

  invisible(dest)
}
