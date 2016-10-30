# permissions.tcl --
#
#       This file implements the Tcl code for working with Discord permissions.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

namespace eval discord {
    variable PermissionInfo {
        CREATE_INSTANT_INVITE   0x00000001  {
            Allows creation of instant invites.
        }
        KICK_MEMBERS            0x00000002  {
            Allows kicking members.
        }
        BAN_MEMBERS             0x00000004  {
            Allows banning members.
        }
        ADMINISTRATOR           0x00000008  {
            Allows all permissions and bypasses channel permission overwrites.
        }
        MANAGE_CHANNELS         0x00000010  {
            Allows management and editing of channels.
        }
        MANAGE_GUILD            0x00000020  {
            Allows management and editing of the guild.
        }
        READ_MESSAGES           0x00000400  {
            Allows reading messages in a channel. The channel will not appear
            for users without this permission.
        }
        SEND_MESSAGES           0x00000800  {
            Allows for sending messages in a channel..
        }
        SEND_TTS_MESSAGES       0x00001000  {
            Allows for sending of /tts messages.
        }
        MANAGE_MESSAGES         0x00002000  {
            Allows for deletion of other users messages.
        }
        EMBED_LINKS             0x00004000  {
            Links sent by this user will be auto-embedded.
        }
        ATTACH_FILES            0x00008000  {
            Allows for uploading images and files.
        }
        READ_MESSAGE_HISTORY    0x00010000  {
            Allows for reading of message history.
        }
        MENTION_EVERYONE        0x00020000  {
            Allows for using the @everyone tag to notify all users in a channel,
            and the @here tag to notify all online users in a channel.
        }
        USE_EXTERNAL_EMOJIS     0x00040000  {
            Allows the usage of custom emojis from other servers.
        }
        CONNECT                 0x00100000  {
            Allows for joining of a voice channel.
        }
        SPEAK                   0x00200000  {
            Allows for speaking in a voice channel.
        }
        MUTE_MEMBERS            0x00400000  {
            Allows for muting members in a voice channel.
        }
        DEAFEN_MEMBERS          0x00800000  {
            Allows for deafening of members in a voice channel.
        }
        MOVE_MEMBERS            0x01000000  {
            Allows for moving of members between voice channels.
        }
        USE_VAD                 0x02000000  {
            Allows for using voice-activity-detection in a voice channel.
        }
        CHANGE_NICKNAME         0x04000000  {
            Allows for modification of own nickname.
        }
        MANAGE_NICKNAMES        0x08000000  {
            Allows for modification of other users nicknames.
        }
        MANAGE_ROLES            0x10000000  {
            Allows management and editing of roles.
        }
    }
    variable Permissions [dict create]
    variable PermissionValues [dict create]
    variable PermissionDescriptions [dict create]
    foreach {permission value description} $PermissionInfo {
        set value [expr {$value}]
        set description [string trim $description]
        dict set Permissions [expr {$value}] $permission
        dict set PermissionValues $permission $value
        dict set PermissionDescriptions $permission $description
    }
}

# discord::GetPermissions --
#
#       Get a list of permissions for the permissions integer.
#
# Arguments:
#       permissions Integer.
#
# Results:
#       Returns a list of permission tokens, or raises an error if the
#       permissions integer is invalid.

proc discord::GetPermissions { permissions } {
    if {![string is integer -strict $permissions]} {
        return -code error "Not an integer: $permissions"
    }
    variable Permissions
    set permissions [expr {$permissions & 0xffffffff}]
    set permList [list]
    dict for {value permission} $Permissions {
        if {[expr {$permissions & $value}]} {
            lappend permList $permission
        }
    }
    return $permList
}

# discord::SetPermissions --
#
#       Add permissions to an existing permissions integer.
#
# Arguments:
#       permissions Integer
#       permList    List of permission tokens. Can be globs-style patterns.
#
# Results:
#       Returns the new permissions integer, or raises an error if the
#       permissions integer is invalid.

proc discord::SetPermissions { permissions permList } {
    if {![string is integer -strict $permissions]} {
        return -code error "Not an integer: $permissions"
    }
    variable PermissionValues
    foreach permission $permList {
        foreach match [dict keys $PermissionValues $permission] {
            set value [dict get $PermissionValues $match]
            set permissions [expr {$permissions | $value}]
        }
    }
    return $permissions
}

# discord::HasPermissions --
#
#       Check if a permissions integer matches the minimum number of permissions
#       in the permission token list.
#
# Arguments:
#       permissions Integer.
#       permList    List of permission tokens.
#       minMatch    Minimum number of elements in permList to match. Specify
#                   0 to match all. Defaults to 0.
#
# Results:
#       Returns 1 if the permissions integer has at least the specified number
#       of matches, or 0 otherwise. An error will be raised if the permissions
#       integer is invalid.

proc discord::HasPermissions { permissions permList {minMatch 0} } {
    if {![string is integer -strict $permissions]} {
        return -code error "Not an integer: $permissions"
    }
    if {![string is integer -strict $minMatch] || $minMatch < 0} {
        return -code error "Invalid minimum match count: $minMatch"
    }
    set permMatch 0
    set totalMatch 0
    variable PermissionValues
    foreach permission $permList {
        set matched 0
        foreach match [dict keys $PermissionValues $permission] {
            set value [dict get $PermissionValues $match]
            if {[expr {$permissions & $value}]} {
                set matched 1
                incr totalMatch
            }
        }
        if {$matched} {
            incr permMatch
        }
    }
    return [expr {($minMatch == 0 && $permMatch >= [llength $permList])
            || ($minMatch != 0 && $permMatch >= $minMatch)}]
}

# discord::GetPermissionDescription --
#
#       Get the description for a permission.
#
# Arguments:
#       permission  Permission token.
#
# Returns:
#       Returns the description string for the permission, or raises an error if
#       the permission is invalid.

proc discord::GetPermissionDescription { permission } {  
    variable PermissionDescriptions
    if {[dict exists $PermissionDescriptions $permission]} {
        return [dict get $PermissionDescriptions $permission]
    } else {
        return -code error "Invalid permission: $permission"
    }
}
