
import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/io;

configurable string host = "localhost";
configurable int port = 3306;
configurable string user = "root";
configurable string password = "mysql";
configurable string database = "issue-tracker";

type Issue record {|
    int id;
    string title;
    string description;
    string status;
    string createdAt;
    string updatedAt;
    string? assignedToUserId;
|};

int PORT = 3200;

service /api on new http:Listener(PORT) {
    private final mysql:Client db;

    function init() returns error? {
        self.db = check new (host, user, password, database, port);
        io:println("API is running on ", PORT);
    }

    resource function get issues() returns Issue[]|error {
        stream<Issue, sql:Error?> issueStream = self.db->query(`SELECT * FROM Issue`);
        return from Issue issue in issueStream select issue;
    }

    // resource function get albums/[string id]() returns Album|http:NotFound|error {
    //     Album|sql:Error result = self.db->queryRow(`SELECT * FROM Albums WHERE id = ${id}`);
    //     if result is sql:NoRowsError {
    //         return http:NOT_FOUND;
    //     } else {
    //         return result;
    //     }
    // }

    // resource function post album(@http:Payload Album album) returns Album|error {
    //     _ = check self.db->execute(`
    //         INSERT INTO Albums (id, title, artist, price)
    //         VALUES (${album.id}, ${album.title}, ${album.artist}, ${album.price});`);
    //     return album;
    // }
}