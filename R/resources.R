#' Open ECCC Movebank Manual for GPS, GSM, and satellite data
#'
#' Opens the Movebank Manual file for GPS, GSM, and satellite data included with the package.
#'
#' @export
open_manual_gps <- function() {
  browseURL(
    system.file("manuals", "ECCC Movebank User Manual - GPS, GSM, Satellite.pdf", package = "seamoveR")
  )
}

#' Open ECCC Attribute Dictionary for GPS, GSM, and satellite data
#'
#' Opens the GPS attribute dictionary file for GPS, GSM, and satellite data included with the package.
#'
#' @export
open_attribute_dictionary_gps <- function() {
  browseURL(
    system.file("manuals", "ECCC Movebank Attribute Dictionary - GPS, GSM, Satellite.pdf", package = "seamoveR")
  )
}

#' Copy Metadata Template for GPS, GSM, and satellite data
#'
#' Copies the metadata template for GPS, GSM, and satellite data to a user-specified location.
#'
#' @param path File path where the template should be copied.
#' @export
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
