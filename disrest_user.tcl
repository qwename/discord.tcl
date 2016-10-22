# disrest_user.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's user resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

# All data dictionary keys are required unless stated otherwise.

# discord::rest::GetCurrentUser --
#
#       Returns the user of the requestor's acconut.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a user dictionary to the callback.

proc discord::rest::GetCurrentUser { token {cmd {}} } {
    Send $token GET "/users/@me" {} $cmd
}

# discord::rest::GetUser --
#
#       Returns a user for the given user ID.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       userId  User ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a user dictionary to the callback.

proc discord::rest::GetUser { token userId {cmd {}} } {
    Send $token GET "/users/$userId" {} $cmd
}

# discord::rest::ModifyCurrentUser --
#
#       Modifies the requestor's user account settings.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       data    Dictionary representing a JSON object. Each key is one of
#               username, avatar. All keys are optional.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a user dictionary to the callback.

proc discord::rest::ModifyCurrentUser { token data {cmd {}} } {
    Send $token PATCH "/users/@me" $data $cmd
}

# discord::rest::GetCurrentUserGuilds --
#
#       Returns a list of guilds the current user is a member of.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of guild dictionaries to the callback.

proc discord::rest::GetCurrentUserGuilds { token {cmd {}} } {
    Send $token GET "/users/@me/guilds" {} $cmd
}

# discord::rest::LeaveGuild --
#
#       Leave a guild.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       guildId Guild ID.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       None.

proc discord::rest::LeaveGuild { token guildId {cmd {}} } {
    Send $token DELETE "/users/@me/guilds/$guildId" {} $cmd
}

# discord::rest::GetUserDMs --
#
#       Returns a list of DM channels.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of DM channel dictionaries to the callback.

proc discord::rest::GetUserDMs { token {cmd {}} } {
    Send $token GET "/users/@me/channels" {} $cmd
}

# discord::rest::CreateDM --
#
#       Creates a new DM channel with a user.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       data    Dictionary representing a JSON object. Only the key recipient_id
#               should be present.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a DM channel dictionary to the callback.

proc discord::rest::CreateDM { token data {cmd {}} } {
    Send $token POST "/users/@me/channels" $data $cmd -type "application/json"
}

# discord::rest::CreateGroupDM --
#
#       Creates a new group DM channel with multiple users.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       data    Dictionary representing a JSON object. Only the key
#               access_tokens should be present.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a DM channel dictionary to the callback.

proc discord::rest::CreateGroupDM { token data {cmd {}} } {
    Send $token POST "/users/@me/channels" $data $cmd
}

# discord::rest::GetUsersConnections --
#
#       Returns a list of connections.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of connection dictionaries to the callback.

proc discord::rest::GetUsersConnections { token {cmd {}} } {
    Send $token GET "/users/@me/connections" {} $cmd
}
