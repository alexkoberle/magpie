*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* ---- Inherited from price_aug22 ----
vm_emission_costs.scale(i) = 1e5;
v56_emission_cost.scale(i,emis_source) = 1e4;
vm_carbon_stock.scale(j,land,c_pools,stockType) = 1e3;
q56_emis_pricing_co2.scale(i,emis_oneoff) = 1e2;

* ---- cap_apr26_ref specific ----
*' CO2eq flows are O(10^2)--O(10^3) Tg CO2eq/yr regionally; 1e2 keeps solver
*' matrix entries close to unity. Slack has the same units as the cap.
v56_emis_co2eq.scale(i,emis_source,pollutants) = 1e2;
v56_slack_emis_cap.scale = 1e2;
