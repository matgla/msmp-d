module source.i_time_provider;

import core.time : Duration;

interface ITimeProvider
{
    Duration milliseconds();
}