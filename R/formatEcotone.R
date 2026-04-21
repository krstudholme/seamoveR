#' Prepare Ecotone GPS-UHF(+TDR) data for import into Movebank
#'
#' @param data.dir Filepath to the directory containing all Ecotone data to be
#'  re-formatted. Data must be in .csv format, the direct (unaltered) result of
#'  processing raw base station .txt files using the NGAnalyser program. The
#'  function supports either a single export file containing all tag IDs, or one
#'  file per tag (both options within NGAnalyzer). Other user-generated files
#'  should not be placed in this folder.
#' @param out.dir Filepath to the directory in which to save .csv files of the
#'  Movebank-formatted position data, and TDR data if applicable.
#' @param spcd Four-letter species code to use when generating the .csv filename
#'  for the Movebank-formatted position data, and TDR data if applicable.
#' @param site Colony name/abbreviation (no spaces) to use when generating the
#'  .csv filename for the Movebank-formatted position data, and TDR data if applicable.
#' @param deployLon Longitude of the deployment location, used to replace NA,NA
#'  locations if the tag is programmed to stop collecting GPS fixes when in range of
#'  the base station. Required if this setting was used.
#' @param deployLat Longitude of the deployment location, used to replace NA,NA
#'  locations if the tag is programmed to stop collecting GPS fixes when in range of
#'  the base station. Required if this setting was used.
#'
#' @details This function is intended to compile and format Ecotone GPS-UHF tracking
#'  data from multiple birds tracked from a single site. It processes the raw data
#'  files (.csv file(s) produced from an Ecotone base station file (.txt) using the
#'  NGAnalyzer program) into a single file for positional data and a single file for
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
#'  spcd, and site are specified, the function will save Movebank-formatted csv file(s) to
#'  the location specified.
#' @export
#' @importFrom utils read.csv read.table write.csv
#' @importFrom dplyr across where everything
formatEcotoneGPS <- function(data.dir, out.dir = NULL, spcd = NULL, site = NULL, deployLon = NULL, deployLat = NULL) {

  ## Format positional data ##

  # Import and merge all '.csv' files, keep distinct, blanks to NA

  files <- list.files(path = data.dir, pattern = "*.csv", recursive = T)

  dat <- do.call(rbind, lapply(paste0(data.dir, "/", files), read.csv, sep = ";")) |>
    dplyr::distinct() |>
    dplyr::mutate(across(where(is.character), ~ dplyr::na_if(., "")))

  print(paste('Loaded', length(files), 'data file(s) from', length(unique(dat$Logger.ID)), "tag(s)."))

  # If tag In.range has values and deployLon or deployLat were not provided (NULL), stop

  if (!all(is.na(dat$In.range)) & (is.null(deployLon) | is.null(deployLat))) {
    stop("Error: Must provide deployLon and deployLat when tag is programmed to turn off in range of the base station.")
  }

  # Make positional dataset (no dive data)

  pos <- dat |>
    dplyr::filter(!is.na(Longitude) | !is.na(In.range) | !is.na(No.GPS...timeout) | !is.na(No.GPS...diving))

  # Handle NA,NA locations
  # If 'in-range' column has value, replace NA,NA location with deploy location
  # Change remaining NA,NA positions to 0,0 and label ‘import-marked-outlier’ == TRUE.
  # Use the 'comments' field to say what you did.

  pos <- pos |>
    dplyr::mutate(`import-marked-outlier` = ifelse(is.na(Longitude) & is.na(In.range), TRUE, FALSE),
                  `comments` = ifelse(!is.na(No.GPS...timeout), "No GPS, timeout",
                                             ifelse(!is.na(No.GPS...diving), "No GPS, diving",
                                                    ifelse(!is.na(In.range), "In range of base station; changed NA,NA to deployment coordinates", NA))),
                  Longitude = ifelse(!is.na(Longitude), Longitude,
                                     ifelse(!is.na(In.range), deployLon, 0)),
                  Latitude = ifelse(!is.na(Latitude), Latitude,
                                    ifelse(!is.na(In.range), deployLat, 0)))

  # Rename columns and format for Movebank
  # Filter duplicates, sort
  # Didn't keep Additive.Vincentys.Distance.Km., Travel.Speed.Km.h.
  # Experimenting with keeping Temperature and PA
  # (Temperature only occurs with coordinates, unlike Temp_sens, PA is Atmospheric and occurs with all lat/lon)

  pos <- pos |>
    dplyr::mutate(`sensor-type` = "GPS",
                  timestamp = paste(paste(Year, sprintf("%02d", Month), sprintf("%02d", Day), sep = "-"), paste(sprintf("%02d", Hour), sprintf("%02d", Minute), sprintf("%02d", Second), sep = ":")),
                  `gps-fix-type-raw` = ifelse(!is.na(No.GPS...timeout) | !is.na(No.GPS...diving) | !is.na(In.range), "1D", #1D = no fix
                                          ifelse(!is.na(Altitude), "3D", "2D")),
                  `gps:satellite-count` = ifelse(!is.na(No.GPS...timeout), 0, Sat..Count),
                  `gps-time-to-fix` = Searching.time,
                  `ground-speed` = Speed/1.94384001, # m/s, Ecotone uses kts
                  `location-lat` = Latitude,
                  `location-long` = Longitude,
                  `tag-voltage` = Voltage*1000, # mV not volts
                  `tag-id` = Logger.ID,
                  `external-temperature` = Temperature,
                  `barometric-pressure` = PA) |>
    dplyr::select('sensor-type', 'tag-id',
                  timestamp, 'location-long', 'location-lat',
                  'gps-fix-type-raw', 'gps:satellite-count', 'gps-time-to-fix',
                  'ground-speed', 'tag-voltage',
                  'external-temperature', 'barometric-pressure',
                  'import-marked-outlier', 'comments') |>
    dplyr::arrange(`tag-id`, timestamp) |>
    dplyr::distinct()

  # Save .csv if required info is provided

  if(!is.null(out.dir) & !is.null(spcd) & !is.null(site)) {

    write.csv(pos, paste0(out.dir, "/posData_", spcd, "_GPS_", site, ".csv"), row.names = F, na = '')

  }


  ## Format TDR data if present ##

  # Occurs within same original file as the pos data

  if(!all(is.na(dat$Depth)) | !all(is.na(dat$Div.down))){

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

    return(out_list)

  } else {

    return(pos)

  }

}
