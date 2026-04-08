module app;

import std.stdio;
import std.conv : to;
import vibe.vibe;
import std.process : environment;

import params;

import db.collections : isUsersEmpty, addUser, findUserByEmail, findUserByID;
import handlers.home;
import handlers.users : configureUserAPIRouter;

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

        case "--skip-import":
            serverparams.repopulateIfEmpty = false;
            break;

        default:
            writeln("Error: Command line argument not recognised: ", args[i]);
            return;
        }

    }

    if (serverparams.repopulateIfEmpty && isUsersEmpty()) {
        repopulateDB();
    }

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
    auto userApi = configureUserAPIRouter();

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

void repopulateDB() {
    // populate users first
    if (exists("./init-data/users.csv")) {
        auto userFile = File("./init-data/users.csv");
        writeln("Reading from user file: ", userFile.name);
        // and save their information (id's or emails)
    } else {
        writeln("No ./init-data/users.csv file found. Skipping database population step.");
        return;
    }

    // populate movies
    if (exists("./init-data/movies.csv")) {
        auto movieFile = File("./init-data/movies.csv");
        writeln("Reading from movie file: ", movieFile.name);
    } else {
        writeln("No ./init-data/movies.csv file found. Skipping movie population step");
        return;
    }

    // then we have the id's (get id from title name function and get id from username) to put in the reviews
    if (exists("./init-data/reviews.csv")) {
        auto reviewFile = File("./init-data/reviews.csv");
        writeln("Reading from review file: ", reviewFile.name);
    } else {
        writeln("No ./init-data/reviews.csv file found. Skipping review population step.");
    }
}

// test database repopulation
unittest {
    // check whether the starting database is empty
    assert(isUsersEmpty() == true, "Starting users database is not empty");

    // repopulation step
    repopulateDB();

    if (exists("./init-data/users.csv")) {
        // test users present in the database as they are in csv

        if (exists("./init-data/movies.csv")) {
            // test movies present in the database as they are in csv

            if (exists("./init-data/reviews.csv")) {
                // test reviews present in the database as they are in csv

            }
        }
    }

}
