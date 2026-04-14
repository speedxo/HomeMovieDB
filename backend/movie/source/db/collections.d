module db.collections;

import vibe.db.mongo.mongo;
import vibe.data.bson;
import vibe.data.serialization;

import std.process : environment;
import std.typecons : Nullable;
import std.datetime : SysTime, Clock, UTC;
import std.file;
import std.csv;
import std.algorithm;
import std.stdio;
import std.conv : to;
import std.array;

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
    userCollection.insertOne(userConfigHelper(user));
}

void addUser(string name, string email) {
    User user;
    user.name = name;
    user.email = email;
    userCollection.insertOne(userConfigHelper(user));
}

/// Generates an _id for a user object, and sets the created/updated at
/// to the current UTC time.
private User userConfigHelper(ref User user) {
    user._id = BsonObjectID.generate();
    user.createdAt = Clock.currTime(UTC());
    user.updatedAt = user.createdAt;
    return user;
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

/// Takes in the title object and inserts it into the titles collection in the db.
/// !! Note that this function only sets the _id, createdAt, and updatedAt fields.
/// Please remember to have the createdBy field set before calling this function 
/// (or use the other overload).
void addTitle(ref Title title) {
    titleCollection.insertOne(titleConfigHelper(title));
}

void addTitle(string name, BsonObjectID createdBy, string[] genres, string type, uint year) {
    Title title;
    title.name = name;
    title.createdBy = createdBy;
    title.genres = genres;
    title.type = type;
    title.year = year;

    titleCollection.insertOne(titleConfigHelper(title));
}

private Title titleConfigHelper(ref Title title) {
    title._id = BsonObjectID.generate();
    title.createdAt = Clock.currTime(UTC());
    title.updatedAt = title.createdAt;

    return title;
}

void updateTitle(BsonObjectID id, string name, string[] genres, string type, uint year) {

    auto update = Bson([
        "$set": Bson([
            "name": Bson(name),
            "updatedAt": Bson(BsonDate(Clock.currTime(UTC()))),
            "genres": serializeToBson(genres),
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
    Nullable!Title result;
    auto document = titleCollection.findOne(["_id": id]);

    if (!document.isNull) {
        result = deserializeBson!Title(document);
    }
    return result;
}

Nullable!Title findTitleByName(string name) {
    Nullable!Title result;
    auto document = titleCollection.findOne(["name": Bson(name)]);

    if (!document.isNull) {
        result = deserializeBson!Title(document);
    }
    return result;
}

Review[] titleReviews(BsonObjectID titleID) {
    auto result = reviewCollection.findOne(
        ["_id": titleID],
        ["reviews": 1]
    );
    auto reviews = result["reviews"].get!(Bson[]);

    // this might fail
    auto cursor = reviewCollection.find!Review([
        "_id": Bson(["$in": Bson(reviews)])
    ]);

    return cursor.array;
}

// Review collection

private MongoCollection reviewCollection() {
    return DBClient.get.getCollection(environment["MONGO_DB"] ~ ".reviews");
}

void addReview(Review review) {
    reviewCollection.insertOne(reviewConfigHelper(review));
}

void addReview(BsonObjectID titleID, BsonObjectID creatorID, int rating, bool recommended, string reviewBody = "") {
    Review newReview;

    newReview.titleID = titleID;
    newReview.creatorID = creatorID;
    newReview.rating = to!ubyte(rating);
    newReview.recommended = recommended;
    newReview.reviewBody = reviewBody;

    reviewCollection.insertOne(reviewConfigHelper(newReview));
}

private Review reviewConfigHelper(ref Review review) {
    review._id = BsonObjectID.generate();
    review.createdAt = Clock.currTime(UTC());
    review.updatedAt = review.createdAt;

    return review;
}

void updateReview(BsonObjectID reviewID, int rating, bool recommended, string reviewBody = "") {
    auto update = Bson([
        "$set": Bson([
            "updatedAt": Bson(BsonDate(Clock.currTime(UTC()))),
            "rating": Bson(rating),
            "recommended": Bson(recommended),
            "reviewBody": Bson(reviewBody)
        ])
    ]);

    reviewCollection.updateOne(["_id": reviewID], update);
}

void deleteReview(BsonObjectID reviewID) {
    reviewCollection.deleteOne(["_id": reviewID]);
}

Nullable!Review findReviewByID(BsonObjectID reviewID) {
    Nullable!Review result;

    auto document = reviewCollection.findOne(["_id": reviewID]);
    if (!document.isNull) {
        result = deserializeBson!Review(document);
    }

    return result;
}

/* -------------------------------------------------------------- */

/// Gives an initial state of the database with user-provided data, if any exists
void repopulateDB(string folder = "./movie/init-data/") {
    if (!isCollectionEmpty(userCollection))
        return;

    /// associative array that associates emails to user's objectID's 
    BsonObjectID[string] userEmailIDs;

    /// associative array that associates title names to objectID's
    BsonObjectID[string] titleIDs;

    // populate users first
    if (exists(folder ~ "users.csv")) {
        auto userFile = File(folder ~ "users.csv");
        writeln("Reading from user file: ", userFile.name);
        // and save their information (id's or emails)

        foreach (line; csvReader!(string[string])(userFile.byLine.joiner("\n"), null)) {
            // bypassing the usual addUser() functions, because we need the id's
            User newUser;

            // configure new user
            userConfigHelper(newUser);
            newUser.email = line["Email"];
            newUser.name = line["Name"];

            // map email to id for later steps
            userEmailIDs[newUser.email] = newUser._id;

            userCollection.insertOne(newUser);
        }
    } else {
        writeln("No " ~ folder ~ "users.csv file found. Skipping database population step.");
        return;
    }

    // populate movies
    if (exists(folder ~ "movies.csv")) {
        import std.datetime.systime;

        auto movieFile = File(folder ~ "movies.csv");
        writeln("Reading from movie file: ", movieFile.name);

        foreach (line; csvReader!(string[string])(movieFile.byLine.joiner("\n"), null)) {
            Title newTitle;

            titleConfigHelper(newTitle);
            newTitle.name = line["Title"];
            newTitle.createdBy = userEmailIDs[line["Created by"]];
            newTitle.genres = line["Genres"].split(", ");
            newTitle.type = line["Type"];
            newTitle.year = to!int(line["Year"]);
            newTitle.createdAt = SysTime.fromISOString(line["Date Created"]).toUTC();

            titleCollection.insertOne(newTitle);

            titleIDs[newTitle.name] = newTitle._id;
        }
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

version (integration) {
    /// tests database repopulation
    unittest {
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

            assert(title.get.year == to!int(line["Year"]), "Year of title defined in db does not match csv.");

            // important: test saved dates and genres
        }

        // test reviews present in the database as they are in csv
        assert(exists(folder ~ "reviews.csv"), "The " ~ folder ~ "reviews.csv file was not found.");

    }

    // TODO: another unittest that tests modifications and deletions (they can happen in parallel)

}
