# Tinkerbell WebSocket 

[![Build Status](https://travis-ci.org/haxetink/tink_websocket.svg)](https://travis-ci.org/haxetink/tink_websocket)
[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg?maxAge=2592000)](https://gitter.im/haxetink/public)

> WebSocket is a computer communications protocol, providing full-duplex communication channels over a single TCP connection.

## Handler

For each connection, there is a stream of incoming messages (chunk of bytes) and a stream of outgoing messages.
So, a websocket handler is `RealStream<Chunk>->IdealStream<Chunk>` where the `RealStream` is the incoming stream
and `IdealStream` is the outgoing stream.

Getting chunks of bytes isn't very useful. So the `MessageStream` class comes to rescue:

```haxe
abstract MessageStream<Quality>(Stream<Message, Quality>) from Stream<Message, Quality> to Stream<Message, Quality> {	
  @:from public static inline function ofChunkStream<Q>(s:Stream<Chunk, Q>):MessageStream<Q>
  @:to public inline function toChunkStream():Stream<Chunk, Quality>
}
```

So `MessageStream.ofChunkStream(chunkStream)` will give you a readily usable stream of websocket messages.
On the other hand, given a stream of messages, calling `messageStream.toChunkStream()` will give you the
stream of chunks that is ready to get piped into the tcp wire.

## Client

### With tink_tcp

Use `Connector.wrap()` to transform a websocket handler to a tcp handler, then use it in a tcp connection.
Visit documentation of tink_tcp for more details on setting up a tcp connection.

## Server

### With tink_tcp

Use `Acceptor.wrap()` to transform a websocket handler to a tcp handler, then use it in a tcp server.
Visit documentation of tink_tcp for more details on setting up a tcp server.

### With tink_http

Use the `WebSocket` middleware to combine a websocket handler with a http handler into a single http handler, then use it in a http container.
Visit documentation of tink_http for more details on setting up a http container.


TODO:

- Respond to ping-pong messages automatically
- Handle connection-close messages
