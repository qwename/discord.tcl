# disrest_voice.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API's voice resource.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

# All data dictionary keys are required unless stated otherwise.

# discord::rest::ListVoiceRegions --
#
#       Returns an array of voice regions that can be used when creating
#       servers.
#
# Arguments:
#       token   Bot token or OAuth2 bearer token.
#       cmd     (optional) callback procedure invoked after a response is
#               received.
#
# Results:
#       Passes a list of voice region dictionaries to the callback.

proc discord::rest::ListVoiceRegions { token {cmd {}} } {
    Send $token GET "/voice/regions" {} $cmd
}
