module source.serializer.message_deserializer;

import std.system: Endian;
import core.stdc.string;

import source.serializer.deserializer;

class MessageDeserializer(Endian endian = Endian.bigEndian)
{
public:
    this(ubyte[] data)
    {
        position_ = 0;
        data_ = data;
    }

    void decompose(T)(ref T data)
    {
        data = decompose_impl!T();
    }

    void decompose(ref char[] data)
    {
        data = decompose_string();
    }

    char[] decompose_string()
    {
        char[] str = cast(char[])(data_[position_..$]);
        auto string_size = strlen(&str[0]) + 1;
        char[] deserialized = cast(char[])(data_[position_..string_size + position_]);
        position_ += string_size;
        return deserialized;
    }

    ubyte decompose_u8()
    {
        return decompose_impl!ubyte();
    }

    ushort decompose_u16()
    {
        return decompose_impl!ushort();
    }

    uint decompose_u32()
    {
        return decompose_impl!uint();
    }

    void drop_u8()
    {
        position_ += 1;
    }

    void drop_u16()
    {
        position_ += 2;
    }

    void drop_u32()
    {
        position_ += 4;
    }

private:
    T decompose_impl(T)()
    {
        auto deserializer = new Deserializer!(Endian.bigEndian);
        const auto data = deserializer.deserialize!(T)(data_[position_..position_ + T.sizeof]);
        position_ += T.sizeof;
        return data;
    }

    size_t position_;
    ubyte[] data_;
}
