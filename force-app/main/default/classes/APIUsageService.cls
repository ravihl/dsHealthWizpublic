/**
 * @description
 *   APIUsageService
 *   Enterprise analytics for API usage reporting: daily, hourly, and per-integration.
 */
public with sharing class APIUsageService {

    /**
     * Get past 24 hours' API usage (one row per hour).
     * For trend charts and monitoring.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getHourlyApiUsage() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<API_Usage_Log__c> logs = [
            SELECT Id, Date__c, Hour__c, Total_Calls_Used__c, Total_Org_Limit__c, Percentage_Used__c
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            ORDER BY Hour__c ASC
        ];
        for (API_Usage_Log__c log : logs) {
            result.add(new Map<String, Object>{
                'id' => log.Id,
                'date' => log.Date__c,
                'hour' => log.Hour__c,
                'callsUsed' => log.Total_Calls_Used__c,
                'orgLimit' => log.Total_Org_Limit__c,
                'usagePct' => log.Percentage_Used__c
            });
        }
        return result;
    }

    /**
     * Get hourly API usage for each integration/client for today.
     * Produces a list suitable for line/bar charts (grouped by client).
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getHourlyApiUsageByIntegration() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<AggregateResult> aggs = [
            SELECT API_Client_Name__c client, Hour__c hour, SUM(Calls_Used__c) calls
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            GROUP BY API_Client_Name__c, Hour__c
            ORDER BY API_Client_Name__c ASC, Hour__c ASC
        ];
        for (AggregateResult ar : aggs) {
            result.add(new Map<String, Object>{
                'client' => (String)ar.get('client'),
                'hour' => (Integer)ar.get('hour'),
                'calls' => (Decimal)ar.get('calls')
            });
        }
        return result;
    }

    /**
     * Get today's total API usage summary per integration/client.
     * For pie charts, leaderboards, tables.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTodayApiUsageByIntegration() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<AggregateResult> grouped = [
            SELECT API_Client_Name__c client, SUM(Calls_Used__c) calls
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            GROUP BY API_Client_Name__c
            ORDER BY SUM(Calls_Used__c) DESC
        ];
        for (AggregateResult ag : grouped) {
            result.add(new Map<String, Object>{
                'client' => (String)ag.get('client'),
                'calls' => (Decimal)ag.get('calls')
            });
        }
        return result;
    }

    /**
     * Get today's summary for dashboard KPI display.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTodayApiSummary() {
        AggregateResult ar = [
            SELECT SUM(Total_Calls_Used__c) used,
                   SUM(Total_Org_Limit__c) vlimit
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
        ];
        Decimal used = (Decimal) ar.get('used');
        Decimal vlimit = (Decimal) ar.get('vlimit');
        Decimal pct = (vlimit > 0 ? used / vlimit * 100 : 0);
        Map<String, Object> summary = new Map<String, Object>();
        summary.put('callsUsed', used);
        summary.put('orgLimit', vlimit);
        summary.put('usagePct', pct.setScale(2));
        return summary;
    }

    // Retain getDailyApiTrends from previous version if you want 30-day history!
}
