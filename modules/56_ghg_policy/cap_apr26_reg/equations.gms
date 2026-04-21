*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

*' @equations

* ---- Inherited from price_aug22 (unchanged) ----

 q56_emis_pricing(i2,pollutants,emis_annual) ..
  v56_emis_pricing(i2,emis_annual,pollutants) =e=
    vm_emissions_reg(i2,emis_annual,pollutants);

 q56_emis_pricing_co2(i2,emis_oneoff) ..
  v56_emis_pricing(i2,emis_oneoff,"co2_c") =e=
    sum((cell(i2,j2),emis_land(emis_oneoff,land,c_pools)),
      (pcm_carbon_stock(j2,land,c_pools,"actual")
       - vm_carbon_stock(j2,land,c_pools,"%c56_carbon_stock_pricing%"))
      / m_timestep_length);

 q56_emission_cost_annual(i2,emis_annual) ..
  v56_emission_cost(i2,emis_annual) =e=
    sum(pollutants,
      v56_emis_pricing(i2,emis_annual,pollutants)
      * sum(ct, im_pollutant_prices(ct,i2,pollutants,emis_annual)));

 q56_emission_cost_oneoff(i2,emis_oneoff) ..
  v56_emission_cost(i2,emis_oneoff) =e=
    sum(pollutants,
      v56_emis_pricing(i2,emis_oneoff,pollutants)
      * m_timestep_length
      * sum(ct,
          im_pollutant_prices(ct,i2,pollutants,emis_oneoff)
          * pm_interest(ct,i2) / (1 + pm_interest(ct,i2))));

*' **Total regional emission costs** include the pricing cost plus a per-region
*' penalty for any slack used to absorb infeasibility. Each region bears only
*' its own slack cost, so the penalty does not cross regional boundaries.

 q56_emission_costs(i2) ..
  vm_emission_costs(i2) =e=
    sum(emis_source, v56_emission_cost(i2,emis_source))
    + v56_slack_emis_cap(i2) * s56_emis_cap_penalty;

 q56_reward_cdr_aff_reg(i2) ..
  vm_reward_cdr_aff(i2) =e=
    sum(cell(i2,j2), v56_reward_cdr_aff(j2));

 q56_reward_cdr_aff(j2) ..
  v56_reward_cdr_aff(j2) =e=
    sum(ct, p56_fader_cpriceaff(ct))
    * sum(ac,
        (sum(aff_effect, (1 - s56_buffer_aff) * vm_cdr_aff(j2,ac,aff_effect))
         * sum((cell(i2,j2),ct), p56_c_price_aff(ct,i2,ac)))
        / ((1 + sum((cell(i2,j2),ct), pm_interest(ct,i2)))**(ac.off * 5)))
    * sum((cell(i2,j2),ct), pm_interest(ct,i2) / (1 + pm_interest(ct,i2)));

* ---- cap_apr26_reg: per-region AFOLU emissions cap (Archetype B) ----
*' For each region i2, the sum of CO2-equivalent emissions from all sources
*' covered by `p56_cap_mask` must not exceed the regional cap `p56_emis_cap(ct,i2)`
*' plus the slack `v56_slack_emis_cap(i2)`. CO2eq conversion is inlined here
*' using AR5 GWP factors stored in `p56_gwp` — no intermediate optimization
*' variable is needed, keeping the NLP size identical to `price_aug22`.
*' The dual variable `q56_emis_cap.m(i)` is the endogenous regional shadow price
*' (mio USD17MER per Tg CO2eq per yr = USD per t CO2eq).

 q56_emis_cap(i2) ..
  sum((emis_source,pollutants),
    vm_emissions_reg(i2,emis_source,pollutants)
    * p56_gwp(pollutants)
    * p56_cap_mask(emis_source,pollutants))
  =l=
  sum(ct, p56_emis_cap(ct,i2)) + v56_slack_emis_cap(i2);
