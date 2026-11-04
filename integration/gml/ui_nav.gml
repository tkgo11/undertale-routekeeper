// Generated single-step wrap navigation; count must be positive.
if (argument2 < 1) return 0;
var next; next = argument0 + argument1;
if (next < 0) return argument2 - 1;
if (next >= argument2) return 0;
return next;
