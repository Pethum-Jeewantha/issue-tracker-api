
import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/io;
import ballerina/time;

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
    string? updatedAt;
    string? assignedToUserId;
|};

type PostIssue record {
    string title;
    string description;
};

int PORT = 3900;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"],
        allowMethods: ["*"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}

service /api on new http:Listener(PORT) {
    private final mysql:Client db;

    function init() returns error? {
        self.db = check new (host, user, password, database, port);
        io:println("API is running on ", PORT);
    }

    resource function get issues(string sortColumn = "id", string sortOrder = "ASC", int pagelimit = 10, int offset = 0, string status = "") returns json|error {
        string orderByClause = string `${sortColumn} ${sortOrder}`;

        sql:ParameterizedQuery query;
        if status == "" {
            query = `SELECT * FROM Issue ORDER BY ${orderByClause} LIMIT ${pagelimit} OFFSET ${offset}`;
        } else {
            query = `SELECT * FROM Issue WHERE status = ${status} ORDER BY ${orderByClause} LIMIT ${pagelimit} OFFSET ${offset}`;
        }
        
        stream<Issue, sql:Error?> issueStream = self.db->query(query);
        Issue[] issues = check from Issue issue in issueStream select issue;

        if status == "" {
            query = `SELECT COUNT(*) AS count FROM Issue`;
        } else {
            query = `SELECT COUNT(*) AS count FROM Issue WHERE status = ${status}`;
        }

        int countResult = check self.db->queryRow(query);

        json responseJson = {
            "list": issues,
            "offset": offset,
            "limit": pagelimit,
            "total": countResult
        };

        return responseJson;
    }

    resource function get issues/[string id]() returns Issue|http:NotFound|error {
        Issue|sql:Error result = self.db->queryRow(`SELECT * FROM Issue WHERE id = ${id}`);

        if result is sql:NoRowsError {
            return http:NOT_FOUND;
        } else {
            return result;
        }
    }

    resource function post issues(@http:Payload PostIssue issue) returns Issue|sql:Error|http:NotFound & readonly|error {
        var insertResult = check self.db->execute(`INSERT INTO Issue (title, description) VALUES (${issue.title}, ${issue.description});`);

        var lastInsertId = insertResult.lastInsertId;
        Issue|sql:Error result = self.db->queryRow(`SELECT * FROM Issue WHERE id = ${lastInsertId}`);
        if result is sql:NoRowsError {
            return http:NOT_FOUND;
        } else {
            return result;
        }
    }
    
    resource function put issues/[string id](@http:Payload PostIssue issue) returns Issue|sql:Error|http:NotFound & readonly|error {
        sql:ParameterizedQuery query = `SELECT COUNT(*) AS count FROM Issue WHERE id = ${id}`;
        int count = check self.db->queryRow(query);
        if count == 0 {
            return http:NOT_FOUND;
        }

        time:Utc currentTime = time:utcNow();

        // Format the time as a string in the SQL DATETIME format
        // string formattedTime = time:format(currentTime, "yyyy-MM-dd'T'HH:mm:ss");

        var updateResult = self.db->execute(`UPDATE Issue SET title = ${issue.title}, description = ${issue.description}, updatedAt = ${currentTime} WHERE id = ${id}`);
        if updateResult is sql:Error {
            return updateResult;
        }

        Issue|sql:Error result = self.db->queryRow(`SELECT * FROM Issue WHERE id = ${id}`);
        if result is sql:NoRowsError {
            return http:NOT_FOUND;
        } else {
            return result;
        }
    }
}