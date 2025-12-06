global class Dataqualityscheduler implements Schedulable {
    
    /**
    * Schedules the Data Quality checks dynamically.
    * @param scheduleType 'DAILY', 'WEEKLY', 'MONTHLY', 'SPECIFIC_DATE'
    * @param dateOrDayValue Day-of-week (1–7), day-of-month (1–31), or YYYY-MM-DD
    * @param timeHour Hour 0–23
    * @param timeMinute Minute 0–59
    */
    global static void scheduleDataQualityChecks(String scheduleType, String dateOrDayValue, Integer timeHour, Integer timeMinute) {
        String jobName = 'DataQuality_ScheduledJob_' + scheduleType;
        String cronExpression = '';
        
        String minute = String.valueOf(timeMinute).leftPad(2, '0');
        String hour = String.valueOf(timeHour).leftPad(2, '0');
        
        if (scheduleType == 'DAILY') {
            cronExpression = '0 ' + minute + ' ' + hour + ' * * ?';
            
        } else if (scheduleType == 'WEEKLY') {
            cronExpression = '0 ' + minute + ' ' + hour + ' ? * ' + dateOrDayValue;
            
        } else if (scheduleType == 'MONTHLY') {
            cronExpression = '0 ' + minute + ' ' + hour + ' ' + dateOrDayValue + ' * ?';
            
        } else if (scheduleType == 'SPECIFIC_DATE') {
            Date targetDate = Date.valueOf(dateOrDayValue);
            String day = String.valueOf(targetDate.day());
            String month = String.valueOf(targetDate.month());
            String year = String.valueOf(targetDate.year());
            cronExpression = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
            
        } else {
            System.debug('Invalid scheduleType provided.');
            return;
        }
        
        try {
            System.schedule(jobName, cronExpression, new Dataqualityscheduler());
        } catch (Exception e) {
            System.debug('Error scheduling job: ' + e.getMessage());
        }
    }
    
    // ========================================================================================================================
    // MAIN EXECUTION
    // ========================================================================================================================
    
    global void execute(SchedulableContext sc) {
        runSnapshot();
    }
    
    // ========================================================================================================================
    // APEX METHOD CALLED FROM LWC & SCHEDULER
    // ========================================================================================================================
    
    @AuraEnabled
    global static Data_Quality_Snapshot__c runSnapshot() {
        
        // 1. Create the Snapshot Parent Record
        // Do not set Name, auto-number will handle it
        Data_Quality_Snapshot__c snapshot = new Data_Quality_Snapshot__c(
            Snapshot_Date__c = System.now()
        );
        
        insert snapshot;       
        Id snapshotId = snapshot.Id;
        
        // 2. Fetch metadata settings
        List<Data_Quality_Score__c> scoreList = new List<Data_Quality_Score__c>();
        
        String query = 'SELECT Id, CheckType__c, EmailFieldAPINames__c, FieldName__c, ' +
            'Object_API_Name__c, PhonefieldAPIName__c, Required_Field_Api_Name__c ' +
            'FROM Data_Quality_Config__mdt';
        List<Data_Quality_Config__mdt> metadata = Database.query(query);
        
        Map<String, List<String>> requiredMap = new Map<String, List<String>>();
        Map<String, List<String>> emailMap = new Map<String, List<String>>();
        Map<String, List<String>> phoneMap = new Map<String, List<String>>();
        Set<String> emailPhoneObjects = new Set<String>();
        
        // 3. Process metadata
        for (Data_Quality_Config__mdt rec : metadata) {
            
            if (rec.CheckType__c == 'searchForDuplicate') {
                scoreList.add(DataQualityValidator.searchForDuplicate(rec.Object_API_Name__c, rec.FieldName__c));
            }
            
            if (rec.CheckType__c == 'runReqFieldChecks') {
                if (!requiredMap.containsKey(rec.Object_API_Name__c)) {
                    requiredMap.put(rec.Object_API_Name__c, new List<String>());
                }
                requiredMap.get(rec.Object_API_Name__c).add(rec.Required_Field_Api_Name__c);
            }
            
            if (rec.CheckType__c == 'runEmailandPhoneChecks') {
                emailPhoneObjects.add(rec.Object_API_Name__c);
                
                if (!emailMap.containsKey(rec.Object_API_Name__c)) {
                    emailMap.put(rec.Object_API_Name__c, new List<String>());
                }
                emailMap.get(rec.Object_API_Name__c).add(rec.EmailFieldAPINames__c);
                
                if (!phoneMap.containsKey(rec.Object_API_Name__c)) {
                    phoneMap.put(rec.Object_API_Name__c, new List<String>());
                }
                phoneMap.get(rec.Object_API_Name__c).add(rec.PhonefieldAPIName__c);
            }
        }
        
        // 4. Required field checks
        for (String objName : requiredMap.keySet()) {
            scoreList.addAll(DataQualityValidator.runReqFieldChecks(objName, requiredMap.get(objName)));
        }
        
        // 5. Email + phone checks
        for (String objName : emailPhoneObjects) {
            scoreList.addAll(DataQualityValidator.runEmailandPhoneChecks(
                objName,
                emailMap.get(objName),
                phoneMap.get(objName)
            ));
        }
        
        // 6. Link Score Records to Snapshot
        if (scoreList.size() > 0) {
            for (Data_Quality_Score__c score : scoreList) {
                score.Snapshot__c = snapshotId; // lookup field
            }
            insert scoreList;
        }
        
        return snapshot;
    }
}