# disrest_webhook.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's webhook resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

# All data dictionary keys are required unless stated otherwise.

# discord::rest::CreateWebhook --
#
#       Create a new webhook.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, avatar.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a webhook dictionary to the callback.

proc discord::rest::CreateWebhook { token channelId data {cmd {}} } {
    Send $token POST "/channels/$channelId/webhooks" $data $cmd
}

# discord::rest::GetChannelWebhooks --
#
#       Returns a list of channel webhooks.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a list of channel webhook dictionaries to the callback.

proc discord::rest::GetChannelWebhooks { token channelId {cmd {}} } {
    Send $token GET "/channels/$channelId/webhooks" {} $cmd
}

# discord::rest::GetGuildWebhooks --
#
#       Returns a list of guild webhooks.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of guild webhook dictionaries to the callback.

proc discord::rest::GetGuildWebhooks { token channelId {cmd {}} } {
    Send $token GET "/guilds/$guildId/webhooks" {} $cmd
}

# discord::rest::GetWebhook --
#
#       Returns the new webhook object for the given ID.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       webhookId   Webhook ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a webhook dictionary to the callback.

proc discord::rest::GetWebhook { token webhookId {cmd {}} } {
    Send $token GET "/webhooks/$webhookId" {} $cmd
}

# discord::rest::GetWebhookWithToken --
#
#       Same as GetWebhook, but does not require a bot token or OAuth2 bearer
#       token.
#
# Arguments:
#       webhookId       Webhook ID.
#       webhookToken    Webhook token.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       Passes a webhook dictionary to the callback.

proc discord::rest::GetWebhookWithToken { webhookId webhookToken {cmd {}} } {
    Send $token GET "/webhooks/$webhookId/$webhookToken" {} $cmd  
}

# discord::rest::ModifyWebhook --
#
#       Modify a webhook.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       webhookId   Webhook ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       Passes a webhook dictionary to the callback.

proc discord::rest::ModifyWebhook { token webhookId {cmd {}} } {
    Send $token PATCH "/webhooks/$webhookId" {} $cmd
}

# discord::rest::ModifyWebhookWithToken --
#
#       Same as ModifyWebhook, but does not require a bot token or OAuth2 bearer
#       token.
#
# Arguments:
#       webhookId       Webhook ID.
#       webhookToken    Webhook token.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       Passes a webhook dictionary to the callback.

proc discord::rest::ModifyWebhookWithToken { webhookId webhookToken {cmd {}} } {
    Send $token PATCH "/webhooks/$webhookId/$webhookToken" {} $cmd  
}

# discord::rest::DeleteWebhook --
#
#       Delete a webhook permanently.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       webhookId   Webhook ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::DeleteWebhook { token webhookId {cmd {}} } {
    Send $token DELETE "/webhooks/$webhookId" {} $cmd
}

# discord::rest::DeleteWebhookWithToken --
#
#       Same as DeleteWebhook, but does not require a bot token or OAuth2 bearer
#       token.
#
# Arguments:
#       webhookId       Webhook ID.
#       webhookToken    Webhook token.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       None.

proc discord::rest::DeleteWebhookWithToken { webhookId webhookToken {cmd {}} } {
    Send $token DELETE "/webhooks/$webhookId/$webhookToken" {} $cmd  
}

# discord::rest::ExecuteWebhook --
#
#       Does not require a bot token or OAuth2 bearer token.
#
# Arguments:
#       webhookId       Webhook ID.
#       webhookToken    Webhook token.
#       data            Dictionary representing a JSON object. Each key is one
#                       of content, username, avatar_url, tts, file, embeds.
#       cmd             (optional) callback procedure invoked after a response
#                       is received.
#
# Results:
#       None.

proc discord::rest::ExecuteWebhook { webhookId webhookToken {cmd {}} } {
    Send $token POST "/webhooks/$webhookId/$webhookToken" {} $cmd
}
