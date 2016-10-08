# discord.tcl 0.1
Discord API library writtten in Tcl. Tested on Tcl 8.5.

### Status

- Can only connect to the Gateway
- Only handles the "READY" Dispatch event
- Does not disconnect properly

### Libraries

- [Tcllib 1.18](http://www.tcl.tk/software/tcllib) (*websocket*, *rest*, *json::write*, *logger*)
- [TLS 1.6.7](https://sourceforge.net/projects/tls) (*tls*)
- [tDOM 0.8.3](https://tdom.github.io) (*rest*)
- [mkZiplib 1.0](http://mkextensions.sourceforge.net) (optional, for compression of Dispatch "READY" event)

### Usage
```
package require discord

${discord::log}::setlevel info

set token "your token here"
discord::gateway connect $token
```

### Links

- [Coding style guide](http://www.tcl.tk/doc/styleGuide.pdf)

### TODO

- Implement more Dispatch events
