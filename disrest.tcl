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
    set log [logger::init discord::rest]
}

# discord::rest::Send
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
#       Returns 1 if successful, and 0 otherwise.

proc discord::rest::Send { token verb resource {data {}} {cmd {}} {timeout 0}
        } {
    variable log
    global discord::ApiBaseUrlV6
    if {$verb ni [list GET POST PUT PATCH DELETE]} {
        ${log}::error "Send: HTTP method not recognized: '$verb'"
        return 0
    }

    set body [list]
    dict for {field value} $data {
        
    }
    set url "${ApiBaseUrl}/${resource}"
    if {[catch [list ::http::geturl $url \
            -headers [list Authorization "Bot $token"] \
            -method $verb \
            -timeout $timeout] res]} {
        ${log}::error "Send: $res"
        return 0
    }
    set status [::http::status $res]
    switch $status {
        error -
        timeout -
        reset {
            ${log}::error "Send: $url: $status"
            return 0
        }
        ok {
            if {[llength $cmd] > 0} {
                if {[catch {json::json2dict [::http::data $res]} resData]} {
                    ${log}::error "Send: $resData"
                    return 0
                }
                after idle [list {*}$cmd $resData]
            }
        }
    }
    ::http::cleanup $token
    return 1
}
