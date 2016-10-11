# gateway.tcl --
#
#       This file implements the Tcl code for interacting with the Discord
#       Gateway.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.5
package require http
package require tls
package require websocket
package require json
package require json::write
package require logger

::http::register https 443 ::tls::socket

namespace eval discord::gateway {
    namespace export connect disconnect setCallback bindSession logWsMsg
    namespace ensemble create

    variable log [::logger::init discord::gateway]
    ${log}::setlevel debug

    variable LogWsMsg 0
    variable MsgLogLevel debug

    variable GatewayApiVer 6

    variable LimitPeriod 60
    variable LimitSend 120
    variable LimitStatusChange 5

    variable EventCallbacks {
        READY                       {}
        RESUME                      {}
        CHANNEL_CREATE              {}
        CHANNEL_UPDATE              {}
        CHANNEL_DELETE              {}
        GUILD_CREATE                {}
        GUILD_UPDATE                {}
        GUILD_DELETE                {}
        GUILD_BAN_ADD               {}
        GUILD_BAN_REMOVE            {}
        GUILD_EMOJIS_UPDATE         {}
        GUILD_INTEGRATIONS_UPDATE   {}
        GUILD_MEMBER_REMOVE         {}
        GUILD_MEMBER_UPDATE         {}
        GUILD_MEMBER_CHUNKS         {}
        GUILD_ROLE_UPDATE           {}
        GUILD_ROLE_DELETE           {}
        MESSAGE_CREATE              {}
        MESSAGE_UPDATE              {}
        MESSAGE_DELETE              {}
        MESSAGE_DELETE_BULK         {}
        PRESENCE_UPDATE             {}
        TYPING_START                {}
        USER_SETTINGS_UPDATE        {}
        USER_UPDATE                 {}
        VOICE_STATE_UPDATE          {}
        VOICE_SERVER_UPDATE         {}
    }

    # Compression only used for Dispatch "READY" event. Set CompressEnabled to 1
    # if you are able to get mkZiplib onto your system.

    variable CompressEnabled 0
    variable DefCompress false
    if $CompressEnabled {
        package require mkZiplib
        set DefCompress true
    }

    variable DefHeartbeatInterval 10000
    variable Sockets [dict create]

    variable OpTokens {
        0   DISPATCH
        1   HEARTBEAT
        2   IDENTIFY
        3   STATUS_UPDATE
        4   VOICE_STATE_UPDATE
        5   VOICE_SERVER_PING
        6   RESUME
        7   RECONNECT
        8   REQUEST_GUILD_MEMBERS
        9   INVALID_SESSION
        10  HELLO
        11  HEARTBEAT_ACK
    }
    variable ProcOps {
        Heartbeat   1
        Identify    2
        Resume      6
    }

}

# discord::gateway::connect --
#
#       Establish a WebSocket connection to the Gateway.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       cmd         (optional) fully-qualified name of a callback procedure that
#                   is invoked before the Identify message is sent. Accepts one
#                   argument 'sock', which can be used to register Dispatch
#                   event callbacks using discord::gateway::eventCallbacks.
#       shardInfo   (optional) list with two elements, the shard ID and number
#                   of shards. Defaults to {0 1}, meaning shard ID 0 and 1 shard
#                   in total.
#
# Results:
#       Returns the connection's WebSocket object if successful, an empty string
#       otherwise.

proc discord::gateway::connect { token {cmd {}} {shardInfo {0 1}} } {
    variable log
    variable GatewayApiVer
    variable DefHeartbeatInterval
    variable DefCompress
    variable EventCallbacks
    set gateway [discord::GetGateway]
    if {$gateway eq ""} {
        ${log}::error "connect: Unable to get Gateway URL."
        return ""
    }
    append gateway "/?v=${GatewayApiVer}&encoding=json"
    ${log}::notice "Connecting to the Gateway: $gateway"
    if {[catch {::websocket::open $gateway ::discord::gateway::Handler} sock]} {
        ${log}::error "connect: $gateway: $sock"
        return ""
    }
    SetConnectionInfo $sock connectCallback $cmd
    SetConnectionInfo $sock eventCallbacks [dict get $EventCallbacks]
    SetConnectionInfo $sock sendCount 0
    SetConnectionInfo $sock shard $shardInfo
    SetConnectionInfo $sock seq null
    SetConnectionInfo $sock token $token
    SetConnectionInfo $sock session_id null
    SetConnectionInfo $sock heartbeat_interval $DefHeartbeatInterval
    SetConnectionInfo $sock compress $DefCompress
    SetConnectionInfo $sock session ""
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

# Manually construct the Close frame body, as the websocket library's close
# procedure does not actually send anything as of version 1.4.

	set msg [binary format Su 1000]
	set msg [string range $msg 0 124];
	::websocket::send $sock 8 $msg
    return
}

