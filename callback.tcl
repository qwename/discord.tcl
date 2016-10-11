# callback.tcl --
#
#       This file implements the Tcl code for callback procedures.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.5

namespace eval discord::callback::event { }

# discord::callback::event::Ready --
#
#       Callback procedure for Dispatch Ready event. Get our user object, list
#       of DM channels, guilds, and session_id.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       Updates variables in session namespace.

proc discord::callback::event::Ready { event data sessionNs } {
    $sessionNs var self [dict get $data user]
    foreach guild [dict get $data guilds] {
        $sessionNs var guilds [dict get $guild id] $guild
    }
    foreach dmChannel [dict get $data private_channels] {
        $sessionNs var dmChannels [dict get $dmChannel id] $dmChannel
    }
    $sessionNs var sessionId [dict get $data session_id]
    return
}

# discord::callback::event::ChannelCreate --
#
#       Callback procedure for Dispatch Channel Create event.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       Update channel information in session guild.

proc discord::callback::event::ChannelCreate { event data sessionNs } {
    set log $::discord::log
    puts "Channel Create: $data"
    set isDM [expr {[dict get $data is_private] eq "true"}]
    set id [dict get $data id]
    if {$isDM} {
        dict set ${sessionNs}::dmChannels $id $data
        set user [dict get $data recipient]
        foreach field {username discriminator} {
            set $field [dict get $user $field]
        }
        ${log}::debug "DM Channel Created with ${username}#$discriminator"
    } else {
        set guildId [dict get $data guild_id]
    }
    return
}

# discord::callback::event::GuildCreate --
#
#       Callback procedure for Dispatch Guild Create event.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       Update guild information in session guilds.

proc discord::callback::event::GuildCreate { event data sessionNs } {
    set log $::discord::log
    set id [dict get $data id]
    dict set ${sessionNs}::guilds $id $data
    set name [dict get $data name]
    ${log}::debug "Guild '$name' ($id) ready."
    return
}
