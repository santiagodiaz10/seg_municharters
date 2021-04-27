#Load packages:
library(tidyverse)
library(sf) # to work with spatial vector data
library(leaflet) # interactive maps
library(OasisR) # to obtain spatial segregation measures
library(here) # path to project's files.

#######################################################
# Load Files:
#######################################################

#Load from web geo-shape municipalities: #Read file and unzip in virtual file system "vsizip"
url_ign <- "http://www.ign.gob.ar/descargas/geodatos/SHAPES/ign_municipio.zip/ign_municipio"
muni_shp <- st_read(file.path("/vsizip//vsicurl", url_ign), layer = "ign_municipio")
muni_shp_cor <- muni_shp %>%  mutate(IDPROV = str_sub(IN1, 1, 2)) %>% filter(IDPROV == 14) #create IDPROV using string, and then filter

#Load from web geo-shape Census tracts:
url_Cordoba<-"https://www.indec.gob.ar/ftp/cuadros/territorio/codgeo/Codgeo_Cordoba_con_datos.zip" #
radios_cordoba <- st_read(file.path("/vsizip/vsicurl", url_Cordoba), layer = "Cordoba_con_datos") #Read file and unzip in virtual file system "vsizip"

#Load from excel. Census tract data from Redatam Census 2010: https://redatam.indec.gob.ar/
radios_nbi <- readxl::read_xlsx(here("data/NBIS_and_Hacinam2010_porradio.xlsx"),
                               sheet = "reporte (22)", range = "A18:K22880", col_names = TRUE)

cordoba_nbi_ng <- radios_nbi %>% rename(link = "Código", H_sinNBI= "Hogares sin NBI", H_NBI = "Hogares con NBI") %>% 
  mutate(H_TOTAL= H_sinNBI+H_NBI, IDPROV = str_sub(link, 1, 2), link = as.character(link), per_H_NBI=H_NBI/H_TOTAL) %>% 
  filter(IDPROV == 14) %>% select(link, H_sinNBI, H_NBI, H_TOTAL, per_H_NBI) %>%  arrange(link)

#Data on Municipal Charters: Multiple sources. Check wp for more information on this. 
cor_co_year <- readxl::read_xlsx(here("data/Cordoba_CO.xlsx"), range = "A2:G431", col_names = TRUE)

#######################################################
# Data Preparation:
#######################################################

#------------------------------------------------------
# 1- Merge by municipality name: Using municipalities greater than 8000.
#1.1 Names in Redatam software:
name_mun_red10_df <- cor_co_year %>% select(name_mun_red10, pob_per_mun_2010) %>% arrange(name_mun_red10) %>% 
  filter(pob_per_mun_2010>8000) #Used to simplify analisys because CO> 10,000
name_mun_red10_df$name_mun_red10 <- str_replace(name_mun_red10_df$name_mun_red10, "Ñ", "N") #Replace Ñ por n.
name_mun_red10_df <- unique(name_mun_red10_df) #removing duplicates

#1.2 Names in shape files:
NAM_df <- muni_shp_cor %>% select(OBJECTID, NAM) %>% arrange(NAM)
NAM_df$NAM <- iconv(NAM_df$NAM,from="UTF-8",to="ASCII//TRANSLIT") #Removes tilde to non-tilde
NAM_df <- unique(NAM_df) #removing duplicates

#1.3  Matching string variables loop:
name_mun_red10_df$name.matched <- "" # Creating an empty column
for(i in 1:dim(name_mun_red10_df)[1]) {
  x <- agrep(name_mun_red10_df$name_mun_red10[i], NAM_df$NAM, #Funcition that matches name in a variable 
             ignore.case=TRUE, value=TRUE,
             max.distance = 0.01, useBytes = TRUE)
  x <- paste0(x,"") # Pasting values if there is a match
  name_mun_red10_df$name.matched[i] <- x
} 

#Checking duplicates:
name_mun_red10_df <- name_mun_red10_df %>% group_by(name.matched) %>% mutate(dupli_names = n()) %>% ungroup()

#------------------------------------------------------
#2- Using unique identifier to merge main datasets: 
#2.1 Corrections to the dataset to merge:
cor_co_year <- cor_co_year %>% arrange(name_mun_red10) %>% 
  filter(pob_per_mun_2010>8000) #Used to simplify analisys because CO> 10,000
cor_co_year$name_mun_red10 <- str_replace(name_mun_red10_df$name_mun_red10, "Ñ", "N")

