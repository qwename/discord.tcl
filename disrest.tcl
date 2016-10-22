# disrest.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API.
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

namespace eval discord::rest {
    variable log [logger::init discord::rest]

    variable SendId 0
    variable SendInfo [dict create]

    variable RateLimits [dict create]
}

# All data dictionary keys are required unless stated otherwise.

# discord::rest::GetChannel --
#
#       Get a channel by ID.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a Guild or DM channel dictionary to the callback.

proc discord::rest::GetChannel { token channelId {cmd {}} } {
    Send $token GET "/channels/$channelId" {} $cmd
}

# discord::rest::ModifyChannel --
#
#       Update a channel's settings.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, position, topic, bitrate, user_limit. All the keys
#                   are optional.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a Guild channel dictionary to the callback.

proc discord::rest::ModifyChannel { token channelId data {cmd {}} } {
    Send $token PATCH "/channels/$channelId" $data $cmd
}

# discord::rest::DeleteChannel --
#
#       Delete a Guild channel, or close a DM channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a Guild or DM channel dictionary to the callback.

proc discord::rest::DeleteChannel { token channelId {cmd {}} } {
    Send $token DELETE "/channels/$channelId" {} $cmd
}

# discord::rest::GetChannelMessages --
#
#       Returns the messages for a channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   limit, around/before/after. All the keys are optional.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a list of message dictionaries to the callback.

proc discord::rest::GetChannelMessages { token channelId data {cmd {}} } {
    Send $token GET "/channels/$channelId/messages" $data $cmd
}

# discord::rest::GetChannelMessage --
#
#       Returns a specific message in the channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       messageId   Message ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a message dictionary to the callback.

proc discord::rest::GetChannelMessage { token channelId messageId {cmd {}} } {
    Send $token GET "/channels/$channelId/messages/$messageId" {} $cmd
}

# discord::rest::CreateMessage --
#
#       Post a message or file to a Guild Text or DM channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   content, nonce, tts, file. At least one of content or file
#                   is required.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a message dictionary to the callback.

proc discord::rest::CreateMessage { token channelId data {cmd {}} } {
    Send $token POST "/channels/$channelId/messages" $data $cmd
}

# discord::rest::EditMessage --
#
#       Edit a previously sent message.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       messageId   Message ID.
#       data        Dictionary representing a JSON object. Only the key content
#                   should be present.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a message dictionary to the callback.

proc discord::rest::EditMessage { token channelId messageId data {cmd {}} } {
    Send $token PATCH "/channels/$channelId/messages/$messageId" $data $cmd
}

# discord::rest::DeleteMessage --
#
#       Delete a message.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       messageId   Message ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::DeleteMessage { token channelId messageId {cmd {}} } {
    Send $token DELETE "/channels/$channelId/messages/$messageId" {} $cmd
}

# discord::rest::BulkDeleteMessages --
#
#       Delete multiple messages in a single request.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Only the key messages
#                   should be present.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::BulkDeleteMessages { token channelId data {cmd {}} } {
    Send $token POST "/channels/$channelId/messages/bulk_delete" $data $cmd
}

# discord::rest::EditChannelPermissions --
#
#       Edit the channel permission overwrites for a user or role in a channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       overwriteId Overwrite ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   allow, deny, type.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes an invite dictionary to the callback.

proc discord::rest::EditChannelPermissions { token channelId overwriteId data \
        {cmd {}} } {
    Send $token POST "/channels/$channelId/permissions/$overwriteId" $data $cmd
}

# discord::rest::DeleteChannelPermission --
#
#       Delete a channel permission overwrite for a user or role in a channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       overwriteId Overwrite ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::DeleteChannelPermission { token channelId overwriteId \
        {cmd {}} } {
    Send $token DELETE "/channels/$channelId/permissions/$overwriteId" {} $cmd
}

# discord::rest::GetChannelInvites --
#
#       Returns a list of invites for the channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a list of invite dictionaries to the callback.

proc discord::rest::GetChannelInvites { token channelId {cmd {}} } {
    Send $token GET "/channels/$channelId/invites" {} $cmd
}

