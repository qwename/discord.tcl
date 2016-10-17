# disrest.tcl --
#
#       This file implements the Tcl code for interacting with the Discord HTTP
#       API.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require Tcl 8.5
package require http
package require tls
package require json
package require logger

::http::register https 443 ::tls::socket

namespace eval discord::rest {
    variable log [logger::init discord::rest]

    variable SendId 0
    variable SendInfo [dict create]
}

# discord::rest::GetChannel --
#
#       Get a channel by ID. Returns a Guild channel or DM channel dictionary.
#
# Arguments:
#       token       Bot token or OAuth2 bearer token.
#       channelId   Channel ID.
#       cmd         (optional) callback procedure invoked after a response is
#                   received.
#
# Results:
#       None.

proc discord::rest::GetChannel { token channelId {cmd {}} } {
    discord::rest::Send $token GET "/channels/$channelId" {} $cmd
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
#                   additional arguments to be passed to it. The last argument
#                   will be the data returned.
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
    global discord::ApiBaseUrlV6
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
    dict set SendInfo $sendId [dict create cmd $cmd url $url]
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
    interp alias {} ::discord::rest::SendCallback${sendId} {}
    set url [dict get $SendInfo $sendId url]
    set cmd [dict get $SendInfo $sendId cmd]
    set status [::http::status $token]
    ${log}::debug "SendCallback${sendId}: $url: $status"
    switch $status {
        error -
        timeout -
        reset {
            if {[llength $cmd] > 0} {
                after idle [list {*}$cmd {}]
            }
        }
        ok {
            set cmd [dict get $SendInfo $sendId cmd]
            if {[llength $cmd] > 0} {
                if {[catch {json::json2dict [::http::data $token]} data]} {
                    ${log}::error "SendCallback: $url: $data"
                    return
                }
                after idle [list {*}$cmd $data]
            }
        }
    }
    ::http::cleanup $token
    dict unset SendInfo $sendId
    return
}
