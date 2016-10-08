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
package require tls
package require websocket
package require rest
package require json::write
package require logger

::http::register https 443 ::tls::socket

namespace eval discord {
    set version 0.1

    set log [logger::init discord]
    ${log}::setlevel debug

    set ApiBaseUrl "https://discordapp.com/api"
    set GatewayUrl ""

}

namespace eval discord::gateway {
    namespace export connect disconnect
    namespace ensemble create

    set CompressEnabled 0
    if $CompressEnabled {
        package require mkZiplib
        set DefCompress true
    } else {
        set DefCompress false
    }

    set log [logger::init discord::gateway]
    ${log}::setlevel debug

    set DefHeatbeatInterval 10000
    set Sockets [dict create]

    set Op {
        DISPATCH                0
        HEARTBEAT               1
        IDENTIFY                2
        STATUS_UPDATE           3
        VOICE_STATE_UPDATE      4
        VOICE_SERVER_PING       5
        RESUME                  6
        RECONNECT               7
        REQUEST_GUILD_MEMBERS   8
        INVALID_SESSION         9
        HELLO                   10
        HEARTBEAT_ACK           11
    }
    set OpTokens [dict create]
    foreach {token op} $Op {
        dict set OpTokens $op $token
    }

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
    global discord::ApiBaseUrl
    global discord::GatewayUrl
    if {$GatewayUrl ne "" && $cached} {
        return $GatewayUrl
    }
    set res [::rest::simple ${ApiBaseUrl}/gateway {} {
        method get
        format json
    }]
    set GatewayUrl [dict get [::rest::format_json $res] url]
    return $GatewayUrl
}

# discord::Every --
#
#       Run a command periodically at the specified interval. Allows
#       cancellation of the command.
#
# Arguments:
#       interval    Duration in milliseconds between each command execution.
#                   Use "cancel" to stop executing the command.
#       script      Command to run.
#
# Results:
#       Returns the return value of the 'after' command.

proc discord::Every {interval script} {
    if {$interval eq "cancel"} {
        catch {after cancel $::discord::EveryIds($script)}
        return
    }
    set afterId [after $interval [info level 0]]
    set ::discord::EveryIds($script) $afterId
    uplevel #0 $script
    return $afterId
}

# discord::gateway::connect --
#
#       Establish a WebSocket connection to the Gateway.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#
# Results:
#       Returns the connection's WebSocket object.

proc discord::gateway::connect { token } {
    set gateway [::discord::GetGateway]
    ${::discord::gateway::log}::notice "Connecting to the Gateway: '$gateway'"

    set sock [::websocket::open $gateway ::discord::gateway::Handler]
    SetConnectionInfo $sock s null
    SetConnectionInfo $sock token $token
    SetConnectionInfo $sock session_id null
    SetConnectionInfo $sock heartbeat_interval \
            $::discord::gateway::DefHeatbeatInterval
    SetConnectionInfo $sock compress $::discord::gateway::DefCompress
    return $sock
}

# discord::gateway::disconnect --
#
#       Disconnect from the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       None.

proc discord::gateway::disconnect { sock } {
    ${::discord::gateway::log}::notice "Disconnecting from the Gateway."
    ::websocket::close $sock 1000
    return
}

# discord::gateway::Every --
#
#       Run a command periodically at the specified interval. Allows
#       cancellation of the command.
#
# Arguments:
#       interval    Duration in milliseconds between each command execution.
#                   Use "cancel" to stop executing the command.
#       script      Command to run.
#
# Results:
#       Returns the return value of the 'after' command.

proc discord::gateway::Every {interval script} {
    if {$interval eq "cancel"} {
        catch {after cancel $::discord::gateway::EveryIds($script)}
        return
    }
    set afterId [after $interval [info level 0]]
    set ::discord::gateway::EveryIds($script) $afterId
    uplevel #0 $script
    return $afterId
}

# discord::gateway::GetConnectionInfo --
#
#       Get a detail of the Gateway connection.
#
# Arguments:
#       sock    WebSocket object.
#       what    Name of the connection detail to return.
#
# Results:
#       Returns the connection detail.

proc discord::gateway::GetConnectionInfo { sock what } {
    return [dict get $::discord::gateway::Sockets $sock connInfo $what]
}