# discord::rest::CreateChannelInvite --
#
#       Create a new invite for the channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   max_age, max_uses, temporary, unique. All the keys are
#                   optional.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::CreateChannelInvite { token channelId data {cmd {}} } {
    Send $token POST "/channels/$channelId/invites" $data $cmd
}

# discord::rest::TriggerTypingIndicator --
#
#       Post a typing indicator for the specified channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::TriggerTypingIndicator { token channelId {cmd {}} } {
    Send $token POST "/channels/$channelId/typing" {} $cmd
}

# discord::rest::GetPinnedMessages --
#
#       Returns all pinned messages in the channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a list of message dictionaries to the callback.

proc discord::rest::GetPinnedMessages { token channelId {cmd {}} } {
    Send $token GET "/channels/$channelId/pins" {} $cmd
}

# discord::rest::AddPinnedChannelMessage --
#
#       Pin a message in a channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       messageId   Message ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::AddPinnedChannelMessage { token channelId messageId \
        {cmd {}} } {
    Send $token PUT "/channels/$channelId/pins/$messageId" {} $cmd
}

# discord::rest::DeletePinnedChannelMessage --
#
#       Delete a pinned message in a channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       messageId   Message ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::DeletePinnedChannelMessage { token channelId messageId \
        {cmd {}} } {
    Send $token DELETE "/channels/$channelId/pins/$messageId" {} $cmd
}

# discord::rest::GetGuild --
#
#       Returns the new guild for the given id.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild dictionary to the callback.

proc discord::rest::GetGuild { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId" {} $cmd
}

# discord::rest::ModifyGuild --
#
#       Modify a guild's settings.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               name region, verification_level, default_message_notifications,
#               afk_channel_id, afk_timeout, icon, owner_id, splash. All keys
#               are optional.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild dictionary to the callback.

proc discord::rest::ModifyGuild { token guildId data {cmd {}} } {
    Send $token PATCH "/guilds/$guildId" $data $cmd
}

# discord::rest::DeleteGuild --
#
#       Delete a guild permanently.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild dictionary to the callback.

proc discord::rest::DeleteGuild { token guildId {cmd {}} } {
    Send $token DELETE "/guilds/$guildId" {} $cmd
}

# discord::rest::GetGuildChannels --
#
#       Returns a list of guild channels.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of guild channel dictionaries to the callback.

proc discord::rest::GetGuildChannels { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/channels" {} $cmd
}

# discord::rest::CreateGuildChannel --
#
#       Create a new channel for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               name, type, bitrate, user_limit, permission_overwrites.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a channel dictionary to the callback.

proc discord::rest::CreateGuildChannel { token guildId data {cmd {}} } {
    Send $token POST "/guilds/$guildId/channels" $data $cmd
}

# discord::rest::ModifyGuildChannelPosition --
#
#       Modify the position of a guild channel.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               id, position.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::ModifyGuildChannelPosition { token guildId data {cmd {}} } {
    Send $token PATCH "/guilds/$guildId/channels" $data $cmd
}

# discord::rest::GetGuildMember --
#
#       Returns a guild member for the specified user.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild member object to the callback.

proc discord::rest::GetGuildMember { token guildId userId {cmd {}} } {
    Send $token GET "/guilds/$guildId/members/$userId" {} $cmd
}

# discord::rest::ListGuildMembers --
#
#       Returns a list of guild members that are members of the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               limit, after. All keys are optional.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of guild member dictionaries to the callback.

proc discord::rest::ListGuildMembers { token guildId data {cmd {}} } {
    Send $token GET "/guilds/$guildId/members" $data $cmd
}

# discord::rest::AddGuildMember --
#
#       Adds a user to the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               access_token, nick, roles, mute, deaf. Only access_token is
#               required.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild member dictionary to the callback.

proc discord::rest::AddGuildMember { token guildId userId data {cmd {}} } {
    Send $token PUT "/guilds/$guildId/members/$userId" $data $cmd
}

