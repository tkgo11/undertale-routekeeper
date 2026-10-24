// Generated from DecisionPolicy. Source-level policy, not runtime certification.
// args: family,action,enemy,xpRisk,ruins,snowdin,waterfall,hotland,waterPending,neutralOutcome,killCap,requiredEncounter,epilogueMismatch,regionalPrerequisitesMissing,neutralFriendshipPending,lastSnowdrakeOpportunity.
if (argument0 == 1 && argument1 == 1 && argument3 == 1 && argument15 == 1) return 11;
if (argument0 == 2 && argument1 == 1 && argument3 == 1 && argument14 == 1) return 10;
if (argument0 == 2 && argument1 == 4 && argument8 == 1 && argument14 == 1) return 2;
if (argument0 == 0 && argument1 == 6 && argument12 == 1) return 9;
if (argument0 == 0 && argument1 == 1 && argument3 == 1) return 1;
if (argument0 == 0 && argument1 == 4 && argument8 == 1) return 2;
if (argument0 == 1 && argument1 == 1 && argument2 == 1 && argument4 < 19) return 3;
if (argument0 == 1 && argument1 == 1 && argument2 == 2 && argument5 < 16) return 3;
if (argument0 == 1 && argument1 == 1 && argument2 == 5 && argument6 < 18) return 3;
if (argument0 == 1 && argument1 == 1 && argument2 == 8 && argument6 < 18) return 3;
if (argument0 == 1 && argument1 == 1 && argument2 == 7 && argument7 < 40) return 3;
if (argument0 == 1 && argument1 == 5 && argument2 == 1 && argument4 < 19) return 3;
if (argument0 == 1 && argument1 == 5 && argument2 == 2 && argument5 < 16) return 3;
if (argument0 == 1 && argument1 == 5 && argument2 == 8 && argument6 < 18) return 3;
if (argument0 == 1 && argument1 == 5 && argument2 == 7 && argument7 < 40) return 3;
if (argument0 == 1 && argument1 == 5 && argument13 == 1) return 8;
if (argument0 == 1 && argument1 == 2 && argument11 == 1) return 4;
if (argument0 == 1 && argument1 == 3 && argument11 == 1) return 4;
if (argument0 == 2 && argument1 == 1 && argument9 == 1) return 5;
if (argument0 == 2 && argument1 == 2 && argument9 == -1) return 6;
if (argument0 == 2 && argument1 == 1 && argument10 == 1 && argument3 == 1) return 7;
return 0;
