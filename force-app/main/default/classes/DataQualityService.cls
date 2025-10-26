/**
 * @description
 *    DataQualityService
 *    Provides data quality analytics and metrics for dashboards and LWC.
 * @author
 *    dsHealthWiz Platform
 * @date
 *    October 2025
 */
public with sharing class DataQualityService {

    /**
     * Returns all recent data quality scores (can be filtered/aggregated as needed).
     * Used by dataQualityMonitor and orgHealthDashboard LWC.
     *
     * @return List of maps with key metrics for Lightning DataTable
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDataQualityScores() {
        // Tune the WHERE clause for your use case - e.g., scores from last 30 days.
        List<Data_Quality_Score__c> scores = [
            SELECT Id, Object_Name__c, Field__c, Score__c, Analysis_Date__c, Notes__c
            FROM Data_Quality_Score__c
            ORDER BY Object_Name__c, Field__c
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Data_Quality_Score__c s : scores) {
            result.add(new Map<String, Object>{
                'id'             => s.Id,
                'objectApiName'  => s.Object_Name__c,
                'fieldApiName'   => s.Field__c,
                'completeness'   => s.Score__c,           // assume Score__c is percent (0-100)
                'analysisDate'   => s.Analysis_Date__c,
                'notes'          => s.Notes__c
            });
        }
        return result;
    }

    /**
     * Returns the average data quality score by object for a dashboard tile.
     *
     * @return List<Map<String, Object>>
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAvgDataQualityByObject() {
        List<AggregateResult> avgs = [
            SELECT Object_Name__c obj, AVG(Score__c) avgScore, COUNT(Id) cnt
            FROM Data_Quality_Score__c
            GROUP BY Object_Name__c
        ];
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (AggregateResult row : avgs) {
            result.add(new Map<String, Object>{
                'objectApiName' => (String) row.get('obj'),
                'avgScore'      => (Decimal) row.get('avgScore'),
                'totalFields'   => (Integer) row.get('cnt')
            });
        }
        return result;
    }

    /**
     * Returns top data quality issues for drill-down.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getDataQualityIssues(Integer scoreThreshold) {
        List<Data_Quality_Score__c> issues = [
            SELECT Id, Object_Name__c, Field__c, Score__c, Analysis_Date__c, Notes__c
            FROM Data_Quality_Score__c
            WHERE Score__c < :scoreThreshold
            ORDER BY Score__c ASC
            LIMIT 100
        ];
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (Data_Quality_Score__c s : issues) {
            result.add(new Map<String,Object>{
                'id'            => s.Id,
                'objectApiName' => s.Object_Name__c,
                'fieldApiName'  => s.Field__c,
                'score'         => s.Score__c,
                'analysisDate'  => s.Analysis_Date__c,
                'notes'         => s.Notes__c
            });
        }
        return result;
    }
}