# palava | signal tower
![Elixir CI](https://github.com/palavatv/signaltower/workflows/Elixir%20CI/badge.svg)
---

[palava.tv](https://palava.tv) is a cost-free, simple to use, secure, and open source platform for video calls, built on top of the [WebRTC](https://webrtc.org/) technology.

This repository contains the WebRTC signaling backend of palava.tv. There is an overview of all parts of palava.tv at [palavatv/palava](https://github.com/palavatv/palava).

The signal tower is a signaling server for WebRTC applications written in Elixir. It implements the [palava signaling protocol][palava protocol] over websockets to be used together with the [palava client][palava client].

## Setup

**Install:**
```
mix deps.get
mix deps.compile
```

**Test:**
```
mix test
```

You can also watch file changes and rerun tests automatically:

```
mix test.watch
```

**Start locally:**
```
./start.sh or ./start_daemon.sh
```

**Release and use in production:**
```
mix release production
```

By default, the websocket port 4233 is used, you can change it via:
```
export SIGNALTOWER_PORT=1234
```

By default, the websocket is bound to all interfaces (0.0.0.0), you can also bind it just localhost (127.0.0.1) via:
```
export SIGNALTOWER_LOCALHOST
```

[palava protocol]: https://github.com/palavatv/palava-client/wiki/Protocol
[palava client]: https://github.com/palavatv/palava-client/
[palava project]: https://github.com/palavatv/palava
