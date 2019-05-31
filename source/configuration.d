module source.configuration;

import core.time : dur, Duration;

class Configuration
{
public:
    int max_payload_size = 255;
    int receiver_payload_size = 255;
    int max_retransmission_tries = 3;
    Duration timeout_for_transmission = dur!"msecs"(500);
}
