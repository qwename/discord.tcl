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
    namespace export getChannel modifyChannel deleteChannel closeDM \
            getMessages getMessage sendMessage uploadFile editMessage \
            deleteMessage createDM sendDM
    namespace ensemble create
}

# discord::GenApiProc --
#
#       Used in place of the proc command for easier programming of API calls
#       in the discord namespace. Code for dealing with coroutine will be
#       added.
#
# Arguments:
#       name    Name of the procedure that will be created in the discord
#               namespace.
#       args    Arguments that the procedure will accept.
#       body    Script to run.
#
# Results:
#       A procedure discord::$name will be created, with these additions:
#       The argument "sessionNs" is prepended to the list of args.
#       The argument "getResult" is appended to the list of args.
#       The variable "cmd" should be passed to discord::rest procedures that
#       take a callback argument.

proc discord::GenApiProc { name args body } {
    set args [list sessionNs {*}$args {getResult 0}]
    set setup {
        if {$getResult == 1} {
            set caller [uplevel info coroutine]
        } else {
            set caller {}
        }
        set cmd [list]
        set name {}
        if {$caller ne {}} {
            set myName [lindex [info level 0] 0]
            dict incr ${sessionNs}::WrapperCallCount $myName
            set count [dict get [set ${sessionNs}::WrapperCallCount] $myName]
            set name ${myName}$count
            set cmd [list coroutine $name discord::rest::CallbackCoroutine \
                    $caller]
        }
    }
    proc ::discord::$name $args "$setup\n$body\nreturn \$name"
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

# discord::getChannel --
#
#       Get a channel by ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc getChannel { channelId } {
    rest::GetChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::modifyChannel --
#
#       Update a channel's settings.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   name, position, topic, bitrate, user_limit. All keys are
#                   optional.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc modifyChannel { channelId data } {
    rest::ModifyChannel [set ${sessionNs}::token] $channelId $data $cmd
}

# discord::deleteChannel --
#
#       Delete a guild channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc deleteChannel { channelId } {
    rest::DeleteChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::closeDM --
#
#       Close a DM channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       userId      User ID.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc closeDM { userId } {
    set channelId {}
    dict for {id dmChan} [set ${sessionNs}::dmChannels] {
        set recipients [dict get $dmChan recipients]
        if {[llength $recipients] > 1} {
            continue
        }
        if {[dict get [lindex $recipients 0] id] eq $userId} {
            set channelId [dict get $dmChan id]
            break
        }
    }
    rest::DeleteChannel [set ${sessionNs}::token] $channelId $cmd
}

# discord::getMessages --
#
#       Get the messages for a channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       data        Dictionary representing a JSON object. Each key is one of
#                   around, before, after, limit. All keys are optional.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc getMessages { channelId data } {
    rest::GetChannelMessages [set ${sessionNs}::token] $channelId $data $cmd
}

# discord::getMessage --
#
#       Get a channel message by ID.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc getMessage { channelId messageId } {
    rest::GetChannelMessage [set ${sessionNs}::token] $channelId $messageId $cmd
}

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

discord::GenApiProc sendMessage { channelId content } {
    rest::CreateMessage [set ${sessionNs}::token] $channelId \
            [dict create content $content] $cmd
}

# discord::uploadFile --
#
#       Upload a file to the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       filename    Name of the file.
#       type        Content-Type value.
#       file        File data.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc uploadFile { channelId filename type file } {
    rest::UploadFile [set ${sessionNs}::token] $channelId $filename $type \
            $file $cmd
}

# discord::editMessage --
#
#       Edit a message in the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       content     New message content.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc editMessage { channelId messageId content } {
    rest::EditMessage [set ${sessionNs}::token] $channelId $messageId \
            [dict create content $content] $cmd
}

# discord::deleteMessage --
#
#       Delete a message from the channel.
#
# Arguments:
#       sessionNs   Name of session namespace.
#       channelId   Channel ID.
#       messageId   Message ID.
#       getResult   See "Shared Arguments".
#
# Results:
#       See "Shared Results".

discord::GenApiProc deleteMessage { channelId messageId } {
    rest::DeleteMessage [set ${sessionNs}::token] $channelId $messageId $cmd
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

discord::GenApiProc createDM { userId } {
    rest::CreateDM [set ${sessionNs}::token] \
            [dict create recipient_id $userId] $cmd
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
        if {[dict get [lindex $recipients 0] id] eq $userId} {
            set channelId [dict get $dmChan id]
            break
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
