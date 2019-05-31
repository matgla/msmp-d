module source.transport_transmitter;

import std.container: DList;
import std.digest.crc;
import std.functional: toDelegate;
import std.experimental.logger;


import source.i_time_provider;
import source.data_link_transmitter: DataLinkTransmitter;
import source.timeout_timer;
import source.context;
import source.message_type;
import source.logger_factory;
import source.transmission_status;


void dummy()
{}

class TransportTransmitter
{
public:
    alias CallbackType = void delegate();
    alias StreamType = ubyte[];
    this(DataLinkTransmitter data_link_transmitter, Context context)
    {
        context_ = context;
        logger_ = LoggerFactory.createLogger("TransportTransmitter");
        data_link_transmitter_ = data_link_transmitter;

        data_link_transmitter_.on_success(&TransportTransmitter.on_transmission_success);
        data_link_transmitter_.on_failure(&TransportTransmitter.on_transmission_failure);
        timer_ = new TimeoutTimer(context_.time_provider());
    }

    void on_transmission_success()
    {
        logger_.trace("Transmission done, starting timer for acknowledge");
        timer_.start(delegate()
        {
            logger_.tracef("Timer fired: %d", retransmission_counter_);

            if (retransmission_counter_ >= context_.configuration().max_retransmission_tries)
            {
                frames_.front().on_failure();
                frames_.removeFront();
                return;
            }
            ++retransmission_counter_;
            send_next_frame();
        }, context_.configuration().timeout_for_transmission);
        context_.timer_manager().register_timer(timer_);
    }

    void on_transmission_failure(TransmissionStatus status)
    {
        logger_.trace("Received failure: ", status);
        auto callback = frames_.front().on_failure;
        if (!frames_.empty())
        {
            send_next_frame();
            ++retransmission_counter_;
        }
        if (retransmission_counter_ >= context_.configuration().max_retransmission_tries)
        {
            callback();
        }
    }

    TransmissionStatus send_control(const StreamType payload, const CallbackType on_success = toDelegate(&dummy),
        const CallbackType on_failure = toDelegate(&dummy))
    {
        logger_.tracef("Sending control message: [%(%#x, %)]", payload);

        if (context_.configuration().max_payload_size < payload.length + 2 + 4)
        {
            return TransmissionStatus.TooMuchPayload;
        }

        auto frame = new Frame;

        frame.buffer ~= MessageType.Control;
        frame.buffer ~= ++transaction_id_counter_;
        frame.transaction_id = transaction_id_counter_;
        frame.buffer ~= payload[];

        CRC32 crc_calculator;
        crc_calculator.put(frame.buffer[]);
        ubyte[4] crc = crc_calculator.finish();
        frame.buffer ~= crc[3];
        frame.buffer ~= crc[2];
        frame.buffer ~= crc[1];
        frame.buffer ~= crc[0];

        frame.on_success = on_success;
        frame.on_failure = on_failure;
        frame.type = MessageType.Control;

        control_frames_.insertBack(frame);


        context_.execution_queue().push_front(&TransportTransmitter.send_control_frame);

        return TransmissionStatus.Ok;
    }

    void send_control_frame()
    {
        logger_.trace("Sending next control frame. Still exists in buffer: ");
        foreach (frame; control_frames_)
        {
            logger_.tracef("id: %d -> [%(%#x, %)]", frame.transaction_id, frame.buffer);
        }
        data_link_transmitter_.send(control_frames_.front().buffer);
        control_frames_.removeFront();
    }

    TransmissionStatus send(const StreamType payload, const CallbackType on_success = toDelegate(&dummy),
        const CallbackType on_failure = toDelegate(&dummy))
    {
        logger_.tracef("Sending message: [%(%#x, %)]", payload);

        return send(MessageType.Data, payload, on_success, on_failure);
    }

    bool confirm_frame_transmission(ubyte transaction_id)
    {
        timer_.stop();
        logger_.tracef("Received ACK for message: %d", transaction_id);

        if (frames_.front().transaction_id == transaction_id)
        {
            auto callback = frames_.front().on_success;
            retransmission_counter_ = 0;
            callback();

            frames_.removeFront();
            if (!frames_.empty())
            {
                send_next_frame();
            }
            return true;
        }

        return false;
    }

    void process_frame_failure(ubyte transaction_id)
    {
        timer_.stop();

        logger_.trace("Received NACK!");
        if (frames_.empty())
        {
            logger_.trace("Buffer is empty, frame can't be transmitted");
            return;
        }

        if (retransmission_counter_ < 3)
        {
            send_next_frame();
            ++retransmission_counter_;
            return;
        }
        frames_.front().on_failure();
    }

private:

    TransmissionStatus send(MessageType type, const StreamType payload, const CallbackType on_success,
        const CallbackType on_failure)
    {
        if (context_.configuration().max_payload_size < payload.length + 2 + 4)
        {
            return TransmissionStatus.TooMuchPayload;
        }

        auto frame = new Frame;
        frame.buffer ~= type;
        frame.buffer ~= ++transaction_id_counter_;
        frame.transaction_id = transaction_id_counter_;
        frame.buffer ~= payload[];

        CRC32 crc_calculator;
        crc_calculator.put(frame.buffer[]);
        ubyte[4] crc = crc_calculator.finish();
        frame.buffer ~= crc[3];
        frame.buffer ~= crc[2];
        frame.buffer ~= crc[1];
        frame.buffer ~= crc[0];

        frame.on_success = on_success;
        frame.on_failure = on_failure;
        frame.type = type;

        bool is_first_frame = frames_.empty();
        frames_.insertBack(frame);

        if (is_first_frame)
        {
            send_next_frame();
        }

        return TransmissionStatus.Ok;
    }

    void send_next_frame()
    {
        context_.execution_queue().push_front(delegate() {
            logger_.trace("Sending next frame. Still exists in buffer: ");
            foreach (frame; frames_)
            {
                logger_.tracef("id: %d -> [%(%#x, %)]", frame.transaction_id, frame.buffer);
            }

            data_link_transmitter_.send(frames_.front().buffer);
        });
    }


    ubyte transaction_id_counter_;
    Logger logger_;
    DataLinkTransmitter data_link_transmitter_;
    long current_byte_;

    class Frame
    {
        public:
            ubyte[] buffer;
            CallbackType on_success;
            CallbackType on_failure;
            ubyte transaction_id;
            MessageType type;
    }

    DList!Frame frames_;
    DList!Frame control_frames_;
    ubyte retransmission_counter_;
    TimeoutTimer timer_;
    Context context_;
}
