/**
 * AuraEnabled controller that returns F1 driver standings
 * from the Data Cloud POC_Dal_DriverStandings_dlm__dlm DMO.
 */
public with sharing class F1DriverStandingsController_poc {

    /**
     * Returns all driver standings ordered by position ascending.
     *
     * @return List of DriverStandingDTO sorted by positionNumber
     * @throws AuraHandledException on query failure
     */
    @AuraEnabled(cacheable=true)
    public static List<DriverStandingDTO> getDriverStandings() {
        try {
            List<SObject> rows = Database.query(
                'SELECT positionNumber__c, driverBroadcastName__c, driverTla__c, ' +
                'teamName__c, championshipPoints__c ' +
                'FROM POC_Dal_DriverStandings_dlm__dlm ' +
                'WITH USER_MODE ' +
                'ORDER BY positionNumber__c ASC ' +
                'LIMIT 20'
            );

            List<DriverStandingDTO> results = new List<DriverStandingDTO>();
            for (SObject row : rows) {
                results.add(new DriverStandingDTO(row));
            }
            return results;
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to load driver standings: ' + ex.getMessage());
        }
    }

    /**
     * Lightweight DTO for a single driver standing row.
     */
    public class DriverStandingDTO {
        @AuraEnabled public Integer positionNumber { get; set; }
        @AuraEnabled public String driverBroadcastName { get; set; }
        @AuraEnabled public String driverTla { get; set; }
        @AuraEnabled public String teamName { get; set; }
        @AuraEnabled public Integer championshipPoints { get; set; }

        /**
         * @param row SObject row from POC_Dal_DriverStandings_dlm__dlm query
         */
        public DriverStandingDTO(SObject row) {
            Object pos = row.get('positionNumber__c');
            this.positionNumber = pos != null ? Integer.valueOf(String.valueOf(pos)) : null;

            this.driverBroadcastName = (String) row.get('driverBroadcastName__c');
            this.driverTla = (String) row.get('driverTla__c');
            this.teamName = (String) row.get('teamName__c');

            Object pts = row.get('championshipPoints__c');
            this.championshipPoints = pts != null ? Integer.valueOf(String.valueOf(pts)) : 0;
        }
    }
}
