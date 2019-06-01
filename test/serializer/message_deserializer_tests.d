module test.serializer.message_deserializer_tests;

import std.system: Endian;

import dunit;

import source.serializer.message_deserializer;

class MessageDeserializerShould
{
    mixin UnitTest;

    @Test
    void DeserializeMessage()
    {
        ubyte[] msg = [
            0xab,
            0xcd, 0xef,
            0x12, 0x34, 0x56, 0x78,
            't', 'e', 's', 't', ' ', 'o', 'n', 'g', 'o', 'i', 'n', 'g', '\0',
            '!', '\0'
        ];

        auto sut = new MessageDeserializer!(Endian.bigEndian)(msg);
        assertEquals(0xab, sut.decompose_u8());
        assertEquals(0xcdef, sut.decompose_u16());
        assertEquals(0x12345678, sut.decompose_u32());
        assertEquals("test ongoing\0", sut.decompose_string());
        assertEquals("!\0", sut.decompose_string());
    }
}