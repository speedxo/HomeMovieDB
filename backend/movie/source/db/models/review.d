module db.models.review;

import vibe.data.bson;
import std.datetime : SysTime;

struct Review {
    BsonObjectID _id;
    BsonObjectID titleID;
    BsonObjectID creator;
    ubyte rating;
    string reviewBody;
}
