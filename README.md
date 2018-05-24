# Philips hue Bash Library

This is a very simple Bash script library to help manipulate Philips hue lights
using the JSON REST API.

https://developers.meethue.com/philips-hue-api

This software is in the early stages of development.

## Installation

    make build
    make install

## Example

`phue.sh` may be incorporated into your own shell scripts using `source`. See
[demo.sh](demo.sh) for more detailed example.

    #!/usr/bin/env bash
    set -Eeuo pipefail
    source phue.sh
    PHUE_BRIDGE=192.168.0.10
    PHUE_USERNAME=fwbef7webfonino4ybbnapsdna7t3afn4ip5n398
    phue_lights on true 1 2 3
    phue_lights bri 255 1 2 3
    phue_lights hue 10000 1 2
    phue_lights sat 255 1 2 3
    phue_lights alert lselect 2

Alternatively `phue.sh` may be installed as a stand-alone script and used
directly from the command line.

    phue lights list
    phue lights
    phue lights off 1 2 3
    phue lights on 7 8
    phue lights bri 255 7 8
    phue lights hue 20000 7
    phue lights sat 255 7
    phue lights alert lselect 3

## Requirements

* Bash 3.2 or newer.

* `curl` is required to communicate with the Philips hue bridge.

* `jq` is not necessary, but it is highly recommended as it will make
  parsing and manipulation of JSON REST API responses significantly easier.

## Functions

Argumemnts to most functions will corresopnd either directly or very closely
to the corresponsing JSON REST API interface. Please refer to
https://developers.meethue.com/philips-hue-api for additional information.

### phue_read_credentials

Read Philips hue bridge and username credentials from a configuration file.

    phue_read_credentials [optional_config_file]

### phue_username

Get or set (when an optional argument is provided) the `PHUE_USERNAME`
environment variable. When used as a get (an accessor), the
`phue_read_credentials` function will automatically be called if no value is
already defined.

    phue_username [optional_username_to_set]

### phue_bridge

Functions identially to `phue_username`, but will get or set the Philips hue
bridge hostname or IP address `PHUE_BRIDGE` environment variable.

    phue_bridge [optional_bridge_ip_to_set]

### phue_bridge_discover

Attempts to disover the Philips hue bridge IP address by contacting the PnP URL
at https://www.meethue.com/api/nupnp.

    phue_bridge_discover | jq -r .[0].internalipaddress

### phue_create_username

Creates a new username on the Philips hue bridge. This requires that the button
has already been pressed on the bridge.

    phue_create_username [optional_application_name] [optional_device_name] | jq -r .[0].success.username

### phue_lights

Turn lights off and on.

Get information or change state for all or specific lights, as well as light
renaming, discovery and deletion.

See https://developers.meethue.com/documentation/lights-api and
[demo.sh](demo.sh) for a full list of all arguments.

    phue_lights
    phue_lights new
    phue_lights get [light_numbers...]
    phue_lights rename <new_name> <light_numbers>
    phue_lights delete <light_numbers...>
    phue_lights on <light_numbers...>
    phue_lights off <light_numbers...>
    phue_lights hue <hue_number> <light_numbers...>
    phue_lights bri <brightness_number> <light_numbers...>
    phue_lights sat <saturation_number> <light_numbers...>

### phue

Make direct JSON REST API to the Philips hue bridge.

    phue GET <api_component_paths...>
    phue DELETE <api_component_paths...>
    phue PUT <json_request_body> <api_component_paths...>
    phue POST <json_request_body> <api_component_paths...>

## Environment Variables

`PHUE_BRIDGE` - Hostname or IP address of the Philips hue bridge.

`PHUE_USERNAME` - Client key username used to authenticate with the bridge.

`PHUE_NOJQ` - Disable pretty-printed JSON RPC responses using `jq`.

## Files

`~/.bash_phue`, `/etc/bash_phue`, `/usr/local/etc/bash_phue`

Configuration file format is strict KEY=VALUE pair format, where all keys must
begin with `PHUE_`. Specifically, only key names matching the environment
variable names above are valid.

## License

MIT License

Copyright (c) 2018 Nicola Worthington <nicolaw@tfb.net>.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## See Also

* https://github.com/markusproske/hue_bashlibrary
* https://github.com/neechbear/blip
* http://icepick.com/website/Blog/HueRasp.shtml
* https://developers.meethue.com/philips-hue-api
