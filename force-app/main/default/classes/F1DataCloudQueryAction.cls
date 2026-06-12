/**
 * Invocable action for Agentforce agents to query F1 Data Cloud DMOs.
 * Supports article search and driver standings lookup.
 */
public with sharing class F1DataCloudQueryAction {

    public enum QueryType {
        ARTICLE_SEARCH,
        DRIVER_STANDINGS
    }

    /**
     * @param queryType Type of query: ARTICLE_SEARCH or DRIVER_STANDINGS
     * @param searchTerm Keyword to search for (used for article search)
     * @param driverName Driver full name filter (used for standings lookup)
     */
    public class Request {
        @InvocableVariable(label='Query Type' description='ARTICLE_SEARCH or DRIVER_STANDINGS' required=true)
        public String queryType;

        @InvocableVariable(label='Search Term' description='Keyword for article search')
        public String searchTerm;

        @InvocableVariable(label='Driver Name' description='Driver full name for standings lookup')
        public String driverName;
    }

    /**
     * @param resultText Plain text result for the agent to use in its response
     * @param isSuccess Whether the query succeeded
     * @param errorMessage Error detail if isSuccess is false
     */
    public class Response {
        @InvocableVariable(label='Result Text')
        public String resultText;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    /**
     * Executes a Data Cloud DMO query based on the request type.
     * @param requests List of query requests from the agent
     * @return List of responses with plain text results
     */
    @InvocableMethod(
        label='Query F1 Data Cloud'
        description='Search F1 articles or driver standings from Data Cloud DMOs'
        category='F1 Data'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            responses.add(processRequest(req));
        }
        return responses;
    }

    private static Response processRequest(Request req) {
        Response res = new Response();
        try {
            if (String.isBlank(req.queryType)) {
                res.isSuccess = false;
                res.errorMessage = 'queryType is required';
                return res;
            }

            String upperType = req.queryType.toUpperCase();
            if (upperType == QueryType.ARTICLE_SEARCH.name()) {
                res.resultText = searchArticles(req.searchTerm);
            } else if (upperType == QueryType.DRIVER_STANDINGS.name()) {
                res.resultText = getDriverStandings(req.driverName);
            } else {
                res.isSuccess = false;
                res.errorMessage = 'Unknown queryType: ' + req.queryType;
                return res;
            }

            res.isSuccess = true;
        } catch (Exception ex) {
            res.isSuccess = false;
            res.errorMessage = ex.getMessage();
            res.errorType = ex.getTypeName();
        }
        return res;
    }

    private static String searchArticles(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return 'No search term provided.';
        }

        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';

        // Replace POC_Apigee_Article__dlm with your actual DMO API name
        List<SObject> articles = Database.query(
            'SELECT Id__c, title__c, abstract__c, body_combined_text__c, articleType__c, tags_comma_separated__c ' +
            'FROM POC_Apigee_Article__dlm ' +
            'WHERE title__c LIKE :likeTerm OR body_combined_text__c LIKE :likeTerm ' +
            'WITH USER_MODE ' +
            'LIMIT 3'
        );

        if (articles.isEmpty()) {
            return 'No articles found matching: ' + searchTerm;
        }

        List<String> parts = new List<String>();
        for (SObject article : articles) {
            String title = (String) article.get('title__c');
            String summary = (String) article.get('abstract__c');
            parts.add(title + ': ' + summary);
        }
        return String.join(parts, '\n\n');
    }

    private static String getDriverStandings(String driverName) {
        String baseQuery =
            'SELECT Id__c, driverFullName__c, teamName__c, position__c, points__c, wins__c ' +
            'FROM POC_Dal_DriverStandings__dlm ' +
            'WITH USER_MODE ';

        List<SObject> standings;
        if (String.isNotBlank(driverName)) {
            String likeTerm = '%' + String.escapeSingleQuotes(driverName) + '%';
            // Replace POC_Dal_DriverStandings__dlm with your actual DMO API name
            standings = Database.query(baseQuery + 'WHERE driverFullName__c LIKE :likeTerm LIMIT 1');
        } else {
            standings = Database.query(baseQuery + 'ORDER BY position__c ASC LIMIT 10');
        }

        if (standings.isEmpty()) {
            return String.isNotBlank(driverName)
                ? 'No standings found for driver: ' + driverName
                : 'No standings data available.';
        }

        List<String> parts = new List<String>();
        for (SObject row : standings) {
            String name = (String) row.get('driverFullName__c');
            Object pos = row.get('position__c');
            Object pts = row.get('points__c');
            Object wins = row.get('wins__c');
            String team = (String) row.get('teamName__c');
            parts.add('P' + pos + ' ' + name + ' (' + team + ') — ' + pts + ' pts, ' + wins + ' wins');
        }
        return String.join(parts, '\n');
    }
}
