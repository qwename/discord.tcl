# discord_wrapper.tcl --
#
#       This file implements the Tcl code that wraps around the procedures in
#       the disrest_*.tcl files.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

namespace eval discord {
    namespace export getChannel modifyChannel deleteChannel closeDM \
            getMessages getMessage sendMessage uploadFile editMessage \
            deleteMessage bulkDeleteMessages editChannelPermissions \
            deleteChannelPermission getChannelInvites createChannelInvite \
            triggerTyping getPinnedMessages pinMessage unpinMessage getGuild \
            modifyGuild getChannels createChannel changeChannelPositions \
            getMember getMembers addMember modifyMember kickMember getBans ban \
            unban getRoles createRole batchModifyRoles modifyRole deleteRole \
            getPruneCount prune createDM sendDM
    namespace ensemble create
}

# discord::GenApiProc --
#
#       Used in place of the proc command for easier programming of API calls
#       in the discord namespace. Code for dealing with coroutine will be
#       added.
#
# Arguments:
#       _name   Name of the procedure that will be created in the discord
#               namespace.
#       _args   Arguments that the procedure will accept.
#       _body   Script to run.
#
# Results:
#       A procedure discord::$name will be created, with these additions:
#       The argument "sessionNs" is prepended to the list of args.
#       The argument "getResult" is appended to the list of args.
#       The variable "cmd" should be passed to discord::rest procedures that
#       take a callback argument.

proc discord::GenApiProc { _name _args _body } {
    set _args [list sessionNs {*}$_args {getResult 0}]
    set _setup {
        if {$getResult == 1} {
            set _caller [uplevel info coroutine]
        } else {
            set _caller {}
        }
        set cmd [list]
        set _coro {}
        if {$_caller ne {}} {
            set _myName [lindex [info level 0] 0]
            dict incr ${sessionNs}::WrapperCallCount $_myName
            set _count [dict get [set ${sessionNs}::WrapperCallCount] $_myName]
            set _coro ${_myName}$_count
            set cmd [list coroutine $_coro discord::rest::CallbackCoroutine \
                    $_caller]
        }
    }
    proc ::discord::$_name $_args "$_setup\n$_body\nreturn \$_coro"
}

# Shared Arguments:
#       sessionNs   Name of session namespace.
#       getResult   (optional) boolean, set to 1 if the caller is a coroutine
#                   and will cleanup the returned result coroutine. Defaults to
#                   0, which means an empty string will be returned to the
#                   caller.

# Shared Results:
#       Returns a coroutine context name if the caller is a coroutine, and an
#       empty string otherwise. If the caller is a coroutine, it should yield
#       after calling this procedure. The caller can then get the HTTP response
#       by calling the returned coroutine. Refer to
#       discord::rest::CallbackCoroutine for more details.

# discord::getChannel --
#
#       Get a channel by ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getChannel { channelId } {
    rest::GetChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::modifyChannel --
#
#       Update a channel's settings.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, position, topic, bitrate, user_limit. All keys are
#                   optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc modifyChannel { channelId data } {
    rest::ModifyChannel [set ${sessionNs}::token] $channelId $data $cmd
}

# discord::deleteChannel --
#
#       Delete a guild channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc deleteChannel { channelId } {
    rest::DeleteChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::closeDM --
#
#       Close a DM channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      User ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc closeDM { userId } {
    set channelId {}
    dict for {id dmChan} [set ${sessionNs}::dmChannels] {
        set recipients [dict get $dmChan recipients]
        if {[llength $recipients] > 1} {
            continue
        }
        if {[dict get [lindex $recipients 0] id] eq $userId} {
            set channelId [dict get $dmChan id]
            break
        }
    }
    rest::DeleteChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::getMessages --
#
#       Get the messages for a channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   around, before, after, limit. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc getMessages { channelId data } {
    rest::GetChannelMessages [set ${sessionNs}::token] $channelId $data $cmd
}

# discord::getMessage --
#
#       Get a channel message by ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getMessage { channelId messageId } {
    rest::GetChannelMessage [set ${sessionNs}::token] $channelId $messageId $cmd
}

# discord::sendMessage --
#
#       Send a message to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       content     Message content.
#       getResult   See "Shared Arguments".

discord::GenApiProc sendMessage { channelId content } {
    rest::CreateMessage [set ${sessionNs}::token] $channelId \
            [dict create content $content] $cmd
}

# discord::uploadFile --
#
#       Upload a file to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       filename    Name of the file.
#       type        Content-Type value.
#       file        File data.
#       getResult   See "Shared Arguments".

discord::GenApiProc uploadFile { channelId filename type file } {
    rest::UploadFile [set ${sessionNs}::token] $channelId $filename $type \
            $file $cmd
}

# discord::editMessage --
#
#       Edit a message in the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       content     New message content.
#       getResult   See "Shared Arguments".

