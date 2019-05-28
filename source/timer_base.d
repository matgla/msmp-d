module source.timer_base;

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
        start_time_ = 0;
        end_time_ = 0;
        state_ = State.Idle;
    }

    bool start(CallbackType callback, long time)
    {
        if (start(time))
        {
            callback_ = callback;
            return true;
        }
        return false;
    }

    bool start(long time)
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

    long start_time_;
    long end_time_;
    CallbackType callback_;

    State state_;
}
