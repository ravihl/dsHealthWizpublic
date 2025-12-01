public with sharing class DataQualityController {
    @AuraEnabled(cacheable=true)
    public static List<Data_Quality_Score__c> getDataQualityScores() {
        return [
            SELECT Id,
                   Object_Name__c,
                   Field__c,
                   Record_Count__c,
                   Analysis_Date__c,
                   Notes__c
            FROM Data_Quality_Score__c
            ORDER BY Object_Name__c, Field__c
        ];
    }
}