discord::GenApiProc editMessage { channelId messageId content } {
    rest::EditMessage [set ${sessionNs}::token] $channelId $messageId \
            [dict create content $content] $cmd
}

# discord::deleteMessage --
#
#       Delete a message from the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc deleteMessage { channelId messageId } {
    rest::DeleteMessage [set ${sessionNs}::token] $channelId $messageId $cmd
}

# discord::bulkDeleteMessages --
#
#       Bulk delete messages from the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageIds  List of Message IDs.
#       getResult   See "Shared Arguments".

discord::GenApiProc bulkDeleteMessages { channelId messageIds } {
    rest::BulkDeleteMessages [set ${sessionNs}::token] $channelId \
            [dict create messages $messageIds] $cmd
}

# discord::editChannelPermissions --
#
#       Edit the channel's permission overwrite.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       overwriteId Overwrite ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   allow, deny, type. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc editChannelPermissions { channelId overwriteId data } {
    rest::EditChannelPermissions [set ${sessionNs}::token] $channelId \
            $overwriteId $data $cmd
}

# discord::deleteChannelPermission --
#
#       Delete permission overwrite for the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       overwriteId Overwrite ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc deleteChannelPermission { channelId overwriteId } {
    rest::DeleteChannelPermission [set ${sessionNs}::token] $channelId \
            $overwriteId $cmd
}

# discord::getChannelInvites --
#
#       Get a list of invites for the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getChannelInvites { channelId } {
    rest::GetChannelInvites [set ${sessionNs}::token] $channelId $cmd
}

# discord::createChannelInvite --
#
#       Create a new invite for the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   max_age, max_uses, temporary, unique. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc createChannelInvite { channelId data } {
    rest::CreateChannelInvite [set ${sessionNs}::token] $channelId $data $cmd
}

# discord::triggerTyping --
#
#       Post a typing indicator to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc triggerTyping { channelId } {
    rest::TriggerTypingIndicator [set ${sessionNs}::token] $channelId $cmd
}

# discord::getPinnedMessages --
#
#       Get all pinned messages in the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getPinnedMessages { channelId } {
    rest::GetPinnedMessages [set ${sessionNs}::token] $channelId $cmd
}

# discord::pinMessage --
#
#       Pin a message in the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc pinMessage { channelId messageId } {
    rest::AddPinnedChannelMessage [set ${sessionNs}::token] $channelId \
            $messageId $cmd
}

# discord::unpinMessage --
#
#       Unpin message in the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc unpinMessage { channelId messageId } {
    rest::DeletePinnedChannelMessage [set ${sessionNs}::token] $channelId \
            $messageId $cmd
}

# discord::getGuild --
#
#       Get a guild by ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getGuild { guildId } {
    rest::GetGuild [set ${sessionNs}::token] $guildId $cmd
}

# discord::modifyGuild --
#
#       Modify a guild's settings.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, region, verification_level,
#                   default_message_notifications, afk_channel_id, afk_timeout,
#                   icon, owner_id, splash. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc modifyGuild { guildId data } {
    rest::ModifyGuild [set ${sessionNs}::token] $guildId $data $cmd
}

# discord::getChannels --
#
#       Get a list of channels in the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getChannels { guildId } {
    rest::GetGuildChannels [set ${sessionNs}::token] $guildId $cmd
}

# discord::createChannel --
#
#       Create a new channel for the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       name        Channel name.
#       data        Dictionary representing a JSON object. Each key is one of
#                   type, bitrate, user_limit, permission_overwrites. All keys
#                   are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc createChannel { guildId name data } {
    dict set data name $name
    rest::CreateGuildChannel [set ${sessionNs}::token] $guildId $data $cmd
}

# discord::changeChannelPositions --
#
#       Change the position of the guild channels.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       data        List of sublists, each sublist contains the channel ID and
#                   the new position. All affected channels must be specified.
#       getResult   See "Shared Arguments".

discord::GenApiProc changeChannelPositions { guildId data } {
    set positions [list]
    foreach list $data {
        lassign $list channelId position
        lappend positions [dict create id $channelId position $position]
    }
    rest::ModifyGuildChannelPosition  [set ${sessionNs}::token] $guildId \
            $positions $cmd
}

# discord::getMember --
#
#       Get a guild member by user ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getMember { guildId userId } {
    rest::GetGuildMember [set ${sessionNs}::token] $guildId $userId $cmd
}

# discord::getMembers --
#
#       Get a list of guild members.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       limit       (optional) maximum number of members to return. Defaults to
#                   1.
#       after       (optional) user ID. Only include members after this ID.
#                   Defaults to 0.
#       getResult   See "Shared Arguments".

discord::GenApiProc getMembers { guildId {limit 1} {after 0} } {
    rest::ListGuildMembers [set ${sessionNs}::token] $guildId \
            [dict create limit $limit after $after] $cmd
}

