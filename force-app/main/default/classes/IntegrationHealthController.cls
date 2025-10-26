/**
 * @description
 *   Provides external integration health metrics for LWC dashboards.
 *   Used by the integrationHealthCheck LWC to display status, response time, and error metrics.
 */
public with sharing class IntegrationHealthController {

    /**
     * Returns details of each integration for display.
     * Called by integrationHealthCheck LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getIntegrationStatus() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        List<Integration_Status__c> integrations = [
            SELECT Id, Integration_Name__c, Status__c, Last_Success__c, 
                   Error_Count__c, Response_Time__c, Integration_Endpoint__c
            FROM Integration_Status__c
            ORDER BY Integration_Name__c ASC
        ];

        for (Integration_Status__c rec : integrations) {
            result.add(new Map<String, Object>{
                'id' => rec.Id,
                'integrationName' => rec.Integration_Name__c,
                'status' => rec.Status__c,
                'lastSuccess' => rec.Last_Success__c,
                'errorCount' => rec.Error_Count__c,
                'responseTime' => rec.Response_Time__c,
                'endpoint' => rec.Integration_Endpoint__c
            });
        }

        return result;
    }

    /**
     * Returns integration health summary totals for KPI indicators
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getIntegrationSummary() {
        Integer total = 0;
        Integer healthy = 0;
        Integer errors = 0;

        for (Integration_Status__c i : [
            SELECT Status__c FROM Integration_Status__c
        ]) {
            total++;
            if (i.Status__c == 'Healthy' || i.Status__c == 'Success') {
                healthy++;
            } else if (i.Status__c == 'Error' || i.Status__c == 'Failed') {
                errors++;
            }
        }

        return new Map<String, Integer>{
            'total' => total,
            'healthy' => healthy,
            'errors' => errors
        };
    }
}