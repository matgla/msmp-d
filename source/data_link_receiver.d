module source.data_link_receiver;

import std.experimental.logger;
import std.signals;

import source.control_byte;
import source.logger_factory;

class DataLinkReceiver
{
public:
    alias StreamType = ubyte[];

    mixin Signal!(StreamType) on_data_;
    mixin Signal!(StreamType) on_failure_;
    alias OnDataReceivedSlot = on_data_.slot_t;
    alias OnFailureSlot = on_failure_.slot_t;

    this()
    {
        state_ = State.Idle;
        logger_ = LoggerFactory.createLogger("DataLinkReceiver");
    }

    void receive(StreamType payload)
    {
        foreach (ubyte data; payload)
        {
            receive_byte(data);
        }
    }

    void on_data(OnDataReceivedSlot slot)
    {
        on_data_.connect(slot);
    }

    void on_failure(OnFailureSlot slot)
    {
        on_failure_.connect(slot);
    }

private:
    enum State
    {
        Idle,
        ReceivingByte,
        ReceivingEscapedByte
    }

    void receive_byte(ubyte data)
    {
        switch (state_)
        {
            case State.Idle:
            {
                if (data == ControlByte.StartFrame)
                {
                    logger_.trace("Received start byte");
                    state_ = State.ReceivingByte;
                }
            } break;
            case State.ReceivingByte:
            {
                if (is_control_byte(data))
                {
                    switch (data)
                    {
                        case ControlByte.EscapeCode:
                        {
                            logger_.trace("Waiting for escaped byte");
                            state_ = State.ReceivingEscapedByte;
                            return;
                        }
                        case ControlByte.StartFrame:
                        {
                            logger_.trace("Received start byte");
                            if (buffer_.length)
                            {
                                logger_.tracef("Payload received: [%(%#x, %)]", buffer_);

                                on_data_.emit(buffer_);
                                buffer_ = [];
                            }
                            return;
                        }
                        default: break;
                    }
                }
                buffer_ ~= data;
                break;
            }
            case State.ReceivingEscapedByte:
            {
                buffer_ ~= data;
                state_ = State.ReceivingByte;
                break;
            }
            default: assert(0);
        }
    }


    Logger logger_;
    StreamType buffer_;
    State state_;
}
