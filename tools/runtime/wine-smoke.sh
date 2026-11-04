#!/bin/sh
# Historical Wine experiment is retained in Git history. This entry cannot launch
# Steam/game or write a profile: the current task requires native safety gates.
printf '%s\n' 'RETIRED_LEGACY_RUNTIME: Wine gameplay execution is disabled; use the guarded native human-testing workflow.' >&2
exit 2
