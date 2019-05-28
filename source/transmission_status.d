module source.transmission_status;

enum TransmissionStatus
{
    Ok,
    NotStarted,
    WriterReportFailure,
    BufferFull,
    TooMuchPayload
}
