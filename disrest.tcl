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
    variable SendCount [dict create]
    variable BurstLimitSend 5
    variable BurstLimitPeriod 1
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
#       args        (optional) addtional options and values to be passed to
#                   http::geturl.
#
# Results:
#       Raises an exception if verb is unknown.

proc discord::rest::Send { token verb resource {data {}} {cmd {}} args } {
    variable log
    variable SendId
    variable SendInfo
    variable RateLimits
    variable SendCount
    variable BurstLimitSend
    variable BurstLimitPeriod
    global discord::ApiBaseUrlV6

    if {$verb ni [list GET POST PUT PATCH DELETE]} {
        ${log}::error "Send: HTTP method not recognized: '$verb'"
        return -code error "Unknown HTTP method: $verb"
    }

    regexp {^(/(?:channels|guilds)/\d+)} $resource -> route
    if {$route ne {}} {
        if {![dict exists $SendCount $token $route]} {
            dict set SendCount $token $route 0
        }
        set sendCount [dict get $SendCount $token $route]
        if {$sendCount == 0} {
            after [expr {$BurstLimitPeriod * 1000}] [list \
                    dict set ::discord::rest::SendCount $token $route 0]
        }
        if {$sendCount >= $BurstLimitSend} {
            ${log}::warn [join [list "Send: Reached $BurstLimitSend messages" \
                    "sent in $BurstLimitPeriod s."]]
            if {[llength $cmd] > 0} {
                {*}$cmd {} "Local rate-limit"
            }
            return
        }
        if {[dict exists $RateLimits $token $route X-RateLimit-Remaining]} {
            set remaining [dict get $RateLimits $token $route \
                    X-RateLimit-Remaining]
            if {$remaining <= 0} {
                set resetTime [dict get $RateLimits $token $route \
                        X-RateLimit-Reset]
                set secsRemain [expr {$resetTime - [clock seconds]}]
                puts "$secsRemain"
                if {$secsRemain >= -3} {
                    ${log}::warn [join [list "Send: Rate-limited on /$route," \
                            "reset in $secsRemain seconds"]]
                    return
                }
            }
        }
        dict set SendCount $token $route [incr sendCount]
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
    dict set SendInfo $sendId [dict create cmd $cmd url $url token $token \
            route $route]
    set command [list ::http::geturl $url \
            -headers [list Authorization "Bot $token"] \
            -method $verb \
            -command $callbackName \
            {*}$args]
    if {[llength $body] > 0} {
        lappend command -query [::http::formatQuery {*}$body]
    }
    ${log}::debug "Send: $route: $command"
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
    set route [dict get $SendInfo $sendId route]
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
                    dict set RateLimits $discordToken $route \
                            $header $meta($header)
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

# discord::rest::CallbackCoroutine
#
#       Resume a coroutine that is waiting for the response from a previous
#       call to Send. The coroutine should call this coroutine after resumption
#       to get the results. This procedure should be passed in a list to the
#       'cmd' argument of Send, e.g.
#           Send ... [list coroutine $contextName \
#                   discord::rest::CallbackCoroutine $callerName]
#
# Arguments:
#       coroutine   Coroutine to be resumed.
#       data        Dictionary representing a JSON object, or empty if an error
#                   had occurred.
#       httpCode    The HTTP status reply, or error message if an error had
#                   occurred.
#
# Results:
#       Returns a list containing data and httpCode.

proc discord::rest::CallbackCoroutine { coroutine data httpCode } {
    if {[llength [info commands $coroutine]] > 0} {
        after idle $coroutine
        yield
    }
    return [list $data $httpCode]
}
