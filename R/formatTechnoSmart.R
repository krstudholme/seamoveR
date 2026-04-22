#' Prepare TechnoSmArt GPS-UHF(+TDR) data for import into Movebank (archival too?)
#'
#' @param data.dir Filepath to the directory containing all TechnoSmArt data to be
#'  re-formatted. Data must be in .csv format, the direct (unaltered) result of
#'  processing raw base station .rem files using the X Manager program. The function
#'  currently relies on the 'Set Movebank Compatibility' button being selected
#'  during processing - pressure in millibars, date and time in the same column,
#'  date format dd/mm/yyy, time format 0-24. Other user-generated files should not
#'  be placed in this folder.
#' @param out.dir Filepath to the directory in which to save .csv files of the
#'  Movebank-formatted position data, and TDR data if applicable.
#' @param spcd Four-letter species code to use when generating the .csv filename
#'  for the Movebank-formatted position data, and TDR data if applicable.
#' @param site Colony name/abbreviation (no spaces) to use when generating the
#'  .csv filename for the Movebank-formatted position data, and TDR data if applicable.
#'
#' @details This function is intended to compile and format TechnoSmArt GPS and GPS-UHF tracking
#'  data from multiple birds tracked from a single site. It processes the raw data
#'  files (.csv file(s) produced from TechnoSmArt base station file(s) (.rem) using the
#'  X Manager program) into a single file for positional data and a single file for
#'  time-depth data. Files are formatted to comply with Movebank's required field
#'  names and units.
#'
#'  Note: For users working with burrow nesting species, you may wish to perform
#'  additional data processing to identify where missing locations likely represent
#'  burrow use. If you do this, you would change 'location-lon' and 'location-lat'
#'  to the deployment location, change the 'comments' field to a description of the
#'  change you made and why, and change 'import-marked-outlier' to FALSE.
#'
#' @return Returns an single object if only positional data are present, or a list
#'  of two objects if both positional and time-depth data are present. If out.dir,
#'  spcd, and site are specified, the function will save Movebank-formatted .csv file(s) to
#'  the location specified.
#' @export
#' @importFrom utils read.csv read.table readr write.csv
#' @importFrom dplyr across where everything
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
  # Fill voltage records, group in case first record of voltage is missing

  dat <- dat |>
    dplyr::mutate(TagID = sub(".*_(\\d+)-.*", "\\1", TagID)) |>  ## Likely needs work! see ard files
    dplyr::filter(substr(Timestamp, 1, 10) != "01/01/0001") |>
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
                  `height-above-mean-sea-level` = `height-msl`, # meters,  is Technosmart m?
                  `ground-speed` = `ground-speed`/3.6, # m/s, is Technosmart kph?
                  `gps:satellite-count` = satellites,
                  `gps-hdop` = hdop,
                  `TechnoSmart-signal-quality` = `signal-strength`, # out of 500
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

  # Occurs within same original file as the pos data

  if(!all(is.na(dat$pressure))){     ## Or would column be missing if no pressure collected?

    # Make TDR dataset
    # Rename columns and format for Movebank

    tdr <- dat |>
      dplyr::filter(dplyr::if_any(c(Div.up, Div.down, PH, Depth), ~ !is.na(.))) |>
      dplyr::select(where(~ !all(is.na(.)))) |>
      dplyr::mutate(`barometric-pressure` = ifelse(!is.na(PH), PH, PA), # hPa (mbar)
                    comments = ifelse(!is.na(PH), "hydrostatic pressure",
                                      ifelse(!is.na(PA), "atmospheric pressure", NA)),
                    `dive-duration` = lubridate::period_to_seconds(lubridate::hms(Diving.duration)),
                    depth = Depth/100, # meters, Ecotone in cm
                    `sensor-type` = "TDR",
                    timestamp = paste(paste(Year, sprintf("%02d", Month), sprintf("%02d", Day), sep = "-"), paste(sprintf("%02d", Hour), sprintf("%02d", Minute), sprintf("%02d", Second), sep = ":"))) |>
      dplyr::rename(`external-temperature` = Temp_sens,
                    `tag-id` = Logger.ID) |>
      dplyr::select('sensor-type', 'tag-id', timestamp,
                    'dive-duration', 'depth',
                    'barometric-pressure', 'external-temperature',
                    comments) |>
      dplyr::arrange(`tag-id`, timestamp)

    # Collapse rows with identical timestamps

    tdr <- tdr |>
      dplyr::group_by(`sensor-type`, `tag-id`, timestamp) |>
      dplyr::summarise(across(everything(), ~ dplyr::first(na.omit(.))), .groups = "drop")

    print(paste("TDR data identified for", length(unique(tdr$`tag-id`)), "tag(s)."))

    ## Get missing value warnings for dive-duration and depth in Movebank
    ## Could remove the Div.Up records (as below) to resolve, lose temp and atmospheric pressure logged at Div.Up
    tdr <- dplyr::filter(tdr, comments == "hydrostatic pressure") |>
      dplyr::select(-comments)

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
