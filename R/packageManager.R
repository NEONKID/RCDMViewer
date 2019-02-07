# rocker container default repo is mran.microsoft.com
options(repos=structure(c(CRAN="http://cloud.r-project.org/")))

check.packages <- function(pkg) {
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if(length(new.pkg))
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}

need_pkg <- c('units', 'xml2', 'openssl', 'httr', 'binman', 
              'devtools', 'oro.dicom', 'oro.nifti', 'neurobase', 'shinythemes', 
              'shinyWidgets', 'shinyBS', 'shinycssloaders', 'plotly')
check.packages(need_pkg)

if(!require('RadETL'))
    devtools::install_github('OHDSI/Radiology-CDM')