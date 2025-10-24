/**
 * dsOrgHealthController
 * Main controller for Salesforce Org Health Monitoring application
 * Provides data to Lightning Web Components for org health metrics
 */
public with sharing class dsOrgHealthController {

    /**
     * Get current governor limits usage
     * @return Map of governor limit metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGovernorLimits() {
        Map<String, Object> limitsMap = new Map<String, Object>();

        try {
            limitsMap.put('soqlQueries', Limits.getQueries());
            limitsMap.put('soqlQueriesLimit', Limits.getLimitQueries());
            limitsMap.put('dmlStatements', Limits.getDMLStatements());
            limitsMap.put('dmlStatementsLimit', Limits.getLimitDMLStatements());
            limitsMap.put('cpuTime', Limits.getCpuTime());
            limitsMap.put('cpuTimeLimit', Limits.getLimitCpuTime());
            limitsMap.put('heapSize', Limits.getHeapSize());
            limitsMap.put('heapSizeLimit', Limits.getLimitHeapSize());
            limitsMap.put('soslQueries', Limits.getSoslQueries());
            limitsMap.put('soslQueriesLimit', Limits.getLimitSoslQueries());
            limitsMap.put('callouts', Limits.getCallouts());
            limitsMap.put('calloutsLimit', Limits.getLimitCallouts());
            limitsMap.put('emailInvocations', Limits.getEmailInvocations());
            limitsMap.put('emailInvocationsLimit', Limits.getLimitEmailInvocations());
            limitsMap.put('futureQueries', Limits.getFutureCalls());
            limitsMap.put('futureQueriesLimit', Limits.getLimitFutureCalls());
            limitsMap.put('queueableJobs', Limits.getQueueableJobs());
            limitsMap.put('queueableJobsLimit', Limits.getLimitQueueableJobs());

            // Calculate percentages
            limitsMap.put('soqlPercentage', calculatePercentage(
                Limits.getQueries(), Limits.getLimitQueries()));
            limitsMap.put('dmlPercentage', calculatePercentage(
                Limits.getDMLStatements(), Limits.getLimitDMLStatements()));
            limitsMap.put('cpuPercentage', calculatePercentage(
                Limits.getCpuTime(), Limits.getLimitCpuTime()));
            limitsMap.put('heapPercentage', calculatePercentage(
                Limits.getHeapSize(), Limits.getLimitHeapSize()));

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving governor limits: ' + e.getMessage());
        }

        return limitsMap;
    }

    /**
     * Get API usage statistics
     * @return Map of API usage metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAPIUsage() {
        Map<String, Object> apiUsage = new Map<String, Object>();

        try {
            // Query organization limits
            List<System.OrgLimit> apiLimits = new List<System.OrgLimit>();

            // Get all org limits
                Map<String, System.OrgLimit> orgLimitsMap = OrgLimits.getMap();

                // Iterate through the map to find limits related to 'API'
                for (String limitName : orgLimitsMap.keySet()) {
                    if (limitName.containsIgnoreCase('API')) {
                        apiLimits.add(orgLimitsMap.get(limitName));
                    }
                }

                // Now, 'apiLimits' contains the OrgLimit objects related to 'API'
                // You can then access their properties like Name, Limit, Remaining, Used
                Integer remainingLimit = 0;
                for (System.OrgLimit vlimit : apiLimits) {
                remainingLimit = vlimit.getLimit() - vlimit.getValue();
                apiUsage.put(vlimit.getName() + '_Limit', vlimit.getLimit());
                apiUsage.put(vlimit.getName() + '_Used', vlimit.getValue());
                apiUsage.put(vlimit.getName() + '_Remaining', remainingLimit);
                apiUsage.put(vlimit.getName() + '_Percentage', calculatePercentage(vlimit.getValue(), vlimit.getLimit()));
                remainingLimit = 0;    
                /*  System.debug('Limit Name: ' + limit.getName());
                    System.debug('Max Limit: ' + limit.getLimit());
                    System.debug('Remaining: ' + limit.getRemaining());
                    System.debug('Used: ' + limit.getValue()); 
                */  
                // Note: 'getValue()' returns the 'Used' value
                    
            }

            // Get hourly breakdown from custom object
            List<API_Usage_Log__c> hourlyLogs = [
                SELECT Hour__c, Call_Count__c 
                FROM API_Usage_Log__c 
                WHERE Date__c = TODAY 
                ORDER BY Hour__c ASC
                LIMIT 24
            ];

            List<Map<String, Object>> hourlyBreakdown = new List<Map<String, Object>>();
            for (API_Usage_Log__c log : hourlyLogs) {
                Map<String, Object> hourData = new Map<String, Object>();
                hourData.put('hour', log.Hour__c);
                hourData.put('count', log.Call_Count__c);
                hourlyBreakdown.add(hourData);
            }

            apiUsage.put('hourlyBreakdown', hourlyBreakdown);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving API usage: ' + e.getMessage());
        }

        return apiUsage;
    }

    /**
     * Get storage usage metrics
     * @return Map of storage metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStorageMetrics() {
        Map<String, Object> storageData = new Map<String, Object>();

        try {
            // Query organization storage limits
            List<System.OrgLimit> storageLimits = new List<System.OrgLimit>();

            // Get all org limits
                Map<String, System.OrgLimit> orgLimitsMap = OrgLimits.getMap();

                // Iterate through the map to find limits related to 'API'
                for (String limitName : orgLimitsMap.keySet()) {
                    if (limitName.containsIgnoreCase('Storage')) {
                        storageLimits.add(orgLimitsMap.get(limitName));
                    }
                }
            Integer remainingLimit = 0;    
            for (System.OrgLimit vlimit : storageLimits) {
                remainingLimit = vlimit.getLimit() - vlimit.getValue();
                storageData.put(vlimit.getName() + '_Limit', vlimit.getLimit());
                storageData.put(vlimit.getName() + '_Used', vlimit.getValue());
                storageData.put(vlimit.getName() + '_Remaining', remainingLimit);
                storageData.put(vlimit.getName() + '_Percentage', calculatePercentage(vlimit.getValue(), vlimit.getLimit()) );
            }

            // Get object-level breakdown
            List<Map<String, Object>> objectBreakdown = getObjectStorageBreakdown();
            storageData.put('objectBreakdown', objectBreakdown);

            // Get top users by storage
            List<Map<String, Object>> topUsers = getTopStorageUsers();
            storageData.put('topUsers', topUsers);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving storage metrics: ' + e.getMessage());
        }

        return storageData;
    }

    /**
     * Get user activity metrics
     * @return Map of user activity data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUserActivity() {
        Map<String, Object> activityData = new Map<String, Object>();

        try {
            // Query login history for last 7 days
            List<LoginHistory> recentLogins = [
                SELECT UserId, LoginTime, Status, Browser, Platform
                FROM LoginHistory 
                WHERE LoginTime = LAST_N_DAYS:7
                ORDER BY LoginTime DESC
                LIMIT 1000
            ];

            // Calculate active users
            Set<Id> activeUserIds = new Set<Id>();
            Integer successfulLogins = 0;
            Integer failedLogins = 0;

            for (LoginHistory login : recentLogins) {
                activeUserIds.add(login.UserId);
                if (login.Status == 'Success') {
                    successfulLogins++;
                } else {
                    failedLogins++;
                }
            }

            activityData.put('activeUsersCount', activeUserIds.size());
            activityData.put('successfulLogins', successfulLogins);
            activityData.put('failedLogins', failedLogins);
            activityData.put('successRate', calculatePercentage(successfulLogins, 
                                                               successfulLogins + failedLogins));

            // Get license information
            List<UserLicense> licenses = [SELECT Name, TotalLicenses, UsedLicenses 
                                         FROM UserLicense];
            activityData.put('licenses', licenses);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving user activity: ' + e.getMessage());
        }

        return activityData;
    }

    /**
     * Calculate percentage
     */
    private static Decimal calculatePercentage(Integer used, Integer total) {
        if (total == 0) return 0;
        return ((Decimal)used / (Decimal)total * 100).setScale(2);
    }

    /**
     * Get object-level storage breakdown
     */
    private static List<Map<String, Object>> getObjectStorageBreakdown() {
        List<Map<String, Object>> breakdown = new List<Map<String, Object>>();

        // Query from custom tracking object
        List<Storage_Snapshot__c> snapshots = [
            SELECT Object_Name__c, Total_Records__c, Data_Storage_Used__c
            FROM Storage_Snapshot__c
            WHERE Date__c = TODAY
            ORDER BY Data_Storage_Used__c DESC
            LIMIT 20
        ];

        for (Storage_Snapshot__c snapshot : snapshots) {
            Map<String, Object> objData = new Map<String, Object>();
            objData.put('objectName', snapshot.Object_Name__c);
            objData.put('recordCount', snapshot.Total_Records__c);
            objData.put('storageUsed', snapshot.Data_Storage_Used__c);
            breakdown.add(objData);
        }

        return breakdown;
    }

    /**
     * Get top users by storage consumption
     */
    private static List<Map<String, Object>> getTopStorageUsers() {
        List<Map<String, Object>> topUsers = new List<Map<String, Object>>();

        // Query users with high storage usage
        List<User> users = [
            SELECT Id, Name, Username, Profile.Name
            FROM User
            WHERE IsActive = true
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];

        for (User user : users) {
            Map<String, Object> userData = new Map<String, Object>();
            userData.put('userId', user.Id);
            userData.put('name', user.Name);
            userData.put('username', user.Username);
            userData.put('profile', user.Profile.Name);
            topUsers.add(userData);
        }

        return topUsers;
    }

    /**
     * Save org health metric snapshot
     * @param metricType Type of metric
     * @param metricValue Value of metric
     * @param status Status (Healthy, Warning, Critical)
     */
    @AuraEnabled
    public static void saveHealthMetric(String metricType, Decimal metricValue, String status) {
        try {
            Org_Health_Metric__c metric = new Org_Health_Metric__c(
                Metric_Type__c = metricType,
                Metric_Value__c = metricValue,
                Status__c = status,
                Recorded_Date__c = System.now().date()
            );
            insert metric;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving health metric: ' + e.getMessage());
        }
    }
}