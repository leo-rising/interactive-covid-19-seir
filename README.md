# Interactive SEIR model for COVID-19 (Shiny app)
Pranav Gundrala
PHP1650

### INTRODUCTION

A SEIR (susceptible-exposed-infected-recovered) model is an epidemiological model that tracks the spread of a disease over a population based on various factors. It defines individuals in a population of N in one of four states: 

**Susceptible**, for a person who has not been exposed to the pathogen, 

**Exposed**, denoting a person who has come into contact with the pathogen, taken it up, and is now experiencing a “non-trivial incubation period” during which they have not developed a true infection (Hou, 2024), 

**Infected**, for a person who is currently infected and able to spread the disease, and 

**Recovered**, for any persons who have endured the course of the disease (which includes those who have died from infection) and can no longer be infected. 

This model was used heavily in studying the dynamics of the COVID-19 pandemic. The paper by Mwalili et. al describes a particularly interesting SEIR model that has a few key differences:

Their model presumes different states for either symptomatic infection (Is) or asymptomatic infection (Is), and assigns different parameters (an asymptomatic individual might interact with others more than a symptomatic person, for example).

Their model includes a new compartment (P, for Pathogen) that models pathogens that are deposited in some “shared” environment that is regularly interacted with (i.e. school, work, grocery stores). Exposures (S to E) can arise from this interaction as well.

The transition from S to E after exposure to the pathogen is not unidirectional. It is possible for an individual to not progress from E to Ia/s and instead return to S based on some “robust immune” response.

### SIMULATION

Based on the methods described by Mwalili et. al, a set of differential equations was defined for each of the six states: `S(t)`, `E(t)`, `Ia(t)`, `Is(t)`, `R(t)`, and `P(t)`. 

These were coded into R using the deSolve package and solved at various time intervals from 0 to 150 days. The original parameters were set using those described by Mwalili et. al. The initial values for the model were set for a population of 1M, where `S(0) = 999999` and `E(0) = 1` (patient-zero).

### FEATURES

The shiny app for this simulation can be found here:
[https://pgundral.shinyapps.io/shiny_simul/]

### REFERENCES

Mwalili, Samuel et al. “SEIR model for COVID-19 dynamics incorporating the environment and social distancing.” BMC research notes vol. 13,1 352. 23 Jul. 2020, doi:10.1186/s13104-020-05192-1 [https://pmc.ncbi.nlm.nih.gov/articles/PMC7376536/]
