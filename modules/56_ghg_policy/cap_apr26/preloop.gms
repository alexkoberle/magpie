*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* ---- Inherited pricing infrastructure initialisation ----
* (Kept verbatim from price_aug22 so optional price-floor mode works correctly)

pcm_carbon_stock(j,land,ag_pools,stockType) = fm_carbon_density("y1995",j,land,ag_pools)*pcm_land(j,land);
vm_carbon_stock.l(j,land,ag_pools,stockType) = pcm_carbon_stock(j,land,ag_pools,stockType);

v56_emis_pricing.fx(i,emis_oneoff,pollutants)$(not sameas(pollutants,"co2_c")) = 0;

p56_country_switch(iso) = 0;
p56_country_switch(policy_countries56) = 1;
p56_region_price_shr(t_all,i) = sum(i_to_iso(i,iso), p56_country_switch(iso) * im_pop_iso(t_all,iso))
                                / sum(i_to_iso(i,iso), im_pop_iso(t_all,iso));

p56_country_switch2(iso) = 0;
p56_country_switch2(fader_countries56) = 1;
p56_region_fader_shr(t_all,i) = sum(i_to_iso(i,iso), p56_country_switch2(iso) * im_pop_iso(t_all,iso))
                                / sum(i_to_iso(i,iso), im_pop_iso(t_all,iso));

$ifthen "%c56_pollutant_prices%" == "none"
 im_pollutant_prices(t_all,i,pollutants,emis_source) = 0;
$elseif "%c56_pollutant_prices%" == "coupling"
 im_pollutant_prices(t_all,i,pollutants,emis_source) = f56_pollutant_prices_coupling(t_all,i,pollutants);
$else
 im_pollutant_prices(t_all,i,pollutants,emis_source) =
   f56_pollutant_prices(t_all,i,pollutants,"%c56_pollutant_prices%") * p56_region_price_shr(t_all,i)
 + f56_pollutant_prices(t_all,i,pollutants,"%c56_pollutant_prices_noselect%") * (1-p56_region_price_shr(t_all,i));
$endif

p56_pollutant_prices_input(t_all,i,pollutants,emis_source) = im_pollutant_prices(t_all,i,pollutants,emis_source);

im_pollutant_prices(t_all,i,pollutants,emis_source)$(s56_ghgprice_devstate_scaling = 1) =
  im_pollutant_prices(t_all,i,pollutants,emis_source) * im_development_state(t_all,i);

if (s56_fader_functional_form = 1,
  m_linear_time_interpol(p56_fader,s56_fader_start,s56_fader_end,0,s56_fader_target);
elseif s56_fader_functional_form = 2,
  m_sigmoid_time_interpol(p56_fader,s56_fader_start,s56_fader_end,0,s56_fader_target);
);

* s56_c_price_induced_aff = 0 by default in cap mode (audit recommendation option ii)
m_linear_time_interpol(p56_fader_cpriceaff,s56_fader_cpriceaff_start,s56_fader_cpriceaff_end,0,s56_c_price_induced_aff);

p56_fader_reg(t_all,i) = p56_fader(t_all) * p56_region_fader_shr(t_all,i)
                        + p56_fader(t_all) * (1 - p56_region_fader_shr(t_all,i));
im_pollutant_prices(t_all,i,pollutants_fader,emis_source)$(s56_ghgprice_fader = 1) =
  im_pollutant_prices(t_all,i,pollutants_fader,emis_source) * p56_fader_reg(t_all,i);

im_pollutant_prices(t_all,i,"co2_c",emis_source) =
  im_pollutant_prices(t_all,i,"co2_c",emis_source) * s56_cprice_red_factor;

im_pollutant_prices(t_all,i,pollutants,emis_source)$(m_year(t_all) <= sm_fix_SSP2) = 0;
im_pollutant_prices(t_all,i,pollutants,emis_source)$(m_year(t_all) > sm_fix_SSP2
  AND m_year(t_all) <= max(m_year("%c56_mute_ghgprices_until%"),s56_fader_start*s56_ghgprice_fader)) = 0;
im_pollutant_prices(t_all,i,"co2_c",emis_source)$(
  im_pollutant_prices(t_all,i,"co2_c",emis_source) < s56_minimum_cprice) = s56_minimum_cprice;

im_pollutant_prices(t_all,i,"ch4",emis_source)$(
  im_pollutant_prices(t_all,i,"ch4",emis_source) > s56_limit_ch4_n2o_price*12/44*28) =
  s56_limit_ch4_n2o_price*12/44*28;
im_pollutant_prices(t_all,i,"n2o_n_direct",emis_source)$(
  im_pollutant_prices(t_all,i,"n2o_n_direct",emis_source) > s56_limit_ch4_n2o_price*12/44*265*44/28) =
  s56_limit_ch4_n2o_price*12/44*265*44/28;
