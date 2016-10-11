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

    set log [set ${sessionNs}::log]
    ${log}::debug "Ready"
    return
}

# discord::callback::event::Channel --
#
#       Callback procedure for Dispatch Channel events Create, Update, Delete.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       Modify session channel information.

proc discord::callback::event::Channel { event data sessionNs } {
    set log [set ${sessionNs}::log]
    set id [dict get $data id]
    set typeNames [dict create 0 Text 1 DM 2 Voice]
    set type [dict get $data type]
    if {![dict exists $typeNames $type]} {
        ${log}::warn "ChannelCreate: Unknown type '$type': $data"
        return
    }
    set typeName [dict get $typeNames $type]
    if {$typeName eq "DM"} {
        switch $event {
            CHANNEL_CREATE -
            CHANNEL_UPDATE {
                dict set ${sessionNs}::dmChannels $id $data
            }
            CHANNEL_DELETE {
                dict unset ${sessionNs}::dmChannels $id
            }
            default {
                ${log}::error "$typeName Channel: Invalid event: '$event'"
                return
            }
        }
        set user [dict get $data recipient]
        foreach field {username discriminator} {
            set $field [dict get $user $field]
        }
        ${log}::debug "$event $typeName: ${username}#$discriminator"
    } else {
        set guildId [dict get $data guild_id]
        set channels [dict get [set ${sessionNs}::guilds] $guildId channels]
        switch $event {
            CHANNEL_CREATE {
                lappend channels $data
                dict set ${sessionNs}::guilds $guildId channels $channels
            }
            CHANNEL_UPDATE {
                set newChannels [list $data]
                foreach channel $channels {
                    if {$id == [dict get $channel id]} {
                        continue
                    } else {
                        lappend newChannels $channel
                    }
                }
                dict set ${sessionNs}::guilds $guildId channels $newChannels
            }
            CHANNEL_DELETE {
                set newChannels [list]
                foreach channel $channels {
                    if {$id == [dict get $channel id]} {
                        continue
                    } else {
                        lappend newChannels $channel
                    }
                }
                dict set ${sessionNs}::guilds $guildId channels $newChannels
            }
            default {
                ${log}::error "$typeName Channel: Invalid event: '$event'"
                return
            }
        }
        set name [dict get $data name]
        ${log}::debug "$typeName $event: '$name' ($id)"
    }
    return
}

# discord::callback::event::Guild --
#
#       Callback procedure for Dispatch Guild events Create, Update, Delete.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       Modify session guild information.

proc discord::callback::event::Guild { event data sessionNs } {
    set log [set ${sessionNs}::log]
    set id [dict get $data id]
    switch $event {
        GUILD_CREATE {
            dict set ${sessionNs}::guilds $id $data
        }
        GUILD_UPDATE {
            dict for {field value} $data {
                dict set ${sessionNs}::guilds $id $field $value
            }
        }
        GUILD_DELETE {
            dict unset ${sessionNs}::guilds $id
        }
        default {
            ${log}::error "Guild: Invalid event: '$event'"
            return
        }
    }

    set name [dict get $data name]
    ${log}::debug "$event: '$name' ($id)"
    return
}

# discord::callback::event::GuildBan --
#
#       Callback procedure for Dispatch Guild Ban events Add, Remove.
#
# Arguments:
#       event       Event name.
#       data        Dictionary representing a JSON object
#       sessionNs   Name of session namespace.
#
# Results:
#       None.

proc discord::callback::event::GuildBan { event data sessionNs } {
    set log [set ${sessionNs}::log]
    set id [dict get $data id]
    set guildId [dict get $data guild_id]
    switch $event {

        # GUILD_MEMBER_REMOVE follows GUILD_BAN_ADD, so no action is required
        # here for both Add/Remove

        GUILD_BAN_ADD -
        GUILD_BAN_REMOVE {
            set guildName [dict get [set ${sessionNs}::guilds] $guildId name]
            foreach field {username discriminator} {
                set $field [dict get $data $field]
            }
            ${log}::debug [join "$event '$guildName' ($guildId):" \
                    "${username}#$discriminator ($id)"
        }
        default {
            ${log}::error "GuildBan: Invalid event: '$event'"
            return
        }
    }
    return
}