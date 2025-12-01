public class DemoRealRecordGenerator {

    public static void generate() {

        // -------------------------
        // 1. Pull real record Ids
        // -------------------------
        List<Id> accIds  = new List<Id>();
        List<Id> conIds  = new List<Id>();
        List<Id> oppIds  = new List<Id>();
        List<Id> leadIds = new List<Id>();
        List<Id> caseIds = new List<Id>();

        for (Account a : [SELECT Id FROM Account LIMIT 50]) accIds.add(a.Id);
        for (Contact c : [SELECT Id FROM Contact LIMIT 50]) conIds.add(c.Id);
        for (Opportunity o : [SELECT Id FROM Opportunity LIMIT 50]) oppIds.add(o.Id);
        for (Lead l : [SELECT Id FROM Lead LIMIT 50]) leadIds.add(l.Id);
        for (Case cs : [SELECT Id FROM Case LIMIT 50]) caseIds.add(cs.Id);

        // -------------------------
        // 2. Build object → id list map
        // -------------------------
        Map<String, List<Id>> objectIds = new Map<String, List<Id>>();
        objectIds.put('Account', accIds);
        objectIds.put('Contact', conIds);
        objectIds.put('Opportunity', oppIds);
        objectIds.put('Lead', leadIds);
        objectIds.put('Case', caseIds);

        // -------------------------
        // 3. Metrics
        // -------------------------
        List<String> metrics = new List<String>{
            'MissingRequired',
            'InvalidEmails',
            'InvalidPhones',
            'DuplicateEmails',
            'DuplicatePhones',
            'DuplicateCheck'
        };

        Date today = Date.today();
        List<Data_Quality_Score__c> out = new List<Data_Quality_Score__c>();

        // -------------------------
        // 4. Create 50 demo rows
        // -------------------------
        Integer total = 0;
        List<String> objects = new List<String>(objectIds.keySet());

        while (total < 50) {

            // Random object
            String obj = objects[Math.mod(Math.abs(Crypto.getRandomInteger()), objects.size())];

            // If that object has no records, skip it
            if (objectIds.get(obj).isEmpty()) {
                continue;
            }

            // Random real record Id
            List<Id> ids = objectIds.get(obj);
            Id recordId = ids[Math.mod(Math.abs(Crypto.getRandomInteger()), ids.size())];

            // Random metric & score
            String metric = metrics[Math.mod(Math.abs(Crypto.getRandomInteger()), metrics.size())];
            Integer score = Math.mod(Math.abs(Crypto.getRandomInteger()), 10);
            String note = 'Demo note ' + Math.mod(Math.abs(Crypto.getRandomInteger()), 9999);

            out.add(new Data_Quality_Score__c(
                Object_Name__c   = obj,
                Field__c         = metric,
                Score__c         = score,
                Analysis_Date__c = today,
                Notes__c         = note,
                Record_Id__c     = recordId
            ));

            total++;
        }

        insert out;
        System.debug('Inserted ' + out.size() + ' demo rows with REAL record IDs.');
    }
}