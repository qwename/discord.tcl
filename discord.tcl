# discord.tcl --
#
#       This file implements the Tcl code for interacting with the Discord API
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.5
package require http
package require json
package require logger


namespace eval discord {
    namespace export connect disconnect
    namespace ensemble create

    variable version 0.2.0

    variable log [::logger::init discord]
    ${log}::setlevel debug

    variable ApiBaseUrl "https://discordapp.com/api"
    variable GatewayUrl ""

    variable SessionId 0
    variable Sessions [dict create]
}

::http::config -useragent "DiscordBot (discord.tcl, ${::discord::version})"

# discord::connect --
#
#       Starts a new session. Connects to the Discord Gateway, and update
#       session details continuously by monitoring Dispatch events.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token
#
# Results:
#       Returns the name of a namespace that is created for the session if the
#       connection is sucessful, and an empty string otherwise.

proc discord::connect { token } {
    variable SessionId
    set sock [gateway::connect $token]
    if {$sock eq ""} {
        return ""
    }
    set id $SessionId
    incr SessionId
    set name ::discord::session::$id
    CreateSession $name $sock $token
    return $name
}

# discord::disconnect --
#
#       Stop an existing session. Disconnect from the Discord Gateway.
#
# Arguments:
#       sessionName Session name returned from discord::connect
#
# Results:
#       Deletes the session namespace. Returns 1 if sessionName is valid, and
#       0 otherwise.

proc discord::disconnect { sessionName } {
    variable log
    if {![namespace exists $sessionName]} {
        ${log}::error "disconnect: Unknown session: '$sessionName'"
        return 0
    }

    if {[catch {gateway::disconnect [$sessionName var sock]} res]} {
        ${log}::error "disconnect: $res"
    }
    namespace delete $sessionName
    return 1
}

# discord::CreateSession --
#
#       Create a namespace for a session.
#
# Arguments:
#       sessionName Fully-qualified name namespace to create.
#       sock        WebSocket object.
#       token       Bot token or OAuth2 bearer token.
#
# Results:
#       Creates a namespace with the variables sock and token present. Also
#       defines the procedure 'variable'. Returns the namespace name.

proc discord::CreateSession { sessionName sock token } {
    namespace eval $sessionName {
        namespace export variable
        namespace ensemble create

        proc variable { name args } {
            ::variable $name
            if {[llength $args] > 0} {
                set $name $args
            }
            return [set $name]
        }
    }
    $sessionName var sock $sock
    $sessionName var token $token
    return $sessionName
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
#       Returns the Gateway wss URL string, or an empty string if an error
#       occurred.

proc discord::GetGateway { {cached 1} } {
    variable log
    variable ApiBaseUrl
    variable GatewayUrl
    if {$GatewayUrl ne "" && $cached} {
        return $GatewayUrl
    }
    set reqUrl "${ApiBaseUrl}/gateway"
    if {[catch {::http::geturl $reqUrl} token]} {
        ${log}::error "GetGateway: $reqUrl: $token"
        return ""
    }
    set status [::http::code $token]
    set body [::http::data $token]
    ::http::cleanup $token
    if {![regexp -nocase ok $status]} {
        ${log}::error "GetGateway: $reqUrl: $status"
        return ""
    }
    if {[catch {::json::json2dict $body} data]} {
        ${log}::error "GetGateway: $data"
        return ""
    }
    set GatewayUrl [dict get $data url]
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
