module source.message_handler;

class MessageHandler
{
    ubyte id;
    void delegate(ubyte[]) handle;
}
