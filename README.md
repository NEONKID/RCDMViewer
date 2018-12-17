# RCDMViewer

This application is an example application of Radiology CDM.



## Overview

If the original radiological image was a DICOM Viewer, this viewer is a viewer based on the Radiology CDM. The role of seeing radiological images is the same, but based on the OMOP CDM, rather than collecting a lot of metadata in DICOM, we developed only reference to common data of radiological images.

See this link for more information on [RCDM](https://github.com/OHDSI/Radiology-CDM)



## How to use

This application must ETL the current user's radiology image in RCDM format, and this viewer will not work when reading normal radiation image.

Be sure to use RadETL module to convert the radiology image to CDM.

This application is not a package. You can not install it by using the package install command. Be sure to clone it.

```
git clone https://github.com/NEONKID/RCDMViewer.git
```

If Clone is finished, create RDBMS connection information with RCDM in the configuration file named RCDMViewer.cfg. ***If you do not create this file, you will not be able to use the application.***

