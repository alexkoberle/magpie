*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de


*' @equations

* ---- Inherited from price_aug22 (verbatim) ----

*' GHG emissions for pricing can differ for CO2 emissions from land-use change
*' depending on `c56_carbon_stock_pricing`. CO2 emissions subject to pricing are
*' calculated from changes in carbon stocks between timesteps in `vm_carbon_stock`.

 q56_emis_pricing(i2,pollutants,emis_annual) ..
  v56_emis_pricing(i2,emis_annual,pollutants) =e=
    vm_emissions_reg(i2,emis_annual,pollutants);

 q56_emis_pricing_co2(i2,emis_oneoff) ..
  v56_emis_pricing(i2,emis_oneoff,"co2_c") =e=
    sum((cell(i2,j2),emis_land(emis_oneoff,land,c_pools)),
    (pcm_carbon_stock(j2,land,c_pools,"actual") - vm_carbon_stock(j2,land,c_pools,"%c56_carbon_stock_pricing%"))/m_timestep_length);

*** Emission costs

*' **Emission costs** are calculated by multiplying regional emissions with the
*' emission price `im_pollutant_prices`, taking into account the pricing policy.

 q56_emission_cost_annual(i2,emis_annual) ..
  v56_emission_cost(i2,emis_annual) =e=
    sum(pollutants,
      v56_emis_pricing(i2,emis_annual,pollutants) *
      sum(ct, im_pollutant_prices(ct,i2,pollutants,emis_annual)));

*' One-off emissions (e.g. deforestation CO2) are discounted by an annuity factor
*' (infinite time horizon) to level them with annually recurring emissions.

 q56_emission_cost_oneoff(i2,emis_oneoff) ..
  v56_emission_cost(i2,emis_oneoff) =e=
    sum(pollutants,
      v56_emis_pricing(i2,emis_oneoff,pollutants)
      * m_timestep_length
      * sum(ct,
          im_pollutant_prices(ct,i2,pollutants,emis_oneoff)
        * pm_interest(ct,i2)/(1+pm_interest(ct,i2))));

*' **Total regional emission costs** include pricing costs and an equal share of
*' the global slack penalty. The slack is a global variable so its penalty is
*' divided by card(i) so that summing over regions yields exactly
*' v56_slack_emis_cap * s56_emis_cap_penalty in the objective.

 q56_emission_costs(i2) ..
  vm_emission_costs(i2) =e=
    sum(emis_source, v56_emission_cost(i2,emis_source))
    + v56_slack_emis_cap * s56_emis_cap_penalty / card(i);

*' CDR reward from afforestation.

 q56_reward_cdr_aff_reg(i2) ..
  vm_reward_cdr_aff(i2) =e=
    sum(cell(i2,j2), v56_reward_cdr_aff(j2));

 q56_reward_cdr_aff(j2) ..
  v56_reward_cdr_aff(j2) =e=
    sum(ct, p56_fader_cpriceaff(ct)) *
    sum(ac,
      (sum(aff_effect,(1-s56_buffer_aff)*vm_cdr_aff(j2,ac,aff_effect)) * sum((cell(i2,j2),ct), p56_c_price_aff(ct,i2,ac)))
      / ((1+sum((cell(i2,j2),ct),pm_interest(ct,i2)))**(ac.off*5)))
    * sum((cell(i2,j2),ct),pm_interest(ct,i2)/(1+pm_interest(ct,i2)));

* ---- cap_apr26: cap constraint with inlined CO2eq ----

*' Global AFOLU cap: CO2eq is computed inline by multiplying vm_emissions_reg
*' by the AR5 GWP factors and the cap scope mask, then summing across all
*' regions, sources and pollutants. This avoids carrying v56_emis_co2eq as
*' an intermediate optimization variable (~2800 extra variables removed).
*' v56_slack_emis_cap prevents hard infeasibility when the biophysical floor
*' exceeds the cap; its level is reported to the platform via postsolve.

 q56_emis_cap ..
  sum((i2,emis_source,pollutants),
    vm_emissions_reg(i2,emis_source,pollutants)
    * p56_gwp(pollutants)
    * p56_cap_mask(emis_source,pollutants))
  =l=
  sum(ct, p56_emis_cap(ct)) + v56_slack_emis_cap;
