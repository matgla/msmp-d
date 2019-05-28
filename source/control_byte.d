module source.control_byte;

enum ControlByte : ubyte
{
    StartFrame = 0x7e,
    EscapeCode = 0x7c
}

static bool is_control_byte(const ubyte data)
{
    return data == ControlByte.StartFrame || data == ControlByte.EscapeCode;
}
