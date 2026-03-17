module app;

import std.stdio;
import vibe.d;
import params;

ServerParams serverparams;

void handleRequest(scope HTTPServerRequest req, scope HTTPServerResponse res)
{
    // TODO: rewrite

    /* example from cloude

    auto api = new URLRouter("/api/v1");
    api.get("/users", &listUsers);
    api.post("/users", &createUser);

    auto router = new URLRouter();
    router.any("/api/v1/*", api);
    router.get("/", &handleHome);

    */

    if (req.path == "/")
    {
        res.writeBody("Hello, World!", "text/plain");
        return;
    }

    auto routes = new URLRouter();
}

void main(string[] args)
{
    // writeln(args.length);
    // serverparams = new ServerParams;

    // save arguments
    for (int i = 1; i < args.length; i++)
    {
        switch (args[i])
        {
        case "-https":
            serverparams.useHTTPS = true;
            break;

        default:
            writeln("Error: Command line argument not recognised: ", args[i]);
            return;
        }

    }

    // configuring http settings
    auto settings = new HTTPServerSettings;

    if (!serverparams.useHTTPS)
    {
        settings.port = 8080;
        settings.bindAddresses = ["::1", "127.0.0.1"];
    }
    else
    {
        // To serve HTTPS connections, 
        // the configuration simply needs to have a TLS context that has 
        // the appropriate certificate and private key files set:
        writeln("!! Warning: attempting to use HTTPS." ~
            "\nMake sure the appropriate certificate files are stored in \"/certificates\". " ~
            "\n(specifically a certificate chain file named \"server-cert.pem\" " ~ 
            "and a Private key file named \"server-key.pem\")");
        settings.port = 443;
        settings.bindAddresses = ["127.0.0.1"];
        // settings.tlsContext = createTLSContext(TLSContextKind.server);
        // settings.tlsContext.useCertificateChainFile("certificates/server-cert.pem");
        // settings.tlsContext.usePrivateKeyFile("certificates/server-key.pem");
    }

    auto listen = listenHTTP(settings, &handleRequest);
    scope (exit) 
    {
        listen.stopListening();
    }

    runApplication();

}
