module handlers.users;

import vibe.http.server;
import vibe.data.json;

// TODO: interface with the mongo database
// below is a skeleton provided by claude.ai (which hopefully works)

// basic user data structure for now
struct User
{
    int id;
    string name;
}

User[] testSet = [
    User(1, "User A"),
    User(2, "User B"),
];

void getAllUsers(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    res.writeJsonBody(testSet.serializeToJson());
}

void getUser(scope HTTPServerRequest req, scope HTTPServerResponse res)
{
    import std.conv : to;

    int id = req.params["id"].to!int;

    foreach (user; testSet)
    {
        if (user.id == id)
        {
            res.writeJsonBody(user.serializeToJson());
            return;
        }
    }

    res.statusCode = HTTPStatus.notFound;
    res.writeJsonBody(Json(["error": Json("User not found")]));
}

void createUser(scope HTTPServerRequest req, scope HTTPServerResponse res)
{
    auto body_ = req.json;
    User newUser = User(
        cast(int) testSet.length + 1,
        body_["name"].get!string,
    );

    testSet ~= newUser;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(newUser.serializeToJson());
}