// Generated from NeutralCatalog. Projection if Neutral is reached, not proof of completion.
var t, p, u, m, k, f, stage;
t = global.rk_neutral_toriel_dead; p = global.rk_neutral_papyrus_dead;
u = global.rk_neutral_undyne_dead; m = global.rk_neutral_mettaton_dead;
k = global.rk_kills; f = global.rk_neutral_undyne_friendship; stage = global.rk_murder_level;
if (t < 0 || p < 0 || u < 0 || m < 0 || k < 0 || f < 0 || stage < 0) return -1;
if (stage >= 12 && m == 1) return 18;
if (t == 0) {
    if (p == 1 || u == 1 || k >= 10) {
        if (u == 1) { if (p == 1) return 9; return 8; }
        if (p == 1) return 7;
        return 6;
    }
    if (f > 3 && k == 0) return 1;
    if (k > 0 && f > 0) { if (m == 1) return 5; return 4; }
    if (m == 1) return 3;
    return 2;
}
if (u == 0) { if (p == 1) return 11; return 10; }
if (m == 0) { if (p == 1) return 13; return 12; }
if (p == 0) return 14;
if (k == 4) return 15;
if (k >= 20) return 17;
return 16;
