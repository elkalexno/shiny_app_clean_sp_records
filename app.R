# ==============================================================================
# INSTITUTO DE INVESTIGACIÓN DE RECURSOS BIOLÓGICOS ALEXANDER VON HUMBOLDT
# Proyecto: Apoyo implementación indicadores basados en especies SIIVRA 
# Programado por: Elkin A. Noguera
# Versión: v1 (20/05/2026)
# Descripción: Aplicación Shiny orientada a la curación espacial de datos de 
#              biodiversidad. Permite consolidar múltiples archivos CSV por 
#              especie y eliminar registros atípicos mediante el uso de una 
#              herramienta de polígonos interactivos en Leaflet.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CARGA DE DEPENDENCIAS Y ENTORNOS
# ------------------------------------------------------------------------------

if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

#################
########################CARGAS DATOS Y HACER UNA CURACIÓN BASICA DE ELLOS,
#### COMO ME COMPARTIERON LOS ARCHIVOS INDEPENDIENTES, LO QUE HICE FUE UNIRLOS EN UN SOLO cvs.
##########################
# Definir la ruta base
#ruta_base <- "D:/2026/Mod_siivra_biomodelos_sdm/ANEXO_6/Reg_curacion_13052026" # Ejemplo del directorio usado originalmente.
ruta_base <- "D:/MY_DIRECTORY"

# Buscar todos los archivos 'occ_colombia_clean.csv' en las subcarpetas
archivos <- list.files(path = ruta_base, 
                       pattern = "*.csv", 
                       full.names = TRUE, 
                       recursive = TRUE)

# Leer y unificar con corrección de tipo de dato
consolidado <- archivos %>% 
  map_df(~{
        datos <- read_csv(.x, col_types = cols(.default = "c"), show_col_types = FALSE)
        nombre_especie <- basename(dirname(dirname(.x)))
        datos %>% mutate(especie_folder = nombre_especie)
  }) %>% type_convert()

nrow(consolidado)

consolidado_coords <- data.frame(species = consolidado$species,
                                 lat  = as.numeric(as.character(consolidado$latitude)),
                                 lon = as.numeric(as.character(consolidado$longitude)),
                                 stringsAsFactors = FALSE)

str(consolidado_coords)
head(consolidado_coords)

consolidado_coords <- consolidado_coords[!is.na(consolidado_coords$lat) & 
                                           !is.na(consolidado_coords$lon), 
                                         ]

# Verificar cuántas filas quedaron
nrow(consolidado_coords)

# Verificar límites mundiales
# Latitud: -90 a 90 | Longitud: -180 a 180
summary(consolidado_coords[, c("lon", "lat")])

# Identificar filas fuera de rango (ejemplo: errores de escritura)
fuera_de_rango <- consolidado_coords[
  abs(consolidado_coords$lat) > 90 | abs(consolidado_coords$lon) > 180, 
]

# Buscar coordenadas en el origen (0,0)
coordenadas_cero <- consolidado_coords[consolidado_coords$lon == 0 & consolidado_coords$lat == 0, ]
length(unique(consolidado_coords$species)) ## 51 especies

# # Guardar el resultado en la carpeta principal
 ruta_guardado <- file.path(ruta_base, "consolidado_51_especies.csv")
 write.table(consolidado_coords, ruta_guardado, sep= ",", row.names = F, quote = FALSE)

# Mensaje de confirmación
cat("Proceso terminado. Se unificaron", length(archivos), "archivos.\n")
cat("Archivo guardado en:", ruta_guardado)

#######
####### Shiny
##########
library(shiny)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(DT)
library(sp)
library(shinythemes)

# --- 1. PREPARACIÓN DE DATOS ---
# Aseguramos un ID único para la gestión de puntos
if(!"uid" %in% names(consolidado_coords)) {
  consolidado_coords$uid <- seq_len(nrow(consolidado_coords))
}

# Variable de respaldo en el Global Environment (Consola)
datos_limpios_consola <<- consolidado_coords

# --- 2. INTERFAZ DE USUARIO (UI) ---
ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Curador de datos. Instituto Humboldt. Elkin Noguera.v1_20/05/2026"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("especie_sel", "1. Especie a validar:", 
                  choices = sort(unique(consolidado_coords$species))),
      
      hr(),
      wellPanel(
        style = "background: #fdfefe; border: 1px solid #dcdfe3;",
        strong("Estado de la Limpieza:"),
        tags$ul(
          tags$li(textOutput("resumen_especie")),
          tags$li(textOutput("resumen_curados")),
          tags$li(textOutput("resumen_total"))
        )
      ),
      
      hr(),
      actionButton("remove", "Eliminar Seleccionados", 
                   class = "btn-danger btn-block", icon = icon("eraser")),
      
      hr(),
      h5("3. Exportar (Elegir método):"),
      
      # Opción 1: Descarga clásica
      downloadButton("downloadData", "Descargar CSV (Navegador)", 
                     class = "btn-success btn-block"),
      br(),
      
      # Opción 2: Guardado directo al disco (OMITE EL ERROR .HTM)
      actionButton("save_local", "Guardar Directo en Carpeta", 
                   class = "btn-info btn-block", icon = icon("hdd")),
      
      helpText("Sugerencia: Si el botón verde falla, usa el azul. El archivo aparecerá en tu carpeta de trabajo.")
    ),
    
    mainPanel(
      width = 9,
      leafletOutput("mapa", height = "550px"),
      hr(),
      h4("Registros Actuales de la Especie:"),
      DTOutput("tabla_especie")
    )
  )
)