# discord::gateway::setCallback --
#
#       Register a callback procedure for a specified Dispatch event. The
#       callback is invoked after the event is handled by EventHandler; it
#       will accept two required arguments, 'event' and 'data', and an optional
#       argument 'session'. Refer to discord::gateway::DefEventCallback for an
#       example.
#
# Arguments:
#       sock    WebSocket object.
#       event   Event name.
#       cmd     Fully-qualified name of the callback command. Set this to the
#               empty string to unregister the callback for an event.
#
# Results:
#       Returns 1 if the event is supported, 0 otherwise.

proc discord::gateway::setCallback { sock event cmd } {
    variable log
    set eventCallbacks [GetConnectionInfo $sock eventCallbacks]
    if {![dict exists $eventCallbacks $event]} {
        return 0
    } else {
        dict set eventCallbacks $event $cmd
        SetConnectionInfo $sock eventCallbacks $eventCallbacks
        ${log}::debug "Registered callback for event '$event': $cmd"
        return 1
    }
}

# discord::gateway::bindSession --
#
#       Set the session namespace that a WebSocket object belongs to.
#
# Arguments:
#       sock        WebSocket object.
#       sessionNs   Session namespace returned by discord::connect
#
# Results:
#       Returns 1 if successful, and 0 otherwise.

proc discord::gateway::bindSession { sock sessionNs } {
    variable log
    if {[catch {SetConnectionInfo $sock session $sessionNs} res]} {
        ${log}::error "bindSession: $res"
        return 0
    } else {
        return 1
    }
}

# discord::gateway::logWsMsg --
#
#       Toggle logging of sent and received WebSocket text messages.
#
# Arguments:
#       on      Disable printing when set to 0, enabled otherwise.
#       level   (optional) Logging level to print messages to. Levels are
#               debug, info, notice, warn, error, critical, alert, emergency.
#               Defaults to debug.
#
# Results:
#       Returns 1 if changes were made, 0 otherwise.

proc discord::gateway::logWsMsg { on {level "debug"} } {
    variable LogWsMsg
    variable MsgLogLevel
    if {$level ni {debug info notice warn error critical alert emergency}} {
        return 0
    }
    if {$on == 0} {
        set LogWsMsg 0
    } else {
        set LogWsMsg 1
    }
    set MsgLogLevel $level
    return 1
}

# discord::gateway::Every --
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

