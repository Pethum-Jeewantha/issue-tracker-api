
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

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"],
        allowCredentials: false,
        allowMethods: ["*"],
        allowHeaders: ["*"]
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

    // resource function get albums/[string id]() returns Album|http:NotFound|error {
    //     Album|sql:Error result = self.db->queryRow(`SELECT * FROM Albums WHERE id = ${id}`);
    //     if result is sql:NoRowsError {
    //         return http:NOT_FOUND;
    //     } else {
    //         return result;
    //     }
    // }

    resource function post issue(@http:Payload Issue issue) returns Issue|error {
        _ = check self.db->execute(`
            INSERT INTO Issue (title, description)
            VALUES (${issue.title}, ${issue.description});`);
        return issue;
    }
}