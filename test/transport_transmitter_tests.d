module test.transport_transmitter_tests;

import dunit;

import source.context;
import source.message_type;
import source.transport_transmitter;
import source.transmission_status;


import test.stubs.time_provider_stub;
import test.stubs.data_link_transmitter_stub;

class TransportTransmitterTests
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
        ubyte[] data = [1, 2, 3, 4];
        ubyte[] data2 = [3, 4];
        sut.send(data);
        sut.send(data2);
        ubyte[] control_data = [0xd, 0x0, 0xd, 0xa];
        sut.send_control(control_data);

        context_.execution_queue().run();

        assertEquals([
            MessageType.Control,
            3,
            0xd, 0x0, 0x0d, 0xa,
            0x9a, 0x2f, 0x47, 0x58,
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4, // data
            0x56, 0x12, 0x0d, 0xc9 // crc
        ], data_link_transmitter_.get_buffer());

        data_link_transmitter_.clear_buffer();
        sut.confirm_frame_transmission(1);

        context_.execution_queue().run();
        assertEquals([
            MessageType.Data,
            2,
            3, 4,
            0xa4, 0x89, 0x54, 0x23
        ], data_link_transmitter_.get_buffer());
    }

    @Test
    public void RetransmitAfterFailure()
    {
        auto sut = new TransportTransmitter(data_link_transmitter_, context_);
        ubyte[] data = [1, 2, 3, 4];
        sut.send(data);
        context_.execution_queue().run();

        assertEquals([
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4, // data
            0x56, 0x12, 0x0d, 0xc9 // crc
        ], data_link_transmitter_.get_buffer());

        data_link_transmitter_.emit_failure(TransmissionStatus.BufferFull);
        context_.execution_queue().run();

        assertEquals([
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4, // data
            0x56, 0x12, 0x0d, 0xc9, // crc
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4, // data
            0x56, 0x12, 0x0d, 0xc9 // crc
        ], data_link_transmitter_.get_buffer());
    }

    @Test
    public void ReportFailureWhenRetransmissionFailedThreeTimes()
    {
        auto sut = new TransportTransmitter(data_link_transmitter_, context_);
        ubyte[] data = [1, 2, 3, 4];
        sut.send(data, &TransportTransmitterTests.on_success, &TransportTransmitterTests.on_failure);
        context_.execution_queue().run();

        assertEquals([
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4, // data
            0x56, 0x12, 0x0d, 0xc9 // crc
        ], data_link_transmitter_.get_buffer());

        data_link_transmitter_.emit_failure(TransmissionStatus.BufferFull);
        data_link_transmitter_.emit_failure(TransmissionStatus.BufferFull);
        assertFalse(succeeded_);
        assertFalse(failed_);
        data_link_transmitter_.emit_failure(TransmissionStatus.BufferFull);
        assertFalse(succeeded_);
        assertTrue(failed_);
    }

    void on_success()
    {
        succeeded_ = true;
    }

    void on_failure()
    {
        failed_ = true;
    }

    bool succeeded_;
    bool failed_;

    Context context_;
    DataLinkTransmitterStub data_link_transmitter_;
    TimeProviderStub time_provider_;
}
