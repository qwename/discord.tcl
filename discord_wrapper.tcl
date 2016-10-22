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
    namespace export sendMessage createDM sendDM
    namespace ensemble create
}

# Shared Arguments:
#       sessionNs   Name of session namespace.
#       getResult   (optional) boolean, set to 1 if the caller is a coroutine
#                   and will cleanup the returned result coroutine. Defaults to
#                   0, which means an empty string will be returned to the
#                   caller.

# Shared Results:
#       Returns a coroutine context name if the caller is a coroutine, and an
#       empty string otherwise. If the caller is a coroutine, it should yield
#       after calling this procedure. The caller can then get the HTTP response
#       by calling the returned coroutine. Refer to
#       discord::rest::CallbackCoroutine for more details.

# discord::sendMessage --
#
#       Send a message to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       content     Message content.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

proc discord::sendMessage { sessionNs channelId content {getResult 0} } {
    if {$getResult == 1} {
        set caller [uplevel info coroutine]
    } else {
        set caller {}
    }
    set count [incr ${sessionNs}::sendMessageCount]
    set cmd [list]
    set name {}
    if {$caller ne {}} {
        set name ${sessionNs}::sendMsgCoro$count
        set cmd [list coroutine $name discord::rest::CallbackCoroutine $caller]
    }
    rest::CreateMessage [set ${sessionNs}::token] $channelId \
            [dict create content $content] $cmd
    return $name
}

# discord::createDM --
#
#       Start a new DM with a user.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      userId
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

proc discord::createDM { sessionNs userId {getResult 0} } {
    if {$getResult == 1} {
        set caller [uplevel info coroutine]
    } else {
        set caller {}
    }
    set cmd [list]
    set name {}
    if {$caller ne {}} {
        set count [incr ${sessionNs}::createDMCount]
        set name ${sessionNs}::createDMCoro$count
        set cmd [list coroutine $name discord::rest::CallbackCoroutine $caller]
    }
    rest::CreateDM [set ${sessionNs}::token] \
            [dict create recipient_id $userId] $cmd
    return $name
}

# discord::sendDM --
#
#       Send a DM to the user.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      userId
#       content     Message content.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results". Also raises an exception if a DM channel is not
#       opened for the user.

proc discord::sendDM { sessionNs userId content {getResult 0} } {
    variable log
    set channelId {}
    dict for {id dmChan} [set ${sessionNs}::dmChannels] {
        set recipients [dict get $dmChan recipients]
        if {[llength $recipients] > 1} {
            continue
        }
        foreach recipient $recipients {
            if {[dict get $recipient id] eq $userId} {
                set channelId [dict get $dmChan id]
                break
            }
        }
    }
    if {$channelId ne {}} {
        set count [incr ${sessionNs}::sendDMCount]
        return [uplevel [list ::discord::sendMessage $sessionNs $channelId \
                $content $getResult]]
    } else {
        ${log}::error "sendDM: DM channel not found for user: $userId"
        return -code error "DM channel not found for user: $userId"
    }
}
