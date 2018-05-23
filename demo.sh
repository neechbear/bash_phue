#!/usr/bin/env bash
#
# MIT License
# 
# Copyright (c) 2018 Nicola Worthington <nicolaw@tfb.net>.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This has been written to work with Bash 3.2 specifically so it can be used by
# all those poor Apple Mac users, without the need for installing Homebrew or
# MacPorts.

set -Eeuo pipefail

# Inspiration taken from
# http://icepick.com/website/Blog/HueRasp.shtml

sos () {
  for light in "$@" ; do
    declare d="" dot=0.5 dash=1.5
    for d in $dot $dot $dot $dash $dash $dash $dot $dot $dot ; do
      phue_lights state '{"bri":255,"on":true}' $light
      sleep $d
      phue_lights off true $light
      sleep $dot
    done
  done
}

main () {
  # Load phue library.
  source "${0%/*}/phue.sh" \
    || source "/usr/local/lib/phue.sh"

  # Set brigde hostname/IP and username from ~/.bash_phue.
  #phue_read_credentials
  phue_bridge
  phue_username

  # Try to discover the bridge hostname/IP.
  phue_bridge_discover | jq -r .[0].internalipaddress

  # Get all light IDs.
  declare -a lights=()
  lights=($(phue_lights | jq -r '.|to_entries[]|.key'))

  # List available lights.
  phue_lights | jq -r '.|to_entries[]|.key + "\t" + .value.name'

  # Select a light(s) to demonstrate on.
  declare -a test_lights=("$@")
  if [[ ${#test_lights} -eq 0 ]] ; then
    test_lights+=(1)
  fi

  # Colour loop.
  phue_lights on "${test_lights[@]}"
  phue_lights effect colorloop "${test_lights[@]}"
  sleep 15

  # Make all the lights flash bright red.
  phue_lights state \
    "$(printf 'on true hue 65535 sat 255 bri 255 alert lselect' \
       | jq -Rs 'split(" ") | . as $a | reduce range(0; length/2) as $i 
                 ({}; . + {($a[2*$i]): ($a[2*$i + 1]|fromjson? // .)})')" \
    "${test_lights[@]}"
  sleep 6

  # Turn lights off and on (terse format).
  phue_lights off "${test_lights[@]}"
  sleep 2
  phue_lights on "${test_lights[@]}"
  sleep 2

  # Turn lights off and on (full argument format).
  phue_lights off true "${test_lights[@]}"
  sleep 2
  phue_lights on true "${test_lights[@]}"
  sleep 2

  # Scale saturation.
  phue_lights sat_inc -150 "${test_lights[@]}"
  sleep 2
  phue_lights sat_inc 150 "${test_lights[@]}"
  sleep 2

  # Scale brightness.
  phue_lights bri_inc -150 "${test_lights[@]}"
  sleep 2
  phue_lights bri_inc 150 "${test_lights[@]}"
  sleep 2

  # Flash SOS in morse code.
  sos "${test_lights[@]}"
  sleep 4

}

main "$@"
