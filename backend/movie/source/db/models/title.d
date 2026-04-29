module db.models.title;

import vibe.data.bson;
import std.datetime : SysTime;
import std.typecons : Nullable;
import vibe.data.serialization : optional;

struct Title {
    BsonObjectID _id;
    string name;
    SysTime createdAt;
    SysTime updatedAt;
    BsonObjectID createdBy;
    @optional string[] genres = [];
    @optional string type = "";
    @optional uint year = uint.max;
    @optional BsonObjectID[] reviews = [];
}
