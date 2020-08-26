library(tidyverse)
library(SafeGraphR)
library(data.table)
library(stringr)


dir <- 'C:/Users/nickc/Documents/SafeGraph/2020/08/'
filename = 'Core-USA-August2020-Release-CORE_POI-2020_07-2020-08-07.zip'

f <- paste0(dir, filename)
files_in_zip <- utils::unzip(f, list = TRUE)$Name
files_in_zip <- files_in_zip[grep("\\.csv\\.gz", files_in_zip)]
utils::unzip(f, files = files_in_zip)
locs <- files_in_zip %>% purrr::map(function(x) {
  message(paste("Starting to read", x, "at", 
                Sys.time()))
  patterns <- data.table::fread(x, select = c("safegraph_place_id", 
                                              "latitude",
                                              "longitude",
                                              "region"))
  patterns <- patterns[region == "TX"]
  patterns[, region := NULL]
  file.remove(x)
  return(patterns)
}) %>% data.table::rbindlist() %>% unique() 


dir <- 'C:/Users/nickc/Documents/SafeGraph/monthly/'

lf <- list.files(dir,pattern = '.csv.gz',recursive = TRUE)

mpats <- read_many_patterns(dir = dir,
                            recursive = TRUE,
                            select = c('safegraph_place_id',
                                       'location_name',
                                       'street_address',
                                       'city',
                                       'brands',
                                       'visitor_home_cbgs'),
                            by = c('safegraph_place_id',
                                   'location_name',
                                   'street_address',
                                   'city',
                                   'brands'),
                            filter = 'state_fips == 48 & county_fips == 201',
                            expand_cat = 'visitor_home_cbgs')

# In-county visits only
mpats <- mpats[str_sub(as.character(visitor_home_cbgs_index),1,5) == '48201']
mpats[,state_fips := NULL]
mpats[,county_fips := NULL]
mpats[,start_date := NULL]

mpats <- merge(mpats, locs, all.x = TRUE)

load('naics_crosswalk.Rdata')
ncodes <- unique(ncodes)
mpats <- merge(mpats, ncodes, all.x = TRUE)
data("naics_codes")
naics_codes <- unique(naics_codes)
mpats <- merge(mpats, naics_codes, all.x = TRUE, by = 'naics_code')

edu <- fread('cbg_b15.csv')
edu <- subset(edu,select=names(edu) %like% 'B15003e' | names(edu) == 'census_block_group')
edu[,collegeshare := (B15003e21 + B15003e22 + B15003e23 + B15003e24 + B15003e25)/B15003e1]
setnames(edu,c('B15003e1','census_block_group'),c('population','visitor_home_cbgs_index'))
edu <- edu[,c('population','visitor_home_cbgs_index','collegeshare')]
edu[,visitor_home_cbgs_index := as.character(visitor_home_cbgs_index)]

inc <- fread('cbg_b19.csv')
inc <- subset(inc,select=names(inc) %like% 'B19301e' | names(inc) == 'census_block_group')
setnames(inc,c('B19301e1','census_block_group'),c('percap_income','visitor_home_cbgs_index'))
inc[,visitor_home_cbgs_index := as.character(visitor_home_cbgs_index)]


mpats <- merge(mpats, edu, all.x = TRUE, by = 'visitor_home_cbgs_index')
mpats <- merge(mpats, inc, all.x = TRUE, by = 'visitor_home_cbgs_index')

saveRDS(mpats, 'houstondash.Rdata')

shn <- fread('short_naics_walk.csv')

mpats[,naics_2 := floor(naics_code/10000)]
mpats <- merge(mpats, shn, all.x = TRUE, by = 'naics_2')

cbg_info <- unique(mpats[,c('visitor_home_cbgs_index','population','collegeshare','percap_income')])
loc_info <- unique(mpats[,c('safegraph_place_id','location_name','street_address','city','brands','broad_naics','naics_title','latitude','longitude')])
vis_info <- unique(mpats[,c('safegraph_place_id','visitor_home_cbgs_index','visitor_home_cbgs')])

saveRDS(cbg_info,'houston_cbg.Rdata')
saveRDS(loc_info,'houston_loc.Rdata')
saveRDS(vis_info,'houston_vis.Rdata')
