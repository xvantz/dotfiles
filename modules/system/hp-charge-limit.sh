#!/usr/bin/env bash
# HP Victus 16-e1xxx charge limiter.
#
# Stock firmware charges to 17.5 V = 4.38 V/cell. The cells are 3.85 V-nominal
# Li-HV (15.4 V / 4), so that is in spec, but it is the ceiling where electrolyte
# oxidation and gas generation peak - the reason the previous pack swelled.
# This holds the pack near 4.05 V/cell instead.
#
# Subcommands:
#   tick      (default) one control pass, run by the timer
#   shutdown  best effort before poweroff: inhibit, so an off-but-plugged-in
#             laptop does not charge to the ceiling
#   status    read-only: EC charge mode, pack state, last logged rows
#   auto      allow normal charging (travel: fill the pack before a flight)
#   inhibit   stop charging
#   selftest  validate the command strings arithmetically; touches no hardware
#
# PROTOCOL - this board, read out of its own DSDT (/sys/firmware/acpi/tables):
#
#   Method (GBCC, 0)   command 0x1F read   - charge control via EC MBDC
#   Method (SBCC, 4)   command 0x1F write  - charge control via EC MBDC
#   Method (GBCO, 0)   command 0x2B read   - charge mode via EC BDVO   <- we use this
#   Method (SBCO, 4)   command 0x2B write  - charge mode via EC BDVO   <- and this
#
# SBCO takes (Arg0, Arg1, Arg2, Arg3) and maps Arg1 to an EC BDVO value:
#   0 -> 0x40 auto        1 -> 0x41 (needs AC)      2 -> 0x42
#   3 -> 0x43 (needs AC)  4 -> 0x44                 5 -> 0x45 INHIBIT
#   6 -> 0x46             7 -> 0x47 + STOE (storage/ship - never touched)
# After writing it waits for BDVO bit 7 (done) and reports the outcome in the
# reply's status byte: 0 OK, 0x03 bad Arg1, 0x34 precondition unmet, 0x35 no AC,
# 0x36 transition refused. GBCO reports 4 when BDVO reads 0xC5, else 0.
#
# The SBCC/MBDC pair takes a completely different model (Arg1 in 1..2 via a
# 20-byte buffer on other HP boards) and refused our writes here - dmesg said
# "\_SB.WMID.SBCC: Insufficient arguments - Caller passed 1, method requires 4".
# Do not go back to it: SBCO/GBCO is the documented path for this firmware.

set -uo pipefail

CALL=/proc/acpi/call
BAT=/sys/class/power_supply/BAT0
LOCK=/run/lock/hp-charge-limit.lock
STATE_DIR=/var/lib/hp-charge-limit
STATE_CSV=$STATE_DIR/state.csv
CSV_MAX=$((2 * 1024 * 1024))

# The cap is what sets the average state of charge, and therefore the aging
# rate; the corridor only decides how often the top-up runs. The laptop needs
# minutes of runtime, not hours (the router dies with the mains anyway), so the
# cap can sit low: 75% still gives over an hour at ~46 W.
#
# V_STOP is a backstop for a gauge that under-reads, NOT a working threshold.
# It must sit well above the charger's terminal voltage or it fires on every
# plug-in: at 74% SoC the pack rests at 16.06 V but the charger drives the
# terminals to ~16.59 V within a second. A 16.5 V guard inhibited a pack at 74%
# and would have pinned it near 65% forever.
V_STOP=17000000     # 17.00 V = 4.25 V/cell terminal, ~82% SoC - backstop only
V_RESUME=15600000   # 15.60 V = 3.90 V/cell - resume if the pack drifted down
PCT_STOP=75         # drive the cap off the gauge; measured 75% ~ 4.03 V/cell
PCT_RESUME=65
OFF_MIN=50          # below this, let it charge while the machine is off

GBCO='\_SB.WMID.GBCO'
SBCO_AUTO='\_SB.WMID.SBCO 0 0 0 0'      # Arg1=0 -> BDVO 0x40
SBCO_INHIBIT='\_SB.WMID.SBCO 0 5 0 0'   # Arg1=5 -> BDVO 0x45

MODE_AUTO=0         # GBCO readback values observed on this board
MODE_CHARGING=1     #   the EC reports the power flow, not only our request
MODE_DISCHARGING=2
MODE_INHIBIT=4

log() { printf 'hp-charge-limit: %s\n' "$*"; }

# acpi_call has one reply buffer for the whole system and resets it after every
# read(). So:
#   - serialise against any other writer (manual run, another tool)
#   - take the reply in a single read(): a shell `cat` may probe twice and come
#     back empty
acquire_lock() {
    local dir
    dir=$(dirname "$LOCK")
    [[ -d $dir ]] || mkdir -p "$dir" 2>/dev/null
    exec 9>"$LOCK" || { log "cannot open $LOCK"; return 1; }
    flock -w 5 9 || { log "another instance holds $LOCK"; return 1; }
}

