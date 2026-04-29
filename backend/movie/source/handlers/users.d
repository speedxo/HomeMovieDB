module handlers.users;

import vibe.http.server;
import vibe.data.json;
import vibe.data.bson;
import vibe.vibe;

import db.models.user : User;
import db.collections : addUser, findUserByID, findUserByEmail, findUserByUsername, deleteUser, updateUser;

URLRouter configureUserAPIRouter() {
    auto router = new URLRouter();
    router.get("/api/user/id/:id", &getUserById);
    // router.get("/api/user/email/:email", &getUserByEmail);
    router.get("/api/user/:name", &getUserByUsername);
    router.post("/api/user", &createUser);

    return router;
}

void getUserById(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto id = BsonObjectID.fromString(req.params["id"]);
    auto user = findUserByID(id);

    if (user.isNull) {
        res.statusCode = HTTPStatus.notFound;
        res.writeJsonBody(["error": "User not found"]);
        return;
    }

    res.writeJsonBody(user.get);
}

void getUserByEmail(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto email = req.params["email"];
    auto user = findUserByEmail(email);

    if (user.isNull) {
        res.statusCode = HTTPStatus.notFound;
        res.writeJsonBody(["error": "User not found"]);
        return;
    }

    res.writeJsonBody(user.get);
}

void getUserByUsername(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto name = req.params["name"];
    auto user = findUserByUsername(name);
    if (user.isNull) {
        res.statusCode = HTTPStatus.notFound;
        res.writeJsonBody(["error": "User not found"]);
        return;
    }
    res.writeJsonBody(user.get);
}

void createUser(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto body_ = req.json;
    User newUser;

    newUser.name = body_["name"].get!string;
    newUser.email = body_["email"].get!string;

    addUser(newUser);

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(newUser.serializeToJson());
}

void modifyUser(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto id = BsonObjectID.fromString(req.params["id"]);
    auto body_ = req.json;

    updateUser(id, body_["name"].get!string, body_["email"].get!string);
    res.statusCode = HTTPStatus.noContent;
}

void removeUser(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto id = BsonObjectID.fromString(req.params["id"]);
    deleteUser(id);
    res.statusCode = HTTPStatus.noContent;
}
