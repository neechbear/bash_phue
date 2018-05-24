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

# https://developers.meethue.com/documentation/important-whitelist-changes
# https://developers.meethue.com/documentation/datatypes-and-time-patterns
# https://developers.meethue.com/philips-hue-api

_phue_curl () {
  curl -ksSL -H "Content-Type: application/json" "$@" | {
    declare rc=${PIPESTATUS[0]};
    if [[ ! ${PHUE_NOJQ:-} ]] && type -P jq >/dev/null ; then
      jq .
    else
      cat
    fi
    return $rc
  }
}

_phue_join () {
  local IFS="${1:-/}"; shift
  echo "$*"
}

phue_read_credentials () {
  declare cfg=""
  for cfg in "$@" ~/.bash_phue /etc/bash_phue /usr/local/etc/bash_phue ; do
    if [[ -e "$cfg" ]] ; then
      eval "$(grep -E '^PHUE_[A-Z0-9_]+=[a-zA-Z0-9\.:]+$' "$cfg")"
      export PHUE_BRIDGE PHUE_USERNAME PHUE_NOJQ
      break
    fi
  done
}

phue_username () {
  if [[ -n "${1:-}" ]] ; then
    export PHUE_USERNAME="$1"
  elif [[ -z "${PHUE_USERNAME:-}" ]] ; then
    phue_read_credentials
  fi
  echo "${PHUE_USERNAME:-}"
}

phue_bridge () {
  if [[ -n "${1:-}" ]] ; then
    shopt -s nocasematch
    case "${1:-}" in
      discover)
        phue_bridge_discover
        return $?
        ;;
      *)
        export PHUE_BRIDGE="$1"
        ;;
    esac
  elif [[ -z "${PHUE_BRIDGE:-}" ]] ; then
    phue_read_credentials
  fi
  echo "${PHUE_BRIDGE:-}"
}

phue_bridge_discover () {
  _phue_curl https://www.meethue.com/api/nupnp
}

phue_create_username () {
  declare app_name="${1:-bash_phue.sh}"
  declare device_name="${2:-$(hostname)}"
  PHUE_USERNAME="" phue POST \
    "$(printf '{"devicetype":"%s#%s"}' "$app_name" "$device_name")"
}

phue_info () {
  phue GET info "$@"
}

phue_capabilities () {
  phue GET capabilities
}

phue () {
  declare cmd="${1:-}"; shift
  shopt -s nocasematch

  case "$cmd" in
    # Perform basic despatching first.
    bridge_discover) phue_bridge discover ;;
    bridge) phue_bridge "$@" ;;
    username) phue_username "$@" ;;
    register|link|create_username) phue_create_username "$@" ;;
    info) phue_info "$@" ;;
    capabilities) phue_capabilities "$@" ;;
    lights|light) phue_lights "$@" ;;
    on|off|hue|bri|sat|ct|transitiontime|bri_inc|sat_inc|hue_inc|ct_inc|xy|alert|effect|xy_inc|state) phue_lights "$cmd" "$@" ;;

    *)
      # Validate global variables required for JSON REST RPC.
      if [[ -z "${PHUE_BRIDGE:-}" ]] ; then
        >&2 echo "Error; PHUE_BRIDGE is not defined!"
        return 1
      fi
      if [[ -z "${PHUE_USERNAME:-}" \
            && "${FUNCNAME[1]}" != "phue_create_username" ]] ; then
        >&2 echo "Error; PHUE_USERNAME is not defined!"
        return 1
      fi
      
      declare query_url=""
      declare query_body=""
      declare api_url="$(_phue_join "/" \
        "https://${PHUE_BRIDGE:-}" api ${PHUE_USERNAME:-})"
      
      case "$cmd" in
        GET|DELETE)
          query_url="$(_phue_join "/" "$api_url" "$@")"
          _phue_curl -X "$cmd" "$query_url"
          ;;
        PUT|POST)
          query_body="${1:-}"; shift
          query_url="$(_phue_join "/" "$api_url" "$@")"
          _phue_curl -X "$cmd" --data "$query_body" "$query_url"
          ;;
        *)
          >&2 echo "Unknown command ${cmd}"
          ;;
      esac
  esac
}