acpi() {
    printf '%s' "$1" >"$CALL" || return 1
    # one read only (see above); tr strips the NUL padding acpi_call returns
    dd if="$CALL" bs=4096 count=1 2>/dev/null | tr -d '\0'
}

# Reply shape: [<status>, <size>, {<byte0>, <byte1>, ...}]
reply_status() {
    local s
    s=$(sed -n 's/^\[\(0x[0-9a-fA-F]\+\).*/\1/p' <<<"$1")
    [[ -n $s ]] || return 1
    printf '%d\n' "$((s))"
}

reply_byte0() {
    local b
    b=$(sed -n 's/.*{0x\([0-9a-fA-F]\{1,2\}\),.*/\1/p' <<<"$1")
    [[ -n $b ]] || return 1
    printf '%d\n' "$((16#$b))"
}

status_name() {
    case $1 in
        0)    echo "ok" ;;
        3)    echo "bad Arg1" ;;
        0x34) echo "precondition unmet (MBTS/BDSO)" ;;
        0x35) echo "AC not present, or EC refused" ;;
        0x36) echo "transition refused" ;;
        *)    echo "unknown status" ;;
    esac
}

read_mode() {
    local reply mode

    reply=$(acpi "$GBCO") || { log "GBCO write failed - root and acpi_call needed"; return 1; }
    case $reply in
        Error*|*AE_NOT_FOUND*) log "firmware has no GBCO: $reply"; return 1 ;;
    esac

    mode=$(reply_byte0 "$reply") || { log "cannot parse GBCO reply: $reply"; return 1; }
    printf '%d\n' "$mode"
}

# Write a mode and prove it landed. Two independent checks, because either one
# alone can lie: the SBCO status byte (did the EC accept it) and the GBCO
# readback (is it actually in effect).
set_mode() {
    local name=$1 cmd want out st after

    case $name in
        auto)    cmd=$SBCO_AUTO;    want=$MODE_AUTO ;;
        inhibit) cmd=$SBCO_INHIBIT; want=$MODE_INHIBIT ;;
        *) log "unknown mode $name"; return 1 ;;
    esac

    out=$(acpi "$cmd") || { log "write failed for $name"; return 1; }
    case $out in
        Error*) log "$name rejected by ACPI: $out"; return 1 ;;
    esac

    if st=$(reply_status "$out"); then
        if (( st != 0 )); then
            log "ERROR: $name -> status 0x$(printf '%02x' "$st") ($(status_name "$st"))"
            return 1
        fi
    else
        log "WARNING: cannot parse status from reply: $out"
    fi

    after=$(read_mode) || { log "$name sent but readback failed"; return 1; }
    if (( after != want )); then
        # On battery the EC reports the power flow (2) rather than the requested
        # mode, so a manual set while unplugged is not a failure.
        if (( after == MODE_DISCHARGING )) && [[ $(<"$BAT/status") == Discharging ]]; then
            log "$name written; EC reports mode=2 (discharging) - retest on AC"
            return 0
        fi
        log "ERROR: $name accepted (status 0) but GBCO reports mode=$after, expected $want"
        return 1
    fi
    log "$name applied (status=0 mode=$after)"
}

