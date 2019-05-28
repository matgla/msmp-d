module test.data_link_transmitter_tests;

import dunit;

import std.stdio;

import source.context;
import source.data_link_transmitter;
import source.control_byte;
import source.transmission_status;

import test.stubs.writer_stub;
import test.stubs.time_provider_stub;


class DataLinkTransmitterTests
{
    mixin UnitTest;

    this()
    {
        time_provider_ = new TimeProviderStub;
        writer_ = new WriterStub;
        context_ = new Context(time_provider_);
    }

    @BeforeAll
    public static void setUpAll()
    {
    }

    @AfterAll
    public static void tearDownAll()
    {
    }

    @BeforeEach
    public void setUp()
    {
        writer_.enable_autoresponding();
    }

    @AfterEach
    public void tearDown()
    {
    }

    @Test
    public void StartTransmissionAndFinishTransmission()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);

        assertEquals(TransmissionStatus.Ok, sut.send([1]));
        context_.execution_queue().run();
        assertEquals([ControlByte.StartFrame, 1, ControlByte.StartFrame], writer_.get_buffer());
    }

    @Test
    public void SendByte()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        ubyte byte1 = 0x12;
        ubyte byte2 = 0xab;

        sut.send([byte1, byte2]);
        context_.execution_queue().run();

        assertEquals([
            ControlByte.StartFrame,
            byte1,
            byte2,
            ControlByte.StartFrame
        ], writer_.get_buffer());
    }

    @Test
    public void StuffBytes()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        ubyte byte1 = ControlByte.EscapeCode;
        ubyte byte2 = ControlByte.StartFrame;
        ubyte escape_byte = ControlByte.EscapeCode;

        sut.send([1, byte1, 2, byte2, 3]);
        context_.execution_queue().run();

        assertEquals([
            ControlByte.StartFrame,
            1,
            escape_byte, byte1,
            2,
            escape_byte, byte2,
            3,
            ControlByte.StartFrame
        ], writer_.get_buffer());

        sut.send([byte1]);
        writer_.clear();

        context_.execution_queue().run();
        assertEquals([
            ControlByte.StartFrame,
            escape_byte, byte1,
            ControlByte.StartFrame
        ], writer_.get_buffer());
    }

    @Test
    void RejectWhenTooMuchPayload()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        context_.configuration().max_payload_size = 2;
        assertEquals(TransmissionStatus.TooMuchPayload, sut.send([1, 2, 3]));
    }

    @Test
    void ReportWriterFailure()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        failed_ = false;
        sut.on_failure(&DataLinkTransmitterTests.on_transmission_failure);

        assertEquals(TransmissionStatus.Ok, sut.send([1, 2, 3]));
        writer_.fail_transmissions(6);
        assertFalse(failed_);
        context_.execution_queue().run();
        assertTrue(failed_);
    }

    @Test
    void NotifySuccess()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        succeeded_ = false;
        sut.on_success(&DataLinkTransmitterTests.on_transmission_success);

        assertEquals(TransmissionStatus.Ok, sut.send([1]));
        assertFalse(succeeded_);
        context_.execution_queue().run();
        assertTrue(succeeded_);
    }

    @Test
    void RetryTransmissionAfterTimeout()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        succeeded_ = false;
        failed_ = false;

        sut.on_success(&DataLinkTransmitterTests.on_transmission_success);
        sut.on_failure(&DataLinkTransmitterTests.on_transmission_failure);
        assertEquals(TransmissionStatus.Ok, sut.send([1]));
        assertFalse(succeeded_);
        writer_.disable_responses();
        context_.timer_manager().run();
        context_.execution_queue().run();

        assertEquals([cast(ubyte)ControlByte.StartFrame], writer_.get_buffer());
        time_provider_.increment(501);
        context_.timer_manager().run();
        context_.execution_queue().run();
        assertEquals([cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame], writer_.get_buffer());
        time_provider_.increment(501);
        context_.timer_manager().run();
        context_.execution_queue().run();
        assertEquals([cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame],
            writer_.get_buffer());
        time_provider_.increment(501);
        context_.timer_manager().run();
        context_.execution_queue().run();
        assertEquals([cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame,
            cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame],
            writer_.get_buffer());
        assertFalse(failed_);
        time_provider_.increment(501);
        context_.timer_manager().run();
        context_.execution_queue().run();
        assertEquals([cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame,
            cast(ubyte)ControlByte.StartFrame, cast(ubyte)ControlByte.StartFrame],
            writer_.get_buffer());
        assertFalse(succeeded_);
        assertTrue(failed_);
    }

    @Test
    void RetryTransmissionAfterFail()
    {
        DataLinkTransmitter sut = new DataLinkTransmitter(writer_, context_);
        succeeded_ = false;
        failed_ = false;

        sut.on_success(&DataLinkTransmitterTests.on_transmission_success);
        sut.on_failure(&DataLinkTransmitterTests.on_transmission_failure);
        assertEquals(TransmissionStatus.Ok, sut.send([1]));
        assertFalse(succeeded_);
        writer_.fail_transmissions(2);
        context_.execution_queue().run();
        assertEquals([
            cast(ubyte)ControlByte.StartFrame,
            cast(ubyte)ControlByte.StartFrame,
            cast(ubyte)ControlByte.StartFrame,
            1,
            cast(ubyte)ControlByte.StartFrame
        ], writer_.get_buffer());

        assertFalse(failed_);
        assertTrue(succeeded_);
    }

    void on_transmission_failure(TransmissionStatus status)
    {
        if (status == TransmissionStatus.WriterReportFailure)
        {
            failed_ = true;
        }
    }

    void on_transmission_success()
    {
        succeeded_ = true;
    }

    TimeProviderStub time_provider_;
    Context context_;
    WriterStub writer_;
    bool failed_;
    bool succeeded_;
}

