# message_formatting.tcl --
#
#       This file implements the Tcl code for working with message formatting in
#       Discord.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

namespace eval discord {
    namespace export getMessageFormat
    namespace ensemble create
}

# discord::getMentionInfo --
#
#       Check if a string follows a Discord message format.
#
# Arguments:
#       message String to be parsed.
#
# Results:
#       Returns a list containing the format type and contents if the string 
#       follows a valid structure, or an empty string otherwise.

proc discord::getMessageFormat { message } {
    set messageInfo [list]
    switch -regexp -matchvar match $message {
        {^<@(\d+)>$} {
            lassign $match - userId
            lappend messageInfo user $userId
        }
        {^<@!(\d+)>$} {
            lassign $match - userId
            lappend messageInfo nickname $userId
        }
        {^<#(\d+)>$} {
            lassign $match - channelId
            lappend messageInfo channel $channelId
        }
        {^<@&(\d+)$} {
            lassign $match - roleId
            lappend messageInfo role $roleId
        }
        {^<:([^:]+):(\d+)>} {
            lassign $match - name emojiId
            lappend messageInfo emoji $name $emojiId
        }
        default {
            set messageInfo {}
        }
    }
    return $messageInfo
}
