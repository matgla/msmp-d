module source.message_broker;

import std.experimental.logger;
import std.container: DList;

import source.logger_factory;
import source.transport_transceiver;
import source.message_handler;

class MessageBroker
{
public:
    alias CallbackType = void delegate();
    this()
    {
        logger_ = LoggerFactory.createLogger("MessageBroker");
    }

    void add_transceiver(TransportTransceiver transceiver)
    {
        transceivers_.insertBack(transceiver);
        transceivers_.back().on_data(&MessageBroker.handle_message);
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

    Logger logger_;
    DList!TransportTransceiver transceivers_;
    DList!MessageHandler handlers_;
}
