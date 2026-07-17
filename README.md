The 'seamoveR' package is designed to facilitate archiving and maintaining ECCC waterbird tracking data on Movebank. 

You can install the most recent version of this package from [GitHub](https://github.com/) with:

```{r}
install.packages("devtools")
devtools::install_github("krstudholme/seamoveR")
```

An ECCC Movebank Manual including step-by-step instructions for project creation and maintenance covering GPS, GSM, and satellite tracking technology can be viewed with:

```{r}
seamoveR::open_manual_gps()
```

An ECCC Movebank Attribute Dictionary to ensure standardization of column names and units can be viewed with:

```{r}
seamoveR::open_attribute_dictionary_gps()
```

An excel template to support the creation of a Movebank-compliant (field names, units) reference data file can downloaded using:

```{r}
copy_metadata_template_gps("Your/file/path")
```

Importantly, this package contains several functions to simplify the reformatting of tag-derived event-level tracking data (positions, accessory data) into a format that is Movebank compliant. Functions currently exist for Pathtrack, Ecotone, and TechnoSmart GPS archival and base station data. We plan to add additional GPS and GLS data formatting functions in the near future. 

Future package updates will also include a function or R markdown template to assist the user in generating a standardized project README file that summarizes the project, including seasonal data coverage information and maps, indicates whether the project is up to date, and highlights any details that future data managers or analysts should know.
