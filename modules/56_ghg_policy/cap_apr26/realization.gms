*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

*' @description This realization implements a hard per-timestep upper bound on
*' total AFOLU GHG emissions (Archetype B), with an optional source-specific
*' bound overlay (Archetype A). Emissions from all sources covered by
*' `c56_cap_policy` are aggregated to CO2-equivalent using AR5 GWP factors
*' (CH4=28, N2O=265) and constrained by the exogenous trajectory in
*' `f56_emis_cap.csv`. The dual variable of the cap constraint (`q56_emis_cap.m`)
*' is the endogenous shadow carbon price (mio USD per Tg CO2eq per yr =
*' USD per t CO2eq). A mandatory slack variable `v56_slack_emis_cap` with a
*' large penalty cost prevents hard infeasibility when the cap is tighter than
*' the biophysical emission floor; its level is reported so the calling platform
*' can detect infeasible allocations.
*'
*' Archetype A overlay: source-specific bounds on `vm_emissions_reg` can be
*' activated by populating `f56_source_bound.cs3` and setting
*' `s56_source_bounds_on = 1`. These bounds tighten the feasible space before
*' the aggregate cap is applied; they are non-binding (1e6 Tg/yr) by default.
*'
*' This realization retains the full pricing infrastructure from `price_aug22`
*' for optional use. The default configuration sets `im_pollutant_prices = 0`
*' (pure quantity instrument). Setting `c56_pollutant_prices` to a non-"none"
*' scenario activates a price floor alongside the cap.
*' Afforestation reward is disabled by default (`s56_c_price_induced_aff = 0`);
*' set it to 1 and provide a C-price trajectory to re-enable.
*'
*' Performance note: CO2eq aggregation is inlined directly into `q56_emis_cap`
*' rather than carried as an intermediate optimization variable. This removes
*' ~2800 variables and equations from the NLP solved at each timestep.
*' Per-(region,source,pollutant) CO2eq levels are still reported in postsolve
*' as a parameter assignment. See `cap_apr26_ref` for the reference version
*' that carries `v56_emis_co2eq` as an explicit optimization variable.
*'
*' @authors NZB project

*####################### R SECTION START (PHASES) ##############################
$Ifi "%phase%" == "sets"         $include "./modules/56_ghg_policy/cap_apr26/sets.gms"
$Ifi "%phase%" == "declarations" $include "./modules/56_ghg_policy/cap_apr26/declarations.gms"
$Ifi "%phase%" == "input"        $include "./modules/56_ghg_policy/cap_apr26/input.gms"
$Ifi "%phase%" == "equations"    $include "./modules/56_ghg_policy/cap_apr26/equations.gms"
$Ifi "%phase%" == "scaling"      $include "./modules/56_ghg_policy/cap_apr26/scaling.gms"
$Ifi "%phase%" == "preloop"      $include "./modules/56_ghg_policy/cap_apr26/preloop.gms"
$Ifi "%phase%" == "presolve"     $include "./modules/56_ghg_policy/cap_apr26/presolve.gms"
$Ifi "%phase%" == "postsolve"    $include "./modules/56_ghg_policy/cap_apr26/postsolve.gms"
*######################## R SECTION END (PHASES) ###############################
