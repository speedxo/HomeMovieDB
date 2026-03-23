module db.collections;

import vibe.db.mongo.mongo;
import db.client;
import vibe.data.bson;
import std.process : environment;
import db.models.user : User;

private MongoCollection userCollection() {
    return DBClient.get.getCollection(environment["MONGO_DB"] ~ ".users");
}

void addUser(ref User user) {
    user._id = BsonObjectID.generate();
    user.createdAt = BsonDate.fromStdTime(Clock.currStdTime);
    user.updatedAt = user.createdAt;
    userCollection.insertOne(user);
}

Nullable!User findUserByID(BsonObjectID id) {
    Nullable!User result;
    auto document = userCollection.findOne(["_id": id]);
    if (!document.isNull) {
        result = deserializeBson!User(doc);
    }
    return result;
}

Nullable!User findUserByEmail(string email) {
    Nullable!User result;
    auto document = userCollection.findOne(["email": email]);
    if (!document.isNull) {
        result = deserializeBson!User(doc);
    }
    return result;
}

void updateUser(BsonObjectID id, string name, string email) {
    auto update = [
        "$set": [
            "name": name,
            "email": email,
            "updatedAt": BsonDate.fromStdTime(Clock.currStdTime).toString()
        ]
    ];
    userCollection.updateOne(["_id": id], update);
}

void deleteUser(BsonObjectID id) {
    userCollection.deleteOne(["_id": id]);
}

// TODO: titleCollection / movieCollection / I still need to find a name for it
