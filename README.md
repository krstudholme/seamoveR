The 'seamoveR' package is designed to facilitate archiving and maintaining ECCC waterbird tracking data on Movebank. 

You can install the most recent version of this package from [GitHub](https://github.com/) with:

```{r}
install.packages("devtools")
devtools::install_github("krstudholme/seamoveR")
```

An ECCC Movebank Manual including step-by-step instructions for project creation and maintenance for GPS, GSM, and satellite tracking technology studies can be viewed with the following code.

```{r}
seamoveR::open_manual_gps()
```

An ECCC Movebank Attribute Dictionary detailing required and optional fields for GPS, GSM, and satellite tracking technology studies can be viewed with the following code. This document ensures that field names and units are standardized and compliant Movebank database requirements.

```{r}
seamoveR::open_attribute_dictionary_gps()
```

A reference data (metadata) Excel template to support the creation of a Movebank-compliant reference data file can downloaded with the following code. This file includes fields color-coded to indicate required or optional status and a README tab with instructions for use.

```{r}
copy_metadata_template_gps("Your/file/path")
```

Importantly, this package contains several functions to simplify the reformatting of tag-derived event-level tracking data (positions, accessory data) into a format that is Movebank compliant. Functions are currently available to process Pathtrack, Ecotone, and TechnoSmart GPS archival and base station data. We plan to add additional GPS and GLS data formatting functions in the near future. 

Future package updates will also include a function or R Markdown template that will support the user in creating a standardized Movebank study README file. This resulting file will include a basic summary of the study, including seasonal data coverage plots and maps. There will be a section where the user can indicate whether the project is up to date and highlight any details that future data managers or analysts should know (e.g. data filtering steps taken, known issues with tags in a particular year).

If you experience any issues with these the content of this package, or have suggestions for new functions or features, please contact [Katie Studholme](mailto:katharine.studholme@ec.gc.ca), [WRD Tracking East](drf.suivi.est-wrd.tracking.east@ec.gc.ca), and [WRD Tracking West](drf.suivi.ouest-wrd.tracking.west@ec.gc.ca) to ensure your feedback is received.