# https://developers.meethue.com/documentation/datatypes-and-time-patterns

_phue_bool_invert () {
  case "${1:-}" in
    true) echo false ;;
    false) echo true ;;
    *) echo "${1:-}" ;;
  esac
}

phue_light () { phue_lights "$@"; }

phue_lights () {
  # https://developers.meethue.com/documentation/lights-api
  declare method="${1:-}"; shift || true
  declare id=""
  shopt -s nocasematch

  case "$method" in
    list)
      phue_lights | jq -r '.|to_entries[]|.key + "\t" + .value.name'
      ;;

    get|"")
      # GET  /api/<username>/lights       Get all lights
      # GET  /api/<username>/lights/<id>  Get light attributes and state
      if [[ $# -eq 0 || "$*" =~ ^\ *$ ]] ; then
        phue GET lights
      else
        for id in "$@" ; do
          phue GET lights "$id"
        done
      fi
      ;;

    new)
      # GET    /api/<username>/lights/new  Get new lights
      # POST*  /api/<username>/lights      Search for new lights
      if [[ $# -eq 0 || "$*" =~ ^\ *$ ]] ; then
        phue GET lights new
      else
        declare body="${1:-}"
        phue POST "$body" lights new
      fi
      ;;

    delete)
      # DELETE  /api/<username>/lights/<id>  Delete lights
      for id in "$@" ; do
        phue DELETE lights "$id"
      done
      ;;

    name|rename)
      # PUT*  /api/<username>/lights/<id>  Set light attributes (rename)
      declare body="${1:-}"; shift || true
      for id in "$@" ; do
        phue PUT "$body" lights "$id"
        break
      done
      ;;

    state)
      # PUT*  /api/<username>/lights/<id>/state  Set light state
      declare body="${1:-}"; shift || true
      for id in "$@" ; do
        phue PUT "$body" lights "$id" state
      done
      ;;

    on|off)
      declare body="true"
      if [[ ! "${1:-}" =~ ^[0-9]+$ ]] ; then
        body="$1"; shift || true
      fi
      case "$method" in
        off) method="on"; body="$(_phue_bool_invert "${body:-true}")" ;;
      esac
      phue_lights state "$(printf '{"%s":%s}' "$method" "$body")" "$@"
      ;;

    bri|hue|sat|ct|transitiontime|bri_inc|sat_inc|hue_inc|ct_inc)
      declare body="${1:-}"; shift || true
      phue_lights state "$(printf '{"%s":%s}' "$method" "$body")" "$@"
      ;;

    xy|alert|effect|xy_inc)
      declare body="${1:-}"; shift || true
      phue_lights state "$(printf '{"%s":"%s"}' "$method" "$body")" "$@"
      ;;

    *)
      >&2 echo "Error; unknown command argument '$method'!"
      return 1
      ;;
  esac
}

_phue_help () {
  echo "Syntax: phue <command> [arguments] [light-id...n]"
  echo ""
  echo "Commands: bridge, register, username, lights, info, capabilities."
  #echo "Commands: lights, groups, schedules, scenes, sensors, rules,"
  #echo "          configuration, info, resourcelinks, capabilities."
  echo ""

  if [[ $# -ge 1 ]] ; then
    declare note=""
    for note in "$@" ; do
      echo "$note"
    done
    echo ""
  fi

  echo "See https://github.com/neechbear/bash_phue for help."
}

_phue_main () {
  declare arg=""
  for arg in "$@" ; do
    case "$arg" in
      --help|-h|-?)
        # Display some command line help.
        _phue_help
        return $?
        ;;
    esac
  done

  # Check and load configuration.
  phue_bridge >/dev/null
  if [[ -z "${PHUE_BRIDGE:-}" \
        && "$*" != "bridge discover"
        && "$*" != "bridge_discover" ]] ; then
    _phue_help \
      "Environment variable PHUE_BRIDGE and PHUE_USERNAME are unset." \
      "Set PHUE_BRIDGE or try '$0 bridge discover'."
    return 1
  fi

  # Passthrough to phue function.
  phue "$@"
}

_phue_is_sourced () {
  [[ "${FUNCNAME[1]}" == "source" ]]
}

if ! _phue_is_sourced ; then
  _phue_main "$@"
fi
