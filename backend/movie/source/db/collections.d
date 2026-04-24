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
// TODO: enforce unique user names
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

Nullable!User findUserByUsername(string name) {
    Nullable!User result;
    auto document = userCollection.findOne(["name": Bson(name)]);
    if (!document.isNull) {
        result = deserializeBson!User(document);
    }
    return result;
}

/// Adds the review's _id to the list of reviewID's under a user.
/// Mostly used internally when addReview() is called.
void addReviewToUser(BsonObjectID userID, BsonObjectID reviewID) {
    auto result = userCollection.findOne(["_id": userID]);
    auto reviews = result["reviews"].get!(Bson[]);

    reviews ~= Bson(reviewID);

    auto update = Bson([
            "$set": Bson([
                    "reviews": Bson(reviews)
                ])
        ]);
    userCollection.updateOne(["_id": userID], update);
}

/// Retrieves all reviews made by a user.
/// Returns an array of the actual Review objects.
Review[] findAllUserReviews(BsonObjectID userID) {
    auto result = userCollection.findOne(
        ["_id": userID],
        ["reviews": 1]
    );
    auto reviews = result["reviews"].get!(Bson[]);

    // this might fail
    auto cursor = reviewCollection.find!Review([
        "_id": Bson(["$in": Bson(reviews)])
    ]);

    return cursor.array;
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

void addTitle(string name, BsonObjectID createdBy, string[] genres = [], Nullable!string type =
        string.init, Nullable!uint year = uint.init) {
    Title title;
    title.name = name;
    title.createdBy = createdBy;
    title.genres = genres;
    title.type = type.get;
    title.year = year.get;

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

/// Retrieves all reviews for a specified title.
/// Returns an array of the actual Review objects.
Review[] findAllTitleReviews(BsonObjectID titleID) {
    auto result = titleCollection.findOne(
        ["_id": titleID],
        ["reviews": 1]
    );

    auto reviewsBson = result["reviews"];
    Bson[] reviews = reviewsBson.type == Bson.Type.array
        ? reviewsBson.get!(Bson[]) : [];

    if (reviews.length == 0)
        return [];

    auto cursor = reviewCollection.find!Review([
        "_id": Bson(["$in": Bson(reviews)])
    ]);

    return cursor.array;
}

/// Adds the review's _id to the list of review id's under one title.
/// Mostly used internally when addReview() is called.
void addReviewToTitle(BsonObjectID titleID, BsonObjectID reviewID) {
    auto result = titleCollection.findOne(["_id": titleID]);
    auto reviews = result["reviews"].get!(Bson[]);

    reviews ~= Bson(reviewID);

    auto update = Bson([
            "$set": Bson([
                    "reviews": Bson(reviews)
                ])
        ]);
    titleCollection.updateOne(["_id": titleID], update);
}

// Review collection

private MongoCollection reviewCollection() {
    return DBClient.get.getCollection(environment["MONGO_DB"] ~ ".reviews");
}

void addReview(Review review) {
    reviewConfigHelper(review);

    reviewCollection.insertOne(review);
    addReviewToTitle(review.titleID, review._id);
    addReviewToUser(review.creatorID, review._id);
}

void addReview(BsonObjectID titleID, BsonObjectID creatorID, int rating, bool recommended, string reviewBody = "") {
    Review newReview;

    reviewConfigHelper(newReview);

    newReview.titleID = titleID;
    newReview.creatorID = creatorID;
    newReview.rating = to!ubyte(rating);
    newReview.recommended = recommended;
    newReview.reviewBody = reviewBody;

    reviewCollection.insertOne(newReview);
    addReviewToTitle(newReview.titleID, newReview._id);
    addReviewToUser(newReview.creatorID, newReview._id);
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
bool repopulateDB(string folder = "./movie/init-data/") {
    import std.string : isNumeric;

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
        return false;
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
            if ((line["Year"].length == 4) & isNumeric(line["Year"])) {
                newTitle.year = to!int(line["Year"]);
            }
            newTitle.createdAt = SysTime.fromISOString(line["Date Created"]).toUTC();

            titleCollection.insertOne(newTitle);

            titleIDs[newTitle.name] = newTitle._id;
        }
    } else {
        writeln("No " ~ folder ~ "movies.csv file found. Skipping movie population step");
        return false;
    }

    // then we have the id's (get id from title name function and get id from username) to put in the reviews
    if (exists(folder ~ "reviews.csv")) {
        auto reviewFile = File(folder ~ "reviews.csv");
        writeln("Reading from review file: ", reviewFile.name);

        foreach (line; csvReader!(string[string])(reviewFile.byLine.joiner("\n"), null)) {
            Review newReview;

            newReview.titleID = titleIDs[line["Title"]];
            newReview.creatorID = userEmailIDs[line["Created by"]];
            newReview.recommended = line["Recommended"] == "Yes" ? true : false;
            newReview.rating = to!ubyte(line["Rating"]);

            addReview(newReview);
        }
    } else {
        writeln("No " ~ folder ~ "reviews.csv file found. Skipping review population step.");
        return false;
    }

    return true;
}

version (integration) {
    /// tests database repopulation
    @("Database Repopulation")
    unittest {
        import std.algorithm.comparison : isPermutation;

        // use a folder with test data
        string folder = "./movie/test-data/";

        // test users present in the database as they are in csv
        assert(exists(folder ~ "users.csv"), "The " ~ folder ~ "users.csv file was not found.");
        // test movies present in the database as they are in csv
        assert(exists(folder ~ "movies.csv"), "The " ~ folder ~ "movies.csv file was not found.");
        // test reviews present in the database as they are in csv
        assert(exists(folder ~ "reviews.csv"), "The " ~ folder ~ "reviews.csv file was not found.");

        // repopulation step
        bool repopulationSuccess = repopulateDB(folder);
        assert(repopulationSuccess, "Failed to fully complete repopulation step.");

        // Testing successful population of user data
        auto userFile = File(folder ~ "users.csv");
        foreach (line; csvReader!(string[string])(userFile.byLine.joiner("\n"), null)) {
            auto user = findUserByEmail(line["Email"]);

            assert(!user.isNull, "User defined in csv was not found in db.");

            assert(user.get.name == line["Name"],
                "User's email (used as identifier) and name (from db) does not match.");
        }

        // Testing successful population of movie and review data
        auto movieFile = File(folder ~ "movies.csv");
        foreach (line; csvReader!(string[string])(movieFile.byLine.joiner("\n"), null)) {
            Nullable!Title title = findTitleByName(line["Title"]);
            assert(!title.isNull, "Title defined in csv was not found in db.");

            // writeln("Testing title type: " ~ title.get.type);
            assert(title.get.type == line["Type"], "Type of title defined in db does not match csv.");

            assert(title.get.year == to!int(line["Year"]), "Year of title defined in db does not match csv.");

            // important: test saved dates and genres
            assert(title.get.createdAt == SysTime.fromISOString(line["Date Created"])
                    .toUTC(),
                    "Title's date created in db does not match csv.");

            assert(isPermutation(title.get.genres, line["Genres"].split(", ")),
                "Title's genre list in db does not match csv");
        }

        auto reviewFile = File(folder ~ "reviews.csv");
        foreach (line; csvReader!(string[string])(reviewFile.byLine.joiner("\n"), null)) {
            // since each review has a title name in the csv, get the titles that have reviews
            Nullable!Title title = findTitleByName(line["Title"]);
            assert(!title.isNull, "Title \"" ~ line["Title"] ~ "\" associated with a review was not found.");

            // get the reviews that are under those titles
            Review[] titleReviews = findAllTitleReviews(title.get._id);

            // then test whether they match those in the csv
            assert(titleReviews.length > 0, "Review information not found for review under title: "
                    ~ line["Title"]);

            // Get the user that is associated with the review
            Nullable!User creator = findUserByEmail(line["Created by"]);
            assert(!creator.isNull, "User associated with review under title \""
                    ~ line["Title"] ~ "\" in csv was not found.");

            Review[] userReviews = findAllUserReviews(creator.get._id);
            assert(userReviews.length > 0, "Review information not found for a review under user: "
                    ~ line["Created by"]);

            // By now we know that the title in the csv has a review and a user in the csv has a review
            // since we only have one review per title for each user,
            // finding the review that corresponds to the title name
            // in the current line in the csv should be the same review every time.

            // The intersection of the two arrays:
            auto sect = setIntersection(title.get.reviews.sort(), creator.get.reviews.sort()).array;

            // writeln(
            //     "------------------" ~ title.get.name ~ " and " ~ creator.get.name ~ "------------------");
            // writeln("title in csv: ", line["Title"]);
            // writeln("title reviews: ", title.get.reviews.sort());
            // writeln("creator in csv: ", line["Created by"]);
            // writeln("creator reviews: ", creator.get.reviews.sort());
            // writeln("detected intersection: ", sect);

            // this id info is not in the csv but we can be pretty sure this is our current review in the csv
            assert(!(sect.length < 1), "No common review id found under title: \"" ~ title.get.name ~
                    "\" and user: " ~ creator.get.name);
            assert(!(sect.length > 1), "More than one common review found under title: \"" ~
                    title.get.name ~ "\" and user: " ~ creator.get.name);
        }
    }

    // TODO: another unittest that tests modifications and deletions (they can happen in parallel)
    @("Normal CRUD tests")
    unittest {

    }
}
