var io = require('socket.io').listen(5001);
var redis = require('redis').createClient();

redis.subscribe('rt-change');

io.on('connection', function(socket){
  console.log('a user connected');
  redis.on('message', function(channel, message){
    console.log(channel);
    console.log(message);
    // console.log(socket);
    console.log(io.emit('rt-change', JSON.parse(message)));
    console.log(io.emit('some event', { someProperty: 'some value', otherProperty: 'other value' })); // This will emit the event to all connected sockets
    console.log(socket.broadcast.emit('hi'));
  });
});
