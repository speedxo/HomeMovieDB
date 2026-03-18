module handlers.home;

import vibe.http.server;

void handleHomePage(scope HTTPServerRequest req, scope HTTPServerResponse res) 
{
    res.writeBody("TESTING TESTING", "text/plain");
}