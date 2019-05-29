module source.data_link_transmitter;

import core.time : dur;

import std.container : DList;
import std.digest.digest;
import std.experimental.logger;
import std.range;
import std.signals;

import source.execution_queue;
import source.i_data_writer;
import source.logger_factory;
import source.transmission_status: TransmissionStatus;
import source.context : Context;
import source.timeout_timer : TimeoutTimer;
import source.control_byte;

class DataLinkTransmitter
{
public:
    alias StreamType = ubyte[];
    alias OnSuccessSlot = on_success_.slot_t;
    alias OnFailureSlot = on_failure_.slot_t;

    this(IDataWriter writer, Context context)
    {
        writer_ = writer;
        context_ = context;
        logger_ = LoggerFactory.createLogger("DataLinkTransmitter");

        writer.on_success(&DataLinkTransmitter.do_on_succeeded);
        writer.on_failure(&DataLinkTransmitter.do_on_failure);
        retries_counter_ = 0;
        state_ = State.Idle;
        timer_ = new TimeoutTimer(context.time_provider());
    }

    TransmissionStatus send(StreamType payload)
    {
        logger_.tracef("Sending: %(%#x, %).", payload);
        if (payload.length >= context_.configuration().max_payload_size)
        {
            return TransmissionStatus.TooMuchPayload;
        }
        buffer_.insert(payload);
        state_ = State.StartingTransmission;
        auto callback = delegate() {
            run();
        };
        context_.execution_queue().push_front(callback);
        return TransmissionStatus.Ok;
    }

    void on_success(OnSuccessSlot callback)
    {
        on_success_.connect(callback);
    }

    void on_failure(OnFailureSlot callback)
    {
        on_failure_.connect(callback);
    }

private:
    void do_on_succeeded()
    {
        logger_.trace("Received succeeded signal from writer");
        process_succeeded_callback();
        run();
    }

    void process_succeeded_callback()
    {
        switch (state_)
        {
            case State.Idle:
            {
            } break;
            case State.StartingTransmission:
            {
                if (buffer_.empty())
                {
                    state_ = State.EndingTransmission;
                    return;
                }
                state_ = State.TransmittingPayload;
            } break;
            case State.TransmittingPayload:
            {
                if (buffer_.empty())
                {
                    state_ = State.EndingTransmission;
                    return;
                }
            } break;
            case State.TransmittedEscapeCode:
            {
                if (buffer_.empty())
                {
                    state_ = State.EndingTransmission;
                    return;
                }
                state_ = State.TransmittedSpecialByte;
            } break;
            case State.TransmittedSpecialByte:
            {
                if (buffer_.empty())
                {
                    state_ = State.EndingTransmission;
                    return;
                }
                state_ = State.TransmittingPayload;
            } break;
            case State.EndingTransmission:
            {
                on_success_.emit();
                if (state_ == State.EndingTransmission)
                {
                    state_ = State.Idle;
                }
                return;
            }
            default: assert(0);
        }
    }

    void do_on_failure()
    {
        if (retries_counter_ == 0)
        {
            report_failure(TransmissionStatus.WriterReportFailure);
            return;
        }
        --retries_counter_;
        send_byte_async(current_byte_);
    }

    void report_failure(TransmissionStatus status)
    {
        on_failure_.emit(status);
    }

    void run()
    {
        switch (state_)
        {
            case State.Idle:
            {
                return;
            }
            case State.StartingTransmission:
            {
                logger_.trace("Starting transmission");
                send_byte_async(ControlByte.StartFrame);
                retries_counter_ = 3;
            }
            break;
            case State.TransmittingPayload:
            {
                if (is_control_byte(buffer_.front()))
                {
                    send_byte_async(ControlByte.EscapeCode);
                    retries_counter_ = 3;

                    state_ = State.TransmittedEscapeCode;
                    return;
                }
                send_byte_async(buffer_.front());
                retries_counter_ = 3;
                buffer_.removeFront();
            }
            break;
            case State.TransmittedEscapeCode:
            {
                send_byte_async(buffer_.front());
                retries_counter_ = 3;
                buffer_.removeFront();
            } break;
            case State.TransmittedSpecialByte:
            {
                state_ = State.TransmittingPayload;
                send_byte_async(buffer_.front());
                retries_counter_ = 3;
                buffer_.removeFront();
            }
            break;
            case State.EndingTransmission:
            {
                send_byte_async(ControlByte.StartFrame);
                retries_counter_ = 3;
            }
            break;
            default: assert(0);
        }
    }

    void send_byte(ubyte data)
    {
        logger_.tracef("Byte will be transmitted: %02#x", data);
        writer_.write(data);
        timer_.start(delegate() {
            if (retries_counter_ == 0)
            {
                report_failure(TransmissionStatus.WriterReportFailure);
                return;
            }
            --retries_counter_;
            send_byte_async(current_byte_);
        }, dur!"msecs"(500));
        context_.timer_manager().register_timer(timer_);
    }

    void send_byte_async(ubyte data)
    {
        current_byte_ = data;
        context_.execution_queue().push_front(delegate(){
            send_byte(current_byte_);
        });
    }

    enum State
    {
        StartingTransmission,
        TransmittingPayload,
        TransmittedEscapeCode,
        TransmittedSpecialByte,
        EndingTransmission,
        Idle
    }

    Logger logger_;
    mixin Signal!() on_success_;
    mixin Signal!(TransmissionStatus) on_failure_;
    IDataWriter writer_;
    Context context_;
    uint retries_counter_;
    ubyte current_byte_;
    DList!(ubyte) buffer_;
    State state_;
    TimeoutTimer timer_;
}
