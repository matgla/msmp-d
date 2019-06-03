module source.message_broker;

import std.experimental.logger;
import std.container: DList;

import eul.logger.logger_factory;

import source.context;
import source.transport_transceiver;
import source.message_handler;
import source.connection;

class MessageBroker
{
public:
    alias CallbackType = void delegate();
    this(Context context)
    {
        context_ = context;
        logger_ = LoggerFactory.createLogger("MessageBroker");
    }

    void add_transceiver(TransportTransceiver transceiver)
    {
        connections_.insertBack(new Connection(transceiver, context_));
        connections_.back().on_data(&MessageBroker.handle_message);
    }

    void publish(Message)(Message message, CallbackType on_success, CallbackType on_failure)
    {

    }

private:
    void handle_message(ubyte[] payload)
    {
        if (payload.length == 0)
        {
            logger_.trace("Received empty message");
            return;
        }
        immutable ubyte id = payload[0];

        foreach (handler; handlers_)
        {
            if (handler.id == id)
            {
                handler.handle(payload);
            }
        }
    }

    Context context_;
    Logger logger_;
    DList!Connection connections_;
    DList!MessageHandler handlers_;
}
