# |  (C) 2008-2023 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# ----------------------------------------------------------
# description: WBCSD runs
# ----------------------------------------------------------

######################################
#### Script to start a MAgPIE run ####
######################################

prefix <- "T05"

library(gms)
library(magclass)
library(gdx)

# Load start_run(cfg) function which is needed to start MAgPIE runs
source("scripts/start_functions.R")

#start MAgPIE run
source("config/default.cfg")

#repos
cfg$repositories <- append(list("./patch_inputdata"=NULL, "https://rse.pik-potsdam.de/data/magpie/public"=NULL), getOption("magpie_repos"))

#output folder
cfg$results_folder <- "output/:title:"
cfg$results_folder_highres <- "output"
cfg$output <- c("extra/disaggregation","rds_report")
#cfg$force_replace <- TRUE
#cfg$force_download <- TRUE
cfg$qos <- "priority"
cfg$sequential <- FALSE

#general settings
cfg$gms$c_timesteps <- "5year2050"
cfg$gms$factor_costs <- "sticky_labor"        # default = per_ton_fao_may22
cfg$gms$c38_fac_req <- "reg"        # default "glo"
cfg$gms$crop <- "penalty_apr22"
cfg$gms$past <- "grasslands_apr22"

#input file vector (for BAU)
cfg$input <- c(regional = "rev4.87_FSEC_magpie.tgz",
               cellular = "rev4.87_FSEC_1b5c3817_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1.tgz",
               validation = "rev4.87_FSEC_validation.tgz",
               calibration = "calibration_FSEC_07Aug23.tgz",
               additional = "additional_data_rev4.43.tgz",
               patch = "WBCSD.tgz")

highIncomeCountries  <- "ALA,AUS,AUT,BEL,BGR,CAN,CHN,CYP,EST,ESP,GBR,FRA,FRO,GGY,HUN,GIB,GRC,HRV,IMN,IRL,JEY,LTU,MLT,
                         NLD,POL,PRT,ROU,AND,ISL,LIE,MCO,SJM,SMR,VAT,ALB,BIH,MKD,MNE,SRB,TUR,GRL,HKG,TWN,CZE,DEU,DNK,
                         ITA,LUX,LVA,SVK,SVN,SWE,SWZ,JPN,KOR,FIN,NOR,USA,NZL,PRK,SPM"

#### START scenarios

## BAU
cfg$title <- paste(prefix,"BAU",sep="_")

#1 set all options to SSP2 defaults including Pop and GDP + NPI
cfg <- setScenario(cfg,c("SSP2","NPI","ForestryEndo","cc","rcp4p5"))
#overwrite with FSEC region input
cfg$input[["cellular"]] <- "rev4.87_FSEC_1b5c3817_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1.tgz"

#2 GHG price and Bioenergy Demand from https://climatescenariocatalogue.org/explore-the-data/
cfg$gms$c60_1stgen_biodem <- "const2020"
cfg$gms$c60_2ndgen_biodem <- "BAU"
cfg$gms$c56_pollutant_prices <- "BAU"
cfg$gms$c56_mute_ghgprices_until <- "y2020"   # def = y2030

#3 Diet shift and food waste; No diet shift and food waste reduction
cfg$gms$s15_kcal_pc_livestock_intake_target <- "750"   # def = 430
cfg$gms$c15_livescen_target <- "constant"           # def = constant
cfg$gms$s15_exo_waste <- 1
cfg$gms$s15_waste_scen <- 1.33
cfg$gms$c70_cereal_scp_scen <- "constant"

#4 Protected areas; WDPA only
cfg$gms$c22_protect_scenario <- "none"      # def = none
cfg$gms$c22_protect_scenario_noselect <- "none"     # def = none
cfg$gms$policy_countries22  <- all_iso_countries
cfg$gms$s22_conservation_start <- 2020       # def = 2020
cfg$gms$s22_conservation_target <- 2030       # def = 2030

#5 SNUPE
cfg$gms$c50_scen_neff <- "maxeff_add3_glo60_glo65"

#6 Timber
cfg$gms$c73_build_demand <- "BAU"

#7 Yields
cfg$gms$c13_tccost <- "high"  # def = medium

results_folder <- gsub(":title:", cfg$title, cfg$results_folder, fixed=TRUE)
if (file.exists(results_folder)) {
  message(paste0("Results folder ", results_folder,
                 " already exists. Jumping to next scenario"))
} else {
  start_run(cfg,codeCheck=FALSE)    
}



## 2degForecastPol
cfg$title <- paste(prefix,"2degForecastPol",sep="_")

