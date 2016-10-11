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
#       token       Bot token or OAuth2 bearer token
#       shardInfo   (optional) list with two elements, the shard ID and number
#                   of shards. Defaults to {0 1}, meaning shard ID 0 and 1 shard
#                   in total.
#
# Results:
#       Returns the name of a namespace that is created for the session if the
#       connection is sucessful, and an empty string otherwise.

proc discord::connect { token {shardInfo {0 1}} } {
    variable log
    variable SessionId
    set sock [gateway::connect $token ::discord::SetupEventCallbacks $shardInfo]
    if {$sock eq ""} {
        return ""
    }
    set id $SessionId
    incr SessionId
    set name ::discord::session::$id
    set sessionNs [CreateSession $name $sock $token]
    if {![gateway::bindSession $sock $sessionNs]} {
        ${log}::error "connect: Failed to bind session to WebSocket '$sock'"
        DeleteSession $sessionNs
        catch {gateway::disconnect $sock}
        return ""
    } else {
        return $sessionNs
    }
}

# discord::disconnect --
#
#       Stop an existing session. Disconnect from the Discord Gateway.
#
# Arguments:
#       sessionNs   Session namespace returned from discord::connect
#
# Results:
#       Deletes the session namespace. Returns 1 if sessionNs is valid, and 0
#       otherwise.

proc discord::disconnect { sessionNs } {
    variable log
    if {![namespace exists $sessionNs]} {
        ${log}::error "disconnect: Unknown session: '$sessionNs'"
        return 0
    }

    if {[catch {gateway::disconnect [$sessionNs var sock]} res]} {
        ${log}::error "disconnect: $res"
    }
    DeleteSession $sessionNs
    return 1
}

# discord::CreateSession --
#
#       Create a namespace for a session.
#
# Arguments:
#       sessionNs   Name of fully-qualified namespace to create.
#       sock        WebSocket object.
#       token       Bot token or OAuth2 bearer token.
#
# Results:
#       Creates a namespace with the variables sock and token present. Also
#       defines the procedure 'variable'. Returns the namespace name.

proc discord::CreateSession { sessionNs sock token } {
    namespace eval $sessionNs {
        namespace export variable
        namespace ensemble create

        # ${sessionNs}::variable --
        #
        #       Get or set a variable in the $sessionNs namespace.
        #
        # Arguments:
        #       name    Name of the variable.
        #       args    (optional) value to set the variable to.
        #
        # Results:
        #       If 'args' is specified, set 'name' to its value. If not
        #       return the value of 'name'. An error will occur if the variable
        #       does not exist and no value is specified.

        proc variable { name args } {
            ::variable $name
            if {[llength $args] > 0} {
                set $name $args
            }
            return [set $name]
        }
    }
    $sessionNs var sock $sock
    $sessionNs var token $token
    $sessionNs var self [dict create]
    $sessionNs var guilds [dict create]
    $sessionNs var dmChannels [dict create]
    $sessionNs var log [::logger::init $sessionNs]
    return $sessionNs
}

# discord::DeleteSession --
#
#       Delete a session namespace
#
# Arguments:
#       sessionNs   Name of fully-qualified namespace to delete.
#
# Results:
#       None.

proc discord::DeleteSession { sessionNs } {
    [set ${sessionNs}::log]::delete
    namespace delete $sessionNs
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

proc discord::Every { interval script } {
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

# discord::SetupEventCallbacks
#
#       Set callbacks for relevant Gateway Dispatch events. Invoked after a
#       connection to the Gateway is made, and before the Identify message is
#       sent.
#
# Arguments:
#       sock    WebSocket object.
#
# Results:
#       None.

proc discord::SetupEventCallbacks { sock } {
    set ns ::discord::callback::event
    gateway::setCallback $sock READY ${ns}::Ready
    gateway::setCallback $sock CHANNEL_CREATE ${ns}::Channel
    gateway::setCallback $sock CHANNEL_UPDATE ${ns}::Channel
    gateway::setCallback $sock CHANNEL_DELETE ${ns}::Channel
    gateway::setCallback $sock GUILD_CREATE ${ns}::Guild
    gateway::setCallback $sock GUILD_UPDATE ${ns}::Guild
    gateway::setCallback $sock GUILD_DELETE ${ns}::Guild
    gateway::setCallback $sock GUILD_BAN_ADD ${ns}::GuildBan
    gateway::setCallback $sock GUILD_BAN_REMOVE ${ns}::GuildBan
    return
}

package provide discord $::discord::version
