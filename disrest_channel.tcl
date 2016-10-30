# disrest_channel.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's channel resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require uuid
package require http

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
    set spec {
            name        string
            position    bare
            topic       string
            bitrate     bare
            user_limit  bare
        }
    set body [DictToJson $data $spec]
    Send $token PATCH "/channels/$channelId" $body $cmd
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
    set query [http::formatQuery {*}$data]
    Send $token GET "/channels/$channelId/messages?$query" {} $cmd
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
#       Post a message to a Guild Text or DM channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   content, nonce, tts. Only the key content is required.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a message dictionary to the callback.

proc discord::rest::CreateMessage { token channelId data {cmd {}} } {
    set spec {
            content string
            nonce   string
            tts     bare
        }
    set body [DictToJson $data $spec]
    Send $token POST "/channels/$channelId/messages" $body $cmd
}

# discord::rest::UploadFile --
#
#       Post a file to a Guild Text or DM channel.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       filename    File name.
#       type        Content-Type value.
#       data        Dictionary representing a JSON object. Each key is one of
#                   content, nonce, tts, file. Only the key file is required.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a message dictionary to the callback.

proc discord::rest::UploadFile { token channelId filename type data {cmd {}} } {
    # Reference: https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
    # UUID is 36 characters
    set boundary "discord::rest::UploadFile--[uuid::uuid generate]"
    set delimiter "\r\n--$boundary"
    set closeDelimiter "$delimiter--"
    set dispoPrefix "Content-Disposition: form-data; "
    set body ""
    foreach name [list content nonce tts] {
        if {[dict exists $data $name]} {
            set value [dict get $data $name]
            append body "$delimiter\r\n${dispoPrefix}name=\"$name\";\r\n\r\n" \
                    "$value\r\n"
        }
    }
    if {[dict exists $data file]} {
        set value [dict get $data file]
        append body "$delimiter\r\n${dispoPrefix}name=\"file\"; "\
                "filename=\"$filename\";\r\n" \
                "Content-Type: $type\r\n\r\n$value"
    }
    append body $closeDelimiter
    Send $token POST "/channels/$channelId/messages" $body $cmd \
            -type "multipart/form-data; boundary=$boundary"
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
    set spec {
            content string
        }
    set body [DictToJson $data $spec]
    Send $token PATCH "/channels/$channelId/messages/$messageId" $body $cmd \
            -type "application/json"
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
    set spec {
            messages    {array string}
        }
    set body [DictToJson $data $spec]
    Send $token POST "/channels/$channelId/messages/bulk-delete" $body $cmd \
            -type "application/json"
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
#                   allow, deny, type. All keys are optional
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes an invite dictionary to the callback.

proc discord::rest::EditChannelPermissions { token channelId overwriteId data \
        {cmd {}} } {
    set spec {
            allow   bare
            deny    bare
            type    string
    }
    set body [DictToJson $data $spec]
    Send $token PUT "/channels/$channelId/permissions/$overwriteId" $body $cmd \
            -type "application/json"
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
    set spec {
            max_age     bare
            max_uses    bare
            temporary   bare
            unique      bare
        }
    set body [DictToJson $data $spec]
    Send $token POST "/channels/$channelId/invites" $body $cmd \
            -type "application/json"
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
    Send $token POST "/channels/$channelId/typing" {} $cmd \
            -headers [list Content-Length 0]
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

# discord::rest::GroupDMAddRecipient --
#
#       Adds a recipient to a Group DM using their access token.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       userId      User ID.
#       data        Dictionary representing a JSON object. Only the key
#                   access_token should be present.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None. (Probably a user dictionary)

proc discord::rest::GroupDMAddRecipient { token channelId userId data {cmd {}} \
        } {
    set spec {
            access_token    string
        }
    set body [DictToJson $data $spec]
    Send $token PUT "/channels/$channelId/recipients/$userId" $body $cmd
}

# discord::rest::GroupDMRemoveRecipient --
#
#       Removes a recipient from a Group DM.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       userId      User ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::GroupDMRemoveRecipient { token channelId userId {cmd {}} } {
    Send $token DELETE "/channels/$channelId/recipients/$userId" {} $cmd
}
