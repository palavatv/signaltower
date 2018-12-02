#!/usr/bin/env node

var WebSocket = require('ws');

ws = new WebSocket("ws://localhost:4233");
ws.on('open', function() {
    var send_msgs = [
        {event: "join_room", room_id: "test"},
        {event: "join_room", room_id: "test"},
        {event: "join_room", room_id: "test2"},
        {event: "leave_room", room_id: "test2"},
        {event: "leave_room", room_id: "test"},
        {event: "join_room", room_id: "test2"}
    ];
    var sendNext = function() {
        if(send_msgs.length > 0) {
            var msg = send_msgs.shift()
            var json = JSON.stringify(msg);
            console.log(json);
            ws.send(json);
            if(msg.event == "leave_room") sendNext();
        } else {
            ws.close();
        }
    };
    ws.on('message', function(msg) {
        console.log("-> " + msg);
        console.log("");
        sendNext();
    });

    sendNext();
});
