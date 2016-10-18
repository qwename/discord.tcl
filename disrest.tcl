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
#       Returns a list of invite objects for the channel.
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
#       Create a new invite object for the channel.
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
#       Pin a message in a channel
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
#       Delete a pinned message in a channel
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

    if {[dict exists $RateLimits $token X-RateLimit-Remaining]} {
        set remaining [dict get $RateLimits $token X-RateLimit-Remaining]
        if {$remaining <= 0} {
            set resetTime [dict get $RateLimits $token X-RateLimit-Reset]
            set secsRemain [expr {$resetTime - [clock seconds]}]
            if {$secsRemain >= 0} {
                ${log}::warn "Send: Rate-limited, reset in $secsRemain seconds"
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
    dict set SendInfo $sendId [dict create cmd $cmd url $url token $token]
    set command [list ::http::geturl $url \
            -headers [list Authorization "Bot $token"] \
            -method $verb \
            -timeout $timeout \
            -command $callbackName]
    if {[llength $body] > 0} {
        lappend command -query [::http::formatQuery {*}$body]
    }
    ${log}::debug "Send: $command"
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
                    dict set RateLimits $discordToken $header $meta($header)
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
