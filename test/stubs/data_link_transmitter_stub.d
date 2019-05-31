module test.stubs.data_link_transmitter_stub;

import std.signals;

import source.data_link_transmitter;
import source.transmission_status;
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
        on_success_.emit();
    }

    void emit_failure(TransmissionStatus status)
    {
        on_failure_.emit(status);
    }

    override TransmissionStatus send(StreamType payload)
    {
        buffer_ ~= payload[];
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
