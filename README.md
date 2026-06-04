# shiny_app_clean_sp_records
Aplicación Shiny para la curación de datos de biodiversidad obtenidos de bases de datos en línea. Permite consolidar registros de especies y eliminar datos atípicos mediante herramientas espaciales.

# Curador Espacial de Datos de Biodiversidad 🇨🇴

> **Proyecto:** Apoyo a la implementación de indicadores basados en especies.
> **Institución:** Instituto de Investigación de Recursos Biológicos Alexander von Humboldt.
> **Autor:** Elkin A. Noguera (v1 - 20/05/2026)

## 📌 Descripción

Shiny_app_clean_sp_records es una aplicación interactiva desarrollada en **R y Shiny** diseñada para la consolidación y curación espacial de registros de presencia de especies. La herramienta automatiza la unificación de múltiples archivos de bases de datos independientes y ofrece una interfaz gráfica basada en **Leaflet** para que el usuario pueda identificar y eliminar visualmente registros atípicos (outliers) mediante polígonos espaciales interactivos.

---

## 🚀 Características Principales

*   **ETL Automatizado:** Busca, lee y unifica archivos independientes `Ejemplo: occ_colombia_clean.csv` en subcarpetas de manera recursiva.
*   **Validación de Coordenadas:** Detecta de forma automática registros con coordenadas nulas (`NA`), ubicadas en el origen (`0,0`) o fuera de los límites mundiales de latitud/longitud.
*   **Curación Espacial Interactiva:** Integración con `leaflet.extras` para permitir al usuario dibujar polígonos libres sobre mapas base (Satélite y CartoDB) para seleccionar y eliminar registros erróneos en tiempo real.
*   **Persistencia y Seguridad de Datos:** 
    *   Mantiene un respaldo reactivo en la consola global de R (`datos_limpios_consola`).
    *   Genera un archivo de respaldo automático tras cada eliminación (`RESPALDO_AUTOMATICO_LIMPIEZA.csv`).
    *   Ofrece un método alternativo de guardado directo en disco local para evitar errores de descarga del navegador (`.htm`).
*   **Métricas Dinámicas:** Muestra contadores en tiempo real de registros por especie seleccionada, registros eliminados y total de la base de datos activa.

---

## 🛠️ Requisitos e Instalación

### 1. Requisitos de Software
Asegúrate de tener instalado **R** (versión 4.2 o superior recomendada) y preferiblemente **RStudio**.

### 2. Clonar el Repositorio
```bash
git clone https://github.com
cd siivra-curador-especies
```

### 3. Dependencias
La aplicación validará e instalará automáticamente `tidyverse` al arrancar. Los paquetes requeridos que debes tener listos son:
```R
install.packages(c("tidyverse", "shiny", "leaflet", "leaflet.extras", "dplyr", "DT", "sp", "shinythemes"))
```

---

## 💻 Configuración y Uso

### Paso 1: Configurar Ruta de Datos
Antes de ejecutar la aplicación, abre el script principal y modifica la variable `ruta_base` con la dirección de tu carpeta local de anexos:
```R
ruta_base <- "D:/XXX"
```

### Paso 2: Ejecutar la Aplicación
Puedes iniciar el tablero ejecutando el script en RStudio o usando el siguiente comando en la consola de R:
```R
shiny::runApp()
```

### Paso 3: Flujo de Trabajo en la Interfaz
1.  **Seleccionar Especie:** Filtra los registros de la especie a validar usando el menú desplegable (Soporta hasta 51 especies pre-consolidadas).
2.  **Dibujar Polígono:** Utiliza la barra de herramientas del mapa para dibujar un polígono alrededor de los puntos que deseas eliminar.
3.  **Eliminar:** Haz clic en el botón rojo **"Eliminar Seleccionados"**. El mapa y la tabla se actualizarán de inmediato.
4.  **Exportar:** Descarga el resultado final usando el botón de descarga del navegador o presiona **"Guardar Directo en Carpeta"** para escribir directamente el archivo CSV en tu directorio de trabajo.

---

## 📂 Estructura del Proyecto

*   `app.R` / `script.R`: Archivo principal que contiene el flujo ETL y la arquitectura Shiny (UI/Server).
*   `.gitignore`: Excluye archivos temporales de R, datos locales pesados y archivos de respaldo generados durante las sesiones de curación.
*   `README.md`: Este archivo guía de documentación.

---

## 🔒 Licencia y Uso
Este software es de uso interno para el **Instituto Humboldt**. Para contribuciones, reportes de fallos o solicitudes de características, por favor abre un *Issue* o envía un *Pull Request* en este repositorio.

