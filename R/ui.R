im_pkg <- c('shinythemes', 'shinyWidgets', 'shinyBS', 'shinycssloaders', 'plotly')
lapply(im_pkg, library, character.only = TRUE)

source('tabs.R')

shinyUI(fluidPage(theme = shinytheme("cerulean"),
    includeCSS("custom/styles.css"),
    chooseSliderSkin(skin = "Round"),
    navbarPage(title = 'RCDMViewer', windowTitle = 'RCDMViewer',
        tabPanel('Image', RADImageTab, icon = icon('image', lib = 'font-awesome')),
        tabPanel('Occurrence', RADOcurrenceTab, icon = icon('user', lib = 'glyphicon')),
        navbarMenu(span('Help', title = "What's the problem ?"), icon = icon('meh', lib = 'font-awesome'),
            tabPanel('How to use', includeMarkdown('howtouse.md')),
            "----",
            tabPanel('About', includeMarkdown('about.md'))
        )
    ),
    fixedPanel(
        dropdown(
            br(),
            textInput(inputId = "prefix", label = "Prefix Path", placeholder = "Example: F:\\Radiology"),
            actionBttn(inputId = 'cfPf', label = 'Confirm', style = 'unite', color = 'primary', size = 'sm'),
            
            br(),
            status = 'primary',
            icon = icon('folder'),
            style = "material-circle",
            up = TRUE,
            animate = animateOptions(
                enter = animations$attention_seekers$pulse,
                exit = animations$zooming_exits$zoomOutDown,
                duration = .5
            )
        ),
        bottom = 5
    )
))