#1 set all options to SSP2 defaults including Pop and GDP + NDC
cfg <- setScenario(cfg,c("SSP2","NDC","ForestryEndo","cc","rcp2p6"))
#overwrite with FSEC region input
cfg$input[["cellular"]] <- "rev4.87_FSEC_6819938d_cellularmagpie_c200_MRI-ESM2-0-ssp126_lpjml-8e6c5eb1.tgz"

#2 GHG price and Bioenergy Demand from https://climatescenariocatalogue.org/explore-the-data/
cfg$gms$c60_1stgen_biodem <- "phaseout2020"
cfg$gms$c60_2ndgen_biodem <- "2degForecastPol"
cfg$gms$c56_pollutant_prices <- "2degForecastPol"
cfg$gms$c56_mute_ghgprices_until <- "y2020"   # def = y2030

#3 Diet shift and food waste; Medium diet shift and food waste reduction
cfg$gms$s15_kcal_pc_livestock_intake_target <- "600"   # def = 430
cfg$gms$c15_livescen_target <- "lin_zero_20_50"           # def = constant
cfg$gms$s15_exo_waste <- 1
cfg$gms$s15_waste_scen <- 1.2
cfg$gms$c70_cereal_scp_scen <- "lin_99-98-90pc_20_50-60-100"

#4 Protected areas; BH protection
cfg$gms$c22_protect_scenario <- "BH"      # def = None
cfg$gms$c22_protect_scenario_noselect <- "none"     # def = None
cfg$gms$policy_countries22  <- highIncomeCountries
cfg$gms$s22_conservation_start <- 2025       # def = 2020
cfg$gms$s22_conservation_target <- 2035       # def = 2030

#5 SNUPE
cfg$gms$c50_scen_neff <- "maxeff_add3_glo65_glo75"

#6 Timber
cfg$gms$c73_build_demand <- "10pc"

#7 Yields
cfg$gms$c13_tccost <- "medium"  # def = medium

results_folder <- gsub(":title:", cfg$title, cfg$results_folder, fixed=TRUE)
if (file.exists(results_folder)) {
  message(paste0("Results folder ", results_folder,
                 " already exists. Jumping to next scenario"))
} else {
  start_run(cfg,codeCheck=FALSE)    
}



## 2degCoordPol
cfg$title <- paste(prefix,"2degCoordPol",sep="_")

#1 set all options to SSP2 defaults including Pop and GDP + NDC
cfg <- setScenario(cfg,c("SSP2","NDC","ForestryEndo","cc","rcp2p6"))
#overwrite with FSEC region input
cfg$input[["cellular"]] <- "rev4.87_FSEC_6819938d_cellularmagpie_c200_MRI-ESM2-0-ssp126_lpjml-8e6c5eb1.tgz"

#2 GHG price and Bioenergy Demand from https://climatescenariocatalogue.org/explore-the-data/
cfg$gms$c60_1stgen_biodem <- "phaseout2020"
cfg$gms$c60_2ndgen_biodem <- "2degCoordPol"
cfg$gms$c56_pollutant_prices <- "2degCoordPol"
cfg$gms$c56_mute_ghgprices_until <- "y2020"   # def = y2030

#3 Diet shift and food waste; Medium diet shift and food waste reduction
cfg$gms$s15_kcal_pc_livestock_intake_target <- "600"   # def = 430
cfg$gms$c15_livescen_target <- "lin_zero_20_50"           # def = constant
cfg$gms$s15_exo_waste <- 1
cfg$gms$s15_waste_scen <- 1.2
cfg$gms$c70_cereal_scp_scen <- "lin_99-98-90pc_20_50-60-100"

#4 Protected areas; BH protection
cfg$gms$c22_protect_scenario <- "BH"      # def = None
cfg$gms$c22_protect_scenario_noselect <- "none"     # def = None
cfg$gms$policy_countries22  <- all_iso_countries
cfg$gms$s22_conservation_start <- 2020       # def = 2020
cfg$gms$s22_conservation_target <- 2030       # def = 2030

#5 SNUPE
cfg$gms$c50_scen_neff <- "maxeff_add3_glo65_glo75"

#6 Timber
cfg$gms$c73_build_demand <- "10pc"

#7 Yields
cfg$gms$c13_tccost <- "medium"  # def = medium

results_folder <- gsub(":title:", cfg$title, cfg$results_folder, fixed=TRUE)
if (file.exists(results_folder)) {
  message(paste0("Results folder ", results_folder,
                 " already exists. Jumping to next scenario"))
} else {
  start_run(cfg,codeCheck=FALSE)    
}



## 1p5degSocialTrans
cfg$title <- paste(prefix,"1p5degSocialTrans",sep="_")

