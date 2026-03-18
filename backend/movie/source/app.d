module app;

import std.stdio;
import vibe.vibe;

import params;

import handlers.home;
import handlers.users;


ServerParams serverparams;


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
        settings.port = serverparams.usePort;
        settings.bindAddresses = serverparams.bindAddresses;
    }
    else
    {
        // To serve HTTPS connections, 
        // the configuration simply needs to have a TLS context that has 
        // the appropriate certificate and private key files set:
        
        // Warning to user
        writeln("!! Warning: attempting to use HTTPS." ~
            "\nMake sure the appropriate certificate files are stored in \"/certificates\". " ~
            "\n(specifically a certificate chain file named \"server-cert.pem\" " ~ 
            "and a Private key file named \"server-key.pem\")");
            
        settings.port = 443; // !! Overrides the port in the serverparams struct
        settings.bindAddresses = serverparams.bindAddresses;
        
        settings.tlsContext = createTLSContext(TLSContextKind.server);
        settings.tlsContext.useCertificateChainFile("certificates/server-cert.pem");
        settings.tlsContext.usePrivateKeyFile("certificates/server-key.pem");
    }

    // Routing:
    // separating concerns, nice for future expansion
    // one serves the web pages
    auto pages = new URLRouter();

    pages.get("/", &handleHomePage);

    // another serves the backend interface
    auto api = new URLRouter();
    api.get("/api/user", &getAllUsers);
    api.get("/api/user/:id", &getUser);
    api.post("/api/user", &createUser);

    // link them together with a root object
    auto rootRouter = new URLRouter();
    rootRouter.any("/api/*", api); // backend api calls
    rootRouter.any("/*", pages); // everything else

    auto listen = listenHTTP(settings, rootRouter);
    scope (exit) 
    {
        listen.stopListening();
    }

    runApplication();

}