# discord::gateway::SetConnectionInfo --
#
#       Set a detail of the Gateway connection.
#
# Arguments:
#       sock    WebSocket object.
#       what    Name of the connection detail to set.
#       value   Value to set the connection detail to.
#
# Results:
#       Returns a string of the connection detail.

proc discord::gateway::SetConnectionInfo { sock what value } {
    return [dict set ::discord::gateway::Sockets $sock connInfo $what $value]
}

# discord::gateway::CheckOp --
#
#       Check if an opcode value is supported.
#
# Arguments:
#       op  A JSON integer.
#
# Results:
#       Returns 1 if the opcode is valid, and 0 otherwise.

proc discord::gateway::CheckOp { op } {
    if ![dict exists $::discord::gateway::OpTokens $op] {
        ${::discord::gateway::log}::error "op not supported: '$op'"
        return 0
    } else {
        return 1
    }
}

# discord::gateway::EventHandler --
#
#       Handle events from Gateway Dispatch messages.
#
# Arguments:
#       sock    WebSocket object.
#       msg     The message as a dictionary that represents a JSON object.
#
# Results:
#       Returns 1 if the event is handled successfully, and 0 otherwise.

proc discord::gateway::EventHandler { sock msg } {
    set t [dict get $msg t]
    set s [dict get $msg s]
    set d [dict get $msg d]
    SetConnectionInfo $sock s $s
    ${::discord::gateway::log}::debug \
            "EventHandler: sock: '$sock' t: '$t' s: $s"
    switch -glob -- $t {
        READY {
            set session_id [dict get $d session_id]
            SetConnectionInfo $sock session_id $session_id
            ${::discord::gateway::log}::debug "EventHandler: READY: session_id: '$session_id'"
            puts fine
            ::discord::gateway::Every [GetConnectionInfo $sock heartbeat_interval] [list ::discord::gateway::SendHeartbeat $sock]
        }
        default {
            ${::discord::gateway::log}::warn "Event not implemented: $t"
            return 0
        }
    }
    return 1
}

# discord::gateway::OpHandler --
#
#       Handles Gateway messages that contain an opcode.
#
# Arguments:
#       sock    WebSocket object.
#       msg     The message as a dictionary that represents a JSON object.
#
# Results:
#       Returns 1 if the message is handled successfully, and 0 otherwise.

proc discord::gateway::OpHandler { sock msg } {
    set op [dict get $msg op]
    if ![CheckOp $op] {
        return 0
    }

    set opToken [dict get $::discord::gateway::OpTokens $op]
    ${::discord::gateway::log}::debug "OpHandler: op: $op ($opToken)"

    switch -glob -- $opToken {
        DISPATCH {
            EventHandler $sock $msg
        }
        RECONNECT {
            SendResume $sock
        }
        INVALID_SESSION {
            SendIdentify $sock
        }
        HELLO {
            SetConnectionInfo $sock heartbeat_interval [dict get $msg heartbeat_interval]
        }
        HEARTBEAT_ACK {
            ${::discord::gateway::log}::debug "OpHandler: Heartbeat ACK received"
        }
        default {
            ${::discord::gateway::log}::warn "op not implemented: ($opToken)"
            return 0
        }
    }
    return 1
}

# discord::gateway::TextHandler --
#
#       Handles all WebSocket text messages.
#
# Arguments:
#       sock    WebSocket object.
#       msg     The message as a JSON string.
#
# Results:
#       Returns 1 if the message is handled successfully, and 0 otherwise.

proc discord::gateway::TextHandler { sock msg } {
    if {[catch {::rest::format_json $msg} res]} {
        ${::discord::gateway::log}::error "TextHandler: $res"
        return
    }
    if {[dict exists $res op]} {
        OpHandler $sock $res
        return 1
    } else {
        ${::discord::gateway::log}::warn "TextHandler: no op: $msg"
        return 0
    }
}

# discord::gateway::Handler --
#
#       Callback procedure invoked when a WebSocket message is received.
#
# Arguments:
#       sock    WebSocket object.
#       msg     The message as a dictionary that represents a JSON object.
#
# Results:
#       Returns 1 if the message is handled successfully, and 0 otherwise.

