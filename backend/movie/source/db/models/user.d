module db.models.user;

import vibe.data.bson;

struct User {
    BsonObjectID _id;
    string name;
    string email;
    BsonDate createdAt;
    BsonDate updatedAt;
}