# Validate the command strings against the DSDT mapping derived above. Pure
# arithmetic and grep: touches neither /proc/acpi/call nor the EC.
selftest() {
    local fails=0 spec name arg rest cmd

    for spec in "auto:0:$SBCO_AUTO" "inhibit:5:$SBCO_INHIBIT"; do
        name=${spec%%:*}
        rest=${spec#*:}
        arg=${rest%%:*}
        cmd=${rest#*:}
        if [[ $cmd == "\\_SB.WMID.SBCO 0 $arg 0 0" ]]; then
            log "selftest $name: PASS  SBCO 0 $arg 0 0  (Arg1=$arg -> BDVO 0x4$arg)"
        else
            log "selftest $name: FAIL  have: $cmd  want: \\_SB.WMID.SBCO 0 $arg 0 0"
            fails=$((fails + 1))
        fi
    done

    # Modes 1,2,3,6 and especially 7 (STOE storage/ship) must never be written.
    if grep -qE 'SBCO 0 [12367] ' "${BASH_SOURCE[0]}"; then
        log "selftest: FAIL - a mode other than 0 or 5 appears in an SBCO command"
        fails=$((fails + 1))
    fi
    # The abandoned SBCC/MBDC path must not creep back in.
    if grep -qE 'SBCC b[0-9a-f]{40}' "${BASH_SOURCE[0]}"; then
        log "selftest: FAIL - a legacy SBCC buffer command is present"
        fails=$((fails + 1))
    fi

    if (( fails )); then
        log "selftest: $fails FAILURE(S) - do not run any write"
        return 1
    fi
    log "selftest: OK - only Arg1=0 and Arg1=5, no legacy SBCC"
}

# One CSV row per pass: the long-term record for judging the pack in 6 months.
# Rotation is deliberately dumb - one generation, overwritten.
record_row() {
    local action=$1 mode=$2 volt=$3 pct=$4 status=$5 now energy size

    mkdir -p "$STATE_DIR" 2>/dev/null
    if [[ -f $STATE_CSV ]]; then
        size=$(stat -c %s "$STATE_CSV" 2>/dev/null || echo 0)
        (( size > CSV_MAX )) && mv -f "$STATE_CSV" "$STATE_CSV.1" 2>/dev/null
    fi
    now=$(date -Is)
    energy=$(cat "$BAT/energy_now" 2>/dev/null || echo 0)
    printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$now" "$volt" "$((volt / 4000))" "$pct" "$energy" "$status" "$mode" "$action" \
        >>"$STATE_CSV" 2>/dev/null
}

show_status() {
    local mode volt pct status
    mode=$(read_mode) || return 1
    volt=$(<"$BAT/voltage_now")
    pct=$(<"$BAT/capacity")
    status=$(<"$BAT/status")
    log "mode=$mode status=$status cap=${pct}%"
    log "voltage=$(awk "BEGIN{printf \"%.3f\", $volt/1000000}")V per-cell=$(awk "BEGIN{printf \"%.3f\", $volt/4000000}")V"
    if [[ -f $STATE_CSV ]]; then
        log "last rows ($STATE_CSV):"
        tail -5 "$STATE_CSV" | sed 's/^/    /'
    fi
}

tick() {
    local mode status volt pct stop=0 resume=0 action=none

    # A control pass is a periodic best effort: the timer retries in 5 minutes,
    # so a missing module must not fail the unit (or a rebuild that starts it).
    # Explicit subcommands still fail loudly through read_mode.
    if [[ ! -r $CALL ]]; then
        log "WARNING: $CALL missing - is the acpi_call module loaded? retrying next tick"
        return 0
    fi

    mode=$(read_mode) || return 1

    status=$(<"$BAT/status")
    volt=$(<"$BAT/voltage_now")
    pct=$(<"$BAT/capacity")

    if [[ $status == Discharging ]]; then
        record_row "on-battery" "$mode" "$volt" "$pct" "$status"
        return 0      # on battery: leave the firmware alone
    fi

    (( volt >= V_STOP )) && stop=1
    (( pct >= PCT_STOP )) && stop=1
    # Resume on EITHER signal. The cap is a state-of-charge cap, so a pack that
    # came back from battery duty below PCT_RESUME must charge whatever its
    # voltage reads; the voltage arm only catches a pack that drifted down.
    (( pct <= PCT_RESUME )) && resume=1
    (( volt <= V_RESUME )) && resume=1

    if (( stop )) && (( mode != MODE_INHIBIT )); then
        set_mode inhibit && action=inhibit
    elif (( resume )) && (( mode == MODE_INHIBIT )); then
        set_mode auto && action=auto
    fi

    record_row "$action" "$mode" "$volt" "$pct" "$status"
}

# Runs from a shutdown unit. BDVO lives in the EC, which keeps running on standby
# power, so inhibit may well outlive the shutdown - but that is unproven here, and
# a low pack is always left charging on purpose so it cannot arrive dead.
at_shutdown() {
    local mode pct action=none

    pct=$(<"$BAT/capacity")
    mode=$(read_mode) || { log "shutdown: cannot read mode, leaving firmware alone"; return 0; }

    if (( pct >= OFF_MIN )); then
        set_mode inhibit && action=inhibit-shutdown
    else
        set_mode auto && action=auto-shutdown
    fi
    record_row "$action" "$mode" "$(<"$BAT/voltage_now")" "$pct" "$(<"$BAT/status")"
}

main() {
    local cmd=${1:-tick}
    case $cmd in
        status|tick|shutdown|auto|inhibit|selftest) ;;
        *) printf 'usage: %s [tick|shutdown|status|selftest|auto|inhibit]\n' "$0" >&2; return 2 ;;
    esac

    acquire_lock || return 1

    case $cmd in
        selftest) selftest ;;
        status)   show_status ;;
        tick)     tick ;;
        shutdown) at_shutdown ;;
        auto)     set_mode auto ;;
        inhibit)  set_mode inhibit ;;
    esac
}

main "$@"
