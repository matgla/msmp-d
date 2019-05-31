module test.transport_transmitter_tests;

import dunit;

import source.context;
import source.transport_transmitter;


import test.stubs.time_provider_stub;
import test.stubs.data_link_transmitter_stub;

class DataLinkReceiverTests
{
    mixin UnitTest;

    this()
    {
        time_provider_ = new TimeProviderStub;
        context_ = new Context(time_provider_);
        data_link_transmitter_ = new DataLinkTransmitterStub(context_);

    }

    @Test
    public void SendPayload()
    {
        auto sut = new TransportTransmitter(data_link_transmitter_, context_);
    }

    Context context_;
    DataLinkTransmitterStub data_link_transmitter_;
    TimeProviderStub time_provider_;
}
