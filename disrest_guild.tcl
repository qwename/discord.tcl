# disrest_guild.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's guild resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

# All data dictionary keys are required unless stated otherwise.

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
