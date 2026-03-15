# Load libraries
library(shiny)
library(shinythemes)
library(shinyalert)
library(spsComps)
library(DT)
library(jsonlite)

HAS_SHINYWIDGETS <- requireNamespace("shinyWidgets", quietly = TRUE)
if (HAS_SHINYWIDGETS) {
  library(shinyWidgets)
}


SAVED_TIME_FILE <- "saved_time.txt"
SERVER_CONFIG_FILE <- "server_config.json"
APP_DIR <- normalizePath(
  if (file.exists(SERVER_CONFIG_FILE)) "." else "frontend",
  winslash = "/",
  mustWork = TRUE
)
SAVED_TIME_FILE <- file.path(APP_DIR, SAVED_TIME_FILE)
SERVER_CONFIG_FILE <- file.path(APP_DIR, SERVER_CONFIG_FILE)

get_saved_time <- function() {
  if (file.exists(SAVED_TIME_FILE)) {
    as.integer(readLines(SAVED_TIME_FILE))
  } else {
    0
  }
}

increment_saved_time <- function() {
  saved_time <- get_saved_time() + 1800 + sample(x = c(1:300), size = 1)
  writeLines(as.character(saved_time), SAVED_TIME_FILE)
  saved_time
}

get_storage_entry <- function(config, server_name) {
  entry <- config$storage_server[[server_name]]

  if (is.null(entry)) {
    return(NULL)
  }

  if (is.character(entry)) {
    return(list(
      rawdata_path = unname(entry),
      results_path = sub("rawdata/?$", "results/", unname(entry))
    ))
  }

  entry
}

get_storage_value <- function(config, server_name, field_name) {
  entry <- get_storage_entry(config, server_name)

  if (is.null(entry)) {
    return(NA_character_)
  }

  value <- entry[[field_name]]
  if (is.null(value) || identical(value, "")) {
    return(NA_character_)
  }

  unname(value)
}

get_cluster_value <- function(config, field_name) {
  value <- config$cluster[[field_name]]

  if (is.null(value) || identical(value, "")) {
    return(NA_character_)
  }

  unname(as.character(value))
}

app_script <- function(script_name) {
  file.path(APP_DIR, "scripts", script_name)
}

app_path <- function(...) {
  file.path(APP_DIR, ...)
}

app_radio_buttons <- function(inputId, label, choices = NULL, selected = NULL, ...) {
  if (HAS_SHINYWIDGETS) {
    shinyWidgets::prettyRadioButtons(inputId, label, choices = choices, selected = selected, ...)
  } else {
    shiny::radioButtons(inputId, label, choices = choices, selected = selected)
  }
}

app_update_radio_buttons <- function(session, inputId, choices = NULL, selected = NULL) {
  if (HAS_SHINYWIDGETS) {
    shinyWidgets::updatePrettyRadioButtons(session, inputId = inputId, choices = choices, selected = selected)
  } else {
    shiny::updateRadioButtons(session, inputId = inputId, choices = choices, selected = selected)
  }
}

app_picker_input <- function(inputId, label, choices = NULL, selected = NULL, options = NULL, ...) {
  if (HAS_SHINYWIDGETS) {
    shinyWidgets::pickerInput(inputId, label, choices = choices, selected = selected, options = options, ...)
  } else {
    shiny::selectInput(inputId, label, choices = choices, selected = selected, selectize = TRUE)
  }
}

app_update_picker_input <- function(session, inputId, choices = NULL, selected = NULL) {
  if (HAS_SHINYWIDGETS) {
    shinyWidgets::updatePickerInput(session, inputId = inputId, choices = choices, selected = selected)
  } else {
    shiny::updateSelectInput(session, inputId = inputId, choices = choices, selected = selected)
  }
}

app_switch_input <- function(inputId, label, value = FALSE, ...) {
  shiny::checkboxInput(inputId, label, value)
}

app_action_button <- function(inputId, label, ...) {
  if (HAS_SHINYWIDGETS) {
    shinyWidgets::actionBttn(inputId, label, ...)
  } else {
    shiny::actionButton(inputId, label)
  }
}

# Read JSON file and extract server names
servers_config <- fromJSON(SERVER_CONFIG_FILE, simplifyVector = FALSE)

# Extract server names
server_names <- names(servers_config$storage_server)

igblast_species_choices <- c(
  "Human" = "human",
  "Mouse" = "mouse"
)

igblast_panel_choices <- c(
  "Immunoglobulin heavy chain only (IgH)" = "igh",
  "Immunoglobulin light chains only (IgK + IgL)" = "ig_light",
  "All immunoglobulins (IgH + IgK + IgL)" = "ig_all",
  "TCR alpha only (TRA)" = "tra",
  "TCR beta only (TRB)" = "trb",
  "All TCR (TRA + TRB + TRD + TRG)" = "tcr_all",
  "All TCR and immunoglobulins" = "all_receptors"
)
