# RCDMViewer

This application is an example application of Radiology CDM.



## Overview

If the original radiological image was a DICOM Viewer, this viewer is a viewer based on the Radiology CDM. The role of seeing radiological images is the same, but based on the OMOP CDM, rather than collecting a lot of metadata in DICOM, we developed only reference to common data of radiological images.

See this link for more information on [RCDM](https://github.com/OHDSI/Radiology-CDM)



## Preview (image)

![Radiology_Image](images/preview-image.gif)



## Preview (Occurrence)

![Radiology_Occurrence](images/preview-occurrence.gif)



## How to install

This application must ETL the current user's radiology image in RCDM format, and this viewer will not work when reading normal radiation image.

Be sure to use RadETL module to convert the radiology image to CDM.

This application is not a package. You can not install it by using the package install command. Be sure to clone it.

```
git clone https://github.com/NEONKID/RCDMViewer.git
```

If Clone is finished, create RDBMS connection information with RCDM in the configuration file named RCDMViewer.cfg. ***If you do not create this file, you will not be able to use the application.***



### Using Docker

The repository contains a Dockerfile with version 3.4.4. RCDMViewer is more than R version 3.4.4, so if you want to use another version, you can modify Dockerfile.

```bash
docker build --tag rcdmviewer:latest .
```

By default, the Shiny server uses port 3838. If you want to distribute it to the outside world, use the following command.

```bash
docker run --name rcdmviewer -d -p 3838:3838 rcdmviewer:latest
```



