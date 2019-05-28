module source.timer_manager;

import std.algorithm.mutation;

import source.i_timer;

class TimerManager
{
public:
    void register_timer(ITimer timer)
    {
        timers_ ~= timer;
    }

    void deregister_timer(ITimer timer)
    {
        remove!(a => a == timer)(timers_);
    }

    void run()
    {
        foreach (timer; timers_)
        {
            if (timer.run() == ITimer.Status.Fired)
            {
                deregister_timer(timer);
            }
        }
    }
private:

    ITimer[] timers_;
}
