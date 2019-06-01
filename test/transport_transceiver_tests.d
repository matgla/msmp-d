module test.transport_transceiver_tests;

import dunit;

import std.algorithm.mutation: reverse;
import std.stdio;
import std.digest.crc;
import core.time: dur;

import source.context;
import source.transport_receiver;
import source.transport_transmitter;
import source.transport_transceiver;
import source.transport_frame;
import source.message_type;
import source.control_messages.ack;
import source.control_messages.messages_ids;
import source.control_messages.nack;

import test.stubs.time_provider_stub;
import test.stubs.data_link_receiver_stub;
import test.stubs.data_link_transmitter_stub;

class TransportTransceiverTests
{
    mixin UnitTest;

    this()
    {
        time_provider_stub_ = new TimeProviderStub;
        context_ = new Context(time_provider_stub_);
        data_link_receiver_ = new DataLinkReceiverStub;
        data_link_transmitter_ = new DataLinkTransmitterStub(context_);

        transport_receiver_ = new TransportReceiver(data_link_receiver_);
        data_link_transmitter_.enable_auto_emitting();
        transport_transmitter_ = new TransportTransmitter(data_link_transmitter_, context_);
    }

    @BeforeEach
    void SetUp()
    {
        buffer_ = [];
        success_ = false;
        failure_ = false;
    }

    ubyte[] generate_ack(ubyte transaction_id)
    {
        ubyte[] payload = [1, 0];
        auto ack = new Ack(transaction_id).serialize();
        payload ~= ack;

        CRC32 crc_calculator;
        crc_calculator.put(payload[]);
        ubyte[] crc = crc_calculator.finish().dup;
        crc = crc.reverse;

        payload ~= crc[];
        return payload;
    }

    ubyte[] generate_nack(ubyte transaction_id)
    {
        ubyte[] payload = [1, 0];
        auto nack = new Nack(transaction_id, Nack.Reason.CrcMismatch).serialize();
        payload ~= nack;

        CRC32 crc_calculator;
        crc_calculator.put(payload[]);
        ubyte[] crc = crc_calculator.finish().dup;
        crc = crc.reverse;

        payload ~= crc[];
        return payload;
    }

    @Test
    public void SendMessages()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.send([1, 2, 3, 4, 5]);
        sut.send([3, 4]);

        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2, 3, 4, 5,
            0x40, 0x86, 0x73, 0x1b], data_link_transmitter_.get_buffer());

        auto ack1 = generate_ack(1);
        data_link_transmitter_.clear_buffer();

        data_link_receiver_.receive(ack1);
        context_.execution_queue().run();

        assertEquals([
            2,
            2,
            3, 4,
            0xa4, 0x89, 0x54, 0x23
        ], data_link_transmitter_.get_buffer());
    }

    @Test
    public void ReceiveMessages()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        ubyte[] data = [
            2,
            1,
            1, 2, 3, 4, 5,
            0x40, 0x86, 0x73, 0x1b
        ];

        data_link_receiver_.receive(data);
        context_.execution_queue().run();

        assertEquals([1, 2, 3, 4, 5], buffer_);
    }

    @Test
    public void RespondNackForCrcMismatch()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        ubyte[] data = [
            1, 0,
            0xff,
            0x75, 0xc0, 0xcc, 0x33
        ];

        data_link_receiver_.receive(data);
        context_.execution_queue().run();

        assertEquals([
            2, 1,
            ControlMessages.Nack,
            0, Nack.Reason.CrcMismatch,
            0xeb, 0x92, 0xc8, 0x03
        ], data_link_transmitter_.get_buffer());
    }

    @Test
    public void RespondNackForWrongMessageType()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        ubyte[] data = [
            7, 0,
            0xff,
            0xd7, 0x0c, 0x20, 0x1a
        ];

        data_link_receiver_.receive(data);
        context_.execution_queue().run();

        assertEquals([
            2, 1,
            ControlMessages.Nack,
            0, Nack.Reason.WrongMessageType,
            0x72, 0x9b, 0x99, 0xb9
        ], data_link_transmitter_.get_buffer());
    }

    @Test
    public void RetransmitAfterNack()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        sut.send([1, 2, 3, 4, 5], &TransportTransceiverTests.on_success, &TransportTransceiverTests.on_failure);
        sut.send([3, 4], &TransportTransceiverTests.on_success, &TransportTransceiverTests.on_failure);
        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2, 3, 4, 5,
            0x40, 0x86, 0x73, 0x1b
        ], data_link_transmitter_.get_buffer());

        auto nack = generate_nack(1);
        data_link_transmitter_.clear_buffer();
        data_link_receiver_.receive(nack);
        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2, 3, 4, 5,
            0x40, 0x86, 0x73, 0x1b
        ], data_link_transmitter_.get_buffer());
        auto ack = generate_ack(1);
        assertFalse(failure_);
        assertFalse(success_);
        data_link_transmitter_.clear_buffer();
        data_link_receiver_.receive(ack);
        context_.execution_queue().run();

        assertEquals([
            2,
            2,
            3, 4,
            0xa4, 0x89, 0x54, 0x23
        ], data_link_transmitter_.get_buffer());

        assertFalse(failure_);
        assertTrue(success_);
    }

    @Test
    public void NotifyFailureWhenRetransmissionExceeded()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        sut.send([1, 2, 3, 4, 5], &TransportTransceiverTests.on_success, &TransportTransceiverTests.on_failure);
        sut.send([3, 4], &TransportTransceiverTests.on_success, &TransportTransceiverTests.on_failure);
        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2, 3, 4, 5,
            0x40, 0x86, 0x73, 0x1b
        ], data_link_transmitter_.get_buffer());

        for (size_t i = 0; i < context_.configuration().max_retransmission_tries + 1; ++i)
        {
            auto nack = generate_nack(1);
            data_link_receiver_.receive(nack);
            context_.execution_queue().run();
        }

        assertTrue(failure_);
        assertFalse(success_);
    }

    @Test
    public void RetransmitAfterTimeout()
    {
        auto sut = new TransportTransceiver(transport_receiver_, transport_transmitter_);
        sut.on_data(&TransportTransceiverTests.receive_data);

        sut.send([1, 2], &TransportTransceiverTests.on_success, &TransportTransceiverTests.on_failure);
        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2,
            0x7d, 0x9a, 0x2d, 0xcd
        ], data_link_transmitter_.get_buffer());
        data_link_transmitter_.clear_buffer();
        time_provider_stub_.increment(context_.configuration().timeout_for_transmission);
        time_provider_stub_.increment(dur!"msecs"(1));
        context_.timer_manager().run();
        context_.execution_queue().run();

        assertEquals([
            2,
            1,
            1, 2,
            0x7d, 0x9a, 0x2d, 0xcd
        ], data_link_transmitter_.get_buffer());
    }

    void receive_data(ubyte[] data)
    {
        buffer_ ~= data;
    }

    void on_success()
    {
        success_ = true;
    }

    void on_failure()
    {
        failure_ = true;
    }

    TimeProviderStub time_provider_stub_;
    Context context_;
    DataLinkReceiverStub data_link_receiver_;
    DataLinkTransmitterStub data_link_transmitter_;
    TransportReceiver transport_receiver_;
    TransportTransmitter transport_transmitter_;
    ubyte[] buffer_;
    bool success_;
    bool failure_;
}
