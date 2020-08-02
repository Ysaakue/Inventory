var io = require('socket.io').listen(5001);
var redis = require('redis').createClient();

redis.subscribe('rt-change');

io.on('connection', function(socket){
  // console.log('a user connected');
  redis.on('message', function(channel, message){
    message_parsed = JSON.parse(message)
    io.emit('count_status_' + message_parsed.id.toString(), message_parsed);
  });
});
