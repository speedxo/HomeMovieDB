module db.models.review;

import vibe.data.bson;
import std.datetime : SysTime;

struct Review {
    BsonObjectID _id;
    BsonObjectID titleID;
    BsonObjectID creatorID;
    SysTime createdAt;
    SysTime updatedAt;
    ubyte rating;
    bool recommended;
    string reviewBody = "";
}
