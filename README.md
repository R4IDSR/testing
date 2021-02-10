
<!-- README.md is generated from README.Rmd. Please edit that file -->

# covidmonitor

<!-- badges: start -->
<!-- badges: end -->

The goal of {covidmonitor} is to provide functions for simplifying data
merging and cleaning for WHO AFRO COVID-19 linelists and monitoring &
evaluation data. The package further contains templates for automating
report production.

## Installation

Currently the package is not on CRAN. Once it is - you can install the
released version of epichecks from [CRAN](https://CRAN.R-project.org)
with:

``` r
# install.packages("covidmonitor")
```

In order to install the package you will first need to install an extra
bit of software called
[Rtools](https://cran.r-project.org/bin/windows/Rtools/).  
You can download the installer from:
<https://cran.r-project.org/bin/windows/Rtools/>  
Please install the version highlighted in green.

Once this is installed and you have restarted your computer, the
development version of the package can be installed from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("R4IDSR/covidmonitor")
```

If you do not have a LaTeX editor installed on your computer, then
please run the following code to install TinyTex. This is needed in
order to be able to create Word and PDF documents using *R markdown*.

``` r
install.packages('tinytex')
tinytex::install_tinytex()
# to uninstall TinyTeX, run tinytex::uninstall_tinytex() 
```

## Country linelists

### Folder structure

Functions and templates are set up to run based on files contained in
the AFRO WHE HIM - Country LineList sharepoint folder. This folder
contains all the latest country linelist files which are automatically
sorted from files emailed to
[afrooutbreak@who.int](afrooutbreak@who.int) by countries, using a .net
script.

To ensure that the data pipeline works in an automated fashion, please
always email the country files to the email address specified. This way
the latest file can be efficiently identified.

### File naming and format

In order for the *R* functions to run, the files must be named
appropriately, with the start of the file name containing the three
letter ISO code for the country followed by a dot (.) and then the date
of report; after this the rest of the name can be anything. For example
a file submitted by Namibia on the 29th of January 2021 should have
“NAM.2021-01-29” at the beginning of the name, and so the full file name
could be “NAM.2021-01-29.Linelist.Namibia COVID-19 Confirmed.xlsx”.

All files must be stored as an excel file (i.e. **xlsx**), those stored
as binary workbooks (**xlsb**) will throw an error and must be re-saved
as **xlsx**.

**n.b** some countries (e.g. TCD) have saved their date variables in
excel using the 1904 date system (i.e. date origin is 1st January 1904
rather than 1900), this needs to be restructured manually in the excel
file otherwise the *R* function will produce dates that are off by four
years. See
[here](https://docs.microsoft.com/en-us/office/troubleshoot/excel/1900-and-1904-date-system)
for details.

### Dictionaries

In order for the functions to work, several data dictionaries are
required. The first is called
[linelist\_dictionary.xlsx](https://github.com/R4IDSR/covidmonitor/raw/master/inst/extdata/linelist_dictionary.xlsx)
and contains information for defining and naming variables, as well as
defining which sheet to read in from the various country linelists. The
second is called
[cleaning\_dictionary.xlsx](https://github.com/R4IDSR/covidmonitor/raw/master/inst/extdata/cleaning_dictionary.xlsx)
and contains information for cleaning and recoding variables. Details of
the required sheet names and contents are in the table below.

The functions use default to using dictionaries which are pre-defined
within the package, however you can also edit these dictionaries by
downloading them from GitHub (links provided above), and then specifying
the file path within the function call (see help files for function
argument details). **N.b** sheet and variable names should not be
changed (otherwise the function will break).

TODO: add details about how to structure dictionaries (table with diff
tabs defined) - create an excel file and put it in the extdata folder
(one sheet per dictionary)

**Table**: Required variables by sheet in the linelist dictionary.

**Table**: Required variables by sheet in the cleaning dictionary

### Templates

TODO: add details about how to use templates

## Monitoring & Evaluation

### Folder structure

TODO: add details about where data should be and how should be named etc

### Dictionaries

TODO: add details about how to structure dictionaries (table with diff
tabs and how to set up if not using defaults)

### Templates

TODO: add details about how to use templates