#2.2 Corrections to the main data set:
muni_shp_cor$NAM <- iconv(muni_shp_cor$NAM,from="UTF-8",to="ASCII//TRANSLIT") #Removes tilde to non-tilde

#2.3- Merge using unique identifier:
test_1 = merge(muni_shp_cor, name_mun_red10_df, by.x= c("NAM"), by.y= c("name.matched")) #use #all=TRUE to keep all
muni_cordoba_CO_shp <- merge(test_1, cor_co_year, by.x= c("name_mun_red10"), by.y= c("name_mun_red10"))

muni_cor_CO_8m_shp <- muni_cordoba_CO_shp %>% select(-pob_per_mun_2010.y) %>% 
  rename(pob_per_mun_2010 = pob_per_mun_2010.x) #extra cleaning

#------------------------------------------------------
# 3- Joining datasets with geolocalization data:
#3.1 Adding data on NBI to geolocalization dataset distribution per census tracts:
cordoba_nbi <- left_join(radios_cordoba, cordoba_nbi_ng, by = c("link"))

#3.2 Joining both shapefiles by geolocalization: 
muni_cor_CO_8m_shp<- st_transform(muni_cor_CO_8m_shp, crs = 4326 ) 
cordoba_nbi<- st_transform(cordoba_nbi, crs = 4326 ) 

#Joining shp per geographic coincidence:
cba_join_shp <- st_join(muni_cor_CO_8m_shp, cordoba_nbi)

#------------------------------------------------------
# 4. Segregation Measures: Obtain Gini and Htail of NBI distribution in municipalities by census tracts.
#4.1
cba_join_shp_1 <- cba_join_shp 

list_ids <- cba_join_shp_1 %>% as.data.frame() %>% select(OBJECTID) %>% unique() %>% filter(!is.na(OBJECTID))

with_hNBI <- cba_join_shp_1 %>%  as.data.frame() %>% select(H_NBI, H_sinNBI, OBJECTID) 

segregation_muni = data.frame()
for (i in list_ids$OBJECTID) {
  muni_hNBI= with_hNBI %>% filter(OBJECTID == i) %>% select(H_NBI, H_sinNBI)
    Gini_i <- c(i, Gini(muni_hNBI)[1], HTheil(muni_hNBI)[1])
    segregation_muni <- rbind(segregation_muni, Gini_i)
  }
names(segregation_muni) <- c("OBJECTID","Gini", "HTheil")
segregation_muni


#######################################################
# Maps:
#######################################################

#------------------------------------------------------
# Join geo-characteristics using municipalities shapes
map_8m_gini <- left_join(muni_cor_CO_8m_shp, segregation_muni, by= c("OBJECTID") )
map_8m_gini <- map_8m_gini %>%  filter(!is.na(Gini))

# Drop Z and M dimensions from map_8m_gini (it comes with extra z dimension)
map_8m_gini <- st_zm(map_8m_gini, drop = T, what = "ZM")
st_geometry(map_8m_gini) #CORRECTED EXTRA Z DIMENSION

#------------------------------------------------------
#1 Leaflet for Gini Segregation:
pal <- colorBin("Blues", domain = map_8m_gini$Gini, 5, pretty = FALSE)

leaflet() %>%
  addTiles() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = map_8m_gini,
              color = ~pal(Gini),
              weight = 1, smoothFactor = 0, 
              stroke = TRUE, fillOpacity = 0.8) %>%
  addLegend(data = map_8m_gini,
            "bottomright", 
            pal = pal, 
            values = ~Gini,
            labFormat = labelFormat(between = "-", digits = 2),
            title = "Gini Segregation Index (UBN)",
            opacity = 0.8  )

#------------------------------------------------------
# 2 Leaflet for time to reform Municipal Charter (MC)
map_time_co <- map_8m_gini %>% mutate(time_to_CO = Year_dictat - Consti_ref_y, time_to_CO = replace_na(time_to_CO, 34) )

pal_co <- colorBin("Blues", domain = map_time_co$time_to_CO, 5, pretty = FALSE, reverse = TRUE)  #reverse the colours of palette

leaflet() %>%
  addTiles() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = map_time_co,
              color = ~pal_co(time_to_CO),
              weight = 1, smoothFactor = 0, 
              stroke = TRUE, fillOpacity = 0.8) %>%
  addLegend(data = map_time_co,
            "bottomright", 
            pal = pal_co, 
            values = ~time_to_CO,
            labFormat = labelFormat(between = "-", digits = 0),
            title = "Time to reform MC (years)",
            opacity = 0.8  )

