# disrest_invite.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's invite resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

# All data dictionary keys are required unless stated otherwise.

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
