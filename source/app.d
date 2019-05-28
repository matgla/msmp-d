import std.stdio;
import source.data_link_transmitter;
import source.i_data_writer;
import source.context;

class Writer : IDataWriter
{
public:
    override void write(ubyte payload)
    {

    }
}

void main()
{
    writeln("Connection test");
    Context context = new Context;
    Writer writer = new Writer;
    DataLinkTransmitter d = new DataLinkTransmitter(writer, context);
    d.send([1, 2, 3, 0xfa]);
}
