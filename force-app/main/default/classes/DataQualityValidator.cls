public class DataQualityValidator {
    public static List<Data_Quality_Score__c>  runReqFieldChecks(String objectApiName,List<String> requiredFieldsApiname) {
        
        List<String> conditions = new List<String>();
        Integer fieldCountNull; 
        Map<String,Integer> mapCount = new Map<String,Integer>();
        List<Data_Quality_Score__c> dataQualityScore= new List<Data_Quality_Score__c>();
            
        String fields = 'Id,' + String.join(requiredFieldsApiname, ',');
        String query = 'SELECT ' + fields + ' FROM ' + objectApiName;
        
        List<SObject> records = Database.query(query);
        
        for (SObject r : records) {
            for (String f : requiredFieldsApiName) {
                if (r.get(f) == null) {
                    if(!mapCount.containsKey(f))
                        mapCount.put(f,0);
                    mapCount.put(f,mapCount.get(f)+1);
                }
            }
        }
        if(mapCount.size()>0){
            for(String fieldApiNAme:mapCount.keySet()){
                dataQualityScore.add(createDataScore(objectApiName,fieldApiNAme,'Required field '+fieldApiNAme+' Missing',mapCount.get(fieldApiNAme)));   
            }
        }
        if(dataQualityScore.size()>0){
            return dataQualityScore;
        }
          return null;  
    }
    
    public static List<Data_Quality_Score__c> runEmailandPhoneChecks(String objectApiName, List<String> emailFieldsApiname,List<String> phoneFieldsApiName ) {
        
        Set<String> emailList = new Set<String>();
        Set<String> phoneList = new Set<String>();
        Map<String,Integer> mapEmailCount = new Map<String,Integer>();
        Map<String,Integer> mapPhoneCount = new Map<String,Integer>();
        List<Data_Quality_Score__c> lsdqs = new List<Data_Quality_Score__c>();
        Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        Pattern phonePattern = Pattern.compile('^[0-9()+\\-\\s]*$');
        List<String> allFields = new List<String>();
        allFields.addAll(emailFieldsApiname);
        allFields.addAll(phoneFieldsApiName);
system.debug(allFields);
        // If no fields exist (example: Opportunity has no email/phone) → SELECT Id only
        String selectFields =  String.join(allFields, ',');
        String soql = 'SELECT id,' + selectFields + ' FROM ' + objectApiName;
        
        List<Sobject> records=  Database.query(soql);
        for(SObject rec:records){
            for (String email : emailFieldsApiname) {
                String emailVal = (String) rec.get(email);
                if (emailVal != null && !emailPattern.matcher(emailVal).matches()) {
                    if(!mapEmailCount.containsKey(email))
                        mapEmailCount.put(email,0);
                    mapEmailCount.put(email,mapEmailCount.get(email)+1);
                }
            }
            
            // --- Phone Format Check Lead ,Contact---
            for (String phn : phoneFieldsApiName) {
                String phoneVal = (String) rec.get(phn);
                if (phoneVal != null && !phonePattern.matcher(phoneVal).matches()) {
                    if(!mapPhoneCount.containsKey(phn)){
                        mapPhoneCount.put(phn,0);
                        
                    }
                    mapPhoneCount.put(phn,mapPhoneCount.get(phn)+1);
                    
                }
            }
        }
        for(String phnapiname:mapPhoneCount.keySet()){
            lsdqs.add(createDataScore(objectApiName,phnapiname,'Invalid '+phnapiname,mapPhoneCount.get(phnapiname))); 
        }
        for(String emailApiname:mapEmailCount.keySet()){
            lsdqs.add(createDataScore(objectApiName,emailApiname,'Invalid '+emailApiname,mapEmailCount.get(emailApiName))); 
        }
        if(lsdqs.size()>0){
            return lsdqs;
        }
        return null;
    }
    
    public static Data_Quality_Score__c searchForDuplicate(String objectApiName,String fieldApiname){
        
        Integer dupCount =0;
        
        String dupquery = 'SELECT '+ fieldApiname+', COUNT(Id) unitCount ' +'FROM ' + objectApiName +'   GROUP BY '+fieldApiname+' HAVING COUNT(Id) > 1';
        List<AggregateResult> dupesObjrecords = Database.query(dupquery);
        for(AggregateResult ag:dupesObjrecords){
            dupCount += (Integer) ag.get('unitCount');
        }
        if( dupCount>0){
            return createDataScore(objectApiName,fieldApiname,fieldApiname+' is Duplicate',dupCount);
        }
        return null;
    }
    public static Data_Quality_Score__c createDataScore (String ObjectName,String FieldName,String Notes,Integer Score){
        Data_Quality_Score__c dsq = new Data_Quality_Score__c();
        dsq.Name ='DATA QUALITY';
        dsq.Object_Name__c =ObjectName;
        dsq.Field__c =FieldName;
        dsq.Record_Count__c= Score;
        dsq.Analysis_Date__c =system.today();
        dsq.Notes__c =notes;
        
        return dsq;
    }
}