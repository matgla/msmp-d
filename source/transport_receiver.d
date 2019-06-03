module source.transport_receiver;

import std.algorithm.mutation;
import std.container: DList;
import std.experimental.logger;
import std.signals;
import std.digest.crc;

import eul.logger.logger_factory;

import source.transport_frame;
import source.data_link_receiver;
import source.message_type;

class TransportReceiver
{
public:
    mixin Signal!(TransportFrame) on_data_frame_;
    mixin Signal!(TransportFrame) on_control_frame_;
    mixin Signal!(TransportFrame) on_failure_;

    alias OnDataFrameSlot = on_data_frame_.slot_t;
    alias OnControlFrameSlot = on_control_frame_.slot_t;
    alias OnFailureSlot = on_failure_.slot_t;

    this(DataLinkReceiver data_link_receiver)
    {
        data_link_receiver_ = data_link_receiver;

        data_link_receiver_.on_data(&TransportReceiver.process_data);
        logger_ = LoggerFactory.createLogger("TransportReceiver");
    }

    void on_data_frame(OnDataFrameSlot slot)
    {
        on_data_frame_.connect(slot);
    }

    void on_control_frame(OnControlFrameSlot slot)
    {
        on_control_frame_.connect(slot);
    }

    void on_failure(OnFailureSlot slot)
    {
        on_failure_.connect(slot);
    }

private:
    void process_data(ubyte[] payload)
    {
        receive_frame(payload);
    }

    void notify_failure(TransportFrame frame)
    {
        on_failure_.emit(frame);
    }

    void notify_control(TransportFrame frame)
    {
        on_control_frame_.emit(frame);
    }

    void notify_data(TransportFrame frame)
    {
        on_data_frame_.emit(frame);
    }

    void receive_frame(ubyte[] payload)
    {
        logger_.tracef("Received frame: [%(%#x, %)]", payload);
        TransportFrame frame = new TransportFrame;
        frame.transaction_id = payload[1];
        frame.buffer = payload[2..$-4];

        CRC32 crc_calculator;
        crc_calculator.put(payload[0..$-4]);
        ubyte[4] crc = crc_calculator.finish();
        ubyte[] received_crc = payload[$-4..$];
        received_crc = received_crc.reverse;

        if (crc != received_crc)
        {
            logger_.tracef("CRC mismatch, expected: [%(%#x, %)], but received [%(%#x, %)]", crc, received_crc);
            frame.status = TransportFrameStatus.CrcMismatch;
            notify_failure(frame);
            return;
        }
        immutable ubyte message_type = payload[0];
        switch (message_type)
        {
            case MessageType.Control:
            {
                frame.status = TransportFrameStatus.Ok;
                frame.type = TransportFrameType.Control;
                logger_.tracef("Received control frame: [%(%#x, %)]", frame.buffer);
                notify_control(frame);
                return;
            }
            case MessageType.Data:
            {
                frame.status = TransportFrameStatus.Ok;
                frame.type = TransportFrameType.Data;
                logger_.tracef("Received data frame: [%(%#x, %)]", frame.buffer);
                notify_data(frame);
                return;
            }
            default:
            {
                frame.status = TransportFrameStatus.WrongMessageType;
                logger_.tracef("Received wrong message type: %d", message_type);
                notify_failure(frame);
            }
        }
    }

    DataLinkReceiver data_link_receiver_;
    DList!TransportFrame buffer_;
    Logger logger_;
}
