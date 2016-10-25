# local_server.tcl --
#
#       This file contains a basic implementation of a HTTP(S)/WS(S) server that
#       is intended to aid in testing the library procedures.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

package require tls
package require logger

set log [logger::init local_server]
${log}::disable emergency

set scriptDir [file dirname [info script]]

# Filename prefixes and suffixes for RSA keys.

set tlsFilePre(configFile)  "$scriptDir/openssl-config-"
set tlsFilePre(privKey)     "$scriptDir/test-server-private-"
set tlsFilePre(pubKey)      "$scriptDir/test-server-public-"
set tlsFileEnd(configFile)  .cfg
set tlsFileEnd(privKey)     .pem
set tlsFileEnd(pubKey)      .pem

# For generating unique names.

set tlsFileId 0

set tlsRegex {^(?:http|ws)s$}
set localServer {}
set localServerUrl {}

set defaults(protocol) https
set defaults(testFile) {}
set defaults(timeout) 3000

# TlsCallback --
#
#       Handler invoked during the OpenSSL handshake.
#
# Arguments:
#       args    Five arguments, the first being one of info, verify. The rest
#               depends on what the first argument is.
#
# Results:
#       None.

proc ::TlsCallback { args } {
    variable log
    switch [lindex $args 0] {
        info {
            lassign $args - channel major minor message
            ${log}::debug [info level 0]
        }
        verify {
            lassign $args - channel depth cert status error
            ${log}::debug [info level 0]
        }
        default {
            ${log}::warn stderr "TlsCallback: Unknown arguments: $args"
        }
    }
}

# HandleConnection --
#
#       Callback to handle connecting clients. The last three arguments are
#       passed by a server socket.
#
# Arguments:
#       scripts List of two scripts to be invoked upon the readable and
#               writable channel events respectively. The argument channel is
#               passed as the last argument to the scripts.
#       options Additional options for "chan configure $channel".
#       channel Client socket.
#       address Client host in network address notation.
#       port    Client port number.
#
# Results:
#       None.

proc ::HandleConnection { scripts options channel address port } {
    variable log
    ${log}::info "HandleConnection: Socket $channel: $address:$port"
    if {[llength $options] > 0} {
        eval chan configure $channel {*}$options
    }
    lassign $scripts readScript writeScript
    if {[llength $readScript] > 0} {
        chan event $channel readable [list {*}$readScript $channel]
    }
    if {[llength $writeScript] > 0} {
        chan event $channel writable [list {*}$writeScript $channel]
    }
}

# SetupLocalServer --
#
#       Opens a socket for the corresponding protocol.
#
# Arguments:
#       protocol    Case-insensitive, one of http, https, ws, wss.
#       handler     Client connection callback.
#
# Results:
#       Returns a list of the server socket and URL.

proc ::SetupLocalServer { protocol handler args } {
    switch $protocol {
        https {
            set socket ::tls::socket
        }
        http {
            set socket ::socket
        }
        ws -
        wss -
        default {
            return -code -error "Unsupported protocol: $protocol"
        }
    }
    set server [$socket -server $handler -myaddr localhost 0]
    lassign [chan configure $server -sockname] address hostname port
    return [list $server "$protocol://$hostname:$port"]
}

# CleanupLocalServer --
#
#       Closes an opened server socket.
#
# Arguments:
#       channel Server socket from SetupLocalServer.
#       url     Server URL from SetupLocalServer.
#
# Results:
#       None.

proc ::CleanupLocalServer { channel url } {
    chan close $channel
}

# LocalServerSetupAll --
#
#       Setup a local test server.
#
# Arguments:
#       timeout     (optional) time in milliseconds until the server closes.
#                   Defaults to 3000, or 3 seconds.
#       protocol    (optional) case-insensitive, one of http, https, ws, wss.
#                   Defaults to https.
#       testFile    (optional) Tcl test file to execute in a subprocess. This
#                   can also be a list with additional arguments to the test
#                   file. The server URL will be passed as the last argument.
#       scripts     (optional) list of two scripts to be invoked upon the
#                   readable and writable channel events respectively. The
#                   argument channel is passed as the last argument to the
#                   scripts.
#       args        Additional options for "chan configure $channel".
#
# Results:
#       Returns a list of the server socket and URL. Creates RSA keys if the
#       protocol requires TLS, and opens a server sockect with the keys. The
#       testFile is executed as a subprocess in the background.