im_pollutant_prices(t_all,i,"n2o_n_indirect",emis_source)$(
  im_pollutant_prices(t_all,i,"n2o_n_indirect",emis_source) > s56_limit_ch4_n2o_price*12/44*265*44/28) =
  s56_limit_ch4_n2o_price*12/44*265*44/28;

loop(t_all,
 if(m_year(t_all) <= sm_fix_SSP2,
  im_pollutant_prices(t_all,i,pollutants,emis_source) =
    im_pollutant_prices(t_all,i,pollutants,emis_source) * f56_emis_policy("reddnatveg_nosoil",pollutants,emis_source);
 else
  im_pollutant_prices(t_all,i,pollutants,emis_source) =
    im_pollutant_prices(t_all,i,pollutants,emis_source) * f56_emis_policy("%c56_emis_policy%",pollutants,emis_source);
 );
);

loop(t_all$(m_year(t_all) > max(m_year("%c56_mute_ghgprices_until%"),s56_fader_start*s56_ghgprice_fader)),
  im_pollutant_prices(t_all,i,"co2_c",emis_source)$(im_pollutant_prices(t_all,i,"co2_c",emis_source) = 0) =
    im_pollutant_prices(t_all-1,i,"co2_c",emis_source);
);
loop(t,
 s56_timesteps = m_yeardiff(t)/5;
  if (s56_timesteps > 1,
   s56_counter = 0;
    repeat(
       s56_counter = s56_counter + 1;
       s56_offset = s56_timesteps-s56_counter;
       im_pollutant_prices(t_all-s56_offset,i,"co2_c",emis_source)$(m_year(t_all) = m_year(t)) =
       im_pollutant_prices(t-1,i,"co2_c",emis_source) +
       (im_pollutant_prices(t,i,"co2_c",emis_source) - im_pollutant_prices(t-1,i,"co2_c",emis_source))
       *s56_counter/(s56_timesteps);
    until s56_counter = s56_timesteps-1);
  );
);

p56_c_price_aff(t_all,i,ac) = im_pollutant_prices(t_all,i,"co2_c","%c56_cprice_aff%");
p56_c_price_aff(t_all,i,ac)$(ord(t_all)+ac.off<card(t_all)) = p56_c_price_aff(t_all+ac.off,i,"ac0");
ac_exp(ac)$(ac.off = s56_c_price_exp_aff/5) = yes;
p56_c_price_aff(t_all,i,ac)$(ac.off >= s56_c_price_exp_aff/5) = sum(ac_exp, p56_c_price_aff(t_all,i,ac_exp));
p56_c_price_aff(t_all,i,ac)$(m_year(t_all) <= max(m_year("%c56_mute_ghgprices_until%"),
  s56_fader_start*s56_ghgprice_fader)) = 0;

* ---- cap_apr26: GWP factors (AR5, consistent with price_aug22 lines 78-82) ----
*' AR5 WG1 CH08 Table 8.7: CH4=28, N2O=265 (100-yr GWP).
*' Non-GHG nitrogen loss forms (nh3_n, no2_n, no3_n) have GWP=0 for CO2eq.
*' co2_c is in Tg C; multiply by 44/12 to get Tg CO2.
p56_gwp(pollutants) = 0;
p56_gwp("co2_c")          = 44/12;
p56_gwp("ch4")            = 28;
p56_gwp("n2o_n_direct")   = 265 * 44/28;
p56_gwp("n2o_n_indirect") = 265 * 44/28;

* ---- cap_apr26: cap policy scope mask ----
*' Mirror of f56_emis_policy for the cap: sources with mask=0 contribute zero
*' CO2eq to the cap constraint via q56_emis_co2eq in equations.gms.
p56_cap_mask(emis_source,pollutants) =
  f56_emis_policy("%c56_cap_policy%",pollutants,emis_source);

* ---- cap_apr26: load cap trajectory ----
*' Set cap to non-binding (1e6) for all periods; override future periods
*' with the chosen scenario. Cap never binds before s56_emis_cap_start.
p56_emis_cap(t_all) = 1e6;
$ifthen not "%c56_emis_cap_scenario%" == "none"
  p56_emis_cap(t_all) = f56_emis_cap(t_all,"%c56_emis_cap_scenario%");
$endif
* Historic and pre-start periods are always non-binding
p56_emis_cap(t_all)$(m_year(t_all) <= sm_fix_SSP2) = 1e6;
p56_emis_cap(t_all)$(m_year(t_all) > sm_fix_SSP2 AND m_year(t_all) < s56_emis_cap_start) = 1e6;

* ---- cap_apr26: initialise source bounds ----
*' f56_source_bound is 0 for unset entries (empty file). Convert to 1e6.
*' Any non-zero file value is treated as an actual bound (Tg/yr native units).
f56_source_bound(t_all,i,emis_source)$(f56_source_bound(t_all,i,emis_source) = 0) = 1e6;
