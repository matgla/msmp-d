module test.transport_receiver_tests;

import dunit;
import std.stdio;

import source.transport_receiver;
import source.transport_frame;
import source.message_type;

import test.stubs.data_link_receiver_stub;

class TransportReceiverTests
{
    mixin UnitTest;

    this()
    {
        data_link_receiver_ = new DataLinkReceiverStub;
    }

    @BeforeEach
    void SetUp()
    {
        control_frame_ = new TransportFrame;
        data_frame_ = new TransportFrame;
        failure_frame_ = new TransportFrame;
    }

    @Test
    public void ReceiveDataPayload()
    {
        auto sut = new TransportReceiver(data_link_receiver_);

        sut.on_control_frame(&TransportReceiverTests.receive_control_frame);
        sut.on_data_frame(&TransportReceiverTests.receive_data_frame);
        ubyte[] data = [
            MessageType.Data,
            1, // transaction id
            1, 2, 3, 4,
            0x56, 0x12, 0x0d, 0xc9
        ];
        data_link_receiver_.receive(data);

        assertEquals([1, 2, 3, 4], data_frame_.buffer);
        assertEquals(0, control_frame_.buffer.length);
        assertEquals(TransportFrameStatus.Ok, data_frame_.status);
        assertEquals(1, data_frame_.transaction_id);
    }

    @Test
    public void ReceiveControlPayload()
    {
        auto sut = new TransportReceiver(data_link_receiver_);

        sut.on_control_frame(&TransportReceiverTests.receive_control_frame);
        sut.on_data_frame(&TransportReceiverTests.receive_data_frame);
        ubyte[] data = [
            MessageType.Control,
            2, // transaction id
            0xd, 0x0, 0xd, 0xa,
            0xa7, 0x4f, 0x6e, 0xe8
        ];
        data_link_receiver_.receive(data);

        assertEquals([0xd, 0x0, 0xd, 0xa], control_frame_.buffer);
        assertEquals(0, data_frame_.buffer.length);
        assertEquals(TransportFrameStatus.Ok, control_frame_.status);
        assertEquals(2, control_frame_.transaction_id);
    }

    @Test
    public void ReportCrcMismatch()
    {
        auto sut = new TransportReceiver(data_link_receiver_);

        sut.on_failure(&TransportReceiverTests.receive_failure);
        ubyte[] data = [
            MessageType.Control,
            2, // transaction id
            0xd, 0x0, 0xd, 0xa,
            0xa1, 0x2, 0x3, 0x4
        ];
        data_link_receiver_.receive(data);

        assertEquals([0xd, 0x0, 0xd, 0xa], failure_frame_.buffer);
        assertEquals(TransportFrameStatus.CrcMismatch, failure_frame_.status);
        assertEquals(2, failure_frame_.transaction_id);
    }

    @Test
    public void ReportWrongMessageTypeMismatch()
    {
        auto sut = new TransportReceiver(data_link_receiver_);

        sut.on_failure(&TransportReceiverTests.receive_failure);
        ubyte[] data = [
            3,
            2, // transaction id
            0xd, 0x0, 0xd, 0xa,
            0xea, 0x87, 0xcf, 0xe3
        ];
        data_link_receiver_.receive(data);

        assertEquals([0xd, 0x0, 0xd, 0xa], failure_frame_.buffer);
        assertEquals(TransportFrameStatus.WrongMessageType, failure_frame_.status);
        assertEquals(2, failure_frame_.transaction_id);
    }


    void receive_control_frame(TransportFrame frame)
    {
        control_frame_ = frame;
    }

    void receive_data_frame(TransportFrame frame)
    {
        data_frame_ = frame;
    }

    void receive_failure(TransportFrame frame)
    {
        failure_frame_ = frame;
    }

    TransportFrame control_frame_;
    TransportFrame data_frame_;
    TransportFrame failure_frame_;
    DataLinkReceiverStub data_link_receiver_;
}
