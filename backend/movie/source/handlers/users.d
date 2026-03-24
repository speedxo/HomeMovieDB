module handlers.users;

import vibe.http.server;
import vibe.data.json;
import vibe.data.bson;
import vibe.vibe;

import db.models.user : User;
import db.collections : addUser;

URLRouter configureRouter() {
    auto router = new URLRouter();
    api.get("/api/user", &getAllUsers);
    api.get("/api/user/:id", &getUser);
    api.post("/api/user", &createUser);

}

void getAllUsers(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    res.writeJsonBody(testSet.serializeToJson());
}

void getUser(scope HTTPServerRequest req, scope HTTPServerResponse res) {
    auto id = BsonObjectID.fromString(req.params["id"]);
    auto user = findUserById(id);

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
