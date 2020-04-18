signal tower
===========

signal tower is a signaling server for webrtc applications written in Elixir.

It is based on the palava signaling protocol (https://github.com/palavatv/palava-client/wiki/Protocol) over websockets and it is used in the palava project (https://github.com/palavatv/palava).

Install:
```
mix deps.get
mix deps.compile
```

Test:
```
mix test
```

Start locally:
```
./start.sh or ./start_daemon.sh
```

Release and use in production:
```
mix release production
```

By default, the websocket port 4233 is used, you can change it via:
```
export PALAVA_RTC_ADDRESS=1234
```