# --- 3. LÓGICA DEL SERVIDOR (SERVER) ---
server <- function(input, output, session) {
  
  # Valor reactivo que contiene toda la base de datos
  puntos_vivos <- reactiveVal(consolidado_coords)
  
  # Filtro reactivo para la especie seleccionada
  data_especie <- reactive({
    puntos_vivos() %>% filter(species == input$especie_sel)
  })
  
  # --- TEXTOS DINÁMICOS ---
  output$resumen_especie <- renderText({ paste("En esta especie:", nrow(data_especie())) })
  output$resumen_total   <- renderText({ paste("Total base actual:", nrow(puntos_vivos())) })
  output$resumen_curados <- renderText({ 
    paste("Total eliminados:", nrow(consolidado_coords) - nrow(puntos_vivos())) 
  })
  
  # --- MAPA ---
  output$mapa <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satélite") %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Mapa Base") %>%
      addLayersControl(baseGroups = c("Satélite", "Mapa Base")) %>%
      addDrawToolbar(
        targetGroup = "seleccion",
        polylineOptions = FALSE, circleOptions = FALSE, markerOptions = FALSE,
        circleMarkerOptions = FALSE, editOptions = editToolbarOptions()
      )
  })
  
  # Actualizar puntos en el mapa
  observe({
    df <- data_especie()
    proxy <- leafletProxy("mapa", data = df)
    proxy %>% clearMarkers()
    
    if(nrow(df) > 0) {
      proxy %>%
        addCircleMarkers(
          lng = ~lon, lat = ~lat,
          radius = 5, color = "#E74C3C", weight = 1,
          fillOpacity = 0.7, popup = ~paste("ID:", uid, "<br>Especie:", species),
          layerId = ~uid, group = "puntos"
        ) %>%
        fitBounds(min(df$lon), min(df$lat), max(df$lon), max(df$lat))
    }
  })
  
  # Captura de selección espacial
  observeEvent(input$mapa_draw_new_feature, {
    feat <- input$mapa_draw_new_feature
    poly <- feat$geometry$coordinates[[1]]
    lons <- sapply(poly, function(x) x[[1]])
    lats <- sapply(poly, function(x) x[[2]])
    
    df_act <- data_especie()
    uids <- df_act$uid[which(point.in.polygon(df_act$lon, df_act$lat, lons, lats) > 0)]
    session$userData$uids_a_eliminar <- uids
  })
  
  # --- PROCESO DE ELIMINACIÓN Y RESPALDO ---
  observeEvent(input$remove, {
    uids <- session$userData$uids_a_eliminar
    req(uids)
    
    nueva_tabla <- puntos_vivos() %>% filter(!(uid %in% uids))
    puntos_vivos(nueva_tabla)
    
    # Respaldo Global en Consola
    datos_limpios_consola <<- nueva_tabla 
    
    # Respaldo Automático en Disco (por si falla todo)
    write.csv(nueva_tabla, "RESPALDO_AUTOMATICO_LIMPIEZA.csv", row.names = FALSE)
    
    leafletProxy("mapa") %>% clearShapes()
    session$userData$uids_a_eliminar <- NULL
    
    showNotification("Puntos eliminados y respaldo actualizado.", type = "warning", duration = 3)
  })
  
  # --- EXPORTACIÓN DE DATOS ---
  
  # A. Botón Guardado Directo (Solución al .htm)
  observeEvent(input$save_local, {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
    nombre_archivo <- paste0("especies_curadas_", timestamp, ".csv")
    
    write.csv(puntos_vivos() %>% select(-uid), nombre_archivo, row.names = FALSE)
    
    showModal(modalDialog(
      title = "¡Guardado con éxito!",
      paste("El archivo se ha guardado directamente en tu carpeta de RStudio como:", nombre_archivo),
      footer = modalButton("Entendido"),
      easyClose = TRUE
    ))
  })
  
  # B. Botón de Descarga (Navegador)
  output$downloadData <- downloadHandler(
    filename = function() { paste0("Registros_curados_", Sys.Date(), ".csv") },
    content = function(file) {
      write.csv(puntos_vivos() %>% select(-uid), file, row.names = FALSE, na = "")
    },
    # Tipo de contenido para forzar descarga binaria en RStudio
    contentType = "application/octet-stream"
  )
  
  # Tabla de datos
  output$tabla_especie <- renderDT({
    datatable(data_especie(), options = list(pageLength = 5, dom = 'ltp'), rownames = FALSE)
  })
}

shinyApp(ui, server)
