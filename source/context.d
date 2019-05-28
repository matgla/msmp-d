module source.context;

import source.configuration;
import source.execution_queue;
import source.i_time_provider;
import source.timer_manager;

class Context
{
public:
    this(ITimeProvider time_provider)
    {
        execution_queue = new ExecutionQueue;
        time_provider_ = time_provider;
        configuration_ = new Configuration;
        timer_manager_ = new TimerManager;
    }

    @safe
    ref ExecutionQueue execution_queue()
    {
        return execution_queue_;
    }

    @safe
    ref ITimeProvider time_provider()
    {
        return time_provider_;
    }

    @safe
    ref Configuration configuration()
    {
        return configuration_;
    }

    @safe
    ref TimerManager timer_manager()
    {
        return timer_manager_;
    }

private:
    ExecutionQueue execution_queue_;
    ITimeProvider time_provider_;
    Configuration configuration_;
    TimerManager timer_manager_;
}
