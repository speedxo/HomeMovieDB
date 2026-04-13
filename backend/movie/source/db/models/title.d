module db.models.title;

import vibe.data.bson;
import std.datetime : SysTime;

struct Title {
    BsonObjectID _id;
    string name;
    SysTime createdAt;
    SysTime updatedAt;
    BsonObjectID createdBy;
    string[] genres;
    string type;
    uint year;
    BsonObjectID[] reviews;
}
