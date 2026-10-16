{ pkgs, ... }:

# `stats`: one-shot snapshot of this Mac as a server. Each section is a fish
# function; add a new one and list it at the bottom. (Not called `status`:
# that's a fish builtin, so a command with that name would never run.)

let
  stats = pkgs.writeScriptBin "stats" ''
    #!/run/current-system/sw/bin/fish

    set -l lms /Users/cooper/.lmstudio/bin/lms
    set -l jq ${pkgs.jq}/bin/jq
    set -l swap_log /Users/cooper/Library/Logs/lmstudio-model-schedule.log

    function row -a label value
        printf '%-8s %s\n' $label $value
    end

    function section_model -V lms -V jq -V swap_log
        set -l ps ($lms ps --json 2>/dev/null)
        if test -z "$ps"
            row Model "LM Studio not responding"
            return
        end
        set -l models (printf '%s' $ps | $jq -r '.[] | "\(.modelKey // .identifier)|\(.status // "?")|\(.queued // 0)"')
        if test (count $models) -eq 0
            row Model "none loaded"
        end
        for m in $models
            set -l f (string split '|' $m)
            set -l name $f[1]
            switch $name
                case qwen3.5-122b-a10b
                    set name "heavy ($name)"
                case qwen/qwen3.6-35b-a3b
                    set name "light ($name)"
            end
            set -l state $f[2]
            test $f[3] -gt 0; and set state "$state, $f[3] queued"
            row Model "$name, $state"
        end
        if test -f $swap_log
            set -l last (grep swapping $swap_log | tail -n 1 \
                | string replace -a qwen3.5-122b-a10b heavy \
                | string replace -a qwen/qwen3.6-35b-a3b light \
                | string replace -r '\[(.*)\]' '$1')
            test -n "$last"; and row "" "last swap: $last"
        end
    end

    function section_uptime
        set -l boot (sysctl -n kern.boottime | string match -r 'sec = (\d+)')[2]
        set -l s (math (date +%s) - $boot)
        set -l d (math -s0 $s / 86400)
        set -l h (math -s0 "$s % 86400 / 3600")
        set -l m (math -s0 "$s % 3600 / 60")
        row Uptime "$d d $h h $m m (since "(date -r $boot '+%F %R')")"
    end

    function section_cpu
        # Second sample of top is the real 1-second snapshot.
        set -l usage (/usr/bin/top -l 2 -n 0 -s 1 | grep 'CPU usage' | tail -n 1 | string replace 'CPU usage: ' "")
        set -l load (sysctl -n vm.loadavg | string trim -c '{} ')
        row CPU "$usage"
        row "" "load $load ("(sysctl -n hw.ncpu)" cores)"
    end

    function section_ram
        set -l total (math -s0 (sysctl -n hw.memsize) / 1073741824)
        set -l free_pct (memory_pressure -Q | string match -r '(\d+)%')[2]
        set -l used_pct (math 100 - $free_pct)
        set -l swap (sysctl -n vm.swapusage | string match -r 'used = (\S+)')[2]
        row RAM (math -s0 $total \* $used_pct / 100)" / $total GB used ($used_pct%), swap $swap"
    end

    function section_disk
        set -l d (df -h /System/Volumes/Data | tail -n 1 | string split -n ' ')
        row Disk "$d[3] used, $d[4] free ($d[5])"
    end

    for s in model uptime cpu ram disk
        section_$s
    end
  '';
in
{
  environment.systemPackages = [ stats ];
}
