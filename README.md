## Welcome to seamoveR!

This package is designed to facilitate and standardize the archiving Environment and Climate Change Canada (ECCC) waterbird tracking data on [Movebank](https://www.movebank.org/cms/movebank-main#).

It includes:

+ An ECCC Movebank Manual
+ An ECCC Movebank Attribute Dictionary 
+ A Reference Data Template
+ Functions for reformatting tracking data from common tag types

These resources currently support studies with GPS, GSM, and satellite tracking technology data types (but see 'Future Scope').

Following these guidelines will improve data discoverability, useability, and security. This package was developed by and for the Biodiversity Research Division (formerly Wildlife Research Division) under the Integrated Marine Response Planning initiative of the Oceans Protection Plan. We encourage Canadian Wildlife Service researchers to consider adopting this approach as well.

In addition to supporting ECCC Open Data initiatives and serving as a secure back-up of data collected by ECCC, Movebank allows different levels of data access for the public, collaborators, and data managers – a feature that can be used to grant other ECCC researchers download access to the most current version of your dataset through the ‘move’ R package. Multi-colony and multi-species analyses are becoming more common and are important for understanding seabird habitat use and vulnerability to threats at regional and national scales, as well as for identifying knowledge gaps. Standardization of data fields and units significantly improves dataset usability and efficiency, enabling such multi-study, large-scale analyses.

Finally, Movebank includes a free, formal archiving service. They will work with you to publish only the data that you used in your analysis, carefully curating it and providing you with a doi to cite in your peer-reviewed publication. This ensures reproducible research and allows your original Movebank study to continue to evolve over time.

You can install the most recent version of this package from GitHub with:

```r
install.packages("devtools")
devtools::install_github("krstudholme/seamoveR")
```
## Resource materials

The **ECCC Movebank Manual** includes step-by-step instructions (with bookmarks) for project creation and maintenance for GPS, GSM, and satellite tracking technology studies. It can be viewed with the following code:

```r
seamoveR::open_manual_gps()
```

The **ECCC Movebank Attribute Dictionary** is organized by data type (with bookmarks) and details required and optional fields for GPS, GSM, and satellite tracking technology studies. This document ensures that field names and units are standardized and compliant Movebank database requirements. It can be viewed with the following code:

```r
seamoveR::open_attribute_dictionary_gps()
```

The **Reference Data Template** (Excel) supports the creation of a Movebank-compliant reference data file. It includes color-coded fields to indicate whether columns are required or optional and a README tab with instructions for use. It can be downloaded to a location of your choice with the following code:

```r
copy_metadata_template_gps("Your/file/path")
```

## Formatting functions

This package contains several functions to simplify converting tag-derived event-level tracking data (positions, accessory data) into a format that is Movebank compliant. Functions are currently available to process Pathtrack, Ecotone, and TechnoSmart GPS archival and base station data. 

## Future scope 

Additional GPS and GLS data formatting functions are under development and will be included in future package updates.

Planned updates also include a function or R Markdown template that will support the user in creating a standardized Movebank study README file. This resulting file will include a basic summary of the study, including seasonal data coverage plots and maps. There will be a section where the user can indicate whether the project is up to date and highlight any details that future data managers or analysts should know (e.g. data filtering steps taken, known issues with tags in a particular year).

## Share your feedback

If you experience any issues with these the content of this package, or have suggestions for new functions or features, please contact [Katie Studholme](mailto:katharine.studholme@ec.gc.ca), [WRD Tracking East](drf.suivi.est-wrd.tracking.east@ec.gc.ca), and [WRD Tracking West](drf.suivi.ouest-wrd.tracking.west@ec.gc.ca) to ensure your feedback is received.


