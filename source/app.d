import std.stdio;
import std.signals;
import source.data_link_transmitter;
import source.data_link_receiver;
import source.transport_transmitter;
import source.transport_receiver;
import source.transport_transceiver;
import source.message_broker;
import source.i_data_writer;
import eul.time.i_time_provider;
import source.context;
import std.datetime;
import core.time : Duration;
import std.socket;
import core.thread;

class ClientFiber : Fiber
{
public:
    mixin Signal!(ubyte[]) on_data_;
    alias OnDataSlot = on_data_.slot_t;

    void on_data(OnDataSlot slot)
    {
        on_data_.connect(slot);
    }

    this(Socket socket)
    {
        socket_ = socket;
        super(&run);
    }
private:
    private void run()
    {
        while (true)
        {
            ubyte[1024] buffer;
            size_t len = socket_.receive(buffer);
            if (len > 0)
            {
                import std.stdio;
                writeln("Received some data: ", buffer);
                on_data_.emit(buffer);
            }
            Fiber.yield();
        }
    }

    Socket socket_;
}

class SocketWriter : IDataWriter
{
public:
    this (Socket socket)
    {
        socket_ = socket;
    }

    override void write(ubyte payload)
    {
        ubyte[] data = [payload];
        socket_.send(data);
        on_success_.emit();
    }
private:
    Socket socket_;
}

class TimeProvider : ITimeProvider
{
public:
    override Duration milliseconds()
    {
        return Clock.currTime().fracSecs;
    }
}


void server()
{
    auto socket = new TcpSocket();
    scope (exit) socket.close();

    socket.bind(new InternetAddress(2525));
    socket.listen(10);

    Fiber[] fibers;

    DataLinkReceiver d_receiver = new DataLinkReceiver;
    TimeProvider time_provider = new TimeProvider;
    Context context = new Context(time_provider);
    SocketWriter writer = new SocketWriter(socket);
    DataLinkTransmitter d_transmitter = new DataLinkTransmitter(writer, context);
    auto receiver = new TransportReceiver(d_receiver);
    auto transmitter = new TransportTransmitter(d_transmitter, context);
    auto transceiver = new TransportTransceiver(receiver, transmitter);
    auto message_broker = new MessageBroker(context);
    message_broker.add_transceiver(transceiver);

    void listen()
    {
        Socket newClient;
        while (socket.isAlive())
        {
            newClient = socket.accept();
            if (!wouldHaveBlocked())
            {
                ClientFiber clientfiber = new ClientFiber(newClient);
                clientfiber.on_data(&d_receiver.receive);
                fibers ~= clientfiber;
                writeln(fibers.length);
            }
            Fiber.yield();
        }
    }

    Fiber listener = new Fiber(&listen);
    fibers ~= listener;

    while (true)
    {
        foreach(f; fibers)
        {
            f.call();
        }
        Thread.sleep(100.msecs);
    }
}

void client()
{
    auto socket = new TcpSocket();
    scope (exit) socket.close();

    socket.blocking = false;
    socket.connect(new InternetAddress("127.0.0.1", 2525));

    TimeProvider time_provider = new TimeProvider;
    Context context = new Context(time_provider);
    SocketWriter writer = new SocketWriter(socket);
    DataLinkReceiver d_receiver = new DataLinkReceiver();
    DataLinkTransmitter d_transmitter = new DataLinkTransmitter(writer, context);
    auto receiver = new TransportReceiver(d_receiver);
    auto transmitter = new TransportTransmitter(d_transmitter, context);
    auto transceiver = new TransportTransceiver(receiver, transmitter);
    auto message_broker = new MessageBroker(context);
    message_broker.add_transceiver(transceiver);
    context.execution_queue().run();
}


void main(string[] args)
{
    if (args[1] == "server")
    {
        server();
    }
    else
    {
        client();
    }
}
