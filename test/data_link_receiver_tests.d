module test.data_link_receiver_tests;

import dunit;

import source.data_link_receiver;
import source.control_byte;

import test.stubs.time_provider_stub;

class DataLinkReceiverTests
{
    mixin UnitTest;

    this()
    {
        time_provider_ = new TimeProviderStub;
    }

    @BeforeEach
    public void setUp()
    {
        data_buffer_ = [];
        failure_buffer_ = [];
    }

    @Test
    public void ReceiveData()
    {
        DataLinkReceiver sut = new DataLinkReceiver();

        sut.on_failure(&DataLinkReceiverTests.onFailure);
        sut.on_data(&DataLinkReceiverTests.onData);
        sut.receive([ControlByte.StartFrame, 1, 2, 3, ControlByte.StartFrame]);

        assertTrue(failure_buffer_.length == 0);
        assertEquals([1, 2, 3], data_buffer_);
    }

    @Test
    public void ReceiveStuffedData()
    {
        DataLinkReceiver sut = new DataLinkReceiver();

        sut.on_failure(&DataLinkReceiverTests.onFailure);
        sut.on_data(&DataLinkReceiverTests.onData);

        sut.receive([ControlByte.StartFrame,
            ControlByte.EscapeCode, 2,
            ControlByte.EscapeCode, ControlByte.EscapeCode,
            ControlByte.EscapeCode, ControlByte.StartFrame,
            ControlByte.StartFrame
        ]);

        assertEquals([2, ControlByte.EscapeCode, ControlByte.StartFrame], data_buffer_);
    }

    void onFailure(DataLinkReceiver.StreamType data)
    {
        failure_buffer_ = data;
    }

    void onData(DataLinkReceiver.StreamType data)
    {
        data_buffer_ = data;
    }

    DataLinkReceiver.StreamType failure_buffer_;
    DataLinkReceiver.StreamType data_buffer_;
    TimeProviderStub time_provider_;
}

