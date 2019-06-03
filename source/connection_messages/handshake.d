module source.connection_messages.handshake;

import std.system: Endian;
import std.conv;

import source.connection_messages.message_ids;
import source.serializer.message_deserializer;
import source.serializer.message_serializer;

class Handshake
{
public:
    ubyte id = ConnectionMessages.Handshake;
    ubyte type = 0;
    ubyte protocol_version_major;
    ubyte protocol_version_minor;
    uint max_payload_size;
    char[30] name;

    this(ubyte protocol_version_major, ubyte protocol_version_minor,
        int max_payload_size, string name)
    {
        this.protocol_version_major = protocol_version_major;
        this.protocol_version_minor = protocol_version_minor;
        this.max_payload_size = max_payload_size;
        size_t size = name.length < 30 ? name.length : 29;
        for (size_t i = 0; i < size; ++i)
        {
            this.name[i] = name[i];
        }
        this.name[size + 1] = '\0';
    }

    static Handshake deserialize(ubyte[] payload)
    {
        auto message = new MessageDeserializer!()(payload);
        message.drop_u8();
        message.drop_u8();
        return new Handshake(
            message.decompose_u8(),
            message.decompose_u8(),
            message.decompose_u32(),
            to!string(message.decompose_string())
        );
    }

    auto serialize()
    {
        auto message = new SerializedMessage!();
        return message
            .compose_u8(id)
            .compose_u8(type)
            .compose_u8(protocol_version_major)
            .compose_u8(protocol_version_minor)
            .compose_u32(max_payload_size)
            .compose_string(name.dup)
            .build();
    }
}
