public with sharing class StorageAnalyzerController {
    @AuraEnabled
    public static void captureTop10DataStorageUsage() {
        System.enqueueJob(new StorageUsageJob());
    }


    public class StorageUsageJob implements Queueable {
        public void execute(QueueableContext ctx) {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            List<Storage_Snapshot__c> tempSnapshots = new List<Storage_Snapshot__c>();
            Datetime nowTime = System.now();
            Decimal estimatedSizePerRecordKB = 2;

            Integer queryCount = 0;

            for (String objName : gd.keySet()) {
                // Stop early to stay within SOQL governor limits
                if (queryCount >= 90) break;
                try {
                    Schema.DescribeSObjectResult describe = gd.get(objName).getDescribe();

                    
                    if (!describe.isQueryable() || !describe.isAccessible()) continue;

                    Integer recordCount = (Integer) Database.countQuery('SELECT COUNT() FROM ' + objName);
                    Decimal usedKB = recordCount * estimatedSizePerRecordKB;

                    tempSnapshots.add(new Storage_Snapshot__c(
                        Object_Name__c = objName,
                        Record_Count__c = recordCount,
                        Data_Storage_Used__c = usedKB,
                        Storage_Used_Percentage__c = 0,
                        Date__c = nowTime.date()
                    ));
                    queryCount++;
                } catch (Exception e) {
                    System.debug('Skipping ' + objName + ': ' + e.getMessage());
                }
            }

        
            tempSnapshots.sort(new StorageAnalyzerController.StorageComparator());
            
            List<Storage_Snapshot__c> toInsert = new List<Storage_Snapshot__c>();
Integer limitCount = Math.min(10, tempSnapshots.size());
for (Integer i = 0; i < limitCount; i++) {
    toInsert.add(tempSnapshots[i]);
}

            if (!toInsert.isEmpty()) {
                insert toInsert;
            }

            System.debug('✅ Inserted ' + toInsert.size() + ' storage snapshot records.');
        }
    }

    // sorting by Data_Storage_Used__c descending
    public class StorageComparator implements Comparator<Storage_Snapshot__c> {
        public Integer compare(Storage_Snapshot__c a, Storage_Snapshot__c b) {
            if (a.Data_Storage_Used__c == null) return 1;
            if (b.Data_Storage_Used__c == null) return -1;

            if (b.Data_Storage_Used__c > a.Data_Storage_Used__c) return 1;
            else if (b.Data_Storage_Used__c < a.Data_Storage_Used__c) return -1;
            else return 0;
        }
    }

    
    @AuraEnabled(cacheable=true)
    public static List<Storage_Snapshot__c> getLatestDataStorageUsage() {
        return [
            SELECT Id,
                   Object_Name__c,
                   Record_Count__c,
                   Data_Storage_Used__c,
                   Storage_Used_Percentage__c,
                   Date__c
            FROM Storage_Snapshot__c
            ORDER BY Data_Storage_Used__c DESC
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOverallDataStorageUsage() {
        Decimal orgLimitMB = 5000; // Example
        Decimal totalUsedKB = 0;

        for (AggregateResult ar : [SELECT SUM(Data_Storage_Used__c) total FROM Storage_Snapshot__c]) {
            totalUsedKB = (Decimal) ar.get('total');
        }

        Decimal totalUsedMB = totalUsedKB / 1024;
        Decimal percentUsed = (orgLimitMB > 0) ? ((totalUsedMB / orgLimitMB) * 100) : 0;

        return new Map<String, Object>{
            'totalUsedMB' => totalUsedMB,
            'orgLimitMB' => orgLimitMB,
            'percentUsed' => percentUsed
        };
    }
    


public class StorageInfo {
    @AuraEnabled public String storageType { get; set; }
    @AuraEnabled public String limitValue { get; set; }
    @AuraEnabled public String used { get; set; }
    @AuraEnabled public String percentUsed { get; set; }

    public StorageInfo(String storageType, String limitValue, String used, String percentUsed) {
        this.storageType = storageType;
        this.limitValue = limitValue;
        this.used = used;
        this.percentUsed = percentUsed;
    }
}

}
