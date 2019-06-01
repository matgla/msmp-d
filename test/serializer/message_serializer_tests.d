module test.serializer.message_serializer_tests;

import std.system: Endian;

import dunit;

import source.serializer.message_serializer;

class MessageSerializerShould
{
    mixin UnitTest;

    @Test
    void SerializeMessage()
    {
        auto sut = new SerializedMessage!(Endian.bigEndian);
        const auto msg = sut
            .compose_u8(0xab)
            .compose_u16(0xcdef)
            .compose_u32(0x12345678)
            .compose_string("test ongoing\0")
            .compose_string("!\0")
            .build();

        assertEquals([
            0xab,
            0xcd, 0xef,
            0x12, 0x34, 0x56, 0x78,
            't', 'e', 's', 't', ' ', 'o', 'n', 'g', 'o', 'i', 'n', 'g', '\0',
            '!', '\0'
        ], msg);
    }
}
