// Generated from NeutralCatalog target table and evaluation policy.
var nt, blocked, unknown, action, k, stage, friend, min_kills, max_kills, matched, total, reserved;
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
// Generated from NeutralGoals; 0 on track,1 action,3 blocked,4 unknown.
var gg_blocked, gg_unknown, gg_action, gg_met;
gg_blocked = 0; gg_unknown = 0; gg_action = 0;
global.rk_greeting_text = scr_routekeeper_text("guidance.the_call_condition_is_not_clear_yet",global.rk_language); global.rk_greeting_status = 0;
if (global.rk_target_greeting == 1) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0))) { } else if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.help_the_fallen_warrior_before_leaving",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills == 0))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.do_not_defeat_any_monsters",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship >= 4))) { } else if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship < 4))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.finish_the_warrior_s_friendship",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship >= 10))) { } else if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship < 10))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.finish_the_letter_and_date_but_do_not_enter",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 2) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.reach_the_chosen_exile_outcome",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 3) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level <= 11))) { } else if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level > 11))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_earlier_regional_route",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 1))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 1))) {
if ((global.rk_mettaton_resolved == 1) && gg_blocked == 0 || (global.rk_mettaton_resolved == 1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.defeat_the_robot_before_the_last_battle",global.rk_language); }
if (global.rk_mettaton_resolved == 1) gg_blocked = 1; else gg_action = 1;
if (global.rk_mettaton_resolved < 0) gg_unknown = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.reach_the_chosen_exile_outcome",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 4) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried == 1))) { } else if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.carry_a_snowy_keepsake_in_your_inventory_for_the",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable == 1))) { } else if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.no_carried_stored_or_obtainable_keepsake_remains_in_this",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 5) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists == 0))) { } else if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.continue_without_writing_a_save",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 6) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_your_starting_armor_equipped",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 7) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.avoid_healing_items_even_at_full_hp",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 4 && global.rk_target_neutral != 6) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.avoid_healing_items_even_at_full_hp",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level == 1))) { } else if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_lv_1_until_the_call",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_your_starting_armor_equipped",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8 && global.rk_target_neutral == 6 && gg_blocked == 0) { gg_unknown = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.this_call_condition_may_not_be_attainable_with_this",global.rk_language); }
// Generated source-backed keepsake acquisition/retrieval objectives.
if (global.rk_target_greeting == 4 && global.rk_snowman_piece_carried == 0 && gg_blocked == 0) {
if (global.rk_snowman_piece_available == 1) { global.rk_greeting_text = scr_routekeeper_text("guidance.return_to_the_snow_figure_in_the_forest_and",global.rk_language); }
if (global.rk_snowman_piece_stored == 1) { global.rk_greeting_text = scr_routekeeper_text("guidance.retrieve_the_snowy_keepsake_from_a_storage_box",global.rk_language); }
if ((global.rk_snowman_piece_stored == 1 || global.rk_snowman_piece_available == 1) && global.rk_inventory_space == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.make_room_in_your_inventory_for_the_keepsake",global.rk_language); }
}
if (gg_action) global.rk_greeting_status = 1;
if (gg_unknown) global.rk_greeting_status = 4;
if (gg_blocked) global.rk_greeting_status = 3;
if (global.rk_target_greeting == 1) { global.rk_neutral_friendship_min = 4; max_kills = 0; }
if (global.rk_target_greeting == 1 || global.rk_target_greeting == 2 || global.rk_target_greeting == 3) global.rk_neutral_keep_toriel = 1;
if (global.rk_target_greeting == 1 || global.rk_target_greeting >= 4) global.rk_neutral_keep_papyrus = 1;
if (global.rk_target_greeting >= 1 && global.rk_target_greeting <= 3) global.rk_neutral_keep_undyne = 1;
if (global.rk_target_greeting == 1 || global.rk_target_greeting == 2) global.rk_neutral_keep_mettaton = 1;
if (global.rk_target_greeting == 3) global.rk_neutral_keep_mettaton = 0;
global.rk_neutral_kill_cap = max_kills;
reserved = 0;
if (global.rk_neutral_keep_toriel == 0 && global.rk_neutral_toriel_dead == 0) reserved += 1;
if (global.rk_neutral_keep_papyrus == 0 && global.rk_neutral_papyrus_dead == 0) reserved += 1;
if (global.rk_neutral_keep_undyne == 0 && global.rk_neutral_undyne_dead == 0) reserved += 1;
if (global.rk_neutral_keep_mettaton == 0 && global.rk_neutral_mettaton_dead == 0) reserved += 1;
if (max_kills >= 0 && k >= 0 && k + reserved > max_kills) blocked = 1;
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
if (global.rk_target_greeting > 0) {
    total += 1;
    if (global.rk_greeting_status == 0) matched += 1;
    if (global.rk_greeting_status == 1) action = 1;
    if (global.rk_greeting_status == 4) unknown = 1;
    if (global.rk_greeting_status == 3) blocked = 1;
}
global.rk_progress_met = matched;
global.rk_progress_total = total;
if (blocked) {
    global.rk_objective_text = scr_routekeeper_text("guidance.this_neutral_outcome_is_blocked_in_this_run",global.rk_language);
    if (global.rk_greeting_status == 3) global.rk_objective_text = global.rk_greeting_text;
    return 3;
}
if (unknown) {
    global.rk_objective_text = scr_routekeeper_text("guidance.observe_the_remaining_encounters_before_selecting_an_outcome",global.rk_language);
    if (global.rk_greeting_status > 0) global.rk_objective_text = global.rk_greeting_text;
    return 4;
}
global.rk_objective_text = scr_routekeeper_text("guidance.continue_while_preserving_the_selected_encounter_outcomes",global.rk_language);
if (nt == 1 && friend < 4) {
    global.rk_objective_text = scr_routekeeper_text("guidance.befriend_the_warrior_without_gaining_exp",global.rk_language);
}
if ((nt == 4 || nt == 5) && friend <= 0) {
    global.rk_objective_text = scr_routekeeper_text("guidance.start_the_warrior_s_friendship_before_additional_kills",global.rk_language);
}
if (nt == 18 && stage < 12) {
    global.rk_objective_text = scr_routekeeper_text("guidance.maintain_the_regional_route_through_waterfall",global.rk_language);
}
if (global.rk_target_greeting > 0 && global.rk_greeting_status == 1) global.rk_objective_text = global.rk_greeting_text;
if (action) return 1;
return 0;
