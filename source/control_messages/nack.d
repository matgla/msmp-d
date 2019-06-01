module source.control_messages.nack;

import std.system: Endian;

import source.control_messages.messages_ids;
import source.serializer.message_deserializer;
import source.serializer.message_serializer;

class Nack
{
    ubyte id = ControlMessages.Nack;

    enum Reason : ubyte
    {
        WrongMessageType = 0x01,
        CrcMismatch      = 0x02,
        WrongMessageId   = 0x03
    }

    this(ubyte transaction_id, Reason reason)
    {
        this.transaction_id = transaction_id;
        this.reason = reason;
    }

    static Nack deserialize(ubyte[] payload)
    {
        auto message = new MessageDeserializer!()(payload);
        message.drop_u8();

        return new Nack(message.decompose_u8(), cast(Reason)(message.decompose_u8()));
    }

    auto serialize()
    {
        auto message = new SerializedMessage!(Endian.bigEndian)();
        return message
            .compose_u8(id)
            .compose_u8(transaction_id)
            .compose_u8(reason)
            .build();
    }

    ubyte transaction_id;
    Reason reason;
}