# discord::rest::ModifyGuildMember --
#
#       Modify attributes of a guild member.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               nick, roles, mute, deaf, channel_id. All keys are optional.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::ModifyGuildMember { token guildId userId data {cmd {}} } {
    Send $token PATCH "/guilds/$guildId/members/$userId" $data $cmd
}

# discord::rest::RemoveGuildMember --
#
#       Remove a member from a guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::RemoveGuildMember { token guildId userId {cmd {}} } {
    Send $token DELETE "/guilds/$guildId/members/$userId" {} $cmd
}

# discord::rest::GetGuildBans --
#
#       Returns a list of users that are banned from this guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of user dictionaries to the callback.

proc discord::rest::GetGuildBans { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/bans" {} $cmd
}

# discord::rest::CreateGuildBan --
#
#       Create a guild ban.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       data    Dictionary representing a JSON object. Only the key
#               delete-message-days should be present.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::CreateGuildBan { token guildId userId data {cmd {}} } {
    Send $token PUT "/guilds/$guildId/bans/$userId" $data $cmd
}

# discord::rest::RemoveGuildBan --
#
#       Remove the ban for a user.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       userId  User ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::RemoveGuildBan { token guildId userId {cmd {}} } {
    Send $token DELETE "/guilds/$guildId/bans/$userId" {} $cmd
}

# discord::rest::GetGuildRoles --
#
#       Return a list of roles for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of role dictionaries to the callback.

proc discord::rest::GetGuildRoles { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/roles" {} $cmd
}

# discord::rest::CreateGuildRole --
#
#       Create a new empty role for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a role object to the callback.

proc discord::rest::CreateGuildRole { token guildId {cmd {}} } {
    Send $token POST "/guilds/$guildId/roles" {} $cmd
}

# discord::rest::ModifyGuildRole --
#
#       Modify a guild role.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       roleId  Role ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               name, permissions, position, color, hoist, mentionable.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a role dictionary to the callback.

proc discord::rest::ModifyGuildRole { token guildId roleId data {cmd {}} } {
    Send $token PATCH "/guilds/$guildId/roles/$roleId" $data $cmd
}

# discord::rest::DeleteGuildRole --
#
#       Delete a guild role.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       roleId  Role ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a role dictionary to the callback.

proc discord::rest::DeleteGuildRole { token guildId roleId {cmd {}} } {
    Send $token DELETE "/guilds/$guildId/roles/$roleId" {} $cmd
}

# discord::rest::GetGuildPruneCount --
#
#       Returns the number of members that would be removed in a prune
#       operation.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Only the key days should
#               be present.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a dictionary with the key 'pruned' to the callback.

proc discord::rest::GetGuildPruneCount { token guildId data {cmd {}} } {
    Send $token GET "/guilds/$guildId/prune" $data $cmd
}

# discord::rest::BeginGuildPrune --
#
#       Begin a prune operation.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Only the key days should
#               be present.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a dictionary with the key 'pruned' to the callback.

proc discord::rest::BeginGuildPrune { token guildId data {cmd {}} } {
    Send $token POST "/guilds/$guildId/prune" $data $cmd
}

# discord::rest::GetGuildVoiceRegions --
#
#       Returns a list of voice regions for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of voice region dictionaries to the callback.

proc discord::rest::GetGuildVoiceRegions { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/regions" {} $cmd
}

# discord::rest::GetGuildInvites --
#
#       Returns a list of invites for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of invite dictionaries to the callback.

proc discord::rest::GetGuildInvites { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/invites" {} $cmd
}

# discord::rest::GetGuildIntegrations --
#
#       Returns a list of integrations for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of integration dictionaries to the callback.

proc discord::rest::GetGuildIntegrations { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/integrations" {} $cmd
}

# discord::rest::CreateGuildIntegration --
#
#       Attach an integration from the current user to the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               type, id.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::CreateGuildIntegration { token guildId data {cmd {}} } {
    Send $token POST "/guilds/$guildId/integrations" $data $cmd
}

# discord::rest::ModifyGuildIntegration --
#
#       Modify the behavior and settings of an integration for the guild.
#
# Arguments:
#       token           Bot token or OAuth2 bearer token.
#       guildId         Guild ID.
#       integrationId   Integration ID.
#       data            Dictionary representing a JSON object. Each key is one
#                       of expire_behavior, expire_grace_period,
#                       enable_emoticons.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       None.

