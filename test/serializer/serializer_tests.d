module test.serializer.serializer_tests;

import std.algorithm.mutation: reverse;
import std.system: Endian;

import dunit;

import source.serializer.serializer;

class SerializerShould
{
public:
    mixin UnitTest;

    @Test
    void SerializeUint8InBigEndian()
    {
        auto serializer = new Serializer!(Endian.bigEndian);

        assertEquals([0x32], serializer.serialize!ubyte(0x32));
        assertEquals([0xff], serializer.serialize!ubyte(0xff));
        assertEquals([0x00], serializer.serialize!ubyte(0x00));
    }

    @Test SerializeUint16InBigEndian()
    {
        auto serializer = new Serializer!(Endian.bigEndian);

        assertEquals([0x12, 0x34], serializer.serialize!ushort(0x1234));
        assertEquals([0xff, 0xff], serializer.serialize!ushort(0xffff));
        assertEquals([0x00, 0x00], serializer.serialize!ushort(0x0000));
    }

    @Test SerializeInt32InBigEndian()
    {
        auto serializer = new Serializer!(Endian.bigEndian);

        assertEquals([0x12, 0x34, 0x56, 0x78], serializer.serialize!int(0x12345678));
        assertEquals([0xff, 0xff, 0x00, 0x00], serializer.serialize!int(0xffff0000));
        assertEquals([0x00, 0x00, 0xdd, 0xdd], serializer.serialize!int(0x0000dddd));
    }

    @Test SerializeFloatInBigEndian()
    {
        auto serializer = new Serializer!(Endian.bigEndian);

        assertEquals([0x4d, 0x91, 0xa2, 0xb4], serializer.serialize!float(cast(float)0x12345678));
        assertEquals([0x4f, 0x7f, 0xff, 0x00], serializer.serialize!float(cast(float)0xffff0000));
        assertEquals([0x47, 0x5d, 0xdd, 0x00], serializer.serialize!float(cast(float)0x0000dddd));
    }

    @Test
    void SerializeUint8InLittleEndian()
    {
        auto serializer = new Serializer!(Endian.littleEndian);

        assertEquals([0x32], serializer.serialize!ubyte(0x32));
        assertEquals([0xff], serializer.serialize!ubyte(0xff));
        assertEquals([0x00], serializer.serialize!ubyte(0x00));
    }

    @Test SerializeUint16InLittleEndian()
    {
        auto serializer = new Serializer!(Endian.littleEndian);

        assertEquals([0x12, 0x34].reverse, serializer.serialize!ushort(0x1234));
        assertEquals([0xff, 0xff].reverse, serializer.serialize!ushort(0xffff));
        assertEquals([0x00, 0x00].reverse, serializer.serialize!ushort(0x0000));
    }

    @Test SerializeInt32InLittleEndian()
    {
        auto serializer = new Serializer!(Endian.littleEndian);

        assertEquals([0x12, 0x34, 0x56, 0x78].reverse, serializer.serialize!int(0x12345678));
        assertEquals([0xff, 0xff, 0x00, 0x00].reverse, serializer.serialize!int(0xffff0000));
        assertEquals([0x00, 0x00, 0xdd, 0xdd].reverse, serializer.serialize!int(0x0000dddd));
    }

    @Test SerializeFloatInLittleEndian()
    {
        auto serializer = new Serializer!(Endian.littleEndian);

        assertEquals([0x4d, 0x91, 0xa2, 0xb4].reverse, serializer.serialize!float(cast(float)0x12345678));
        assertEquals([0x4f, 0x7f, 0xff, 0x00].reverse, serializer.serialize!float(cast(float)0xffff0000));
        assertEquals([0x47, 0x5d, 0xdd, 0x00].reverse, serializer.serialize!float(cast(float)0x0000dddd));
    }

}
