module test.stubs.data_link_receiver_stub;

import std.signals;

import source.data_link_receiver;

class DataLinkReceiverStub : DataLinkReceiver
{
public:
    alias StreamType = ubyte[];

    override void receive(StreamType payload)
    {
        on_data_.emit(payload);
    }
}

