*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

*' @description This realization implements per-region per-timestep upper bounds
*' on AFOLU GHG emissions (Archetype B, regional variant). Each of the H13 regions
*' has an independent cap trajectory supplied via `f56_emis_cap.cs3`
*' (dimensions: t_all x i x capscen56). Emissions within each region are
*' aggregated to CO2-equivalent using AR5 GWP factors (CH4=28, N2O=265) and
*' constrained by `q56_emis_cap(i)`. The dual variable `q56_emis_cap.m(i)` is
*' the endogenous regional shadow carbon price (mio USD per Tg CO2eq per yr =
*' USD per t CO2eq). A per-region mandatory slack variable `v56_slack_emis_cap(i)`
*' with large penalty cost prevents hard infeasibility; levels are written to
*' `p56_emis_cap_slack(t,i)` for platform signalling.
*'
*' Archetype A overlay: source-specific bounds on `vm_emissions_reg` can be
*' activated by setting `s56_source_bounds_on = 1` and populating
*' `f56_source_bound.cs3`. These tighten the feasible space before each
*' regional cap is applied; they are non-binding (1e6 Tg/yr) by default.
*'
*' Performance: CO2eq is inlined directly into `q56_emis_cap(i)` rather than
*' computed via a separate optimization variable, keeping NLP variable count
*' identical to the `price_aug22` baseline. `ov56_emis_co2eq` is reported as a
*' parameter computed in postsolve from `vm_emissions_reg.l`.
*'
*' The full pricing infrastructure from `price_aug22` is retained for optional
*' use. Default: `im_pollutant_prices = 0` (pure quantity instrument).
*' Afforestation reward is disabled by default (`s56_c_price_induced_aff = 0`).
*'
*' @authors NZB project

*####################### R SECTION START (PHASES) ##############################
$Ifi "%phase%" == "sets"         $include "./modules/56_ghg_policy/cap_apr26_reg/sets.gms"
$Ifi "%phase%" == "declarations" $include "./modules/56_ghg_policy/cap_apr26_reg/declarations.gms"
$Ifi "%phase%" == "input"        $include "./modules/56_ghg_policy/cap_apr26_reg/input.gms"
$Ifi "%phase%" == "equations"    $include "./modules/56_ghg_policy/cap_apr26_reg/equations.gms"
$Ifi "%phase%" == "scaling"      $include "./modules/56_ghg_policy/cap_apr26_reg/scaling.gms"
$Ifi "%phase%" == "preloop"      $include "./modules/56_ghg_policy/cap_apr26_reg/preloop.gms"
$Ifi "%phase%" == "presolve"     $include "./modules/56_ghg_policy/cap_apr26_reg/presolve.gms"
$Ifi "%phase%" == "postsolve"    $include "./modules/56_ghg_policy/cap_apr26_reg/postsolve.gms"
*######################## R SECTION END (PHASES) ###############################
