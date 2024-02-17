#!/usr/bin/env bash
#!#!#/usr/bin/env zsh

set -eu -o pipefail
#set -x

systemd_title="Pacman Update Checker"
systemd_unit="pac-updater"
start_ts="$(date "+%s")"

set +e
updates="$(checkupdates || true)" # Return 0 exit code always and check output
#updates_avail="$(echo "$updates" | wc -l)"
updates_avail="$(grep -c '.' <(echo "$updates"))"
updates_pkg=""
set -e

while read -r line
do
  updates_pkg+="$(echo "$line" | awk '{ print $1 }') "
done < <(echo "$updates")

echo "Updates: $updates_pkg"

function write_log() {
  local msg="$1"
  local prio="${2:-info}"

  echo "$systemd_title: $msg" | systemd-cat -t "$systemd_unit" -p "${prio-:info}"
}

function runtime_stats() {
  end_ts="$(date "+%s")"
  seconds=$((end_ts - start_ts))
  if [[ $seconds -lt 60 ]]; then
    echo "${seconds}s"
  else
    minutes=$((seconds / 60))
    seconds=$((seconds % 60))
  
    if [[ $minutes -lt 60 ]]; then
      echo "${minutes}m${seconds}s"
    else
      hours=$((minutes / 60))
      minutes=$((minutes % 60))
      echo "${hours}h${minutes}m${seconds}s"
    fi
  fi
}

## Inform all logged on users
## Usage: notify_users TITLE MESSAGE [urgency [icon]]
#function notify_users() {
#    typeset title="$1"
#    typeset message="$2"
#    typeset urgency="${3:-critical}"
#    typeset icon="${4:-}"
#    typeset timeout="${5:-5000}"
#
#    case "$urgency" in
#        "low") : ;;
#        "normal") : ;;
#        "critical") : ;;
#        *)
#            urgency="normal"
#            ;;
#    esac
#
#    typeset ls user bus_addr
#
#    typeset IFS=$'\n'
#
#    # for all dbus-daemon processes that create a session bus
#    for ln in "$(ps -eo user,args | grep "dbus-daemon.*--session.*--address=" | grep -v grep)"; do
#        # get the user name
#        user="$(echo "$ln" | cut -d' ' -f 1)"
#        # get dbus address
#        bus_addr="$(echo "$ln" | sed 's/^.*--address=//;s/ .*$//')"
#        # run notify-send with the correct user
#        DBUS_SESSION_BUS_ADDRESS="$bus_addr" sudo -u $user -E /usr/bin/notify-send -u "$urgency" -i "$icon" -t "$timeout" "$title" "$message"
#    done
#}

function notify_users() {
    typeset title="$1"
    typeset message="$2"
    typeset urgency="${3:-critical}"
    typeset icon="${4:-/usr/share/pixmaps/archlinux-logo.png}"
    #typeset icon="${4:-}"

    case "$urgency" in
        "low") : ;;
        "normal") : ;;
        "critical") : ;;
        *)
            urgency="normal"
            ;;
    esac
    #Detect the name of the display in use
    local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

    #Detect the user using such display
    local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)
    if [[ "$user" == "" ]]; then
      local user=$(who | grep 'tty2' | awk '{print $1}' | head -n 1)
    fi
    #local user=scarver

    #Detect the id of the user
    local uid="$(id -u "$user")"

    #sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus notify-send "$@"
    #DBUS_SESSION_BUS_ADDRESS="$bus_addr" sudo -u $user -E 
    sudo -u "$user" DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" /usr/bin/notify-send -u "$urgency" -i "$icon" "$title" "$message"
}

#notify_users "$systemd_title" "HEREL"

function write_log_and_notify() {
  local message="$1"

  write_log "$message"
  notify_users "$systemd_title" "$message"

}


if [[ $updates_avail -gt 0 ]]; then
  write_log "${updates_avail} updates found.."
  write_log "Installing ($updates_pkg)"
  notify_users "$systemd_title" "${updates_avail} updates found, starting pacman update.."
  
  if ! pacman -Syu --noconfirm; then
    write_log_and_notify "Errors encountered - Runtime: $(runtime_stats))"
  else
    write_log_and_notify "Updates completed (${updates_avail} packages installed - Runtime: $(runtime_stats))"
  fi
else
  echo "thsi"
  write_log_and_notify "System is up to date (${updates_avail} packages installed - Runtime: $(runtime_stats))"
fi
