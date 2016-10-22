# discord_wrapper.tcl --
#
#       This file implements the Tcl code that wraps around the procedures in
#       the disrest_*.tcl files.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

namespace eval discord {
    namespace export sendMessage
    namespace ensemble create
}

# discord::sendMessage --
#
#       Send a message to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       content     Message content.
#
# Results:
#       Returns a coroutine context name if the caller is a coroutine, and an
#       empty string otherwise. If the caller is a coroutine, it should yield
#       after calling this procedure. The caller can then get the HTTP response
#       by calling the returned coroutine. Refer to
#       discord::rest::CallbackCoroutine for more details.

proc discord::sendMessage { sessionNs channelId content } {
    set caller [uplevel info coroutine]
    set count [incr ${sessionNs}::sendMessageCount]
    set cmd [list]
    if {$caller ne {}} {
        set name ${sessionNs}::sendMsgCoro$count
        set cmd [list coroutine $name discord::rest::CallbackCoroutine $caller]
    }
    rest::CreateMessage [set ${sessionNs}::token] $channelId \
            [dict create content $content] $cmd
    return $name
}
