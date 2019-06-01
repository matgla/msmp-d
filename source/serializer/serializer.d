module source.serializer.serializer;

import std.system: Endian;
import std.string;
import core.stdc.string;

class Serializer(Endian endian)
{
public:
    static ubyte[] serialize(T)(T data)
    {
        ubyte[] serialized;
        ubyte* memory = cast(ubyte*)(&data);

        version (LittleEndian)
        {
            if (endian == Endian.littleEndian)
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    serialized ~= memory[i];
                }

                return serialized;
            }
            else
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    serialized ~= memory[T.sizeof - 1 - i];
                }
                return serialized;
            }
        }

        version (BigEndian)
        {
            if (endian == Endian.bigEndian)
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    serialized ~= memory[i];
                }
                return serialized;
            }
            else
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    serialized ~= memory[T.sizeof - 1 - i];
                }
                return serialized;
            }
        }
    }

    static ubyte[] serialize(char[] data)
    {
        ubyte[] serialized;
        serialized = cast(ubyte[])data;

        if (serialized[$ - 1] != 0)
        {
            serialized ~= 0;
        }
        return serialized;
    }

    static ubyte[] serialize(string data)
    {
        return serialize(data.dup);
    }
}
