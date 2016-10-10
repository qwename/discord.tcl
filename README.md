# discord.tcl 0.1
Discord API library writtten in Tcl.
Tested with Tcl 8.5.
Supports Discord Gateway API version 6.

### Status

- Can only connect to the Gateway
- Dispatch events supported: Restart, Resume
- Callbacks can be registered for all events

### Libraries

- [Tcllib 1.18](http://www.tcl.tk/software/tcllib) (*websocket*, *json*, *json::write*, *logger*)
- [TLS 1.6.7](https://sourceforge.net/projects/tls) (*tls*)
- [mkZiplib 1.0](http://mkextensions.sourceforge.net) (optional, for compression of Dispatch "READY" event)

### Usage
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
```

Example output
```
[Sun Oct 09 14:43:01 EDT 2016] [discord::gateway] [notice] 'Connecting to the Gateway: wss://gateway.discord.gg/?v=6&encoding=json'
2016-10-09T18:43:36.651000+00:00 qwename#5406: hi there
```

### Links

- [Coding style guide](http://www.tcl.tk/doc/styleGuide.pdf)

### TODO

- Implement Dispatch event callbacks in namespace discord
