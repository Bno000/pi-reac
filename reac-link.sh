#!/bin/sh
# reac-link.sh — patch reac-capture ch 1..40 onto the two 20-ch USB gadget sinks.
# Run as the same user reac-pw runs under (PipeWire is per-user).
#
# Usage: reac-link.sh            link
#        reac-link.sh -n         dry run (print pairs only)
#        reac-link.sh -d         unlink
#
# Assumes both gadget cards are on the "pro-audio" profile, so each has
# playback_AUX0..AUX19 ports. Set once per card (WirePlumber remembers it):
#   wpctl status            # note the Device ids of the two gadget cards
#   wpctl set-profile <id> pro-audio   (or the profile's index from `pw-cli e <id> EnumProfile`)

set -eu
MODE=link
case "${1:-}" in -n) MODE=dry;; -d) MODE=unlink;; esac

SRC=$(pw-link -o | grep '^reac-capture' | sort -V)
DST=$(pw-link -i | grep -E 'fe980000|UAC2' | grep -i 'AUX' | sort -V)

ns=$(printf '%s\n' "$SRC" | grep -c . || true)
nd=$(printf '%s\n' "$DST" | grep -c . || true)
echo "reac ports: $ns   gadget ports: $nd"
[ "$ns" -ge 1 ] && [ "$nd" -ge 1 ] || { echo "missing ports — check reac-pw and the gadget"; exit 1; }

printf '%s\n' "$SRC" > /tmp/reac_src.$$
printf '%s\n' "$DST" > /tmp/reac_dst.$$
paste -d'|' /tmp/reac_src.$$ /tmp/reac_dst.$$ | head -n 40 | while IFS='|' read -r s d; do
  [ -n "$s" ] && [ -n "$d" ] || continue
  case $MODE in
    dry)    echo "$s -> $d" ;;
    link)   pw-link "$s" "$d" 2>/dev/null || echo "skip (exists?) $s -> $d" ;;
    unlink) pw-link -d "$s" "$d" 2>/dev/null || true ;;
  esac
done
rm -f /tmp/reac_src.$$ /tmp/reac_dst.$$
