module source.logger_factory;

import std.experimental.logger;
import std.conv;
import std.stdio;
import std.string;
import std.process;

class StdoutLogger : Logger
{
public:
    this(string name, LogLevel lv = LogLevel.all) @safe
    {
        name_ = name;
        super(lv);
    }

    override void writeLogMsg(ref LogEntry payload) @safe
    {
        auto is_logging_enabled = environment.get("ENABLE_LOGGING");

        if (is_logging_enabled == null)
        {
            return;
        }

        auto ts = payload.timestamp;
        writef("<%02d/%02d/%02d %02d:%02d:%02d> ", ts.day(), ts.month(), ts.year(), ts.hour(), ts.minute(), ts.second());
        writef("%s/%s: ", getLevel(payload.logLevel), name_);
        writeln(payload.msg);
    }
private:
    string getLevel(ref LogLevel logLevel) @safe
    {
        switch (logLevel)
        {
            case LogLevel.trace: return "TRC";
            case LogLevel.info: return "INF";
            case LogLevel.warning: return "WRN";
            case LogLevel.error: return "ERR";
            case LogLevel.critical: return "CRT";
            case LogLevel.fatal: return "FTL";
            default: assert(0);
        }
    }

    string name_;
}

class LoggerFactory
{
public:
    static Logger createLogger(string name)
    {
        return new StdoutLogger(name);
    }
}