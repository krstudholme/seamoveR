#' Prepare TechnoSmArt GPS/GPS-UHF(+TDR) data for import into Movebank
#'
#' @param data.dir Filepath to the directory containing all TechnoSmArt data to be
#'  re-formatted. Data must be in .csv format, the direct (unaltered) result of
#'  processing raw base station .rem or .ard files using the X Manager program.
#'  Multiple files can exist for each tag. The function currently relies on the
#'  'Set Movebank Compatibility' button being selected during processing - pressure
#'  in millibars, date and time in the same column, date format dd/mm/yyyy, time
#'  format 0-24. Other user-generated files should not be placed in this folder.
#' @param out.dir Filepath to the directory in which to save .csv files of the
#'  Movebank-formatted position data, and TDR data if applicable.
#' @param spcd Four-letter species code to use when generating the .csv filename
#'  for the Movebank-formatted position data, and TDR data if applicable.
#' @param site Colony name/abbreviation (no spaces) to use when generating the
#'  .csv filename for the Movebank-formatted position data, and TDR data if applicable.
#'
#' @details This function is intended to compile and format TechnoSmArt GPS and GPS-UHF tracking
#'  data from multiple birds tracked from a single site. It processes the raw data
#'  files (.csv file(s) produced from TechnoSmArt base station file(s) (.rem or .ard) using the
#'  X Manager program) into a single file for positional data and a single file for
#'  temperature-depth data. Files are formatted to comply with Movebank's required field names and units.
#'
#'  Note: For users working with burrow nesting species, you may wish to perform
#'  additional data processing to identify where missing locations likely represent
#'  burrow use, utilizing the base station generated metadata files. If you do this,
#'  you would change 'location-lon' and 'location-lat' to the deployment location,
#'  change the 'comments' field to a description of the change you made and why, and
#'  change 'import-marked-outlier' to FALSE.
#'
#' @return Returns an single object if only positional data are present, or a list
#'  of two objects if both positional and temperature-depth data are present. If out.dir,
#'  spcd, and site are specified, the function will save Movebank-formatted .csv file(s) to
#'  the location specified.
#' @export
#' @importFrom utils read.csv read.table write.csv
#' @importFrom dplyr across where everything
#' @importFrom readr read_delim
formatTechnoSmartGPS <- function(data.dir, out.dir = NULL, spcd = NULL, site = NULL) {

  ## Format positional data ##

  # Import and merge all '.csv' files, keep distinct, blanks to NA

  files <- list.files(path = data.dir, pattern = "*.csv", recursive = T)

  # Allow either ; or , separator with delim = NULL

  dat <- do.call(rbind, lapply(paste0(data.dir, "/", files),
                               readr::read_delim, delim = NULL, show_col_types = FALSE, guess_max = 10000)) |>
    dplyr::distinct()

  # Fix tagIDs
  # Remove invalid dates
  # Fix datetime format
  # Fill voltage records, group in case first record of voltage is missing

  dat <- dat |>
    dplyr::filter(substr(Timestamp, 1, 10) != "01/01/0001") |>
    dplyr::mutate(TagID = sub(".*_(\\d+)-.*", "\\1", TagID),     ## Likely needs work! see ard files
                  Timestamp = as.character(as.POSIXct(Timestamp, format = "%d/%m/%Y %H:%M:%S", tz = "UTC"))) |>
    dplyr::group_by(TagID) |>
    tidyr::fill(`Battery (V)`, .direction = "down") |>
    dplyr::ungroup()

  print(paste('Loaded', length(files), 'data file(s) from', length(unique(dat$TagID)), "tag(s)."))

  # Make positional dataset (no dive data)
  # No records for failed/skipped fixes (poor signal, accelerometry-based) - info in separate metadata file for TechnoSmart
  # No off in range of base station setting

  pos <- dat |>
    dplyr::filter(!is.na(`location-lon`)) |>
    dplyr::filter(substr(Timestamp, 1, 10) != "01/01/0001")

  # Rename columns and format for Movebank
  # Filter duplicates, sort

  ## NEED to handle filling for voltage before splitting off lat/lon data. ##

  pos <- pos |>
    dplyr::mutate(`sensor-type` = "GPS",
                  `gps-fix-type-raw` = ifelse(!is.na(`height-msl`), "3D", "2D"), # Technosmart reports skipped/missed fixes in separate metadata file
                  `tag-id` = TagID,
                  timestamp = Timestamp,
                  #`location-lat` = `location-lat`,
                  `location-long` = `location-lon`,
                  `height-above-mean-sea-level` = `height-msl`, # meters
                  `ground-speed` = `ground-speed`/3.6, # m/s, Technosmart in kph
                  `gps:satellite-count` = satellites,
                  `gps-hdop` = hdop,
                  `TechnoSmart-signal-quality` = `signal-strength`, # dB-Hz
                  `tag-voltage` = `Battery (V)`*1000, # mV not volts
                  ) |>
    dplyr::select('sensor-type', 'tag-id',
                  timestamp, 'location-long', 'location-lat',
                  'gps-fix-type-raw', 'gps:satellite-count', 'gps-hdop', 'TechnoSmart-signal-quality',
                  'height-above-mean-sea-level', 'ground-speed', 'tag-voltage') |>
    dplyr::arrange(`tag-id`, timestamp) |>
    dplyr::distinct()

  # Save .csv if required info is provided

  if(!is.null(out.dir) & !is.null(spcd) & !is.null(site)) {

    write.csv(pos, paste0(out.dir, "/posData_", spcd, "_GPS_", site, ".csv"), row.names = F, na = '')

  }


  ## Format TDR data if present ##

  # Occurs within same original file as the position data
  # Column for Pressure or Depth may be absent

  if(("Pressure" %in% names(dat) && !all(is.na(dat$Pressure))) || "Depth" %in% names(dat) && !all(is.na(dat$Depth))){

    # Make basic TDR dataset, start formatting for Movebank

    tdr <- dat |>
      dplyr::filter(dplyr::if_any(c(Pressure, `Temp. (?C)`), ~ !is.na(.))) |> # remove row if all are NA, drops some Activity records, all Accel 0
      dplyr::select(TagID, Timestamp, Activity, Pressure, `Temp. (?C)`) |>    ## Any point in keeping volatage here too?
      dplyr::mutate(`sensor-type` = "TDR",
                    `TechnoSmart-activity` = ifelse('Active' %in% Activity, 'active', 'inactive'),
                    wet = ifelse('Wet' %in% Activity, TRUE, FALSE)) |>
      dplyr::rename(`tag-id` = TagID,
                    timestamp = Timestamp,
                    `external-temperature` = `Temp. (?C)`) |>
      dplyr::arrange(`tag-id`, timestamp)

    # Fix Pressure column for Movebank, if present

    if("Pressure" %in% names(dat)){
      tdr <- tdr |>
        dplyr::rename(`barometric-pressure` = Pressure) |> # hPa (mbar)
        dplyr::select('sensor-type', 'tag-id', timestamp,
                      'barometric-pressure', 'external-temperature',
                      'TechnoSmart-activity', wet)
    }

    # Fix Depth column for Movebank, if present

    if("Depth" %in% names(dat)){
      tdr <- tdr |>
        dplyr::rename(depth = Depth) |> # meters
        dplyr::select('sensor-type', 'tag-id', timestamp,
                      depth, 'external-temperature',
                      'TechnoSmart-activity', wet)
    }

    print(paste("TDR data identified for", length(unique(tdr$`tag-id`)), "tag(s)."))

    # Save .csv if required info is provided

    if(!is.null(out.dir) & !is.null(spcd) & !is.null(site)) {

      write.csv(tdr, paste0(out.dir, "/tdrData_", spcd, "_GPS_", site, ".csv"), row.names = F, na = '')

    }

    # Save pos and tdr as a list
    out_list <- list(
      pos = pos,
      tdr = tdr
    )

  } else {

    return(pos)

  }

}
