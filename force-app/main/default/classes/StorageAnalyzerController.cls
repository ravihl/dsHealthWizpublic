/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class StorageAnalyzerController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getLatestStorageSnapshots() {
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        List<Storage_Snapshot__c> snapshots = [
            SELECT Id, Object_Name__c, Date__c, Storage_Used_Percentage__c, File_Storage_Used__c, Data_Storage_Used__c
            FROM Storage_Snapshot__c 
            WHERE Date__c = TODAY 
            ORDER BY CreatedDate DESC 
            LIMIT 7
        ];

        for (Storage_Snapshot__c snap : snapshots) {
            results.add(new Map<String, Object>{
                'id'        => snap.Id,
                'objectName'=> snap.Object_Name__c,
                'date'      => snap.Date__c,
                'usedPct'   => snap.Storage_Used_Percentage__c,
                'FileStorage'    => snap.File_Storage_Used__c,
                'DataStorage'    => snap.Data_Storage_Used__c
            });
        }
        return results;
    }
}
