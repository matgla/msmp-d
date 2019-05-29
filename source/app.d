import std.stdio;
import source.data_link_transmitter;
import source.i_data_writer;
import source.i_time_provider;
import source.context;
import std.datetime;
import core.time : Duration;

class Writer : IDataWriter
{
public:
    override void write(ubyte payload)
    {

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
    Writer writer = new Writer;
    DataLinkTransmitter d = new DataLinkTransmitter(writer, context);
    d.send([1, 2, 3, 0xfa]);
}
