module db.client;

import vibe.db.mongo.mongo;

// Credit: Low-Lock Singleton Pattern
// From David Simcha's D-Specific Design Patterns talk at DConf 2013
// https://wiki.dlang.org/Low-Lock_Singleton_Pattern

class DBClient {
    // inaccessible constructor
    private this() {
    }

    // Cache instantiation flag in thread-local bool
    // Thread local
    private static bool instantiated_;

    // Thread global
    private __gshared MongoClient instance_;

    // avoids Double-checked locking problem
    // https://en.wikipedia.org/wiki/Double-checked_locking
    static DBClient get() {

        // referring to the thread-global instance_ here
        // would possibly make younger threads make references 
        // to a premature object
        if (!instantiated_) {
            synchronized (DBClient.classinfo) {
                if (!instance_) {
                    instance_ = new DBClient();
                }

                instantiated_ = true;
            }
        }

        return instance_;
    }
}

void initialise(string mongoURI) {
    instance_ = connectMongoDB(mongoURI);
}
