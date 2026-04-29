module db.models.user;

import vibe.data.bson;
import std.datetime : SysTime;
import vibe.data.serialization : optional;

struct User {
    BsonObjectID _id;
    string name;
    string email;
    SysTime createdAt;
    SysTime updatedAt;
    @optional BsonObjectID[] seenTitles = [];
    @optional BsonObjectID[] watchingTitles = [];
    @optional BsonObjectID[] topTitles = [];
    @optional BsonObjectID[] reviews = [];
}
