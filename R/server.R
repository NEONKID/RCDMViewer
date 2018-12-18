library('RadETL')
library('oro.dicom')
library('oro.nifti')

options(niftiAuditTrail = TRUE)

cfgReadFile <- function(file, pattern) {
    gsub(paste0(pattern, "="),
         "",
         grep(paste0("^", pattern, "="), scan(file, what="", quiet = TRUE, sep = "\n"), value = TRUE))
}

viewerConfig <- '../RCDMviewer.cfg'

db <- DBMSIO$new(
    server = cfgReadFile(viewerConfig, 'address'),
    user = cfgReadFile(viewerConfig, 'user'),
    pw = cfgReadFile(viewerConfig, 'password'),
    dbms = cfgReadFile(viewerConfig, 'dbms')
)

duration <- as.integer(cfgReadFile(viewerConfig, 'duration'))
debug <- as.logical(cfgReadFile(viewerConfig, 'debugMode'))

# If success connection, input tableName, databaseName,,
databaseSchema <- 'Radiology_CDM_QUER.dbo'
tbSchema_Image <- 'Radiology_Image'
tbSchema_Occurrence <- 'Radiology_Occurrence'

# RCDM Occurrence
occurrence <- db$dbGetdtS(dbS = databaseSchema, tbS = tbSchema_Occurrence)

# RCDM Image
image <- db$dbGetdtS(dbS = databaseSchema, tbS = tbSchema_Image)
RadImageList <- unique(image$RADIOLOGY_OCCURRENCE_ID)

db$finalize()

