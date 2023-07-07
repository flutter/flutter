/**
 * server.js
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *    2019/11/20, Created by jumperchen
 *
 * Copyright (C) 2019 Potix Corporation. All Rights Reserved.
 */
'use strict';
const app = require('express')();
const server = require('http').createServer(app);
const io = require('socket.io')(server);
io.on('connection', userSocket => {
    console.log('connected');
    userSocket.on('toServer', data => {
        userSocket.emit('fromServer', data);
    });
});
server.listen(3000, function(){
    console.log('listening on *:3000');
});

