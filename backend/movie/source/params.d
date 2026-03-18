module params;

struct ServerParams
{
    string[] bindAddresses = ["0.0.0.0"];
    ushort usePort = 8080;
    bool useHTTPS = false;
}