extractColumns <- function(hdrs, string, idx) {
    hdrs[[string]][idx]
}

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    # Common component
    choosePrefix = reactive({
        input$prefix
    })
    
    #
    # Radiology_Occurrence component
    # 
    getRadiologyOccurrence = reactive({
        occurrence[occurrence$RADIOLOGY_OCCURRENCE_ID == input$RADO_occurrence_id,]
    })
    
    loadOcur <- reactive({
        validate({
            need(input$prefix != "", "Please input Prefix path")
            need(input$RADO_occurrence_id != "", "Please check CDM connection information..")
        })
        withProgress(message = 'Image loading...', value = 100, {
            dc <- tryCatch({
                showModal(modalDialog(
                    title = sprintf("Occurrence ID: %s Reading", input$RADO_occurrence_id), 
                    sprintf("Reading the %d images Please wait", getRadiologyOccurrence()$IMAGE_TOTAL_COUNT), easyClose = FALSE, footer = NULL))
                readDICOM(path = paste0(choosePrefix(), getRadiologyOccurrence()$RADIOLOGY_DIRPATH), verbose = debug)
            }, error = function(e) { 
                e 
                removeModal(session)
            })
        })
        if(inherits(dc, "simpleError")) showNotification(ui = dc$message, type = "error", duration = duration)
        else dc
    })
    
    niftiVolume <- reactive({
        withProgress(message = 'Convert dicom to nifti...', value = 100, {
            nif <- tryCatch({
                dicom2nifti(loadOcur(), datatype = 4)
            }, error = function(e) { e })
        })
        if(inherits(nif, "simpleError")) showNotification(ui = nif$message, type = "error", duration = duration)
        else nif
    })
    
    observe({
        volume <- niftiVolume()
        d <- dim(volume)
        
        # Control the value, min, max, and step.
        # Step size is 2 when input value is even; 1 when value is odd.
        updateSliderInput(session, 'slider_x', value = as.integer(d[1] / 2), max = d[1])
        updateSliderInput(session, 'slider_y', value = as.integer(d[2] / 2), max = d[2])
        updateSliderInput(session, 'slider_z', value = as.integer(d[3] / 2), max = d[3])
    })
    
    output$RADO_occurrence_id <- renderUI({
        selectInput(inputId = "RADO_occurrence_id", label = "Choose Occurrence ID", choices = occurrence$RADIOLOGY_OCCURRENCE_ID, selected = NULL)
    })
    
    output$Axial <- renderPlot({
        validate({
            need(input$prefix != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Axial image...', value = 100, {
            try(image(niftiVolume(), z = input$slider_z, plane = "axial", plot.type = "single", col = gray(0:64 / 64)))
        })
        removeModal(session)
    })
    
    output$Sagittal <- renderPlot({
        validate({
            need(input$prefix != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Sagittal image...', value = 100, {
            try(image(niftiVolume(), z = input$slider_x, plane = "sagittal", plot.type = "single", col = gray(0:64 / 64)))
        })
        removeModal(session)
    })
    
    output$Coronal <- renderPlot({
        validate({
            need(input$prefix != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Coronal image...', value = 100, {
            try(image(niftiVolume(), z = input$slider_y, plane = "coronal", plot.type = "single", col = gray(0:64 / 64)))
        })
        removeModal(session)
    })
    
    output$RADOccurrence <- renderTable({
        validate({
            need(input$RADO_occurrence_id != "", "Please check CDM connection information..")
        })
        tags <- c("PERSON_ID", "IMAGE_TOTAL_COUNT", "RADIOLOGY_PROTOCOL_CONCEPT_ID", "DOSAGE_VALUE_AS_NUMBER", "RADIOLOGY_DIRPATH")
        t(data.frame(sapply(X = tags, extractColumns, hdrs = getRadiologyOccurrence())))
    }, bordered = TRUE, hover = TRUE, na = "Unknown")
    
    #
    # Radiology_Image component
    # 
    getRadiologyImage = reactive({
        image[image$RADIOLOGY_OCCURRENCE_ID == input$RADI_occurrence_id
              & image$RADIOLOGY_PHASE_CONCEPT == input$phase,]
    })
    
    loadImg = reactive({
        validate({
            need(input$prefix != "", "Please input Prefix path")
        })
        dc <- tryCatch({
            readDICOM(path = paste0(choosePrefix(), getRadiologyImage()$IMAGE_FILEPATH[input$no]))
        }, error = function(e) { e })
        if(inherits(dc, "simpleError")) showNotification(ui = dc$message, type = "error", duration = duration)
        else dc
    })
    
    imageCount = reactive({
        nrow(x = getRadiologyImage())
    })
    
    phaseList = reactive({
        rev(unique(image$RADIOLOGY_PHASE_CONCEPT[image$RADIOLOGY_OCCURRENCE_ID == input$RADI_occurrence_id]))
    })
    
    modalityList = reactive({
        unique(occurrence$RADIOLOGY_MODALITY_CONCEPT_ID[occurrence$RADIOLOGY_OCCURRENCE_ID == input$RADI_occurrence_id])
    })
    
    output$no <- renderUI({
        validate({
            need(input$RADI_occurrence_id != "", "Please choose occurrence id")
        })
        sliderInput(inputId = "no", label = "Image No", min = 1, max = imageCount(), step = 1, value = 1)
    })
    
    output$viewer <- renderPlot({
        validate({
            need(input$prefix != "", "Please input Prefix path")
        })
        nif <- tryCatch({
            dicom2nifti(loadImg())
        }, error = function(e) { e })
        if(inherits(nif, "simpleError")) showNotification(ui = nif$message, type = "error", duration = duration)
        else try(image(x = nif))
    })
    
    output$RADImage <- renderTable({
        validate({
            need(input$RADI_occurrence_id != "", "Please check CDM connection information..")
        })
        tags <- c("PERSON_ID", "IMAGE_NO", "IMAGE_RESOLUTION_ROWS", "IMAGE_RESOLUTION_COLUMNS", "IMAGE_SLICE_THICKNESS", "IMAGE_FILEPATH")
        t(data.frame(sapply(X = tags, extractColumns, hdrs = getRadiologyImage(), idx = input$no)))
    }, bordered = TRUE, hover = TRUE, na = "Unknown")
    
    output$RADI_occurrence_id <- renderUI({
        selectInput(inputId = "RADI_occurrence_id", label = "Choose Occurrence ID", choices = RadImageList, selected = NULL)
    })
    
    output$modality <- renderUI({
        selectInput(inputId = "modality", label = "Choose Modality", choices = modalityList(), selected = NULL)
    })
    
    output$phase <- renderUI({
        selectInput(inputId = "phase", label = "Choose Phase ID", choices = phaseList(), selected = NULL)
    })
}
