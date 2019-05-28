module source.execution_queue;

import std.container : DList;

import std.stdio;
class ExecutionQueue
{
public:
    @safe
    void push_back(void delegate() executor)
    {
        executors_.insert(executor);
    }

    @safe
    void push_front(void delegate() executor)
    {
        executors_.insertFront(executor);
    }

    void run()
    {
        while (!executors_.empty())
        {
            auto executor = executors_.front();
            executors_.removeFront();
            executor();
        }
    }
private:
    DList!(void delegate()) executors_;
};
