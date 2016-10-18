# discord.tcl 0.4.0
Discord API library writtten in Tcl.
Tested with Tcl 8.6.
Supports Discord Gateway API version 6.

### Status

- Can only connect to the Gateway
- Tracks users, guilds, DM channels
- Callbacks can be registered for all Dispatch events
- Event callbacks not implemented: Typing Start, User Settings Update,
  Voice State Update, Voice Server Update.
- HTTP requests supported: Get Channel, Modify Channel.

### Libraries

- [Tcllib 1.18](http://www.tcl.tk/software/tcllib) (*websocket*, *json*,
    *json::write*, *logger*)
- [TLS 1.6.7](https://sourceforge.net/projects/tls) (*tls*)

### Usage
Use provided event handling and local state tracking.
```
package require discord

${discord::log}::setlevel info

proc messageCreate { sessionNs event data } {
    set timestamp [dict get $data timestamp]
    set username [dict get $data author username]
    set discriminator [dict get $data author discriminator]
    set content [dict get $data content]
    puts "$timestamp ${username}#${discriminator}: $content"
}

proc registerCallbacks { sessionNs } {
    discord setCallback $sessionNs MESSAGE_CREATE ::messageCreate
}

set token "your token here"
set session [discord connect $token ::registerCallbacks]

vwait forever

discord disconnect $session

# Cleanup
discord disconnect $session
```
DIY
```
package require discord

${discord::log}::setlevel info

proc messageCreate { event data } {
    set timestamp [dict get $data timestamp]
    set username [dict get $data author username]
    set discriminator [dict get $data author discriminator]
    set content [dict get $data content]
    puts "$timestamp ${username}#${discriminator}: $content"
}

proc registerCallbacks { sock } {
    discord::gateway setCallback $sock MESSAGE_CREATE messageCreate
}

set token "your token here"
set sock [discord::gateway connect $token registerCallbacks]

vwait forever

# Cleanup
discord::gateway disconnect $sock
```

Example output
```
[Sun Oct 09 14:43:01 EDT 2016] [discord::gateway] [notice] 'Connecting to the Gateway: wss://gateway.discord.gg/?v=6&encoding=json'
2016-10-09T18:43:36.651000+00:00 qwename#5406: hi there
```

### Links

- [Tcl Developer Xchange](https://tcl.tk)
- [Coding style guide](http://www.tcl.tk/doc/styleGuide.pdf)

### TODO

- Implement all Gateway Dispatch event callbacks
- Create test cases for most procedures.
- Find out why *zlib inflate* fails.
- Local message cache using sqlite3/tdbc::sqlite3/tdbc::postgres package.
