#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#
# name: Pranav Gundrala
# date: 12/15/2024
# class: PHP1560

## IMPORTING LIBRARIES

library(shiny)
library(deSolve)
library(reshape2)
library(plotly)
library(tidyverse)
library(bslib)
library(bsicons)

#####################################################################

## INITIAL CALCULATIONS

# SETTING UP THE MODEL (Mwalili, 2020) USING deSolve

require(deSolve)
    
    COVID_SEIR <- function(time, current_state, params){
      
      with(as.list(c(current_state, params)),{
        N <- S+E+Ia+Is+R+P
        dS <- b - (beta1*S*P)/(1+alpha1*P) - (beta2*S*(Ia+Is))/(1+alpha2*(Ia+Is)) + psi*E - mu*S
        dE <- (beta1*S*P)/(1+alpha1*P) + (beta2*S*(Ia+Is))/(1+alpha2*(Ia+Is)) - psi*E - mu*E - omega*E
        dIa <- (1-delta)*omega*E - (mu+sigma)*Ia - gamma_a*Ia
        dIs <- delta*omega*E - (mu+sigma)*Is - gamma_s*Is
        dR <- gamma_s*Is + gamma_a*Ia - mu*R
        dP <- eta_a*Ia + eta_s*Is - mu_p*P
        
        return(list(c(dS, dE, dIa, dIs, dR, dP)))
      })
    }
    
# Calculating a DEFAULT plot based on published parameters from (Mwalili, 2020)
    
    # Set parameters
    params <- c(b = 0.00018, mu = (4.563*(10^(-5))), mu_p = 0.1724, alpha1 = 0.10, alpha2 = 0.10, 
                beta1 = 0.00414, beta2 = 0.0115, delta = 0.7, psi = 0.0051, omega = 0.09, sigma = 0.0018,
                gamma_s = 0.05, gamma_a = 0.0714, eta_s = 0.1, eta_a = 0.05)
    
    # Set initial state
    initial_state <- c(S=999999, E=1, Ia=0, Is=0, R=0, P=0)
    
    # Run for 150 days
    times <- 0:150
    
    # Using ode() from deSolve to solve diff eqs
    model <- ode(initial_state, times, COVID_SEIR, params)
    
    # Prepare data for animation in plotly
    data <- as.data.frame(model)

    framed_data <- list()
    
      for(i in 1:nrow(data)) {
        
        # This loops through the data and creates a cumulative "chunk" of
        # all the data up to that point for each "frame."
        # This allows plotly to create smooth, animated lines over time
      
        temp_df <- data[1:i, ]
        temp_df$frame <- i
        framed_data[[i]] <- temp_df
      
      }
    
    output_data <- bind_rows(framed_data)
    
    # Using plotly to generate a plot with one line for each SEIR
    
    p2 <- plot_ly(output_data, x = ~time, y = ~S, frame = ~frame, name = 'S', 
                  type = 'scatter', mode = 'lines') %>%
      add_trace(y = ~E, name = 'E') %>%
      add_trace(y = ~Ia, name = 'Ia') %>%
      add_trace(y = ~Is, name = 'Is') %>%
      add_trace(y = ~R, name = 'R') %>%
      layout(xaxis = list(title = "Time (Days)"),
             yaxis = list(title = "Population"))
    
    # Implementing interactive animation
    
    p2 <- p2 %>% animation_slider(currentvalue = list(prefix = "Day: ")) %>%
      animation_opts(frame = 500, transition = 0, redraw = FALSE)
    
    # Piped to toWebGL() to improve animation performance
    p2 <- p2 %>% toWebGL()
    
    
#####################################################################

