# Radiology_Image tab
no_help <- "Use this control bar to provide each image. However, 3D images that have been DERIVED may not be displayed by packages provided by R."
cohort_help <- "Select Cohort ID in ATLAS."
modality_help <- "Select Modality for the patient."
phase_help <- "Select Pre, Post, DERIVED for the patient."
occurrence_help <- "Select Occurrence ID..."

# Orthograhic View options
o_help <- "Orthographic settings"

RADImageTab <- sidebarLayout(
    sidebarPanel(
        h3('Radiology Image Viewer'),
        p('This viewer supports viewers for the Radiology Image table.'),
        p('You can see each image by selecting the desired Occurrence ID and slowly moving the Image No bar.'),
        p('Please enter the Prefix Path before proceeding to the image.'),
        br(),
        uiOutput(outputId = "no"),
        helpText(no_help),
        uiOutput(outputId = "RADI_cohort"),
        helpText(cohort_help),
        uiOutput(outputId = "modality"),
        helpText(modality_help),
        uiOutput(outputId = "phase"),
        helpText(phase_help),
        uiOutput(outputId = "RADI_occurrence_id"),
        helpText(occurrence_help)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
        h3('Radiology Image View'),
        plotOutput('viewer'),
        
        h3('Radiology OMOP CDM (Image)'),
        tableOutput(outputId = 'RADImage')
    )
)

RADOcurrenceTab <- fluidRow(
    column(width = 3,
           wellPanel(
               h3('Radiology Occurrence Viewer'),
               p('This viewer supports viewers for the Radiology Occurrence table.'),
               p('You can analyze the image by selecting the desired Occurrence ID and tapping the tabs corresponding to X, Y, Z.'),
               p(strong('Notice'),': This viewer must work with all DICOM images with the corresponding Occurrence ID.'),
               p('Please enter the Prefix Path before proceeding to the image.'),
               br(),
        
               uiOutput(outputId = "RADO_cohort"),
               helpText(cohort_help),
               uiOutput(outputId = "RADO_occurrence_id"),
               sliderInput('slider_x', 'X orientation (Sagittal)', min = 1, max = 10, value = 5),
               sliderInput('slider_y', 'Y orientation (Coronal)', min = 1, max = 10, value = 5),
               sliderInput('slider_z', 'Z orientation (Axial)', min = 1, max = 10, value = 5),
               helpText(o_help),
               
               splitLayout(
                   switchInput('crosshair_stat', value = FALSE, size = 'mini', label = 'CH'),
                   switchInput('orientation_stat', value = FALSE, size = 'mini', label = 'OR'),
                   switchInput('contrast_stat', value = FALSE, size = 'mini', label = 'BR')
               )
           )
    ),
    column(width = 6,
           h3('Radiology Occurrence View'),
           tabsetPanel(type = "tabs", 
                       tabPanel("Axial", plotOutput("Axial", height = "450px", brush = "plot_brush")), 
                       tabPanel("Sagittal", plotOutput("Sagittal", height = "450px", brush = "plot_brush")), 
                       tabPanel("Coronal", plotOutput("Coronal", height = "450px", brush = "plot_brush"))
           ),
           h3('Radiology OMOP CDM (Occurrence)'),
           tableOutput(outputId = 'RADOccurrence')
    ),
    column(width = 3,
           h3('Orthographic View'),
           tabsetPanel(type = "tabs",
                       tabPanel("All view", plotOutput(outputId = "orthographic") %>% withSpinner(color = "#1E88E5", type = 8))
           ),
           plotlyOutput(outputId = "densityPlot") %>% withSpinner(color = "#1E88E5", type = 8)
    )
)
