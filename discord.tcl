# discord.tcl --
#
#       This file implements the Tcl code for interacting with the Discord API
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.5
package require rest
package require logger

namespace eval discord {
    set version 0.1

    set log [logger::init discord]
    ${log}::setlevel debug

    set ApiBaseUrl "https://discordapp.com/api"
    set GatewayUrl ""

}

# discord::GetGateway --
#
#       Retrieve the Gateway WebSocket Secure (wss) URL
#
# Arguments:
#       cached  Return a cached URL value if available, or else send a new
#               request to Discord. Defaults to 1, meaning true.
#
# Results:
#       Returns the Gateway wss URL string.

proc discord::GetGateway { {cached 1} } {
    variable ApiBaseUrl
    variable GatewayUrl
    if {$GatewayUrl ne "" && $cached} {
        return $GatewayUrl
    }
    set res [rest::simple ${ApiBaseUrl}/gateway {} {
        method get
        format json
    }]
    set GatewayUrl [dict get [rest::format_json $res] url]
    return $GatewayUrl
}

# discord::Every --
#
#       Run a command periodically at the specified interval. Allows
#       cancellation of the command. Must be called using the full name.
#
# Arguments:
#       interval    Duration in milliseconds between each command execution.
#                   Use "cancel" to stop executing the command.
#       script      Command to run.
#
# Results:
#       Returns the return value of the 'after' command.

proc discord::Every {interval script} {
    variable EveryIds
    if {$interval eq "cancel"} {
        catch {after cancel $EveryIds($script)}
        return
    }
    set afterId [after $interval [info level 0]]
    set EveryIds($script) $afterId
    uplevel #0 $script
    return $afterId
}

package provide discord $::discord::version
