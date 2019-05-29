module test.stubs.time_provider_stub;

import core.time : Duration;

import source.i_time_provider;

class TimeProviderStub : ITimeProvider
{
public:
    override Duration milliseconds()
    {
        return milliseconds_;
    }

    void increment(Duration milliseconds)
    {
        milliseconds_ += milliseconds;
    }

private:
    Duration milliseconds_;
}
