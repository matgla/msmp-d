module source.timer_base;

import core.time : Duration, dur;

import source.i_timer;
import source.i_time_provider;

class TimerBase : ITimer
{
public:
    alias CallbackType = void delegate();

    abstract Status run();

    enum State
    {
        Running,
        Idle
    }

    this(ITimeProvider time_provider)
    {
        time_provider_ = time_provider;
        start_time_ = dur!"msecs"(0);
        end_time_ = dur!"msecs"(0);
        state_ = State.Idle;
    }

    bool start(CallbackType callback, Duration time)
    {
        if (start(time))
        {
            callback_ = callback;
            return true;
        }
        return false;
    }

    bool start(Duration time)
    {
        if (state_ == State.Running)
        {
            return false;
        }

        start_time_ = time_provider_.milliseconds();
        end_time_   = start_time_ + time;
        state_      = State.Running;

        return true;
    }

    bool stop()
    {
        if (state_ == State.Running)
        {
            state_ = State.Idle;
            return true;
        }
        return false;
    }

    void setCallback(CallbackType callback)
    {
        callback_ = callback;
    }

protected:
    void fire()
    {
        if (callback_)
        {
            callback_();
        }
    }

    ITimeProvider time_provider_;

    Duration start_time_;
    Duration end_time_;
    CallbackType callback_;

    State state_;
}
