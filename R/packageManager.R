# rocker container default repo is mran.microsoft.com
options(repos=structure(c(CRAN="http://cloud.r-project.org/")))

check.packages <- function(pkg) {
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if(length(new.pkg))
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}

req_pkg <- c('xml2', 'openssl', 'httr', 'binman', 'devtools',                       # Basic required packages
              'oro.dicom', 'oro.nifti', 'neurobase', 'shinythemes',                 # Server required packages
              'shinyWidgets', 'shinyBS', 'shinycssloaders', 'plotly', 'jsonlite')   # UI required packages
check.packages(req_pkg)

if(!require('RadETL'))
    devtools::install_github('OHDSI/Radiology-CDM')