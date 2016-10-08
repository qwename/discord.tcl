# discord.tcl
Discord API library writtten in Tcl. Tested on Tcl 8.5.

### Required Libraries

- [Tcllib 1.18](http://www.tcl.tk/software/tcllib) (*websocket*, *rest*, *json::write*, *logger*)
- [TLS 1.6.7](https://sourceforge.net/projects/tls) (*tls*)
- [tDOM 0.8.3](https://tdom.github.io) (*rest*)

### Usage
```
package require discord

${discord::log}::setlevel info
set token "your token here"
discord::gateway connect $token
```
