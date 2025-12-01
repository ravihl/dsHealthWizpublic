public class DataQualityChecker {
    
    //Method for Processing Records of Sobject 
    public static void runChecks(String objectApiName,List<String> requiredFieldsApiname,List<String> emailFieldsApiname,List<String> phoneFieldsApiname,Integer limitSize) {
        
        List<Data_Quality_Score__c> dqRecords = new List<Data_Quality_Score__c>();
        Set<String> emailList = new Set<String>();
        Set<String> phoneList = new Set<String>();
        Map<String,Integer> dupesmapObj = new Map<String,Integer>();
        List<Sobject> dupesObjrecordsToInsert = new List<Sobject>(); 
        Map<String,Integer> dupesmapObjphn =  new Map<String,Integer>();
        List<Sobject> dupesphnObjrecordsToInsert = new List<Sobject>(); 
         
        String soql = 'SELECT Id';
        for (String f : requiredFieldsApiname) soql += ', ' + f;
        for (String f : emailFieldsApiname) soql += ', ' + f;
        for (String f : phoneFieldsApiname) soql += ', ' + f;
        soql += ' FROM ' + objectApiName + ' LIMIT ' + limitSize;
        
        List<SObject> records = Database.query(soql);
        
        // Patterns
        Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        Pattern phonePattern = Pattern.compile('^[0-9()+\\-\\s]*$');
        
        for (SObject rec : records) {
            String fieldsList; 
            String Notes; 
            Integer fieldCount;
            // --- Required Field Check --- for all objects
            for (String rf : requiredFieldsApiname) {
                if(fieldExists(objectApiName,rf)){
                    Object val = rec.get(rf);
                    if (val == null || String.valueOf(val).trim() == '') {
                        fieldsList = fieldsList + rf +',';
                    }
                }
            }
            if(fieldsList!=null){
                notes = fieldsList +'Are empty fields for record'+rec.Id;
                dqRecords.add(createDataScore(objectApiName,fieldsList,notes,rec.id));
            }
            if(objectApiName =='Lead' || objectApiName =='Contact' ){
                
                //Email check
                for (String email : emailFieldsApiname) {
                    if(fieldExists(objectApiName,email)){
                        String emailVal = (String) rec.get(email);
                        if(emailVal!=null)
                            emailList.add(emailVal);
                        if (emailVal != null && !emailPattern.matcher(emailVal).matches()) {
                            notes = 'Not a valid email ' + emailVal + 'on Record Id '+rec.id;
                            dqRecords.add(createDataScore(objectApiName,email,notes,rec.id)); 
                        }
                    }
                }
                // --- Phone Format Check Lead ,Contact---
                for (String phn : phoneFieldsApiName) {
                    if(fieldExists(objectApiName,phn)){
                        String phoneVal = (String) rec.get(phn);
                        if(phoneVal!=null)
                            phoneList.add(phoneVal);
                        if (phoneVal != null && !phonePattern.matcher(phoneVal).matches()) {
                            notes = 'Not a valid Phone ' + phoneVal + 'on Record Id '+rec.id;
                            dqRecords.add(createDataScore(objectApiName,phn,notes,rec.id)); 
                        }
                    }
                }
                
                
            }
            
        }
        //logic to process the duplicate email for Contact lead
        if(emailList.size()>0){
            String dupquery = 'SELECT Email, COUNT(Id) EmailCount ' +'FROM ' + objectApiName +'  WHERE Email IN :emailList   GROUP BY Email HAVING COUNT(Id) > 1';
            List<AggregateResult> dupesObjrecords = Database.query(dupquery);
            
            for(AggregateResult ar : dupesObjrecords){
                if(ar.get('Email') !=null && ar.get('EmailCount') !=null)
                    dupesmapObj.put(String.valueOf(ar.get('Email')),Integer.valueOf(ar.get('EmailCount')));
            }
            
            if(dupesmapObj.size()>0){
                Set<String> setString =dupesmapObj.keySet();
                String getdupesRecord = 'Select id,name,Email FROM ' + objectApiName +'  WHERE Email IN :setString';
                dupesObjrecordsToInsert = Database.query(getdupesRecord);
            }
            
            
            for(Sobject sobj:dupesObjrecordsToInsert){
                dqRecords.add(createDataScore(objectApiName,'Email','Email is duplicate',String.valueOf(sobj.get('id'))));
            } 
        } 
        //logic to process the duplicate phone for Contact lead
        if(phoneList.size()>0){
            String dupquery = 'SELECT Phone, COUNT(Id) PhoneCount ' +'FROM ' + objectApiName +'  WHERE Phone IN :PhoneList   GROUP BY phone HAVING COUNT(Id) > 1';
            List<AggregateResult> dupesObjrecords = Database.query(dupquery);
            
            for(AggregateResult ar : dupesObjrecords){
                if(ar.get('Phone') !=null && ar.get('PhoneCount') !=null)
                    dupesmapObjphn.put(String.valueOf(ar.get('Phone')),Integer.valueOf(ar.get('PhoneCount')));
            }
            
            if(dupesmapObjphn.size()>0){
                Set<String> setString =dupesmapObjphn.keySet();
                String getphndupesRecord = 'Select id,name,Phone FROM ' + objectApiName +'  WHERE Phone IN :setString';
                dupesphnObjrecordsToInsert = Database.query(getphndupesRecord);
            }
            
            
            for(Sobject sobj:dupesphnObjrecordsToInsert){
                dqRecords.add(createDataScore(objectApiName,'Phone','Phone is duplicate',String.valueOf(sobj.get('id'))));
            } 
        }
        if(dqRecords.size()>0){
            insert dqRecords;
        }
    }
    
    public static Boolean fieldExists(String objectApiName ,String fieldApiName){
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        return fieldsMap.containsKey(fieldApiName);
    }
    
    public static Data_Quality_Score__c createDataScore (String ObjectName,String FieldName,String Notes,String RecordId){
        Data_Quality_Score__c dsq = new Data_Quality_Score__c();
        dsq.Name ='DATA QUALITY';
        dsq.Record_Id__c = RecordId;
        dsq.Object_Name__c =ObjectName;
        dsq.Field__c =FieldName;
        dsq.Score__c= 10;
        dsq.Analysis_Date__c =system.today();
        dsq.Notes__c =notes;
        
        return dsq;
    }
    
}