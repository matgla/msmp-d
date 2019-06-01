module test.serializer.deserializer_tests;

import std.algorithm.mutation: reverse;
import std.system: Endian;

import dunit;

import source.serializer.deserializer;

class DeserializerShould
{
    mixin UnitTest;

    @Test
    void DeserializeUint8FromBigEndian()
    {
        auto deserializer = new Deserializer!(Endian.bigEndian);

        assertEquals(0x32, deserializer.deserialize!ubyte(cast(ubyte[])[0x32]));
        assertEquals(0xff, deserializer.deserialize!ubyte(cast(ubyte[])[0xff]));
        assertEquals(0x00, deserializer.deserialize!ubyte(cast(ubyte[])[0x00]));
    }

    @Test
    void DeserializeUint16FromBigEndian()
    {
        auto deserializer = new Deserializer!(Endian.bigEndian);

        assertEquals(0x1232, deserializer.deserialize!ushort(cast(ubyte[])[0x12, 0x32]));
        assertEquals(0xffff, deserializer.deserialize!ushort(cast(ubyte[])[0xff, 0xff]));
        assertEquals(0x0000, deserializer.deserialize!ushort(cast(ubyte[])[0x00, 0x00]));
    }

    @Test
    void DeserializeUint32FromBigEndian()
    {
        auto deserializer = new Deserializer!(Endian.bigEndian);

        assertEquals(0x12345678, deserializer.deserialize!uint(cast(ubyte[])[0x12, 0x34, 0x56, 0x78]));
        assertEquals(0xffff0000, deserializer.deserialize!uint(cast(ubyte[])[0xff, 0xff, 0x00, 0x00]));
        assertEquals(0x0000dddd, deserializer.deserialize!uint(cast(ubyte[])[0x00, 0x00, 0xdd, 0xdd]));
    }

    @Test
    void DeserializeFloatFromBigEndian()
    {
        auto deserializer = new Deserializer!(Endian.bigEndian);

        assertEquals(cast(float)0x12345678, deserializer.deserialize!float(cast(ubyte[])[0x4d, 0x91, 0xa2, 0xb4]));
        assertEquals(cast(float)0xffff0000, deserializer.deserialize!float(cast(ubyte[])[0x4f, 0x7f, 0xff, 0x00]));
        assertEquals(cast(float)0x0000dddd, deserializer.deserialize!float(cast(ubyte[])[0x47, 0x5d, 0xdd, 0x00]));
    }

    @Test
    void DeserializeUint8FromLittleEndian()
    {
        auto deserializer = new Deserializer!(Endian.littleEndian);

        assertEquals(0x32, deserializer.deserialize!ubyte(cast(ubyte[])[0x32]));
        assertEquals(0xff, deserializer.deserialize!ubyte(cast(ubyte[])[0xff]));
        assertEquals(0x00, deserializer.deserialize!ubyte(cast(ubyte[])[0x00]));
    }

    @Test
    void DeserializeUint16FromLittleEndian()
    {
        auto deserializer = new Deserializer!(Endian.littleEndian);

        import std.stdio;
        assertEquals(0x1232, deserializer.deserialize!ushort((cast(ubyte[])[0x12, 0x32]).reverse));
        assertEquals(0xffff, deserializer.deserialize!ushort((cast(ubyte[])[0xff, 0xff]).reverse));
        assertEquals(0x0000, deserializer.deserialize!ushort((cast(ubyte[])[0x00, 0x00]).reverse));
    }

    @Test
    void DeserializeUint32FromLittleEndian()
    {
        auto deserializer = new Deserializer!(Endian.littleEndian);

        assertEquals(0x12345678, deserializer.deserialize!uint((cast(ubyte[])[0x12, 0x34, 0x56, 0x78]).reverse));
        assertEquals(0xffff0000, deserializer.deserialize!uint((cast(ubyte[])[0xff, 0xff, 0x00, 0x00]).reverse));
        assertEquals(0x0000dddd, deserializer.deserialize!uint((cast(ubyte[])[0x00, 0x00, 0xdd, 0xdd]).reverse));
    }

    @Test
    void DeserializeFloatFromLittleEndian()
    {
        auto deserializer = new Deserializer!(Endian.littleEndian);

        assertEquals(cast(float)0x12345678, deserializer.deserialize!float((cast(ubyte[])[0x4d, 0x91, 0xa2, 0xb4]).reverse));
        assertEquals(cast(float)0xffff0000, deserializer.deserialize!float((cast(ubyte[])[0x4f, 0x7f, 0xff, 0x00]).reverse));
        assertEquals(cast(float)0x0000dddd, deserializer.deserialize!float((cast(ubyte[])[0x47, 0x5d, 0xdd, 0x00]).reverse));
    }
}