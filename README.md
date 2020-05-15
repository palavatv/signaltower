signal tower
===========

Signal tower is a signaling server for WebRTC applications written in Elixir.

It is based on the [palava signaling protocol][palava protocol] over websockets and is used in the [palava project][palava project].

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

[palava protocol]: https://github.com/palavatv/palava-client/wiki/Protocol
[palava project]: https://github.com/palavatv/palava
