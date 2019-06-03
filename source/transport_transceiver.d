module source.transport_transceiver;

import std.signals;
import std.experimental.logger;

import eul.logger.logger_factory;

import source.transport_receiver;
import source.transport_transmitter;
import source.transport_frame;
import source.control_messages.messages_ids;
import source.control_messages.nack;
import source.control_messages.ack;

class TransportTransceiver
{
public:
    alias StreamType = ubyte[];
    mixin Signal!(StreamType) on_data_;
    alias OnDataSlot = on_data_.slot_t;

    this(TransportReceiver receiver, TransportTransmitter transmitter)
    {
        logger_ = LoggerFactory.createLogger("TransportTransceiver");
        receiver_ = receiver;
        transmitter_ = transmitter;

        receiver_.on_control_frame(&TransportTransceiver.receive_control);
        receiver_.on_data_frame(&TransportTransceiver.receive_data);
        receiver_.on_failure(&TransportTransceiver.receive_failure);
    }

    void on_data(OnDataSlot slot)
    {
        on_data_.connect(slot);
    }

    void send(StreamType payload)
    {
        transmitter_.send(payload);
    }

    void send(StreamType payload, TransportTransmitter.CallbackType on_success, TransportTransmitter.CallbackType on_failure)
    {
        transmitter_.send(payload, on_success, on_failure);
    }
private:
    void receive_control(TransportFrame frame)
    {
        if (frame.buffer.length == 0)
        {
            logger_.trace("Received frame with wrong size");
            return;
        }
        immutable ControlMessages id = cast(ControlMessages)(frame.buffer[0]);
        logger_.tracef("Received control frame: [%(%#x, %)]", frame.buffer);

        switch (id)
        {
            case ControlMessages.Ack:
            {
                const auto ack = Ack.deserialize(frame.buffer);
                logger_.tracef("Received ACK for %d", ack.transaction_id);
                transmitter_.confirm_frame_transmission(ack.transaction_id);
            } break;
            case ControlMessages.Nack:
            {
                const auto nack = Nack.deserialize(frame.buffer);
                logger_.tracef("Received NACK for: %d. With reason: %s", nack.transaction_id, nack.reason);
                transmitter_.process_frame_failure(nack.transaction_id);
            } break;
            default:
            {
                logger_.tracef("Received unexpected control message: %d", id);
            }
        }
    }

    void receive_data(TransportFrame frame)
    {
        respond_ack(frame);
        on_data_.emit(frame.buffer);
    }

    void receive_failure(TransportFrame frame)
    {
        respond_nack(frame);
    }

    void respond_nack(TransportFrame frame)
    {
        switch (frame.status)
        {
            case TransportFrameStatus.Ok:
            {

            } break;
            case TransportFrameStatus.CrcMismatch:
            {
                const auto nack = new Nack(frame.transaction_id, Nack.Reason.CrcMismatch).serialize();
                transmitter_.send(nack);
            } break;
            case TransportFrameStatus.WrongMessageType:
            {
                const auto nack = new Nack(frame.transaction_id, Nack.Reason.WrongMessageType).serialize();
                transmitter_.send(nack);
            } break;
            default: assert(0);
        }
    }

    void respond_ack(TransportFrame frame)
    {
        auto ack = new Ack(frame.transaction_id).serialize();
        transmitter_.send(ack);
    }

    Logger logger_;
    TransportReceiver receiver_;
    TransportTransmitter transmitter_;
}