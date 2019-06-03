module source.serializer.message_serializer;

import std.system: Endian;

import source.serializer.serializer;

class SerializedMessage(Endian endian = Endian.bigEndian)
{
public:
    this()
    {
    }

    auto compose_u8(ubyte d)
    {
        return compose_impl!ubyte(d);
    }

    auto compose_u16(ushort d)
    {
        return compose_impl!ushort(d);
    }

    auto compose_u32(uint d)
    {
        return compose_impl!uint(d);
    }

    auto compose_string(char[] str)
    {
        size_t str_length = 0;
        for (str_length = 0; str_length < str.length; ++str_length)
        {
            if (str[str_length] == '\0')
            {
                break;
            }
        }
        SerializedMessage msg = new SerializedMessage(buffer_, str[0..str_length+1]);
        return msg;
    }

    auto build()
    {
        return buffer_;
    }

private:
    this(T)(ubyte[] previous, T data)
    {
        buffer_ ~= previous;
        buffer_ ~= data;
    }

    auto compose_impl(T)(T t)
    {
        auto serializer = new Serializer!(Endian.bigEndian);
        auto serialized = serializer.serialize!(T)(t);
        auto msg = new SerializedMessage(buffer_, serialized);
        return msg;
    }

    ubyte[] buffer_;
}
