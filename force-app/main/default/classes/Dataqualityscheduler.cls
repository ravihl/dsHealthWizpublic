global class Dataqualityscheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        List<Data_Quality_Score__c> lsdqs =  new List<Data_Quality_Score__c>();
        String query = 'SELECT Id, CheckType__c, EmailFieldAPINames__c,FieldName__c,Object_API_Name__c,PhonefieldAPIName__c,Required_Field_Api_Name__c FROM Data_Quality_Config__mdt';
        List<Data_Quality_Config__mdt> records = Database.query(query);
        Map<String,List<String>> objVsreqFieldsMap = new Map<String,List<String>>();
        Map<String,List<String>> ObjVsEmailMap = new Map<String,List<String>>();
        Map<String,List<String>> objVsphnMap = new Map<String,List<String>>();
        Set<String> objectsName = new Set<String>();
        for(Data_Quality_Config__mdt mrec:records){
           if(mrec.CheckType__c == 'searchForDuplicate'){
               lsdqs.add(DataQualityValidator.searchForDuplicate(mrec.Object_API_Name__c,mrec.FieldName__c));
            }
            if(mrec.CheckType__c == 'runReqFieldChecks'){
                if(!objVsreqFieldsMap.containsKey(mrec.Object_API_Name__c)){
                    objVsreqFieldsMap.put(mrec.Object_API_Name__c,new List<String>());
                }
                objVsreqFieldsMap.get(mrec.Object_API_Name__c).add(mrec.Required_Field_Api_Name__c);
            }
            if(mrec.CheckType__c == 'runEmailandPhoneChecks'){
                objectsName.add(mrec.Object_API_Name__c);
                 if(!ObjVsEmailMap.containsKey(mrec.Object_API_Name__c)){
                    ObjVsEmailMap.put(mrec.Object_API_Name__c,new List<String>());
                }
                ObjVsEmailMap.get(mrec.Object_API_Name__c).add(mrec.EmailFieldAPINames__c);   
                
                if(!objVsphnMap.containsKey(mrec.Object_API_Name__c)){
                    objVsphnMap.put(mrec.Object_API_Name__c,new List<String>());
                }
                objVsphnMap.get(mrec.Object_API_Name__c).add(mrec.PhonefieldAPIName__c); 
                
            }
        }
        
        if(objVsreqFieldsMap.Size()>0){
            for(String objApiname:objVsreqFieldsMap.keySet()){
                if(objVsreqFieldsMap.containsKey(objApiname))
                    lsdqs.addall(DataQualityValidator.runReqFieldChecks(objApiname,objVsreqFieldsMap.get(objApiname)));
            }
        }
        for(String objapiname:objectsName){
          lsdqs.addall( DataQualityValidator.runEmailandPhoneChecks(objapiname,ObjVsEmailMap.get(objapiname),objVsphnMap.get(objapiname)));
        }
        if(lsdqs.size()>0){
           insert lsdqs; 
        }
    }
       
}