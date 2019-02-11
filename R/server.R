im_pkg <- c('oro.dicom', 'oro.nifti', 'neurobase', 'RadETL')
lapply(im_pkg, library, character.only = TRUE)

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
databaseSchema <- cfgReadFile(viewerConfig, 'database')
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
    getPrefix = eventReactive(input$cfPf, {
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
            need(getPrefix() != "", "Please input Prefix path")
            need(input$RADO_occurrence_id != "", "Please check CDM connection information..")
        })
        withProgress(message = 'Image loading...', value = 100, {
            shinyjs::disable(id = "RADO_occurrence_id")
            dc <- tryCatch({
                readDICOM(path = paste0(getPrefix(), getRadiologyOccurrence()$RADIOLOGY_DIRPATH), verbose = debug)
            }, error = function(e) { 
                e
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

        updateSliderInput(session, 'slider_x', value = as.integer(d[1] / 2), max = d[1])
        updateSliderInput(session, 'slider_y', value = as.integer(d[2] / 2), max = d[2])
        updateSliderInput(session, 'slider_z', value = as.integer(d[3] / 2), max = d[3])
        
        # Ortho2 options,,
        updateSwitchInput(session, 'crosshair_stat', value = FALSE)
        updateSwitchInput(session, 'orientation_stat', value = FALSE)
        updateSwitchInput(session, 'contrast_stat', value = FALSE)
    })
    
    output$RADO_occurrence_id <- renderUI({
        pickerInput(inputId = "RADO_occurrence_id", label = "Choose Occurrence ID", choices = occurrence$RADIOLOGY_OCCURRENCE_ID, selected = NULL,
                    options = list(
                        'live-search' = TRUE,
                        'actions-box' = TRUE,
                        style = 'btn-primary'))
    })
    
    output$Axial <- renderPlot({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Axial image...', value = 100, {
            # try(image(niftiVolume(), z = input$slider_z, plane = "axial", plot.type = "single", col = gray(0:64 / 64)))
            try(image(niftiVolume(), z = input$slider_z, plane = "axial", plot.type = "single"))
        })
    })
    
    output$Sagittal <- renderPlot({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Sagittal image...', value = 100, {
            try(image(niftiVolume(), z = input$slider_x, plane = "sagittal", plot.type = "single"))
        })
    })
    
    output$Coronal <- renderPlot({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        withProgress(message = 'loading Coronal image...', value = 100, {
            try(image(niftiVolume(), z = input$slider_y, plane = "coronal", plot.type = "single"))
        })
    })
    
    output$RADOccurrence <- renderTable({
        validate({
            need(input$RADO_occurrence_id != "", "Please check CDM connection information..")
        })
        name <- c("PERSON_ID", "IMAGE_TOTAL_COUNT", "RADIOLOGY_PROTOCOL_CONCEPT_ID", "DOSAGE_VALUE_AS_NUMBER", "RADIOLOGY_DIRPATH")
        df <- t(data.frame(sapply(X = name, extractColumns, hdrs = getRadiologyOccurrence(), simplify = FALSE, USE.NAMES = FALSE)))
        row.names(df) <- NULL
        colnames(df) <- 'value'
        cbind(name, df)
    }, bordered = TRUE, hover = TRUE, na = "Unknown")
    
    output$orthographic <- renderPlot({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        withProgress(message = 'loading orthographic image...', value = 100, {
            nif <- niftiVolume()
            if(input$contrast_stat) {
                try(ortho2(nif, 
                           col.crosshairs = "green",
                           xyz = c(input$slider_x, input$slider_y, input$slider_z),
                           crosshairs = input$crosshair_stat,
                           y = nif > quantile(nif, 0.8),
                           oma = rep(0, 4),
                           mar = rep(0.5, 4),
                           add.orient = input$orientation_stat))
            } else {
                try(ortho2(nif, 
                           col.crosshairs = "green",
                           xyz = c(input$slider_x, input$slider_y, input$slider_z),
                           crosshairs = input$crosshair_stat,
                           oma = rep(0, 4),
                           mar = rep(0.5, 4),
                           add.orient = input$orientation_stat))
            }
        })
    })
    
    output$densityPlot <- renderPlotly({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        try(val_den <- density(niftiVolume()))
        plot_ly(x = ~val_den$x, y = ~val_den$y, type = 'scatter', mode = 'lines', fill = 'tozeroy', 
                fillcolor = 'rgba(30, 136, 229, 0.5)', line = list(simplyfy = FALSE, width = 1.0)) %>%
            layout(xaxis = list(title = paste0('N = ', val_den$n, ', Bandwidth = ', val_den$bw), zeroline = FALSE),
                   yaxis = list(title = 'Density', zeroline = FALSE)) %>%
            animation_opts(frame = 100, transition = 0, redraw = TRUE) %>%
            animation_slider(hide = TRUE)
    })
    
    #
    # Radiology_Image component
    # 
    getRadiologyImage = reactive({
        image[image$RADIOLOGY_OCCURRENCE_ID == input$RADI_occurrence_id
              & image$RADIOLOGY_PHASE_CONCEPT == input$phase,]
    })
    
    loadImg = reactive({
        validate({
            need(getPrefix() != "", "Please input Prefix path")
        })
        dc <- tryCatch({
            readDICOM(path = paste0(getPrefix(), getRadiologyImage()$IMAGE_FILEPATH[input$no]))
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
            need(getPrefix() != "", "Please input Prefix path")
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
        pickerInput(inputId = 'RADI_occurrence_id', label = 'Choose Occurrence ID', choices = RadImageList, selected = NULL, 
                    options = list(
                        'live-search' = TRUE,
                        'actions-box' = TRUE,
                        style = 'btn-primary'))
    })
    
    output$modality <- renderUI({
        pickerInput(inputId = 'modality', label = 'Choose Modality', choices = modalityList(), selected = NULL,
                    options = list(style = 'btn-primary'))
    })
    
    output$phase <- renderUI({
        pickerInput(inputId = "phase", label = "Choose Phase ID", choices = phaseList(), selected = NULL,
                    options = list(style = 'btn-primary'))
    })
}
