module db.models.user;

import vibe.data.bson;
import std.datetime : SysTime;

struct User {
    BsonObjectID _id;
    string name;
    string email;
    SysTime createdAt;
    SysTime updatedAt;
    BsonObjectID[] seenTitles;
    BsonObjectID[] watchingTitles;
    BsonObjectID[] topTitles;
}
