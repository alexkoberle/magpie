*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* ---- Inherited from price_aug22 ----
pcm_carbon_stock(j,land,ag_pools,stockType) = vm_carbon_stock.l(j,land,ag_pools,stockType);

* ---- cap_apr26: record slack level for platform signalling ----
*' A non-zero p56_emis_cap_slack(t) signals that the cap was infeasible for
*' this timestep; the platform should adjust the budget allocation accordingly.
p56_emis_cap_slack(t) = v56_slack_emis_cap.l;

* ---- cap_apr26: compute CO2eq for reporting (parameter, not optimization variable) ----
*' v56_emis_co2eq is not an optimization variable in cap_apr26 — it is computed
*' here from the solved vm_emissions_reg.l levels. Only the "level" type is
*' meaningful; marginal/upper/lower are not available for this output.
ov56_emis_co2eq(t,i,emis_source,pollutants,"level") =
  vm_emissions_reg.l(i,emis_source,pollutants)
  * p56_gwp(pollutants)
  * p56_cap_mask(emis_source,pollutants);

*#################### R SECTION START (OUTPUT DEFINITIONS) #####################
 ov_carbon_stock(t,j,land,c_pools,stockType,"marginal")   = vm_carbon_stock.m(j,land,c_pools,stockType);
 ov56_slack_emis_cap(t,"marginal")                        = v56_slack_emis_cap.m;
 ov_emission_costs(t,i,"marginal")                        = vm_emission_costs.m(i);
 ov_emissions_reg(t,i,emis_source,pollutants,"marginal")  = vm_emissions_reg.m(i,emis_source,pollutants);
 ov56_emis_pricing(t,i,emis_source,pollutants,"marginal") = v56_emis_pricing.m(i,emis_source,pollutants);
 ov56_emission_cost(t,i,emis_source,"marginal")           = v56_emission_cost.m(i,emis_source);
 ov_reward_cdr_aff(t,i,"marginal")                        = vm_reward_cdr_aff.m(i);
 ov56_reward_cdr_aff(t,j,"marginal")                      = v56_reward_cdr_aff.m(j);
 oq56_emission_costs(t,i,"marginal")                      = q56_emission_costs.m(i);
 oq56_emission_cost_annual(t,i,emis_annual,"marginal")    = q56_emission_cost_annual.m(i,emis_annual);
 oq56_emission_cost_oneoff(t,i,emis_oneoff,"marginal")    = q56_emission_cost_oneoff.m(i,emis_oneoff);
 oq56_reward_cdr_aff_reg(t,i,"marginal")                  = q56_reward_cdr_aff_reg.m(i);
 oq56_reward_cdr_aff(t,j,"marginal")                      = q56_reward_cdr_aff.m(j);
 oq56_emis_pricing(t,i,pollutants,emis_source,"marginal") = q56_emis_pricing.m(i,pollutants,emis_source);
 oq56_emis_pricing_co2(t,i,emis_oneoff,"marginal")        = q56_emis_pricing_co2.m(i,emis_oneoff);
 oq56_emis_cap(t,"marginal")                              = q56_emis_cap.m;
 ov_carbon_stock(t,j,land,c_pools,stockType,"level")      = vm_carbon_stock.l(j,land,c_pools,stockType);
 ov56_slack_emis_cap(t,"level")                           = v56_slack_emis_cap.l;
 ov_emission_costs(t,i,"level")                           = vm_emission_costs.l(i);
 ov_emissions_reg(t,i,emis_source,pollutants,"level")     = vm_emissions_reg.l(i,emis_source,pollutants);
 ov56_emis_pricing(t,i,emis_source,pollutants,"level")    = v56_emis_pricing.l(i,emis_source,pollutants);
 ov56_emission_cost(t,i,emis_source,"level")              = v56_emission_cost.l(i,emis_source);
 ov_reward_cdr_aff(t,i,"level")                           = vm_reward_cdr_aff.l(i);
 ov56_reward_cdr_aff(t,j,"level")                         = v56_reward_cdr_aff.l(j);
 oq56_emission_costs(t,i,"level")                         = q56_emission_costs.l(i);
 oq56_emission_cost_annual(t,i,emis_annual,"level")       = q56_emission_cost_annual.l(i,emis_annual);
 oq56_emission_cost_oneoff(t,i,emis_oneoff,"level")       = q56_emission_cost_oneoff.l(i,emis_oneoff);
 oq56_reward_cdr_aff_reg(t,i,"level")                     = q56_reward_cdr_aff_reg.l(i);
 oq56_reward_cdr_aff(t,j,"level")                         = q56_reward_cdr_aff.l(j);
 oq56_emis_pricing(t,i,pollutants,emis_source,"level")    = q56_emis_pricing.l(i,pollutants,emis_source);
 oq56_emis_pricing_co2(t,i,emis_oneoff,"level")           = q56_emis_pricing_co2.l(i,emis_oneoff);
 oq56_emis_cap(t,"level")                                 = q56_emis_cap.l;
 ov_carbon_stock(t,j,land,c_pools,stockType,"upper")      = vm_carbon_stock.up(j,land,c_pools,stockType);
 ov56_slack_emis_cap(t,"upper")                           = v56_slack_emis_cap.up;
 ov_emission_costs(t,i,"upper")                           = vm_emission_costs.up(i);
 ov_emissions_reg(t,i,emis_source,pollutants,"upper")     = vm_emissions_reg.up(i,emis_source,pollutants);
 ov56_emis_pricing(t,i,emis_source,pollutants,"upper")    = v56_emis_pricing.up(i,emis_source,pollutants);
 ov56_emission_cost(t,i,emis_source,"upper")              = v56_emission_cost.up(i,emis_source);
 ov_reward_cdr_aff(t,i,"upper")                           = vm_reward_cdr_aff.up(i);
 ov56_reward_cdr_aff(t,j,"upper")                         = v56_reward_cdr_aff.up(j);
 oq56_emission_costs(t,i,"upper")                         = q56_emission_costs.up(i);
 oq56_emission_cost_annual(t,i,emis_annual,"upper")       = q56_emission_cost_annual.up(i,emis_annual);
 oq56_emission_cost_oneoff(t,i,emis_oneoff,"upper")       = q56_emission_cost_oneoff.up(i,emis_oneoff);
 oq56_reward_cdr_aff_reg(t,i,"upper")                     = q56_reward_cdr_aff_reg.up(i);
 oq56_reward_cdr_aff(t,j,"upper")                         = q56_reward_cdr_aff.up(j);
 oq56_emis_pricing(t,i,pollutants,emis_source,"upper")    = q56_emis_pricing.up(i,pollutants,emis_source);
 oq56_emis_pricing_co2(t,i,emis_oneoff,"upper")           = q56_emis_pricing_co2.up(i,emis_oneoff);
 oq56_emis_cap(t,"upper")                                 = q56_emis_cap.up;
 ov_carbon_stock(t,j,land,c_pools,stockType,"lower")      = vm_carbon_stock.lo(j,land,c_pools,stockType);
 ov56_slack_emis_cap(t,"lower")                           = v56_slack_emis_cap.lo;
 ov_emission_costs(t,i,"lower")                           = vm_emission_costs.lo(i);
 ov_emissions_reg(t,i,emis_source,pollutants,"lower")     = vm_emissions_reg.lo(i,emis_source,pollutants);
 ov56_emis_pricing(t,i,emis_source,pollutants,"lower")    = v56_emis_pricing.lo(i,emis_source,pollutants);
 ov56_emission_cost(t,i,emis_source,"lower")              = v56_emission_cost.lo(i,emis_source);
 ov_reward_cdr_aff(t,i,"lower")                           = vm_reward_cdr_aff.lo(i);
 ov56_reward_cdr_aff(t,j,"lower")                         = v56_reward_cdr_aff.lo(j);
 oq56_emission_costs(t,i,"lower")                         = q56_emission_costs.lo(i);
 oq56_emission_cost_annual(t,i,emis_annual,"lower")       = q56_emission_cost_annual.lo(i,emis_annual);
 oq56_emission_cost_oneoff(t,i,emis_oneoff,"lower")       = q56_emission_cost_oneoff.lo(i,emis_oneoff);
 oq56_reward_cdr_aff_reg(t,i,"lower")                     = q56_reward_cdr_aff_reg.lo(i);
 oq56_reward_cdr_aff(t,j,"lower")                         = q56_reward_cdr_aff.lo(j);
 oq56_emis_pricing(t,i,pollutants,emis_source,"lower")    = q56_emis_pricing.lo(i,pollutants,emis_source);
 oq56_emis_pricing_co2(t,i,emis_oneoff,"lower")           = q56_emis_pricing_co2.lo(i,emis_oneoff);
 oq56_emis_cap(t,"lower")                                 = q56_emis_cap.lo;
*##################### R SECTION END (OUTPUT DEFINITIONS) ######################