# discord::addMember --
#
#       Add a user to the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       accessToken OAuth2 access token.
#       data        Dictionary representing a JSON object. Each key is one of
#                   nick, roles, mute, deaf. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc addMember { guildId userId accessToken data } {
    dict set data access_token $accessToken
    rest::AddGuildMember [set ${sessionNs}::token] $guildId $userId $data $cmd
}

# discord::modifyMember --
#
#       Modify attributes of a guild member.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   nick, roles, mute, deaf, channel_id. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc modifyMember { guildId userId data } {
    rest::ModifyGuildMember [set ${sessionNs}::token] $guildId $userId $data \
            $cmd
}

# discord::kickMember --
#
#       Remove a member from the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc kickMember { guildId userId } {
    rest::RemoveGuildMember [set ${sessionNs}::token] $guildId $userId $cmd
}

# discord::getBans --
#
#       Get a list of users that are banned from the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getBans { guildId } {
    rest::GetGuildBans [set ${sessionNs}::token] $guildId $cmd
}

# discord::ban --
#
#       Create a guild ban.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       delMsgDays  Number of days to delete messages for.
#       getResult   See "Shared Arguments".

discord::GenApiProc ban { guildId userId {delMsgDays 0} } {
    rest::CreateGuildBan [set ${sessionNs}::token] $guildId $userId \
            [dict create delete-message-days $delMsgDays] $cmd
}

# discord::unban --
#
#       Remove the ban for a user.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       userId      User ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc unban { guildId userId } {
    rest::RemoveGuildBan [set ${sessionNs}::token] $guildId $userId $cmd
}

# discord::getRoles --
#
#       Get a list of roles for the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc getRoles { guildId } {
    rest::GetGuildRoles [set ${sessionNs}::token] $guildId $cmd
}

# discord::createRole --
#
#      Create a new empty role for the guild.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc createRole { guildId } {
    rest::CreateGuildRole [set ${sessionNs}::token] $guildId $cmd
}

# discord::batchModifyRoles --
#
#      Batch modify a set of guild roles.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       data        List of dictionaries representing JSON objects. Each key is
#                   one of id, name, permissions, position, color, hoist,
#                   mentionable. All keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc batchModifyRoles { guildId data } {
    rest::BatchModifyGuildRole [set ${sessionNs}::token] $guildId $data $cmd
}

# discord::modifyRole --
#
#      Modify a guild role.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       roleId      Role ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, permissions, position, color, hoist, mentionable. All
#                   keys are optional.
#       getResult   See "Shared Arguments".

discord::GenApiProc modifyRole { guildId roleId data } {
    rest::ModifyGuildRole [set ${sessionNs}::token] $guildId $roleId \
            $data $cmd
}

# discord::deleteRole --
#
#      Delete a guild role.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       roleId      Role ID.
#       getResult   See "Shared Arguments".

discord::GenApiProc deleteRole { guildId roleId } {
    rest::DeleteGuildRole [set ${sessionNs}::token] $guildId $roleId $cmd
}

# discord::getPruneCount --
#
#      Get the number of members that would be removed in a prune operation.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       days        (optional) number of days to count prune for. Defauls to 1.
#       getResult   See "Shared Arguments".

discord::GenApiProc getPruneCount { guildId {days 1} } {
    rest::GetGuildPruneCount [set ${sessionNs}::token] $guildId \
            [dict create days $days] $cmd
}

# discord::prune --
#
#      Begin a prune operation.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       guildId     Guild ID.
#       days        (optional) number of days to count prune for. Defauls to 1.
#       getResult   See "Shared Arguments".

discord::GenApiProc prune { guildId {days 1} } {
    rest::BeginGuildPrune [set ${sessionNs}::token] $guildId \
            [dict create days $days] $cmd
}

# discord::createDM --
#
#       Start a new DM with a user.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      userId
#       getResult   See "Shared Arguments".

discord::GenApiProc createDM { userId } {
    rest::CreateDM [set ${sessionNs}::token] \
            [dict create recipient_id $userId] $cmd
}

# discord::sendDM --
#
#       Send a DM to the user.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      userId
#       content     Message content.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results". Also raises an exception if a DM channel is not
#       opened for the user.

proc discord::sendDM { sessionNs userId content {getResult 0} } {
    variable log
    set channelId {}
    dict for {id dmChan} [set ${sessionNs}::dmChannels] {
        set recipients [dict get $dmChan recipients]
        if {[llength $recipients] > 1} {
            continue
        }
        if {[dict get [lindex $recipients 0] id] eq $userId} {
            set channelId [dict get $dmChan id]
            break
        }
    }
    if {$channelId ne {}} {
        set count [incr ${sessionNs}::sendDMCount]
        return [uplevel [list ::discord::sendMessage $sessionNs $channelId \
                $content $getResult]]
    } else {
        ${log}::error "sendDM: DM channel not found for user: $userId"
        return -code error "DM channel not found for user: $userId"
    }
}
