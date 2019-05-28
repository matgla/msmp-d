module test.stubs.time_provider_stub;

import source.i_time_provider;

class TimeProviderStub : ITimeProvider
{
public:
    override long milliseconds()
    {
        return milliseconds_;
    }

    void increment(long milliseconds)
    {
        milliseconds_ += milliseconds;
    }

private:
    long milliseconds_;
}
