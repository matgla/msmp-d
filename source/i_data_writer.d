module source.i_data_writer;

import std.signals;

class IDataWriter
{
public:
    alias OnSuccessSlot = on_success_.slot_t;
    alias OnFailureSlot = on_failure_.slot_t;

    abstract void write(ubyte payload);

    void on_success(OnSuccessSlot callback)
    {
        on_success_.connect(callback);
    }

    void on_failure(OnFailureSlot callback)
    {
        on_failure_.connect(callback);
    }

    mixin Signal!() on_success_;
    mixin Signal!() on_failure_;
}