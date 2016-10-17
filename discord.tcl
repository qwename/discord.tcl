# discord.tcl --
#
#       This file implements the Tcl code for interacting with the Discord API.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.6
package require http
package require tls
package require json
package require logger

::http::register https 443 ::tls::socket

namespace eval discord {
    namespace export connect disconnect
    namespace ensemble create

    variable version 0.3.2

    variable log [::logger::init discord]
    ${log}::setlevel debug

    variable ApiBaseUrl "https://discordapp.com/api"
    variable ApiBaseUrlV6 "https://discordapp.com/api/v6"
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
    set id $SessionId
    incr SessionId
    set name ::discord::session::$id
    set sessionNs [CreateSession $name]
    set sock [gateway::connect $token \
            [list ::discord::SetupEventCallbacks $sessionNs] $shardInfo]
    if {$sock eq ""} {
        return ""
    }
    set ${sessionNs}::sock $sock
    set ${sessionNs}::token $token
    set ${sessionNs}::self [dict create]
    set ${sessionNs}::guilds [dict create]
    set ${sessionNs}::dmChannels [dict create]
    set ${sessionNs}::users [dict create]
    set ${sessionNs}::log [::logger::init $sessionNs]
    return $sessionNs
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

    if {[catch {gateway::disconnect [set ${sessionNs}::sock]} res]} {
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
#
# Results:
#       Creates a namespace specific to a session. Returns the namespace name.

proc discord::CreateSession { sessionNs } {
    namespace eval $sessionNs {
    }
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
    variable ApiBaseUrlV6
    variable GatewayUrl
    if {$GatewayUrl ne "" && $cached} {
        return $GatewayUrl
    }
    set reqUrl "${ApiBaseUrlV6}/gateway"
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
#       sessionNs   Name of a session namespace.
#       sock        WebSocket object.
#
# Results:
#       None.

proc discord::SetupEventCallbacks { sessionNs sock } {
    set eventToProc {
        READY                       Ready
        CHANNEL_CREATE              Channel
        CHANNEL_UPDATE              Channel
        CHANNEL_DELETE              Channel
        GUILD_CREATE                Guild
        GUILD_UPDATE                Guild
        GUILD_DELETE                Guild
        GUILD_BAN_ADD               GuildBan
        GUILD_BAN_REMOVE            GuildBan
        GUILD_EMOJIS_UPDATE         GuildEmojisUpdate
        GUILD_INTEGRATIONS_UPDATE   GuildIntegrationsUpdate
        GUILD_MEMBER_ADD            GuildMember
        GUILD_MEMBER_REMOVE         GuildMember
        GUILD_MEMBER_UPDATE         GuildMember
        GUILD_MEMBERS_CHUNK         GuildMembersChunk
        GUILD_ROLE_CREATE           GuildRole
        GUILD_ROLE_UPDATE           GuildRole
        GUILD_ROLE_DELETE           GuildRole
        MESSAGE_CREATE              Message
        MESSAGE_UPDATE              Message
        MESSAGE_DELETE              Message
        MESSAGE_DELETE_BULK         MessageDeleteBulk
        PRESENCE_UPDATE             PresenceUpdate
        USER_UPDATE                 UserUpdate
    }
    dict for {event proc} $eventToProc {
        gateway::setCallback $sock $event \
                [list ::discord::callback::event::$proc $sessionNs]
    }
    return
}

package provide discord $::discord::version
