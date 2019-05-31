module source.transport_frame;

enum TransportFrameStatus
{
    Ok,
    CrcMismatch,
    WrongMessageType
}

enum TransportFrameType
{
    Data,
    Control
}

class TransportFrame
{
public:
    ubyte[] buffer;
    ubyte transaction_id;
    TransportFrameStatus status;
    TransportFrameType type;
}