## UI SECTION
ui <- fluidPage(
  
    theme = bs_theme(version = 5, bootswatch = "sandstone"),
    
    ## WEBSITE
    # define two pages for Results and then Background Info
    page_navbar(
      
      ## SIMULATION PAGE
      nav_panel("Simulation",
                
                ## SIDEBAR
                # create a sidebar that contains all of the UI inputs
                page_sidebar( 
                  sidebar = sidebar(style = "height: 90vh; overflow-y: auto;",
                    
                    # title with tooltip attached to give instructions
                    tooltip(span("INPUTS", bs_icon("info-circle")),
                    "Update the values below, 
                    then hit REPLOT to create a new simulation"),
                    
                    # central "replot" button to generate new plot based on inputs
                    actionButton("go", "REPLOT"),
                    
                    # example interventions with tooltip for more info
                    tooltip(checkboxGroupInput( 
                      "interventions", "INTERVENTIONS",
                      c( 
                        "Vaccination" = "vac",
                        "Social Distancing" = "sd", 
                        "Remote School/Work" = "rem" 
                      ) 
                    ),
                      "Example Interventions:",
                      "(1) Increases psi tenfold, and halves omega",
                      "(2) Halves alpha-2",
                      "(3) Halves alpha-1"),
                    
                    # equalized grid of many UI inputs
                    layout_column_wrap(
                      
                    # section for params relating to person-to-person contact
                    # (infection from Ia/Is)
                    card("PEOPLE (Ia/Is)", numericInput( 
                      "beta2", 
                      "Transmisison Rate (b2)",
                      value = 0.0115, min = 0, max = 1
                    ), numericInput( 
                      "alpha2", 
                      "Interaction Rate (1/a2)",
                      value = 1/0.10, min = 0
                    ), numericInput( 
                      "delta", 
                      "Proportion Symptomatic (delta)",
                      value = 0.7, min = 0, max = 1
                    )),
                    
                    # section for params relating to environmental contamination
                    # (infection from P compartment)
                    card("ENVIRONMENT (P)", numericInput( 
                      "beta1", 
                      "Transmisison Rate (b1)",
                      value = 0.00414, min = 0, max = 1
                    ), numericInput( 
                      "alpha1", 
                      "Interaction Rate (1/a1)",
                      value = 1/0.10, min = 0
                    ), numericInput( 
                      "mu_p", 
                      "Rate: Pathogen Death in Environment (mu_p)",
                      value = 0.1724, min = 0, max = 1
                    )),
                    
                    # section for params relating to dynamics of pathogen
                    # for SYMPTOMATIC individuals (Is)
                    card("SYMPTOMATIC (Is)",numericInput( 
                      "gamma_s", 
                      "Recovery Rate (gamma_s)",
                      value = 0.05, min = 0, max = 1
                    ), numericInput( 
                      "eta_s", 
                      "Rate: Spread to Environment (eta_s)",
                      value = 0.1, min = 0, max = 1
                    )),
                    
                    # section for params relating to dynamics of pathogen
                    # for ASYMPTOMATIC individuals (Ia)
                    card("ASYMPTOMATIC (Ia)", numericInput( 
                      "gamma_a", 
                      "Recovery Rate (gamma_a)",
                      value = 0.0714, min = 0, max = 1
                    ), numericInput( 
                      "eta_a", 
                      "Rate: Spread to Environment (eta_a)",
                      value = 0.05, min = 0, max = 1
                    )),
                    
                    # section for params relating to base population (S)
                    card("BIRTH/DEATH (+/-S)", numericInput( 
                      "b", 
                      "Birth Rate (b)",
                      value = 0.00018, min = 0, max = 1
                    ), numericInput( 
                      "mu", 
                      "Natural Death Rate (mu)",
                      value = (4.563*(10^(-5))), min = 0, max = 1
                    ), numericInput( 
                      "sigma", 
                      "COVID-19 Death Rate",
                      value = 0.0018, min = 0, max = 1
                    )),
                    
                    # section for params relating to transitions out of E
                    # to either Ia/Is or BACK to S
                    card("IMMUNE FACTORS (Transition to/from E)", numericInput( 
                      "psi", 
                      "Rate: Robust Immune Response (E back to S) (psi)",
                      value = 0.0051, min = 0, max = 1
                    ), numericInput( 
                      "omega", 
                      "Rate: Successful Infection (E to Ia/Is) (omega)",
                      value = 0.09, min = 0, max = 1
                    )))
                ),
                
                ## MAIN SECTION
                # create a space for outputs to appear
                card(
                    "OUPUTS (Please wait for graph to load)",
                    
                     # two tabs for original (default) plot, and new plot (replot)
                     navset_card_tab(id="display_charts",
                                     
                          nav_panel(title="DEFAULT", value="def", card(plotlyOutput("plot2"))),
                          nav_panel(title="REPLOT", value="replot", 
                                           card(plotlyOutput("plot1")))
                                 
                               )
                             ))
                ),
      
      ## BACKGROUND PAGE
      nav_panel("Understanding Your Results",
                
                    # Create various sections...
                    navset_card_tab(
                      # (1) Explains what each SEIR curve is
                      nav_panel("Navigating the Chart", 
                                img(src='seir_model_annotated.png', align = "right")),
                      
                      # (2) Shows a chart of the underlying model and diff eqs
                      nav_panel("Underlying Model", 
                                img(src='interaction_chart.png', align = "right")),
                      
                      # (3) Shows a table of each parameter and definitions
                      nav_panel("Parameter Definitions", 
                                img(src='parameters_table.png', align = "right")),
                      
                      # (4) Explains how to interpret the results you get from your own test
                      nav_panel("Interpreting the Curves", 
                                img(src='interpreting_results.png', align = "right")),
                      
                      # (5) Citations
                      nav_panel("Citations",
                                card("This simulation was created from a model described in paper 
                                     below from Mwalili et. al"),
                                card("Mwalili, Samuel et al. “SEIR model for COVID-19 dynamics 
                                     incorporating the environment and social distancing.” 
                                     BMC research notes vol. 13,1 352. 23 Jul. 2020, 
                                     doi:10.1186/s13104-020-05192-1"),
                                card("Pranav Gundrala | PHP1560")
                                )
                    )
                ),
      
      # Extra icon to switch from dark to light node
      nav_item(input_dark_mode(mode = "light")),
      
      ## WEBSITE ARGUMENTS
      title = "Enhanced SEIR Model for COVID-19", 
      id = "page"),

    )
    
#####################################################################

## SERVER SECTION
server <- function(input, output, session) {
  
    # Renders default plot from initial calculations
    output$plot2 <- renderPlotly(p2)
    
    # If replot button is clicked, go to the replot tab
    observeEvent(input$go, {
      updateTabsetPanel(session, "display_charts",
                        selected = "replot")
    })

    # Render the new calculated plot
    output$plot1 <- renderPlotly({
      
    # Set up a progress bar
    withProgress( min = 0, max = 164, {
      
          setProgress(1, "Setting parameters...")
    
    # Defines a few parameters b/c they are reciprocals
    a2 <- reactiveVal(1/input$alpha2)
    a1 <- reactiveVal(1/input$alpha1)
    psi <- reactiveVal(input$psi)
    omega <- reactiveVal(input$omega)
    
    # Checks for interventions and updates params accordingly
    if("sd" %in% input$interventions){ a2(a2()/2) }
    if("rem" %in% input$interventions){ a1(a1()/2) }
    if("vac" %in% input$interventions){ 
      psi(psi()*10)
      omega(omega()/2)
    }
    
          setProgress(2, "Setting parameters...")
    
    # Defines params based on inputs
    params <- c(b = input$b, 
                mu = input$mu, 
                mu_p = input$mu_p, 
                alpha1 = a1(), 
                alpha2 = a2(), 
                beta1 = input$beta1, 
                beta2 = input$beta2, 
                delta = input$delta, 
                psi = psi(), 
                omega = omega(), 
                sigma = input$sigma,
                gamma_s = input$gamma_s, 
                gamma_a = input$gamma_a, 
                eta_s = input$eta_s, 
                eta_a = input$eta_a)
    
          setProgress(3, "Setting parameters...")
    
    # Defines initial state
    initial_state <- c(S=999999, E=1, Ia=0, Is=0, R=0, P=0)
    
          setProgress(4, "Setting parameters...")
    
    # Model for 150 days
    times <- 0:150
    
          setProgress(5, "Calculating model...")
    
    # deSolve::ode() to calculate curves
    model <- ode(initial_state, times, COVID_SEIR, params)
    
          setProgress(10, "Arranging data...")
    
    ## Set up for animation
    data <- as.data.frame(model)
    
    framed_data <- list()
    
    for(i in 1:nrow(data)) {
      
      temp_df <- data[1:i, ]
      temp_df$frame <- i
      framed_data[[i]] <- temp_df
      
          incProgress(1, "Preparing animation...")
      
    }
    
    output_data <- bind_rows(framed_data)
    
          incProgress(1, "Plotting...")

    # Generate plots 
    p <- plot_ly(output_data, x = ~time, y = ~S, frame = ~frame, name = 'S', 
                 type = 'scatter', mode = 'lines') %>%
      add_trace(y = ~E, name = 'E') %>%
      add_trace(y = ~Ia, name = 'Ia') %>%
      add_trace(y = ~Is, name = 'Is') %>%
      add_trace(y = ~R, name = 'R') %>%
      layout(xaxis = list(title = "Time (Days)"),
             yaxis = list(title = "Population"))
    
    # Add animation
    p <- p %>% animation_slider(currentvalue = list(prefix = "Day: ")) %>%
      animation_opts(frame = 500, transition = 0, redraw = FALSE)
    
          incProgress(1, "Almost done...")
    
    # For enhanced performance
    p <- p %>% toWebGL()
    
          # Complete progress bar
          setProgress(164, "Done!")
    
    })
    
    # (Outside of progress function), return plot
    p
  }) %>% bindEvent(input$go) # Binds the plot generation to the "replot" button
  
  }

# Run the application 
shinyApp(ui = ui, server = server)
