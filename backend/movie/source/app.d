module app;

import std.stdio;
import std.conv : to;
import vibe.vibe;

import params;

import db.client;
import handlers.home;
import handlers.users;
import std.process : environment;

ServerParams serverparams;

void main(string[] args) {
    // save arguments
    foreach (i; 1 .. args.length) {
        switch (args[i]) {
        case "--https":
            serverparams.useHTTPS = true;
            break;

        case "--port":
            // optionally TODO : data validation and feedback message on fail
            serverparams.usePort = to!ushort(args[++i]);
            break;

        case "--ip":
            // optionally TODO : data validation and feedback message on fail
            // select an address to use, can be v6 or v4
            serverparams.bindAddresses = [args[++i]];
            break;

        default:
            writeln("Error: Command line argument not recognised: ", args[i]);
            return;
        }

    }

    // TODO: make a db call and populate it if empty

    // configuring http settings
    auto settings = new HTTPServerSettings;

    if (!serverparams.useHTTPS) {
        settings.port = serverparams.usePort;
        settings.bindAddresses = serverparams.bindAddresses;
    } else {
        // To serve HTTPS connections, 
        // the configuration needs to have a TLS context that has 
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
    // TODO: have handlers give their own routes that they define themselves, 
    // and combine them all here.
    // perhaps I should choose new routes for the user one instead of just /api/*

    // one serves the web pages
    auto pages = new URLRouter();

    pages.get("/", &handleHomePage);

    // another serves the backend interface
    auto userApi = users.configureRouter();

    // link them together with a root object
    auto rootRouter = new URLRouter();
    rootRouter.any("/api/*", userApi); // backend api calls
    rootRouter.any("/*", pages); // everything else

    // Start listening with the chosen settings
    auto listen = listenHTTP(settings, rootRouter);
    scope (exit) {
        listen.stopListening();
    }

    runApplication();

}
