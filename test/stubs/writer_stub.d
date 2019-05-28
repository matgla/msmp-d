module test.stubs.writer_stub;

import std.signals;

import source.i_data_writer;

class WriterStub : IDataWriter
{
public:
    this()
    {
        autoresponding_enabled_ = false;
        number_of_transmissions_to_fail = 0;
        disabled_responses_ = false;
    }

    void disable_responses()
    {
        disabled_responses_ = true;
    }

    override void write(ubyte data)
    {
        data_ ~= data;
        if (disabled_responses_)
        {
            return;
        }
        if (number_of_transmissions_to_fail)
        {
            --number_of_transmissions_to_fail;
            on_failure_.emit();
            return;
        }
        if (autoresponding_enabled_)
        {
            on_success_.emit();
        }
    }


    ubyte[] get_buffer()
    {
        return data_;
    }

    void enable_autoresponding()
    {
        autoresponding_enabled_ = true;
    }

    void clear()
    {
        data_ = [];
    }

    void fail_transmissions(int number)
    {
        number_of_transmissions_to_fail = number;
    }

private:
    ubyte[] data_;
    bool autoresponding_enabled_;
    bool disabled_responses_;
    int number_of_transmissions_to_fail;
}
