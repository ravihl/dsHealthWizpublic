/**
 * @description
 *   AlertController
 *   Provides alert configuration and alert status data for LWC and dashboards.
 * @author
 *   dsHealthWiz Platform Team
 * @date
 *   October 2025
 */
public with sharing class AlertController {

    /**
     * Returns all active alert configurations.
     * Used for rendering alert lists and notifications.
     */
    @AuraEnabled(cacheable=true)
    public static List<Alert_Configuration__c> getActiveAlerts() {
        return [
            SELECT Id, Alert_Type__c, Threshold_Value__c, Severity__c, Notification_Recipients__c, Active__c
            FROM Alert_Configuration__c
            WHERE Active__c = TRUE
            ORDER BY Severity__c DESC, Alert_Type__c ASC
        ];
    }

    /**
     * Returns count of alerts grouped by severity.
     * Useful for displaying quick summary badges or KPI tiles.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getAlertCountBySeverity() {
        Map<String, Integer> alertCounts = new Map<String, Integer>{
            'Critical' => 0,
            'Warning' => 0,
            'Info' => 0
        };

        AggregateResult[] groupedResults = [
            SELECT Severity__c severity, COUNT(Id) cnt
            FROM Alert_Configuration__c
            WHERE Active__c = TRUE
            GROUP BY Severity__c
        ];

        for (AggregateResult ar : groupedResults) {
            String severity = (String) ar.get('severity');
            Integer count = ((Decimal) ar.get('cnt')).intValue();
            alertCounts.put(severity, count);
        }
        return alertCounts;
    }
}