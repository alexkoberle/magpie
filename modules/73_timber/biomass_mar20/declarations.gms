*** |  (C) 2008-2020 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

parameters
p73_timber_demand_gdp_pop(t_all,i,kforestry)                                Timber demand based on lauri et al 2019 (mio. m3 per yr)
p73_forestry_demand_prod_specific(t_all,iso,total_wood_products)            End product specific timber demand (mio. m3 per yr)
pm_demand_forestry_future(i,kforestry)           						                 Future forestry demand in current time step (tDM per yr)
pm_demand_ext(t_ext,i,kforestry)                                            Extended demand for timber beyound simulation (mio. tDM per yr)
p73_timber_harvest_cost(t,j,ac,forest_land)									                Harvesting costs as a function of carbon density (USD per ac per ha)
p73_cost_multiplier(land_natveg)                                            Cost multiplier for natural vegetation to make harvests expensive by a factor (1)
p73_base_min(iso,total_wood_products)                                       Percentage of initial demand above which a jump is not permitted between time steps (mio. tDM)
p73_demand_calib(t_all,i,kforestry)                                         Additive calibration factor for timber demand
;

positive variables
v73_cost_hvarea(i)                                                          Cost of harvesting timber from forests (mio. USD per yr)
v73_prod_forestry(j,ac,kforestry)                                           Production of woody biomass from commercial plantations (mio. tDM per yr)
v73_prod_natveg(j,land_natveg,ac,kforestry)                                 Production of woody biomass from natural vegetation (mio. tDM per yr)
v73_prod_heaven_timber(j,kforestry)                                         Production of woody biomass from heaven (mio. tDM per yr)
vm_cost_timber(i)				                                                    Actual cost of harvesting timber from forests (mio. USD per yr)
;

equations
q73_cost_timber(i)												                                  Actual cost of harvesting timber from forests (mio. USD per yr)
q73_cost_hvarea(i)												                                  Cost of harvesting timber from forests (mio. USD per yr)
q73_prod_timber(j,kforestry)                                                Production of woody biomass from commercial plantations and natural vegetation (mio. tDM per yr)
q73_prod_forestry(j,ac)                                                     Production of woody biomass from commercial plantations (mio. tDM per yr)
q73_prod_secdforest(j,ac)                                                   Production of woody biomass from secondary forests (mio. tDM per yr)
q73_prod_primforest(j)                                                      Production of woody biomass from primary forests (mio. tDM per yr)
q73_prod_other(j,ac)                                                        Production of woody biomass from other land (mio. tDM per yr)
;


*#################### R SECTION START (OUTPUT DECLARATIONS) ####################
parameters
 ov73_cost_hvarea(t,i,type)                          Cost of harvesting timber from forests (mio. USD per yr)
 ov73_prod_forestry(t,j,ac,kforestry,type)           Production of woody biomass from commercial plantations (mio. tDM per yr)
 ov73_prod_natveg(t,j,land_natveg,ac,kforestry,type) Production of woody biomass from natural vegetation (mio. tDM per yr)
 ov73_prod_heaven_timber(t,j,kforestry,type)         Production of woody biomass from heaven (mio. tDM per yr)
 ov_cost_timber(t,i,type)                            Actual cost of harvesting timber from forests (mio. USD per yr)
 oq73_cost_timber(t,i,type)                          Actual cost of harvesting timber from forests (mio. USD per yr)
 oq73_cost_hvarea(t,i,type)                          Cost of harvesting timber from forests (mio. USD per yr)
 oq73_prod_timber(t,j,kforestry,type)                Production of woody biomass from commercial plantations and natural vegetation (mio. tDM per yr)
 oq73_prod_forestry(t,j,ac,type)                     Production of woody biomass from commercial plantations (mio. tDM per yr)
 oq73_prod_secdforest(t,j,ac,type)                   Production of woody biomass from secondary forests (mio. tDM per yr)
 oq73_prod_primforest(t,j,type)                      Production of woody biomass from primary forests (mio. tDM per yr)
 oq73_prod_other(t,j,ac,type)                        Production of woody biomass from other land (mio. tDM per yr)
;
*##################### R SECTION END (OUTPUT DECLARATIONS) #####################
