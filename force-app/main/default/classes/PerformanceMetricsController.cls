/**
 * @description
 *   Provides performance metrics (such as EPT) for LWC dashboards.
 *   Designed for use with the performanceMetrics LWC component.
 */
public with sharing class PerformanceMetricsController {

    /**
     * Returns EPT and related metrics from Org_Health_Metric__c.
     * Each map corresponds to one metric record.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPerformanceMetrics() {
        List<Org_Health_Metric__c> rows = [
            SELECT Id, Metric_Value__c, Status__c, Recorded_Date__c, Threshold__c
            FROM Org_Health_Metric__c
            WHERE Metric_Type__c = 'Performance - EPT'
            ORDER BY Recorded_Date__c DESC
            LIMIT 100
        ];
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Org_Health_Metric__c record : rows) {
            // Optionally, parse Additional_Details__c as JSON if you store extra fields
            result.add(new Map<String, Object>{
                'id'         => record.Id,
                'ept'        => record.Metric_Value__c,   // EPT ms
                'status'     => record.Status__c,
                'timestamp'  => record.Recorded_Date__c,
                'threashold'    => record.Threshold__c
            });
        }
        return result;
    }
}