proc discord::gateway::Every {interval script} {
    variable log
    variable EveryIds
    ${log}::debug [info level 0]
    if {$interval eq "cancel"} {
        catch {after cancel $EveryIds($script)}
        return
    }
    set afterId [after $interval [info level 0]]
    set EveryIds($script) $afterId
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
    return [dict get $::discord::gateway::Sockets $sock $what]
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
    return [dict set ::discord::gateway::Sockets $sock $what $value]
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
    variable log
    variable OpTokens
    if ![dict exists $OpTokens $op] {
        ${log}::error "op not supported: '$op'"
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
    variable log
    set t [dict get $msg t]
    set s [dict get $msg s]
    set d [dict get $msg d]
    SetConnectionInfo $sock seq $s
    ${log}::debug "EventHandler: sock: '$sock' t: '$t' seq: $s"
    switch -glob -- $t {
        READY {
            foreach field [dict keys $d] {
                switch $field {
                    default {
                        SetConnectionInfo $sock $field [dict get $d $field]
                    }
                }
            }

            set interval [GetConnectionInfo $sock heartbeat_interval]
            ${log}::debug "EventHandler: Sending heartbeat every $interval ms"
            ::discord::gateway::Every $interval \
                    [list ::discord::gateway::Send $sock Heartbeat]
        }
        RESUME {    ;# Not much to do here
            if {[dict exists $d _trace]} {
                SetConnectionInfo $sock _trace [dict get $d _trace]
            }
        }
    }
    set eventCallbacks [GetConnectionInfo $sock eventCallbacks]
    set callback {}
    set knownEvent [dict exists $eventCallbacks $t]
    if {$knownEvent} {
        set callback [dict get $eventCallbacks $t]
    } else {
        ${log}::warn "EventHandler: Unknown Event: $t"
    }
    if {$callback == {}} {
        set callback discord::gateway::DefEventCallback
    }
    after idle [list ::$callback $t $d [GetConnectionInfo $sock session]]
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

    variable log
    variable OpTokens
    set opToken [dict get $OpTokens $op]
    ${log}::debug "OpHandler: op: $op ($opToken)"

    switch -glob -- $opToken {
        DISPATCH {
            after idle [list discord::gateway::EventHandler $sock $msg]
        }
        RECONNECT {
            after idle [list discord::gateway::Send $sock Resume]
        }
        INVALID_SESSION {
            after idle [list discord::gateway::Send $sock Identify]
        }
        HELLO {
            SetConnectionInfo $sock heartbeat_interval \
                    [dict get $msg d heartbeat_interval]
        }
        HEARTBEAT_ACK {
            ${log}::debug "OpHandler: Heartbeat ACK received"
        }
        default {
            ${log}::warn "OpHandler: op not implemented: ($opToken)"
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
    variable log
    variable LogWsMsg
    variable MsgLogLevel
    if {$LogWsMsg} {
        ${log}::${MsgLogLevel} "TextHandler: msg: $msg"
    }
    if {[catch {::json::json2dict $msg} res]} {
        ${log}::error "TextHandler: $res"
        return 0
    }
    if {[dict exists $res op]} {
        after idle [list discord::gateway::OpHandler $sock $res]
        return 1
    } else {
        ${log}::warn "TextHandler: no op: $res"
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
    variable log
    variable Sockets
    ${log}::debug "Handler: type: $type"
    switch -glob -- $type {
        text {
            after idle [list discord::gateway::TextHandler $sock $msg]
        }
        binary {
            if {![catch {::inflate $msg} res]} {
                after idle [list discord::gateway::TextHandler $sock $res]
            } else {
                set bytes [string length $res]
                ${log}::warn "Handler: $bytes bytes of binary data."
            }
        }
        connect {
            set callback [GetConnectionInfo $sock connectCallback]
            if {$callback != {}} {
                ::$callback $sock
            }
            after idle [list discord::gateway::Send $sock Identify]
            ${log}::notice "Handler: Connected."
        }
        close {
            ::discord::gateway::Every cancel \
                    [list ::discord::gateway::Send $sock Heartbeat]
            ${log}::notice "Handler: Connection closed."
        }
        disconnect {
            dict unset Sockets $sock
            ${log}::notice "Handler: Disconnected."
        }
        ping {      ;# Not sure if Discord uses this.
            ${log}::notice "Handler: ping: $msg"
        }
        default {
            ${log}::warn "Handler: type not implemented: '$type'"
            return 0
        }
    }
    ${log}::debug "Exit Handler"
    return 1
}

# discord::gateway::Send --
#
#       Send WebSocket messages to the Gateway, rate limited to 120 per minute.
#
# Arguments:
#       sock    WebSocket object.
#       opProc  Suffix of the Make* procedure that returns the message data.
#       args    Arguments to pass to opProc.
#
# Results:
#       Returns 1 if the message is sent successfully, and 0 otherwise.

proc discord::gateway::Send { sock opProc args } {
    variable log
    variable ProcOps
    variable LogWsMsg
    variable MsgLogLevel
    variable LimitPeriod
    variable LimitSend
    set sendCount [GetConnectionInfo $sock sendCount]
    if {$sendCount == 0} {
        after [expr {$LimitPeriod * 1000}] \
                [list discord::gateway::SetConnectionInfo $sock sendCount 0]
    }
    if {$sendCount >= $LimitSend} {
        ${log}::warn "Send: Reached $LimitSend messages sent in $LimitPeriod s"
        return 0
    }
    if {![dict exists $ProcOps $opProc]} {
        ${log}::error "Invalid procedure suffix: '$opProc'"
        return 0
    }
    set op [dict get $ProcOps $opProc]
    set data [Make${opProc} $sock {*}$args]
    set msg [::json::write::object op $op d $data]
    if {$LogWsMsg} {
        ${log}::${MsgLogLevel} "Send: $msg"
    }
    if [catch {::websocket::send $sock text $msg} res] {
        ${log}::error "::websocket::send: $res"
        return 0
    }
    SetConnectionInfo $sock sendCount [incr sendCount]
    return 1
}

# discord::gateway::MakeHeartbeat --
#
#       Create a message to tell the Gateway that you are alive. Do this
#       periodically.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       Returns the last sequence number received.

proc discord::gateway::MakeHeartbeat { sock } {
    return [GetConnectionInfo $sock seq]
}

# discord::gateway::MakeIdentify --
#
#       Create a message to identify yourself to the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#       args    List of options and their values to set in the message. Prepend
#               options with a '-'. Accepted options are: os, browser, device,
#               referrer, referring_domain, compress, large_threshold, shard.
#               Example: -os linux
#
# Results:
#       Returns a JSON object containing the required information.

proc discord::gateway::MakeIdentify { sock args } {
    variable log
    set token               [::json::write::string \
                                    [GetConnectionInfo $sock token]]
    set os                  [::json::write::string linux]
    set browser             [::json::write::string "discord.tcl 0.1"]
    set device              [::json::write::string "discord.tcl 0.1"]
    set referrer            [::json::write::string ""]
    set referring_domain    [::json::write::string ""]
    set compress            [GetConnectionInfo $sock compress]
    set large_threshold     50
    set shardInfo [GetConnectionInfo $sock shard]
    set shardId [lindex $shardInfo 0]
    set numShards [lindex $shardInfo 1]
    if {![string is integer -strict $numShards] || $numShards < 1} {
        ${log}::warning \
                "MakeIdentify: Invalid num_shards, setting to 1: $numShards"
        set numShards 1
    }
    if {![string is integer -strict $shardId] || $shardId < 0 \
            || $numShards <= $shardId} {
        ${log}::warning "MakeIdentify: Invalid shard_id, setting to 0: $shardId"
        set shardId 0
    }
    set shard               [::json::write::array $shardId $numShards]
    foreach { option value } $args {
        if {[string index $option 0] ne -} {
            continue
        }
        set opt [string range $option 1 end]
        if {$opt ni {os browser device referrer referring_domain compress
                      large_threshold shard}} {
            ${log}::error "MakeIdentify: Invalid option: '$opt'"
            continue
        }
        switch -glob -- $opt {
            compress {
                if {$value ni {true false}} {
                    ${log}::error \
                            "MakeIdentify: compress: Invalid value: '$value'"
                    continue
                }
            }
            large_threshold {
                if {![string is integer -strict $value] \
                            || $value < 50 || $value > 250} {
                    ${log}::error \
                        "MakeIdentify: large_threshold: Invalid value: '$value'"
                    continue
                }
            }
        }
        set $opt $value
    }
    return [::json::write::object \
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
}

# discord::gateway::MakeResume --
#
#       Create a message to resume a connection after you are disconnected from 
#       the Gateway.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       Returns a JSON object containing the required information.

proc discord::gateway::MakeResume { sock } {
    return [::json::write::object \
            token [GetConnectionInfo $sock token] \
            session_id [GetConnectionInfo $sock session_id] \
            seq [GetConnectionInfo $sock seq]]
}

# discord::gateway::DefEventCallback --
#
#       Stub for Dispatch events.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   (option) name of session namespace.
#
# Results:
#       None.

proc discord::gateway::DefEventCallback { event data {sessionNs ""} } {
    return
}
