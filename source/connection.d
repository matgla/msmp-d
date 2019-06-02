module source.connection;

import std.container: DList;
import std.experimental.logger;
import std.signals;

import source.transport_transceiver;
import source.logger_factory;
import source.message_handler;

class Connection
{
public:
    alias StreamType = ubyte[];
    mixin Signal!(Connection) on_connected_;
    alias OnConnectedSlot = on_connected_.slot_t;
    mixin Signal!(StreamType) on_data_;
    alias OnDataSlot = on_data_.slot_t;

    this(TransportTransceiver transceiver)
    {
        transceiver_ = transceiver;
        transceiver_.on_data(&Connection.handle);
        logger_ = LoggerFactory.createLogger("Connection");
    }

    void on_connected(OnConnectedSlot slot)
    {
        on_connected_.connect(slot);
    }

    void on_data(OnDataSlot slot)
    {
        on_data_.connect(slot);
    }

    TransportTransceiver get_transceiver()
    {
        return transceiver_;
    }

private:
    void handle(StreamType payload)
    {
        if (payload.length == 0)
        {
            logger_.trace("Received empty message");
            return;
        }

        if (0 == payload[0])
        {
            handle_message(payload[1..$]);
        }
        else if (1 == payload[0])
        {
            on_data_.emit(payload[1..$]);
        }
    }

    void handle_message(StreamType payload)
    {
        foreach (handler; handlers_)
        {
            if (handler.id == payload[0])
            {
                handler.handle(payload);
            }
        }
    }

    DList!MessageHandler handlers_;
    TransportTransceiver transceiver_;
    Logger logger_;
}
