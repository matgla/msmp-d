import std.stdio;
import std.signals;
import source.data_link_transmitter;
import source.data_link_receiver;
import source.transport_transmitter;
import source.transport_receiver;
import source.transport_transceiver;
import source.message_broker;
import source.i_data_writer;
import source.i_time_provider;
import source.context;
import std.datetime;
import core.time : Duration;

class SocketWriter : IDataWriter
{
public:
    override void write(ubyte payload)
    {

    }
}

class SocketDataLinkReceiver: DataLinkReceiver
{
public:
    void on_data(ubyte[] data)
    {
        receive(data);
    }
}

class TimeProvider : ITimeProvider
{
public:
    override Duration milliseconds()
    {
        return Clock.currTime().fracSecs;
    }
}

void main()
{
    TimeProvider time_provider = new TimeProvider;
    Context context = new Context(time_provider);
    SocketWriter writer = new SocketWriter;
    SocketDataLinkReceiver d_receiver = new SocketDataLinkReceiver;
    DataLinkTransmitter d_transmitter = new DataLinkTransmitter(writer, context);
    auto receiver = new TransportReceiver(d_receiver);
    auto transmitter = new TransportTransmitter(d_transmitter, context);
    auto transceiver = new TransportTransceiver(receiver, transmitter);
    auto message_broker = new MessageBroker;
    message_broker.add_transceiver(transceiver);
}
