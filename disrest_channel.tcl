# disrest_channel.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's channel resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

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
