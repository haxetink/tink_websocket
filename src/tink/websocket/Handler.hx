package tink.websocket;

import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.Chunk;

using tink.CoreApi;

typedef Handler = RealStream<Chunk>->IdealStream<Chunk>;