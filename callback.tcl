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
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       Updates variables in session namespace.

proc discord::callback::event::Ready { sessionNs event data } {
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
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       Modify session channel information.

proc discord::callback::event::Channel { sessionNs event data } {
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
        set userId [dict get $user id]
        foreach field {username discriminator} {
            set $field [dict get $user $field]
        }
        ${log}::debug "$typeName $event: ${username}#$discriminator ($userId)"
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
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       Modify session guild information.

proc discord::callback::event::Guild { sessionNs event data } {
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
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       None.

proc discord::callback::event::GuildBan { sessionNs event data } {
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

# discord::callback::event::GuildMember --
#
#       Callback procedure for Dispatch Guild Member events Add, Remove, Update.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       Modify session guild information.

proc discord::callback::event::GuildMember { sessionNs event data } {
    set log [set ${sessionNs}::log]
    set user [dict get $data user]
    set id [dict get $user id]
    set guildId [dict get $data guild_id]
    set members [dict get [set ${sessionNs}::guilds] $guildId members]
    switch $event {
        GUILD_MEMBER_ADD {
            lappend members [dict remove $data guild_id]
            dict set ${sessionNs}::guilds $guildId members $members
        }
        GUILD_MEMBER_REMOVE {
            set newMembers [list]
            foreach member $members {
                if {$id == [dict get $member user id]} {
                    continue
                } else {
                    lappend newMembers $member
                }
            }
            dict set ${sessionNs}::guilds $guildId members $newMembers
        }
        GUILD_MEMBER_UPDATE {
            set newMembers [list]
            foreach member $members {
                if {$id == [dict get $member user id]} {
                    dict for {field value} [dict remove $data guild_id] {
                        dict set member $field $value
                    }
                }
                lappend newMembers $member
            }
            dict set ${sessionNs}::guilds $guildId members $newMembers
        }
        default {
            ${log}::error "GuildMember: Invalid event: '$event'"
            return
        }
    }
    set guildName [dict get [set ${sessionNs}::guilds] $guildId name]
    foreach field {username discriminator} {
        set $field [dict get $user $field]
    }
    ${log}::debug [join "$event '$guildName' ($guildId):" \
            "${username}#$discriminator ($id)"]
    return
}

# discord::callback::event::GuildRole --
#
#       Callback procedure for Dispatch Guild Role events Create, Update,
#       Delete.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       event       Event name.
#       data        Dictionary representing a JSON object
#
# Results:
#       Modify session guild information.

proc discord::callback::event::GuildRole { sessionNs event data } {
    set log [set ${sessionNs}::log]
    set role [dict get $data role]
    foreach field {id name} {
        set $field [dict get $role $field]
    }
    set guildId [dict get $data guild_id]
    set roles [dict get [set ${sessionNs}::guilds] $guildId roles]
    switch $event {
        GUILD_ROLE_CREATE {
            lappend roles $role
            dict set ${sessionNs}::guilds $guildId roles $roles
        }
        GUILD_ROLE_UPDATE {
            set newRoles [list $role]
            foreach r $roles {
                if {$id == [dict get $r id]} {
                    continue
                } else {
                    lappend newRoles $r
                }
            }
            dict set ${sessionNs}::guilds $guildId roles $newRoles
        }
        GUILD_ROLE_DELETE {
            set newRoles [list]
            foreach r $roles {
                if {$id == [dict get $r id]} {
                    continue
                } else {
                    lappend newRoles $r
                }
            }
            dict set ${sessionNs}::guilds $guildId roles $newRoles
        }
        default {
            ${log}::error "GuildMember: Invalid event: '$event'"
            return
        }
    }
    set guildName [dict get [set ${sessionNs}::guilds] $guildId name]
    ${log}::debug "$event '$guildName' ($guildId): '$name' ($id)"
    return
}
