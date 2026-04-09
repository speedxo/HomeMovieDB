module db.collections;

import vibe.db.mongo.mongo;
import vibe.data.bson;

import std.process : environment;
import std.typecons : Nullable;
import std.datetime : SysTime, Clock, UTC;
import std.file;
import std.csv;
import std.algorithm;
import std.stdio;

import db.client;
import db.models;

private MongoCollection userCollection() {
    return DBClient.get.getCollection(environment["MONGO_DB"] ~ ".users");
}

bool isCollectionEmpty(MongoCollection c) {
    // empty object matches all (equivalent to {})
    return c.countDocuments(Bson.emptyObject) == 0;
}

// TODO: password authorisation and token authentication
void addUser(ref User user) {
    user._id = BsonObjectID.generate();
    user.createdAt = Clock.currTime(UTC());
    user.updatedAt = user.createdAt;
    userCollection.insertOne(user);
}

void addUser(string name, string email) {
    User user;
    user._id = BsonObjectID.generate();
    user.createdAt = Clock.currTime(UTC());
    user.updatedAt = user.createdAt;
    userCollection.insertOne(user);
}

void updateUser(BsonObjectID id, string name, string email) {
    auto update = Bson([
        "$set": Bson([
            "name": Bson(name),
            "email": Bson(email),
            "updatedAt": Bson(BsonDate(Clock.currTime(UTC())))
        ])
    ]);
    userCollection.updateOne(["_id": id], update);
}

void deleteUser(BsonObjectID id) {
    userCollection.deleteOne(["_id": id]);
}

Nullable!User findUserByID(BsonObjectID id) {
    Nullable!User result;
    auto document = userCollection.findOne(["_id": id]);
    if (!document.isNull) {
        result = deserializeBson!User(document);
    }
    return result;
}

Nullable!User findUserByEmail(string email) {
    Nullable!User result;
    auto document = userCollection.findOne(["email": Bson(email)]);
    if (!document.isNull) {
        result = deserializeBson!User(document);
    }
    return result;
}

// Title collection (might be named movies elsewhere)

private MongoCollection titleCollection() {
    return DBClient.get.getCollection(environment["MONGO_DB"] ~ ".titles");
}

void addTitle() {
    throw new Exception("Function not implemented");
}

void updateTitle(BsonObjectID id, string title, string[] genres, string type, uint year) {
    auto update = Bson([
        "$set": Bson([
            "title": Bson(title),
            "updatedAt": Bson(BsonDate(Clock.currTime(UTC()))),
            "genres": Bson(genres),
            "type": Bson(type),
            "year": Bson(year)
        ])
    ]);

    titleCollection.updateOne(["_id": id], update);
}

void deleteTitle(BsonObjectID id) {
    titleCollection.deleteOne(["_id": id]);
}

Nullable!Title findTitleByID(BsonObjectID id) {
    throw new Exception("Function not implemented");
}

Nullable!Title findTitleByName(string name) {
    throw new Exception("Function not implemented");
}

/* -------------------------------------------------------------- */

/// Gives an initial state of the database with user-provided data
void repopulateDB(string folder = "./movie/init-data/") {
    if (!isCollectionEmpty(userCollection))
        return;

    // populate users first
    if (exists(folder ~ "users.csv")) {
        auto userFile = File(folder ~ "users.csv");
        writeln("Reading from user file: ", userFile.name);
        // and save their information (id's or emails)
    } else {
        writeln("No " ~ folder ~ "users.csv file found. Skipping database population step.");
        return;
    }

    // populate movies
    if (exists(folder ~ "movies.csv")) {
        auto movieFile = File(folder ~ "movies.csv");
        writeln("Reading from movie file: ", movieFile.name);
    } else {
        writeln("No " ~ folder ~ "movies.csv file found. Skipping movie population step");
        return;
    }

    // then we have the id's (get id from title name function and get id from username) to put in the reviews
    if (exists(folder ~ "reviews.csv")) {
        auto reviewFile = File(folder ~ "reviews.csv");
        writeln("Reading from review file: ", reviewFile.name);
    } else {
        writeln("No " ~ folder ~ "reviews.csv file found. Skipping review population step.");
    }
}

/// tests database repopulation
unittest {
    // check whether the starting database is empty
    assert(isCollectionEmpty(userCollection) == true, "Starting users database is not empty");
    assert(isCollectionEmpty(titleCollection) == true, "Starting title database is not empty");

    // use a folder with test data
    string folder = "./movie/test-data/";

    // repopulation step
    repopulateDB(folder);

    // test users present in the database as they are in csv
    assert(exists(folder ~ "users.csv"), "The " ~ folder ~ "users.csv file was not found.");

    auto userFile = File(folder ~ "users.csv");
    foreach (line; csvReader!(string[string])(userFile.byLine.joiner("\n"), null)) {
        // auto user = findUserByEmail(line["Email"]).get;
        assert(!findUserByEmail(line["Email"]).isNull, "User defined in csv was not found in db.");

        assert(findUserByEmail(line["Email"]).get.name == line["Name"],
            "User's email (used as identifier) and name (from db) does not match.");
    }

    // test movies present in the database as they are in csv
    assert(exists(folder ~ "movies.csv"), "The " ~ folder ~ "movies.csv file was not found.");

    auto movieFile = File(folder ~ "movies.csv");
    foreach (line; csvReader!(string[string])(userFile.byLine.joiner("\n"), null)) {
        Nullable!Title title = findTitleByName(line["Title"]);
        assert(!title.isNull, "Title defined in csv was not found in db.");

        assert(title.get.type == line["Type"], "Type of title defined in db does not match csv.");

        // important: test saved date
    }

    // test reviews present in the database as they are in csv
    assert(exists(folder ~ "reviews.csv"), "The " ~ folder ~ "reviews.csv file was not found.");

}

// TODO: another unittest that tests modifications and deletions (they can happen in parallel)
