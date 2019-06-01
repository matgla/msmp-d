module source.serializer.deserializer;

import std.system: Endian;

class Deserializer(Endian from_endianness)
{
public:
    auto deserialize(T)(ubyte[] data)
    {
        T deserialized = 0;
        ubyte* memory = cast(ubyte*)(&deserialized);

        version (LittleEndian)
        {
            if (from_endianness == Endian.littleEndian)
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    memory[i] = data[i];
                }
                return deserialized;
            }
            else
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    memory[i] = data[T.sizeof - 1 -i];
                }
                return deserialized;
            }
        }

        version (BigEndian)
        {
            if (from_endianness == Endian.bigEndian)
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    memory[i] = data[i];
                }
                return deserialized;
            }
            else
            {
                for (size_t i = 0; i < T.sizeof; ++i)
                {
                    memory[i] = data[T.sizeof - 1 -i];
                }
                return deserialized;
            }
        }
    }

}
