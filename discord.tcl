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
    namespace export connect disconnect setCallback
    namespace ensemble create

    variable version 0.5.0
    variable UserAgent "DiscordBot (discord.tcl, $version)"

    ::http::config -useragent $UserAgent

    variable ApiBaseUrl "https://discordapp.com/api"

    variable log [::logger::init discord]
    ${log}::setlevel debug

    variable SessionId 0

    variable DefCallbacks {
        READY                       {}
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
        GUILD_MEMBER_ADD            {}
        GUILD_MEMBER_REMOVE         {}
        GUILD_MEMBER_UPDATE         {}
        GUILD_MEMBERS_CHUNK         {}
        GUILD_ROLE_CREATE           {}
        GUILD_ROLE_UPDATE           {}
        GUILD_ROLE_DELETE           {}
        MESSAGE_CREATE              {}
        MESSAGE_UPDATE              {}
        MESSAGE_DELETE              {}
        MESSAGE_DELETE_BULK         {}
        PRESENCE_UPDATE             {}
        USER_UPDATE                 {}
    }
    set EventToProc {
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
}

# discord::connect --
#
#       Starts a new session. Connects to the Discord Gateway, and update
#       session details continuously by monitoring Dispatch events.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token
#       cmd         (optional) list that includes a callback procedure, and any
#                   arguments to be passed to the callback. The last argument
#                   passed will be the session namespace, which can be used to
#                   register event callbacks using discord::setCallback. The
#                   callback is invoked before the Identify message is sent, but
#                   after the library sets up internal callbacks.
#       shardInfo   (optional) list with two elements, the shard ID and number
#                   of shards. Defaults to {0 1}, meaning shard ID 0 and 1 shard
#                   in total.
#
# Results:
#       Returns the name of a namespace that is created for the session if the
#       connection is sucessful, and an empty string otherwise.

proc discord::connect { token {cmd {}} {shardInfo {0 1}} } {
    variable log
    variable DefCallbacks
    set sessionNs [CreateSession]
    set sock [gateway::connect $token \
            [list ::discord::SetupEventCallbacks $cmd $sessionNs] $shardInfo]
    if {$sock eq ""} {
        return ""
    }
    set ${sessionNs}::sock $sock
    set ${sessionNs}::token $token
    set ${sessionNs}::self [dict create]
    set ${sessionNs}::guilds [dict create]
    set ${sessionNs}::dmChannels [dict create]
    set ${sessionNs}::users [dict create]
    set ${sessionNs}::channels [dict create]
    set ${sessionNs}::callbacks $DefCallbacks
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

# discord::setCallback --
#
#       Register a callback procedure for a specified Dispatch event. The
#       callback is invoked after the event is handled by the library callback;
#       it will accept three arguments, 'sessionNs', 'event' and 'data'. Refer
#       to callback.tcl for examples.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       event       Event name.
#       cmd         List that includes a callback procedure, and any
#                   arguments to be passed to the callback. Set this to the
#                   empty string to unregister a callback.
#
# Results:
#       Returns 1 if the event is supported, 0 otherwise.

proc discord::setCallback { sessionNs event cmd } {
    variable log
    if {![dict exists [set ${sessionNs}::callbacks] $event]} {
        ${log}::error "Event not recognized: '$event'"
        return 0
    } else {
        dict set ${sessionNs}::callbacks $event $cmd
        ${log}::debug "Registered callback for event '$event': $cmd"
        return 1
    }
}

# discord::CreateSession --
#
#       Create a namespace for a session.
#
# Arguments:
#       None.
#
# Results:
#       Creates a namespace specific to a session. Returns the namespace name.

proc discord::CreateSession { } {
    variable SessionId
    set sessionNs ::discord::session::$SessionId
    incr SessionId
    namespace eval $sessionNs {
    }
    set ${sessionNs}::log [::logger::init $sessionNs]
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
#       cmd         List that contains a callback procedure and any other
#                   arguments to be passed it to. The last argument to the
#                   callback will be the session namespace. The callback  is
#                   invoked at the end of this procedure.
#       sessionNs   Name of a session namespace.
#       sock        WebSocket object.
#
# Results:
#       None.

proc discord::SetupEventCallbacks { cmd sessionNs sock } {
    foreach event [dict keys [set ${sessionNs}::callbacks]] {
        gateway::setCallback $sock $event \
                [list ::discord::ManageEvents $sessionNs]
    }
    if {[llength $cmd] > 0} {
        {*}$cmd $sessionNs
    }
    return
}

# discord::ManageEvents --
#
#       Invokes internal library callback and user-defined callback if any.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       None.

proc discord::ManageEvents { sessionNs event data } {
    variable EventToProc
    if {![catch {dict get $EventToProc $event} procName]} { 
        callback::event::$procName $sessionNs $event $data
    }
    if {![catch {dict get [set ${sessionNs}::callbacks] $event} cmd]
            && [llength $cmd] > 0} {
        {*}$cmd $sessionNs $event $data
    }
    return
}

package provide discord $::discord::version