proc discord::gateway::Handler { sock type msg } {
    ${::discord::gateway::log}::debug "Handler: type: $type"
    switch -glob -- $type {
        text {
            TextHandler $sock $msg
        }
        binary {
            if {![catch {::inflate $msg} res]} {
                TextHandler $sock $res
            } else {
                ${::discord::gateway::log}::warn \
                        "Handler: [string length $res] bytes of binary data."
            }
        }
        connect {
            SendIdentify $sock
        }
        close -
        disconnect {
            ::discord::gateway::Every cancel [list ::discord::gateway::SendHeartbeat $sock]
            dict unset ::discord::gateway::Sockets $sock
        }
        ping {
            ${::discord::gateway::log}::notice "Handler: ping: $msg"
        }
        default {
            ${::discord::gateway::log}::warn \
                    "Handler: type not implemented: '$type'"
            return 0
        }
    }
    ${::discord::gateway::log}::debug "Exit Handler"
    return 1
}

# discord::gateway::Send --
#
#       Send WebSocket messages to the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#       opToken A token string that is one of the values in the dictionary
#               discord::gateway::OpTokens.
#       data    The data to be sent.
#
# Results:
#       Returns 1 if the message is sent successfully, and 0 otherwise.

proc discord::gateway::Send { sock opToken data } {
    if ![dict exists $::discord::gateway::Op $opToken] {
        ${::discord::gateway::log}::error "Invalid op name: '$opToken'"
        return
    }
    set op [dict get $::discord::gateway::Op $opToken]

    set payload [::json::write::object op $op d $data]
    if [catch {::websocket::send $sock text $payload} res] {
        ${::discord::gateway::log}::error "::websocket::send: $res"
        return 0
    }

    return 1
}

# discord::gateway::SendHeartbeat --
#
#       Tell the Gateway that you are alive. Do this periodically.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       Returns 1 if the message is sent successfully, and 0 otherwise.

proc discord::gateway::SendHeartbeat { sock } {
    return [Send $sock HEARTBEAT [GetConnectionInfo $sock s]]
}

# discord::gateway::SendIdentify --
#
#       Identify yourself to the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       Returns 1 if the message is sent successfully, and 0 otherwise.

proc discord::gateway::SendIdentify { sock args } {
    set token               [::json::write::string [GetConnectionInfo $sock token]]
    set os                  [::json::write::string linux]
    set browser             [::json::write::string "Tcl 8.5, websocket 1.4"]
    set device              [::json::write::string "Tcl 8.5, websocket 1.4"]
    set referrer            [::json::write::string ""]
    set referring_domain    [::json::write::string ""]
    set compress            [GetConnectionInfo $sock compress]
    set large_threshold     50
    set shard               [::json::write::array 0 1]
    foreach { option value } $args {
        if {[string index $option 0] ne -} {
            continue
        }
        set opt [string range $option 1 end]
        if {$opt ni {os browser device referrer referring_domain compress
                      large_threshold shard}} {
            ${::discord::gateway::log}::error "Invalid options: '$opt'"
            return
        }
        switch -glob -- $opt {
            compress {
                if {$value ni {true false}} {
                    ${::discord::gateway::log}::error "SendIdentify: compress: Invalid value: '$value'"
                    continue
                }
            }
            large_threshold {
                if {![string is integer -strict $value] \
                            || $value < 50 || $value > 250} {
                    ${::discord::gateway::log}::error "SendIdentify: large_threshold: Invalid value: '$value'"
                }
            }
        }
        set $opt $value
    }
    set d [::json::write::object \
              token $token \
              properties [::json::write::object \
                  {$os} $os \
                  {$browser} $browser \
                  {$device} $device \
                  {$referrer} $referrer \
                  {$referring_domain} $referring_domain] \
              compress $compress \
              large_threshold $large_threshold \
              shard $shard]
    return [Send $sock IDENTIFY $d]
}

# discord::gateway::SendResume --
#
#       Resume a connection after you are disconnected from the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       Returns 1 if the message is sent successfully, and 0 otherwise.

proc discord::gateway::SendResume { sock } {
    return [Send $sock RESUME [GetConnectionInfo $sock session_id]]
}

package provide discord $::discord::version

# Create a pkgIndex.tcl file in the same directory if this file is executed.

if {[info exists argv0] && [file tail [info script]] == [file tail $argv0]} {
    pkg_mkIndex -verbose [file dirname [info script]] [file tail [info script]]
}