#1 set all options to SSP2 defaults including Pop and GDP + NDC
cfg <- setScenario(cfg,c("SSP2","NDC","ForestryEndo","cc","rcp1p9"))
#overwrite with FSEC region input
cfg$input[["cellular"]] <- "rev4.87_FSEC_0bd54110_cellularmagpie_c200_MRI-ESM2-0-ssp119_lpjml-8e6c5eb1.tgz"

#2 GHG price and Bioenergy Demand from https://climatescenariocatalogue.org/explore-the-data/
cfg$gms$c60_1stgen_biodem <- "phaseout2020"
cfg$gms$c60_2ndgen_biodem <- "1p5degSocialTrans"
cfg$gms$c56_pollutant_prices <- "1p5degSocialTrans"
cfg$gms$c56_mute_ghgprices_until <- "y2020"   # def = y2030

#3 Diet shift and food waste; High diet shift and food waste reduction
cfg$gms$s15_kcal_pc_livestock_intake_target <- "450"   # def = 430
cfg$gms$c15_livescen_target <- "lin_zero_20_50"           # def = constant
cfg$gms$s15_exo_waste <- 1
cfg$gms$s15_waste_scen <- 1.165
cfg$gms$c70_cereal_scp_scen <- "lin_99-98-90pc_20_50-60-100"

#4 Protected areas; 30by30
cfg$gms$c22_protect_scenario <- "30by30"      # def = None
cfg$gms$c22_protect_scenario_noselect <- "none"     # def = None
cfg$gms$policy_countries22  <- all_iso_countries
cfg$gms$s22_conservation_start <- 2020       # def = 2020
cfg$gms$s22_conservation_target <- 2050       # def = 2030

#5 SNUPE
cfg$gms$c50_scen_neff <- "maxeff_add3_glo65_glo75"

#6 Timber
cfg$gms$c73_build_demand <- "10pc"

#7 Yields
cfg$gms$c13_tccost <- "medium"  # def = medium

results_folder <- gsub(":title:", cfg$title, cfg$results_folder, fixed=TRUE)
if (file.exists(results_folder)) {
  message(paste0("Results folder ", results_folder,
                 " already exists. Jumping to next scenario"))
} else {
  start_run(cfg,codeCheck=FALSE)    
}



## 1p5degInnovation
cfg$title <- paste(prefix,"1p5degInnovation",sep="_")

#1 set all options to SSP2 defaults including Pop and GDP + NDC
cfg <- setScenario(cfg,c("SSP2","NDC","ForestryEndo","cc","rcp1p9"))
#overwrite with FSEC region input
cfg$input[["cellular"]] <- "rev4.87_FSEC_0bd54110_cellularmagpie_c200_MRI-ESM2-0-ssp119_lpjml-8e6c5eb1.tgz"

#2 GHG price and Bioenergy Demand from https://climatescenariocatalogue.org/explore-the-data/
cfg$gms$c60_1stgen_biodem <- "phaseout2020"
cfg$gms$c60_2ndgen_biodem <- "1p5degInnovation"
cfg$gms$c56_pollutant_prices <- "1p5degInnovation"
cfg$gms$c56_mute_ghgprices_until <- "y2020"   # def = y2030

#3 Diet shift and food waste; Medium diet shift and food waste reduction
cfg$gms$s15_kcal_pc_livestock_intake_target <- "600"   # def = 430
cfg$gms$c15_livescen_target <- "lin_zero_20_50"           # def = constant
cfg$gms$s15_exo_waste <- 1
cfg$gms$s15_waste_scen <- 1.2
cfg$gms$c70_cereal_scp_scen <- "lin_99-98-90pc_20_50-60-100"

#4 Protected areas; BH protection
cfg$gms$c22_protect_scenario <- "BH"      # def = None
cfg$gms$c22_protect_scenario_noselect <- "none"     # def = None
cfg$gms$policy_countries22  <- all_iso_countries
cfg$gms$s22_conservation_start <- 2020       # def = 2020
cfg$gms$s22_conservation_target <- 2030       # def = 2030

#5 SNUPE
cfg$gms$c50_scen_neff <- "maxeff_add3_glo75_glo80"

#6 Timber
cfg$gms$c73_build_demand <- "50pc"

#7 Yields
cfg$gms$c13_tccost <- "low"  # def = medium

results_folder <- gsub(":title:", cfg$title, cfg$results_folder, fixed=TRUE)
if (file.exists(results_folder)) {
  message(paste0("Results folder ", results_folder,
                 " already exists. Jumping to next scenario"))
} else {
  start_run(cfg,codeCheck=FALSE)    
}
