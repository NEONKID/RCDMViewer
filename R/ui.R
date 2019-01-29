library(shinythemes)
library(shinyWidgets)
library(shinyBS)
library(shinycssloaders)
library(plotly)

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
    responsive = TRUE
))