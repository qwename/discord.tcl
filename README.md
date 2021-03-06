# discord.tcl 0.6.0
Discord API library writtten in Tcl.
Tested with Tcl 8.6.
Supports Discord Gateway API version 6.

### Status

- Gateway API
  - All events except Request Guild Members, Message Reaction Add/Remove.
- HTTP API
  - All Channel related requests.
  - All Guild related requests.
  - All Invite related requests.
  - All User related requests.
  - All Voice related requests.
  - All Webhook related requests except Slack/Github Webhooks.
- Callbacks can be registered for all Dispatch events
- Event callbacks not implemented: Typing Start, User Settings Update,
  Voice State Update, Voice Server Update.
- Library API not implemented:
  - For whitelisted bots: Group DM Add/Remove Recipient, Create Guild,
    Delete Guild, Create Group DM.
  - Webhooks

### Libraries

- [Tcllib 1.18](http://www.tcl.tk/software/tcllib) (*websocket*, *json*,
    *json::write*, *logger*, *uuid*)
- [TLS 1.6.7](https://sourceforge.net/projects/tls) (*tls*)

### Usage
Check out [tclqBot](https://github.com/qwename/tclqBot) for a bot written
with this library.

DIY: For when you feel like writing your own discord.tcl.
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
[Wed Nov 23 18:39:19 EST 2016] [discord::gateway] [notice] 'GetGateway: No cached Gateway API URL for https://discordapp.com/api'
[Wed Nov 23 18:39:19 EST 2016] [discord::gateway] [info] 'GetGateway: Retrieving Gateway API URL from https://discordapp.com/api/v6/gateway'
[Wed Nov 23 18:39:19 EST 2016] [discord::gateway] [info] 'GetGateway: Cached Gateway API URL for https://discordapp.com/api: wss://gateway.discord.gg'
[Wed Nov 23 18:39:19 EST 2016] [discord::gateway] [notice] 'connect: wss://gateway.discord.gg/?v=6&encoding=json'
[Wed Nov 23 18:39:19 EST 2016] [discord::gateway] [notice] 'Handler: Connected.'
2016-11-23T23:39:25.953000+00:00 [redacted]#0000: Don't ever reduce achievements. Add more!!
```

### Testing

Sourcing or executing a .test file found under tests/ will test related
namespace procedures.

E.g.
```
tclsh tests/gateway.test
```

The file [local\_server.tcl](/tests/local_server.tcl) contains procedures for
setting up a local HTTP(S) server. The main proc is LocalServerSetupAll.

### Links

- [Tcl Developer Xchange](https://tcl.tk)
- [Coding style guide](http://www.tcl.tk/doc/styleGuide.pdf)

### TODO

- Message queue for rate-limited requests.
- Find out HTTP API Batch Modify Guild Role payload format.
- Implement Request Guild Members Gateway opcode.
- Implement all Gateway Dispatch event callbacks.
- Test cases for "pure" procs, send HTTP requests to test both HTTP responses
  and Gateway events.
- Find out why *zlib inflate* fails.
- ~~Local message cache using sqlite3/tdbc::sqlite3/tdbc::postgres package.~~
  Leave message logging up to library users.
- Use "return -code error -errorcode ..." when possible for standardized
  exception handling. See ThrowError in websocket from tcllib for an example.
- Use the *try* command.
- Create a tcltest custommatch to check -errorcode.
- Test HTTP API and Gateway API with local server.
- Change disrest::Send to send JSON payload without http::formatQuery.
  json::dict2json doesn't work as expected, so types have to be stored.
