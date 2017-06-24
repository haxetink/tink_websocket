package tink.websocket;

using tink.CoreApi;

typedef ClientHandler = RawMessageStream<Error>->RawMessageStream<Noise>;