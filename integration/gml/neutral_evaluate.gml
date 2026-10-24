// Generated from NeutralCatalog target table and evaluation policy.
var nt, blocked, unknown, action, k, stage, friend, min_kills, max_kills, matched, total;
nt = global.rk_target_neutral; blocked = 0; unknown = 0; action = 0;
k = global.rk_kills; stage = global.rk_murder_level; friend = global.rk_neutral_undyne_friendship;
min_kills = 0; max_kills = -1; matched = 0; total = 0;
global.rk_neutral_friendship_min = 0;
global.rk_objective_text = "";
global.rk_neutral_keep_toriel = -1; global.rk_neutral_keep_papyrus = -1;
global.rk_neutral_keep_undyne = -1; global.rk_neutral_keep_mettaton = -1;
if (nt < 0 || nt >= 19) return 4;
if (nt == 0) {
global.rk_neutral_friendship_min = 0;
min_kills = 0; max_kills = -1;
}
if (nt == 1) {
global.rk_neutral_friendship_min = 4;
min_kills = 0; max_kills = 0;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 1;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 0) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 2) {
global.rk_neutral_friendship_min = 0;
min_kills = 0; max_kills = 9;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 1;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 0) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 3) {
global.rk_neutral_friendship_min = 0;
min_kills = 1; max_kills = 9;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 4) {
global.rk_neutral_friendship_min = 1;
min_kills = 1; max_kills = 9;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 1;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 0) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 5) {
global.rk_neutral_friendship_min = 1;
min_kills = 1; max_kills = 9;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 6) {
global.rk_neutral_friendship_min = 0;
min_kills = 10; max_kills = -1;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 7) {
global.rk_neutral_friendship_min = 0;
min_kills = 1; max_kills = -1;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 8) {
global.rk_neutral_friendship_min = 0;
min_kills = 1; max_kills = -1;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 9) {
global.rk_neutral_friendship_min = 0;
min_kills = 2; max_kills = -1;
global.rk_neutral_keep_toriel = 1;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 0) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 10) {
global.rk_neutral_friendship_min = 0;
min_kills = 1; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 11) {
global.rk_neutral_friendship_min = 0;
min_kills = 2; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 1;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 0) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 12) {
global.rk_neutral_friendship_min = 0;
min_kills = 2; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 1;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 0) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 13) {
global.rk_neutral_friendship_min = 0;
min_kills = 3; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 1;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 0) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 14) {
global.rk_neutral_friendship_min = 0;
min_kills = 3; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 1;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 0) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 15) {
global.rk_neutral_friendship_min = 0;
min_kills = 4; max_kills = 4;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 16) {
global.rk_neutral_friendship_min = 0;
min_kills = 5; max_kills = 19;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 17) {
global.rk_neutral_friendship_min = 0;
min_kills = 20; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
if (nt == 18) {
global.rk_neutral_friendship_min = 0;
min_kills = 4; max_kills = -1;
global.rk_neutral_keep_toriel = 0;
total += 1;
if (global.rk_neutral_toriel_dead < 0) unknown = 1;
else if (global.rk_neutral_toriel_dead != 1) {
if (global.rk_neutral_toriel_dead == 1 || global.rk_toriel_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_toriel_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_papyrus = 0;
total += 1;
if (global.rk_neutral_papyrus_dead < 0) unknown = 1;
else if (global.rk_neutral_papyrus_dead != 1) {
if (global.rk_neutral_papyrus_dead == 1 || global.rk_papyrus_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_papyrus_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_undyne = 0;
total += 1;
if (global.rk_neutral_undyne_dead < 0) unknown = 1;
else if (global.rk_neutral_undyne_dead != 1) {
if (global.rk_neutral_undyne_dead == 1 || global.rk_undyne_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_undyne_resolved < 0) unknown = 1; }
} else matched += 1;
global.rk_neutral_keep_mettaton = 0;
total += 1;
if (global.rk_neutral_mettaton_dead < 0) unknown = 1;
else if (global.rk_neutral_mettaton_dead != 1) {
if (global.rk_neutral_mettaton_dead == 1 || global.rk_mettaton_resolved == 1) blocked = 1;
else { action = 1; if (global.rk_mettaton_resolved < 0) unknown = 1; }
} else matched += 1;
}
global.rk_neutral_kill_cap = max_kills;
if (global.rk_hard_mode < 0 || global.rk_world_erased < 0 || global.rk_true_lab_completed < 0) unknown = 1;
if (global.rk_hard_mode == 1 || global.rk_world_erased == 1) blocked = 1;
if (stage < 0) unknown = 1;
else if (stage >= 16) blocked = 1;
if (global.rk_true_lab_completed == 1) blocked = 1;
if (k < 0) unknown = 1;
else if (max_kills >= 0 && k > max_kills) blocked = 1;
else if (k < min_kills) action = 1;
if (nt >= 1 && nt <= 5) {
    if (friend < 0) unknown = 1;
    else if (nt == 1 && friend < 4) {
        if (k > 0 || global.rk_water_opportunity_missed == 1) blocked = 1;
        else action = 1;
    }
    else if ((nt == 2 || nt == 3) && friend > 0 && k > 0) blocked = 1;
    else if ((nt == 2 || nt == 3) && friend > 3) blocked = 1;
    else if ((nt == 4 || nt == 5) && friend <= 0) {
        if (k > 0 || global.rk_water_opportunity_missed == 1) blocked = 1;
        else action = 1;
    }
}
if (nt == 18) {
    if (stage >= 0 && stage < 12) {
        if (global.rk_undyne_resolved == 1) blocked = 1;
        else action = 1;
    }
}
else if (global.rk_neutral_keep_mettaton == 0 && stage >= 12) blocked = 1;
global.rk_progress_met = matched;
global.rk_progress_total = total;
if (blocked) {
    global.rk_objective_text = "This Neutral outcome is blocked in this run.";
    if (global.rk_language == 1) global.rk_objective_text = "이번 회차에서 선택한 뉴트럴 결과가 막혔습니다.";
    return 3;
}
if (unknown) {
    global.rk_objective_text = "Observe the remaining encounters before selecting an outcome.";
    if (global.rk_language == 1) global.rk_objective_text = "남은 조우 상태를 확인하세요.";
    return 4;
}
global.rk_objective_text = "Continue while preserving the selected encounter outcomes.";
if (global.rk_language == 1) global.rk_objective_text = "선택한 조우 결과를 유지하며 진행하세요.";
if (nt == 1 && friend < 4) {
    global.rk_objective_text = "Befriend the warrior without gaining EXP.";
    if (global.rk_language == 1) global.rk_objective_text = "EXP 없이 전사와 우정을 쌓으세요.";
}
if ((nt == 4 || nt == 5) && friend <= 0) {
    global.rk_objective_text = "Start the warrior's friendship before additional kills.";
    if (global.rk_language == 1) global.rk_objective_text = "추가 처치 전에 전사와 우정을 시작하세요.";
}
if (nt == 18 && stage < 12) {
    global.rk_objective_text = "Maintain the regional route through Waterfall.";
    if (global.rk_language == 1) global.rk_objective_text = "워터폴까지 지역 경로 조건을 지키세요.";
}
if (action) return 1;
return 0;
