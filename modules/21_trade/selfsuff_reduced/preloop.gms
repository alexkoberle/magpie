*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de


*' Trade liberalization i.e. shift from self-sufficiency fixed pool to free pool begins
*' with sm_fix_SSP2 to keep values matching historical data until then.
loop(t_all,
 if(m_year(t_all) <= sm_fix_SSP2,
 i21_trade_bal_reduction(t_all,h,k_trade)=f21_trade_bal_reduction(t_all,"easytrade","l909090r808080");
 i21_trade_bal_reduction(t_all,h,k_hardtrade21)=f21_trade_bal_reduction(t_all,"hardtrade","l909090r808080");
 else
 i21_trade_bal_reduction(t_all,h,k_trade)=f21_trade_bal_reduction(t_all,"easytrade","%c21_trade_liberalization%");
i21_trade_bal_reduction(t_all,h,k_hardtrade21)=f21_trade_bal_reduction(t_all,"hardtrade","%c21_trade_liberalization%");
 );
);

*' Region mask for the optional self-sufficiency floor (below): a superregion h is
*' eligible only if ALL its countries are in policy_countries21 (forcing self-sufficiency
*' on a partial superregion is not meaningful) -- i.e. every country in every region it
*' contains (supreg(h,i), i_to_iso(i,iso)) is selected; an empty / partially-selected
*' superregion makes it a no-op. Mirrors the region mask in module 56.
p21_country_switch(iso) = 0;
p21_country_switch(policy_countries21) = 1;
p21_selfsuff_region(h) = 1$(sum((supreg(h,i), i_to_iso(i,iso)), 1 - p21_country_switch(iso)) = 0);

*' Optional minimum self-sufficiency floor: for the commodities in forcesuff21 (empty by
*' default) and the fully-selected regions in policy_countries21, hold self-sufficiency at
*' (s21_forcesuff_value x) its 2025 baseline level from sm_fix_SSP2 onwards, enforced by
*' q21_min_selfsuff. The floor tracks the input f21_self_suff (constant over time), so it
*' holds each commodity's 2025 export/import intensity. This subsumes the former wood-only
*' switch: to force wood/woodfuel self-sufficiency simply include them in forcesuff21.
*' s21_forcesuff_value = 1 freezes exactly at 2025; < 1 allows some erosion. Empty
*' forcesuff21 / s21_force_selfsuff = 0 keeps develop behaviour unchanged.
i21_min_selfsuff(t_all,h,k_trade) = 0;
i21_min_selfsuff(t_all,h,forcesuff21)$(s21_force_selfsuff = 1 AND p21_selfsuff_region(h) AND m_year(t_all) > sm_fix_SSP2) = s21_forcesuff_value * f21_self_suff(t_all,h,forcesuff21);

i21_exports(t_all,h,k_trade) =  ((f21_self_suff(t_all,h,k_trade) * f21_dom_supply(t_all,h,k_trade)) - f21_dom_supply(t_all,h,k_trade))$(f21_self_suff(t_all,h,k_trade) > 1);
i21_exp_glo(t_all,k_trade) = sum(h, i21_exports(t_all,h,k_trade));
i21_exp_shr(t_all,h,k_trade) = i21_exports(t_all,h,k_trade) / (i21_exp_glo(t_all,k_trade) +  0.001$(i21_exp_glo(t_all,k_trade) = 0));

i21_trade_margin(h,k_trade) = f21_trade_margin(h,k_trade);

if ((s21_trade_tariff=1),
    i21_trade_tariff(h,k_trade) = f21_trade_tariff(h,k_trade);
elseif (s21_trade_tariff=0),
    i21_trade_tariff(h,k_trade) = 0;
);

i21_trade_margin(h,"wood")$(i21_trade_margin(h,"wood") < s21_min_trade_margin_forestry) = s21_min_trade_margin_forestry;
i21_trade_margin(h,"woodfuel")$(i21_trade_margin(h,"woodfuel") < s21_min_trade_margin_forestry) = s21_min_trade_margin_forestry;

v21_import_for_feasibility.fx(h,k_trade) = 0;
v21_import_for_feasibility.lo(h,k_import21) = 0;
v21_import_for_feasibility.up(h,k_import21) = Inf;
