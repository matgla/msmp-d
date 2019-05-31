module test.stubs.data_link_transmitter_stub;

import source.data_link_transmitter: TransmissionStatus, DataLinkTransmitter;
import source.context;

import test.stubs.writer_stub;

class DataLinkTransmitterStub : DataLinkTransmitter
{
public:
    this(Context context)
    {
        writer_ = new WriterStub;
        super(writer_, context);
        auto_emit_ = false;
    }

    ubyte[] get_buffer()
    {
        return buffer_;
    }

    void clear_buffer()
    {
        buffer_ = [];
    }

    void emit_success()
    {
        if (on_success_)
        {
            on_success_();
        }
    }

    void emit_failure(TransmissionStatus status)
    {
        if (on_failure_)
        {
            on_failure_(status);
        }
    }

    override TransmissionStatus send(StreamType payload)
    {
        buffer_ = payload;
        if (auto_emit_)
        {
            emit_success();
            return TransmissionStatus.Ok;
        }
        return TransmissionStatus.Ok;
    }

    void enable_auto_emitting()
    {
        auto_emit_ = true;
    }

    void disable_auto_emitting()
    {
        auto_emit_ = false;
    }

private:
    ubyte[] buffer_;
    bool auto_emit_;
    WriterStub writer_;
}
