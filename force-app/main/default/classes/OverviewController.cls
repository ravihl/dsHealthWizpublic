/**
 * @description
 *   Provides high-level overview statistics for the org health dashboard.
 *   Returns KPI data for executive summary tiles.
 * @author
 *   dsHealthWiz Platform Team
 * @date
 *   October 2025
 */
public with sharing class OverviewController {

    /**
     * Returns overview statistics for the main dashboard summary.
     * @return Map<String, Object> containing key metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOverviewStats() {
        Map<String, Object> stats = new Map<String, Object>();
        
        try {
            // Get latest API usage percentage
            Decimal apiUsagePct = getLatestAPIUsage();
            
            // Get latest storage usage percentage  
            Decimal storageUsedPct = getLatestStorageUsage();
            
            // Calculate overall health score
            Decimal healthScore = calculateHealthScore();
            
            // Get active alerts count
            Integer activeAlertsCount = getActiveAlertsCount();
            
            // Get integration status summary
            Map<String, Integer> integrationSummary = getIntegrationSummary();
            
            // Build result map
            stats.put('apiUsagePct', apiUsagePct);
            stats.put('storageUsedPct', storageUsedPct);
            stats.put('healthScore', healthScore);
            stats.put('activeAlerts', activeAlertsCount);
            stats.put('totalIntegrations', integrationSummary.get('total'));
            stats.put('healthyIntegrations', integrationSummary.get('healthy'));
            stats.put('lastUpdated', System.now());
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving overview stats: ' + e.getMessage());
        }
    }
    
    /**
     * Get the latest API usage percentage from API_Usage_Log__c
     */
    private static Decimal getLatestAPIUsage() {
        List<API_Usage_Log__c> apiLogs = [
            SELECT Percentage_Used__c
            FROM API_Usage_Log__c 
            WHERE Date__c = TODAY 
            ORDER BY Hour__c DESC 
            LIMIT 1
        ];
        
        return !apiLogs.isEmpty() ? apiLogs[0].Percentage_Used__c: 0;
    }
    
    /**
     * Get the latest storage usage percentage from Storage_Snapshot__c
     */
    private static Decimal getLatestStorageUsage() {
        List<Storage_Snapshot__c> storageSnapshots = [
            SELECT Storage_Used_Percentage__c
            FROM Storage_Snapshot__c 
            WHERE Date__c = TODAY 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        return !storageSnapshots.isEmpty() ? storageSnapshots[0].Storage_Used_Percentage__c : 0;
    }
    
    /**
     * Calculate overall health score based on various metrics
     */
    private static Decimal calculateHealthScore() {
        // Get recent health metrics
        List<Org_Health_Metric__c> metrics = [
            SELECT Metric_Type__c, Metric_Value__c, Status__c
            FROM Org_Health_Metric__c
            WHERE Recorded_Date__c = LAST_N_DAYS:1
        ];
        
        if (metrics.isEmpty()) {
            return 85; // Default score when no data
        }
        
        Integer totalScore = 0;
        Integer count = 0;
        
        for (Org_Health_Metric__c metric : metrics) {
            Integer score = 100; // Start with perfect score
            
            // Adjust score based on status
            if (metric.Status__c == 'Warning') {
                score = 75;
            } else if (metric.Status__c == 'Critical') {
                score = 25;
            }
            
            totalScore += score;
            count++;
        }
        
        return count > 0 ? Decimal.valueOf(totalScore) / count : 85;
    }
    
    /**
     * Get count of active alerts
     */
    private static Integer getActiveAlertsCount() {
        return [
            SELECT COUNT() 
            FROM Alert_Configuration__c 
            WHERE Active__c = true
        ];
    }
    
    /**
     * Get integration status summary
     */
    private static Map<String, Integer> getIntegrationSummary() {
        List<Integration_Status__c> integrations = [
            SELECT Status__c 
            FROM Integration_Status__c
        ];
        
        Integer total = integrations.size();
        Integer healthy = 0;
        
        for (Integration_Status__c integration : integrations) {
            if (integration.Status__c == 'Healthy' || integration.Status__c == 'Success') {
                healthy++;
            }
        }
        
        return new Map<String, Integer>{
            'total' => total,
            'healthy' => healthy
        };
    }
    
    /**
     * Get recent performance trend data for mini charts
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPerformanceTrend() {
        List<Org_Health_Metric__c> metrics = [
            SELECT Metric_Value__c, Recorded_Date__c
            FROM Org_Health_Metric__c
            WHERE Metric_Type__c = 'Performance - EPT'
            AND Recorded_Date__c = LAST_N_DAYS:7
            ORDER BY Recorded_Date__c ASC
        ];
        
        List<Map<String, Object>> trend = new List<Map<String, Object>>();
        for (Org_Health_Metric__c metric : metrics) {
            trend.add(new Map<String, Object>{
                'date' => metric.Recorded_Date__c,
                'value' => metric.Metric_Value__c
            });
        }
        
        return trend;
    }
}