proc ::LocalServerSetupAll { {timeout 3000} {protocol https} {testFile {}} \
        {scripts {}} args } {
    variable defaults
    variable log
    variable tlsRegex
    set pids [list]
    set files [list]
    set localServer {}
    set localServerUrl {}
    if {$protocol eq {}} {
        set protocol $defaults(protocol)
        ${log}::info "Using default protocol: $protocol"
    } else {
        set protocol [string tolower $protocol]
        ${log}::info "Using protocol: $protocol"
    }
    
    if {$testFile eq {}} {
        ${log}::info "No test file specified."
    } elseif {![file isfile $testFile]} {
        return -code error "Not a file: $testFile"
    } else {
        ${log}::info "Using test file: $testFile"
    }
    
    if {$timeout eq {}} {
        set timeout $defaults(timeout)
        ${log}::info "Using default timeout: $timeout ms"
    } elseif {![string is integer $timeout] || $timeout <= 0} {
        return -code error "Invalid timeout: $timeout"
    } else {
        ${log}::info "Using timeout: $timeout"
    }
    
    # If a openssl program can be found on the system, create the private and
    # public RSA keys for our local server.
    
    if {[regexp $tlsRegex $protocol]
            && ![catch {auto_execok openssl} openssl]
            && $openssl ne {}} {
    
        variable tlsFileId
        set id $tlsFileId
        incr tlsFileId
        variable tlsFilePre
        variable tlsFileEnd
        foreach name [list configFile privKey pubKey] {
            set filename $tlsFilePre($name)${tlsFileId}$tlsFileEnd($name)
            set $name $filename
            lappend files $filename
        }

        # Generate a config file to avoid openssl prompting for information.
    
        set f [open $configFile w]
        chan puts $f [join {
                {prompt              = no}
                {distinguished_name  = req_distinguished_name}
                {[req_distinguished_name]}
                {countryName         = XX}} "\n"]
        chan close $f
    
        # Adapted from http://wiki.tcl.tk/15244
        # openssl may output an error ending with "e is 65537 (0x10001)", but we
        # can ignore it by wrapping it in a catch script.

        catch {exec $openssl genrsa -out $privKey 1024}
        exec $openssl req -new -x509 -key $privKey -out $pubKey -days 1 \
                -config $configFile
    
        if {[file exists $privKey] && [file exists $pubKey]} {
            ::tls::init -certfile $pubKey -keyfile $privKey -request false \
                    -require false -ssl2 true -ssl3 true -tls1 true \
                    -command ::TlsCallback
            set protocol https
        }
    }
    
    lassign [::SetupLocalServer $protocol [list ::HandleConnection $scripts \
            {*}$args]] localServer localServerUrl
    
    ${log}::debug "Server socket: $localServer URL: $localServerUrl"
    puts $localServerUrl
    
    if {$testFile ne {}} {
        set pid [eval exec {*}[auto_execok tclsh] {*}$testFile \
                $localServerUrl &]
        ${log}::info "Executing $testFile in subprocess, PID $pid"
        append pids $pid
    }
    after $timeout [list ::LocalServerCleanupAll $pids $files $localServer \
            $localServerUrl]
    
    return [list $localServer $localServerUrl]
}

# LocalServerCleanupAll --
#
#       Revert test directory to original state.
#
# Arguments:
#       pids    List of pids of processes to kill.
#       files   List of files to remove.
#       channel Server socket to close.
#       url     Server URL from LocalServerSetupAll.
#
# Results:
#       Kills spawned processes, removes created files, and closes server
#       socket.

proc ::LocalServerCleanupAll { pids files channel url } {
    global tcl_platform
    variable log
    set prog {}
    if {[llength $pids] > 0} {
        set platform $tcl_platform(platform)
        switch $platform {
            windows {
                set prog taskkill
            }
            unix {
                set prog kill
            }
        }
        if {$prog ne {}} {
            ${log}::info "Using '$prog' to kill processes."
        } else {
            ${log}::warn "Unknown platform: $tcl_platform(platform)"
        }
    }
    foreach pid $pids {
        if {$prog ne {}} {
            if {[catch {exec {*}[auto_execok $prog] $pid} result]} {
                ${log}::error $result
            } else {
                ${log}::notice "Killed process $pid."
            }
        } else {
            ${log}::warn "Please kill process $pid yourself."
        }
    }
    ::CleanupLocalServer $channel $url
    foreach file $files {
        if {[file exists $file]} {
            ${log}::info "Deleting $file"
            file delete $file
        }
    }
    ${log}::info "LocalServerCleanupAll complete."
    return
}

if {[info script] eq $argv0} {
    lassign $argv timeout
    if {![string is integer -strict $timeout] || $timeout <= 0} {
        set timeout $defaults(timeout)
    }
    ::LocalServerSetupAll {*}$argv
    after $timeout set ::forever 1
    vwait ::forever
    ${log}::info "Normal exit."
}