proc discord::rest::ModifyGuildIntegration { token guildId integrationId data \
        {cmd {}} } {
    Send $token PATCH "/guilds/$guildId/integrations/$integrationId" $data $cmd
}

# discord::rest::DeleteGuildIntegration --
#
#       Delete the attached integration for the guild.
#
# Arguments:
#       token           Bot token or OAuth2 bearer token.
#       guildId         Guild ID.
#       integrationId   Integration ID.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       None.

proc discord::rest::DeleteGuildIntegration { token guildId integrationId \
        {cmd {}} } {
    Send $token DELETE "/guilds/$guildId/integrations/$integrationId" {} $cmd
}

# discord::rest::SyncGuildIntegration --
#
#       Sync an integration.
#
# Arguments:
#       token           Bot token or OAuth2 bearer token.
#       guildId         Guild ID.
#       integrationId   Integration ID.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       None.

proc discord::rest::SyncGuildIntegration { token guildId integrationId \
        {cmd {}} } {
    Send $token POST "/guilds/$guildId/integrations/$integrationId/sync" {} $cmd
}

# discord::rest::GetGuildEmbed --
#
#       Returns the guild embed.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild embed dictionary to the callback.

proc discord::rest::GetGuildEmbed { token guildId {cmd {}} } {
    Send $token GET "/guilds/$guildId/embed" {} $cmd
}

# discord::rest::ModifyGuildEmbed --
#
#       Modify a guild embed for the guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       data    Dictionary representing a JSON object. Each key is one of
#               enabled, channel_id.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a guild embed dictionary to the callback.

proc discord::rest::ModifyGuildEmbed { token guildId data {cmd {}} } {
    Send $token GET "/guilds/$guildId/embed" $data $cmd
}

# discord::rest::GetInvite --
#
#       Returns an invite for the given code.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       inviteCode  Invite Code.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes an invite dictionary to the callback.

proc discord::rest::GetInvite { token inviteCode {cmd {}} } {
    Send $token GET "/invites/$inviteCode" {} $cmd
}

# discord::rest::DeleteInvite --
#
#       Delete an invite.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       inviteCode  Invite Code.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes an invite dictionary to the callback.

proc discord::rest::DeleteInvite { token inviteCode {cmd {}} } {
    Send $token DELETE "/invites/$inviteCode" {} $cmd
}

# discord::rest::AcceptInvite --
#
#       Accept an invite.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       inviteCode  Invite Code.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes an invite dictionary to the callback.

proc discord::rest::DeleteInvite { token inviteCode {cmd {}} } {
    Send $token POST "/invites/$inviteCode" {} $cmd
}

# discord::rest::Send --
#
#       Send HTTP requests to the Discord HTTP API.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       verb        HTTP method. One of GET, POST, PUT, PATCH, DELETE.
#       resource    Path relative to the base URL, prefixed with '/'.
#       data        (optional) dictionary of parameters and values to include.
#       cmd         (optional) list containing a callback procedure, and
#                   additional arguments to be passed to it. The last two
#                   arguments will be a data dictionary, and the HTTP code or
#                   error.
#       timeout     (optional) timeout for HTTP request in milliseconds.
#                   Defaults to 0, which means no timeout.
#
# Results:
#       None.

