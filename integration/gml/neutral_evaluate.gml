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
global.rk_greeting_text = "The call condition is not clear yet."; if (global.rk_language == 1) global.rk_greeting_text = "아직 통화 조건을 확인할 수 없습니다."; global.rk_greeting_status = 0;
if (global.rk_target_greeting == 1) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0))) { } else if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Help the fallen warrior before leaving."; if (global.rk_language == 1) global.rk_greeting_text = "떠나기 전에 쓰러진 전사를 도와주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills == 0))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Do not defeat any monsters."; if (global.rk_language == 1) global.rk_greeting_text = "몬스터를 죽이지 마세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship >= 4))) { } else if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship < 4))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Finish the warrior's friendship."; if (global.rk_language == 1) global.rk_greeting_text = "전사와 우정을 쌓으세요."; }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship >= 10))) { } else if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship < 10))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Finish the letter and date, but do not enter the hidden lab."; if (global.rk_language == 1) global.rk_greeting_text = "편지와 데이트를 마치되 숨겨진 연구소에는 들어가지 마세요."; }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 2) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Reach the chosen exile outcome."; if (global.rk_language == 1) global.rk_greeting_text = "선택한 추방 결말의 조건을 채우세요."; }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 3) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level <= 11))) { } else if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level > 11))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the earlier regional route."; if (global.rk_language == 1) global.rk_greeting_text = "앞선 지역 경로를 유지하세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 1))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 1))) {
if ((global.rk_mettaton_resolved == 1) && gg_blocked == 0 || (global.rk_mettaton_resolved == 1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Defeat the robot before the last battle."; if (global.rk_language == 1) global.rk_greeting_text = "마지막 전투 전에 로봇을 쓰러뜨리세요."; }
if (global.rk_mettaton_resolved == 1) gg_blocked = 1; else gg_action = 1;
if (global.rk_mettaton_resolved < 0) gg_unknown = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Reach the chosen exile outcome."; if (global.rk_language == 1) global.rk_greeting_text = "선택한 추방 결말의 조건을 채우세요."; }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 4) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried == 1))) { } else if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Carry a snowy keepsake in your inventory for the call."; if (global.rk_language == 1) global.rk_greeting_text = "통화할 때 눈으로 된 기념품을 소지하세요."; }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable == 1))) { } else if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "No carried, stored or obtainable keepsake remains in this run."; if (global.rk_language == 1) global.rk_greeting_text = "이번 회차에 소지·보관·획득 가능한 기념품이 남아 있지 않습니다."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 5) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists == 0))) { } else if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Continue without writing a SAVE."; if (global.rk_language == 1) global.rk_greeting_text = "SAVE를 하지 않고 진행하세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 6) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep your starting armor equipped."; if (global.rk_language == 1) global.rk_greeting_text = "처음 방어구를 계속 착용하세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 7) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Avoid healing items, even at full HP."; if (global.rk_language == 1) global.rk_greeting_text = "HP가 가득 차 있어도 회복 아이템을 쓰지 마세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 4 && global.rk_target_neutral != 6) { gg_blocked = 1; global.rk_greeting_text = "Choose a compatible ending type for this call condition."; if (global.rk_language == 1) global.rk_greeting_text = "이 통화 조건과 맞는 결말 유형을 선택하세요."; }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep the required characters alive."; if (global.rk_language == 1) global.rk_greeting_text = "필요한 인물을 살려 주세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Avoid healing items, even at full HP."; if (global.rk_language == 1) global.rk_greeting_text = "HP가 가득 차 있어도 회복 아이템을 쓰지 마세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level == 1))) { } else if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep LV 1 until the call."; if (global.rk_language == 1) global.rk_greeting_text = "통화할 때까지 LV 1을 유지하세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = "Keep your starting armor equipped."; if (global.rk_language == 1) global.rk_greeting_text = "처음 방어구를 계속 착용하세요."; }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8 && (global.rk_target_neutral == 4 || global.rk_target_neutral == 6) && gg_blocked == 0) { gg_unknown = 1; global.rk_greeting_text = "This call condition may not be attainable with this ending type."; if (global.rk_language == 1) global.rk_greeting_text = "이 결말 유형에서는 이 통화 조건에 도달하지 못할 수 있습니다."; }
// Generated source-backed keepsake acquisition/retrieval objectives.
if (global.rk_target_greeting == 4 && global.rk_snowman_piece_carried == 0 && gg_blocked == 0) {
if (global.rk_snowman_piece_available == 1) { global.rk_greeting_text = "Return to the snow figure in the forest and ask for a piece."; if (global.rk_language == 1) global.rk_greeting_text = "숲의 눈으로 된 친구에게 돌아가 조각을 부탁하세요."; }
if (global.rk_snowman_piece_stored == 1) { global.rk_greeting_text = "Retrieve the snowy keepsake from a storage box."; if (global.rk_language == 1) global.rk_greeting_text = "보관함에서 눈으로 된 기념품을 꺼내세요."; }
if ((global.rk_snowman_piece_stored == 1 || global.rk_snowman_piece_available == 1) && global.rk_inventory_space == 0) { global.rk_greeting_text = "Make room in your inventory for the keepsake."; if (global.rk_language == 1) global.rk_greeting_text = "기념품을 넣을 가방 공간을 비우세요."; }
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
    global.rk_objective_text = "This Neutral outcome is blocked in this run.";
    if (global.rk_language == 1) global.rk_objective_text = "이번 회차에서 선택한 뉴트럴 결과가 막혔습니다.";
    if (global.rk_greeting_status == 3) global.rk_objective_text = global.rk_greeting_text;
    return 3;
}
if (unknown) {
    global.rk_objective_text = "Observe the remaining encounters before selecting an outcome.";
    if (global.rk_language == 1) global.rk_objective_text = "남은 조우 상태를 확인하세요.";
    if (global.rk_greeting_status > 0) global.rk_objective_text = global.rk_greeting_text;
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
if (global.rk_target_greeting > 0 && global.rk_greeting_status == 1) global.rk_objective_text = global.rk_greeting_text;
if (action) return 1;
return 0;
