*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* ---- Inherited from price_aug22 ----

parameters
 im_pollutant_prices(t_all,i,pollutants,emis_source)         Certificate prices (USD17MER per Mg)
 p56_pollutant_prices_input(t_all,i,pollutants,emis_source)  Certificate prices from input files (USD17MER per Mg)
 p56_c_price_aff(t_all,i,ac)           C price for afforestation decisions (USD17MER per tC)
 pc56_c_price_induced_aff              Helper for fixing aff reward to zero in historic period (binary)
 p56_region_price_shr(t_all,i)         GHG price share of region (1)
 p56_country_switch(iso)               Switch: country affected by ghg policy (1)
 p56_region_fader_shr(t_all,i)         GHG policy fader share of region (1)
 p56_country_switch2(iso)              Switch: country affected by ghg policy fader (1)
 p56_fader(t_all)                      GHG policy fader (1)
 p56_fader_reg(t_all,i)                Regional GHG policy fader (1)
 pcm_carbon_stock(j,land,c_pools,stockType) Carbon stock in prev timestep (mio. tC)
 p56_fader_cpriceaff(t_all)            Fader for C price induced afforestation (1)
* ---- cap_apr26_reg specific ----
 p56_gwp(pollutants)                   AR5 GWP factors for CO2eq conversion (Tg CO2eq per Tg native unit)
 p56_cap_mask(emis_source,pollutants)  Policy mask for cap scope: 1=included 0=excluded (1)
 p56_emis_cap(t_all,i)                 Active regional AFOLU cap per region (Tg CO2eq per yr)
 p56_emis_cap_slack(t,i)              Regional slack level — platform infeasibility signal (Tg CO2eq per yr)
* ov56_emis_co2eq declared here (not in R section) because it is computed manually
* in postsolve rather than copied from a GAMS variable attribute (.l/.m/.up/.lo).
* Declaring it outside the R section prevents the gms linter from stripping it.
 ov56_emis_co2eq(t,i,emis_source,pollutants,type) CO2-equivalent emissions by source — level only, computed in postsolve (Tg CO2eq per yr)
;

equations
* Inherited
 q56_emission_costs(i)             Total emission costs incl. slack penalty (mio. USD17MER per yr)
 q56_emission_cost_annual(i,emis_annual)   Regional costs for annual emissions (mio. USD17MER per yr)
 q56_emission_cost_oneoff(i,emis_oneoff)   Regional costs for one-off emissions (mio. USD17MER per yr)
 q56_reward_cdr_aff_reg(i)         Regional CDR revenues from afforestation (mio. USD17MER per yr)
 q56_reward_cdr_aff(j)             Cellular CDR revenues from afforestation (mio. USD17MER per yr)
 q56_emis_pricing(i,pollutants,emis_source)   Annual emissions for pricing (Tg per yr)
 q56_emis_pricing_co2(i,emis_oneoff)          CO2 emissions for pricing via carbon stocks (Tg per yr)
* cap_apr26_reg specific — one constraint per region; CO2eq inlined for performance
 q56_emis_cap(i)                           Regional AFOLU emissions cap constraint (Tg CO2eq per yr)
;

positive variables
 vm_carbon_stock(j,land,c_pools,stockType)  Carbon stock (mio. tC)
 v56_slack_emis_cap(i)                      Per-region slack for cap infeasibility guard (Tg CO2eq per yr)
;

variables
 vm_emission_costs(i)                   Emission costs incl. slack penalty (mio. USD17MER per yr)
 vm_emissions_reg(i,emis_source,pollutants)  Regional emissions (Tg per yr)
 v56_emis_pricing(i,emis_source,pollutants)  Regional emissions for pricing (Tg per yr)
 v56_emission_cost(i,emis_source)        GHG emission cost by source (mio. USD17MER per yr)
 vm_reward_cdr_aff(i)                   Annual CDR revenue from afforestation (mio. USD17MER per yr)
 v56_reward_cdr_aff(j)                  Cellular CDR revenue from afforestation (mio. USD17MER per yr)
;

*#################### R SECTION START (OUTPUT DECLARATIONS) ####################
parameters
 ov_carbon_stock(t,j,land,c_pools,stockType,type)   Carbon stock (mio. tC)
 ov56_slack_emis_cap(t,i,type)                      Per-region slack for cap infeasibility guard (Tg CO2eq per yr)
 ov_emission_costs(t,i,type)                        Emission costs incl. slack penalty (mio. USD17MER per yr)
 ov_emissions_reg(t,i,emis_source,pollutants,type)  Regional emissions (Tg per yr)
 ov56_emis_pricing(t,i,emis_source,pollutants,type) Regional emissions for pricing (Tg per yr)
 ov56_emission_cost(t,i,emis_source,type)           GHG emission cost by source (mio. USD17MER per yr)
 ov_reward_cdr_aff(t,i,type)                        Annual CDR revenue from afforestation (mio. USD17MER per yr)
 ov56_reward_cdr_aff(t,j,type)                      Cellular CDR revenue from afforestation (mio. USD17MER per yr)
 oq56_emission_costs(t,i,type)                      Total emission costs incl. slack penalty (mio. USD17MER per yr)
 oq56_emission_cost_annual(t,i,emis_annual,type)    Regional costs for annual emissions (mio. USD17MER per yr)
 oq56_emission_cost_oneoff(t,i,emis_oneoff,type)    Regional costs for one-off emissions (mio. USD17MER per yr)
 oq56_reward_cdr_aff_reg(t,i,type)                  Regional CDR revenues from afforestation (mio. USD17MER per yr)
 oq56_reward_cdr_aff(t,j,type)                      Cellular CDR revenues from afforestation (mio. USD17MER per yr)
 oq56_emis_pricing(t,i,pollutants,emis_source,type) Annual emissions for pricing (Tg per yr)
 oq56_emis_pricing_co2(t,i,emis_oneoff,type)        CO2 emissions for pricing via carbon stocks (Tg per yr)
 oq56_emis_cap(t,i,type)                            Regional AFOLU emissions cap constraint (Tg CO2eq per yr)
;
*##################### R SECTION END (OUTPUT DECLARATIONS) #####################