proc discord::rest::Send { token verb resource {data {}} {cmd {}} {timeout 0}
        } {
    variable log
    variable SendId
    variable SendInfo
    variable RateLimits
    global discord::ApiBaseUrlV6

    regexp {^/([^/]+)} $resource -> route
    if {$route ne {} && [dict exists $RateLimits $token $route \
            X-RateLimit-Remaining]} {
        set remaining [dict get $RateLimits $token $route X-RateLimit-Remaining]
        if {$remaining <= 0} {
            set resetTime [dict get $RateLimits $token $route X-RateLimit-Reset]
            set secsRemain [expr {$resetTime - [clock seconds]}]
            puts "$secsRemain"
            if {$secsRemain >= -3} {
                ${log}::warn [join [list "Send: Rate-limited on /$route," \
                        "reset in $secsRemain seconds"]]
                return
            }
        }
    }
    if {$verb ni [list GET POST PUT PATCH DELETE]} {
        ${log}::error "Send: HTTP method not recognized: '$verb'"
        return 0
    }

    set sendId $SendId
    incr SendId
    set callbackName ::discord::rest::SendCallback${sendId}
    interp alias {} $callbackName {} ::discord::rest::SendCallback $sendId

    set body [list]
    dict for {field value} $data {
        lappend body $field $value
    }
    set url "${ApiBaseUrlV6}${resource}"
    dict set SendInfo $sendId [dict create cmd $cmd url $url token $token \
            route $route]
    set command [list ::http::geturl $url \
            -headers [list Authorization "Bot $token"] \
            -method $verb \
            -timeout $timeout \
            -command $callbackName]
    if {[llength $body] > 0} {
        lappend command -query [::http::formatQuery {*}$body]
    }
    ${log}::debug "Send: $route: $command"
    {*}$command
    return
}

# discord::rest::SendCallback --
#
#       Callback procedure invoked when a HTTP transaction completes.
#
# Arguments:
#       id      Internal Send ID.
#       token   Returned from ::http::geturl, name of a state array.
#
# Results:
#       Invoke stored callback procedure for the corresponding send request.
#       Returns 1 on success

proc discord::rest::SendCallback { sendId token } {
    variable log
    variable SendInfo
    variable RateLimits
    interp alias {} ::discord::rest::SendCallback${sendId} {}
    set route [dict get $SendInfo $sendId route]
    set url [dict get $SendInfo $sendId url]
    set cmd [dict get $SendInfo $sendId cmd]
    set discordToken [dict get $SendInfo $sendId token]
    set status [::http::status $token]
    switch $status {
        ok {
            array set meta [::http::meta $token]
            foreach header [list X-RateLimit-Limit X-RateLimit-Remaining \
                    X-RateLimit-Reset] {
                if {[info exists meta($header)]} {
                    dict set RateLimits $discordToken $route \
                            $header $meta($header)
                }
            }
            set code [::http::code $token]
            set ncode [::http::ncode $token]
            if {$ncode >= 300} {
                ${log}::warn "SendCallback${sendId}: $url: $status ($code)"
            } else {
                ${log}::debug "SendCallback${sendId}: $url: $status ($code)"
            }
            set cmd [dict get $SendInfo $sendId cmd]
            if {[llength $cmd] > 0} {
                if {[catch {json::json2dict [::http::data $token]} data]} {
                    ${log}::error "SendCallback${sendId}: $url: $data"
                    set data {}
                }
                after idle [list {*}$cmd $data $code]
            }
        }
        error {
            set error [::http::error $token]
            ${log}::error "SendCallback${sendId}: $url: $status ($error)"
            if {[llength $cmd] > 0} {
                after idle [list {*}$cmd {} [::http::error $token]]
            }
        }
        default {
            ${log}::error "SendCallback${sendId}: $url: $status"
            if {[llength $cmd] > 0} {
                after idle [list {*}$cmd {} $status]
            }
        }
    }
    ::http::cleanup $token
    dict unset SendInfo $sendId
    return
}

# discord::rest::CallbackCoroutine
#
#       Resume a coroutine that is waiting for the response from a previous
#       call to Send. The coroutine should call this coroutine after resumption
#       to get the results. This procedure should be passed in a list to the
#       'cmd' argument of Send, e.g.
#           Send ... [list coroutine $contextName \
#                   discord::rest::CallbackCoroutine $callerName]
#
# Arguments:
#       coroutine   Coroutine to be resumed.
#       data        Dictionary representing a JSON object, or empty if an error
#                   had occurred.
#       httpCode    The HTTP status reply, or error message if an error had
#                   occurred.
#
# Results:
#       Returns a list containing data and httpCode.

proc discord::rest::CallbackCoroutine { coroutine data httpCode } {
    if {[llength [info commands $coroutine]] > 0} {
        after idle $coroutine
        yield
    }
    return [list $data $httpCode]
}
