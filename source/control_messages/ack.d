module source.control_messages.ack;

import std.system: Endian;

import source.control_messages.messages_ids;
import source.serializer.message_deserializer;
import source.serializer.message_serializer;

class Ack
{
public:
    immutable ubyte id = ControlMessages.Ack;
    ubyte transaction_id;

    this(ubyte transaction_id)
    {
        this.transaction_id = transaction_id;
    }

    static Ack deserialize(ubyte[] payload)
    {
        auto message = new MessageDeserializer!()(payload);
        message.drop_u8();

        return new Ack(message.decompose_u8());
    }

    auto serialize()
    {
        auto message = new SerializedMessage!(Endian.bigEndian);
        return message
            .compose_u8(id)
            .compose_u8(transaction_id)
            .build();
    }

}
