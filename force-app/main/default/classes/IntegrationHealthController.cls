public with sharing class IntegrationHealthController {
    public class IntegrationStatusDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String integrationName;
        @AuraEnabled public String notes;
        @AuraEnabled public String status;
        @AuraEnabled public DateTime lastSuccess;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public Decimal responseTime;
        @AuraEnabled public String endpoint;
    }   // DTO for returning integration details to LWC.

    // getIntegrationStatus method
    @AuraEnabled(cacheable=true)
    public static List<IntegrationStatusDTO> getIntegrationStatus() {
        List<IntegrationStatusDTO> result = new List<IntegrationStatusDTO>();

        for (Integration_Statuses__c rec : [
            SELECT Id, Integration_Name__c, Status__c, Last_Success__c, Notes__c,
                   Error_Count__c, Response_Time__c, Integration_Endpoint__c
            FROM Integration_Statuses__c
            ORDER BY Integration_Name__c ASC
        ]) {

            IntegrationStatusDTO dto = new IntegrationStatusDTO();
            dto.id = rec.Id;
            dto.integrationName = rec.Integration_Name__c;
            dto.notes = rec.Notes__c;
            dto.status = rec.Status__c;
            dto.lastSuccess = rec.Last_Success__c;
            dto.errorCount = (Integer) rec.Error_Count__c;
            dto.responseTime = rec.Response_Time__c;
            dto.endpoint = rec.Integration_Endpoint__c;

            result.add(dto);
        }

        return result;
    }

    // getIntegrationSummary method
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getIntegrationSummary() {
        Integer total = 0;
        Integer healthy = 0;
        Integer errors = 0;

        for (AggregateResult ar : [
            SELECT Status__c status, COUNT(Id) cnt
            FROM Integration_Statuses__c
            GROUP BY Status__c
        ]) {
            Integer cnt = (Integer) ar.get('cnt');
            String status = (String) ar.get('status');
            total += cnt;
            if (status == 'Healthy' || status == 'Success') {
                healthy += cnt;
            } else if (status == 'Error' || status == 'Failed') {
                errors += cnt;
            }
        }
      return new Map<String, Integer>{
            'total' => total,
            'healthy' => healthy,
            'errors' => errors
        };
    }
    
    /*  Fetches data from Tooling API and creates Integration_Statuses__c record    */
    @AuraEnabled
    public static void fetchToolingDataAndCreateRecords() {
        // HTTP callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Tooling_API/services/data/v58.0/tooling/query/?q=' + 
                        EncodingUtil.urlEncode('SELECT Id, Name, Status FROM ApexClass', 'UTF-8'));
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            System.debug('Tooling API call failed: ' + res.getBody());
            return;
        }

        // Parse JSON
        Map<String, Object> jsonRes = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> records = (List<Object>) jsonRes.get('records');

        List<Integration_Statuses__c> toInsert = new List<Integration_Statuses__c>();

        for (Object rec : records) {
            Map<String, Object> r = (Map<String, Object>) rec;

            Integration_Statuses__c statusRec = new Integration_Statuses__c();
            statusRec.Integration_Name__c = (String) r.get('Name');
            statusRec.Status__c = (String) r.get('Status');
            statusRec.Last_Success__c = System.now();
            statusRec.Error_Count__c = 0;
            statusRec.Response_Time__c = 0;
            statusRec.Integration_Endpoint__c = 'ToolingAPI';

            toInsert.add(statusRec);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            System.debug('Created ' + toInsert.size() + ' Integration_Statuses__c records.');
        }
    } 

/*   Fetches data from Tooling API and creates Integration_Statuses__c record    */
  /*  @AuraEnabled
    public static void fetchMetadataAndCreateRecords() {
        List<Integration_Statuses__c> recordsToInsert = new List<Integration_Statuses__c>();

        // --- 1. Apex Classes ---
        List<ApexClass> apexClasses = [SELECT Id, Name, Status FROM ApexClass];
        for (ApexClass cls : apexClasses) {
            Integration_Statuses__c rec = new Integration_Statuses__c();
            rec.Integration_Name__c = cls.Name;
            rec.Status__c = cls.Status; // 'Active', 'Inactive', etc.
            rec.Last_Success__c = System.now();
            rec.Error_Count__c = 0;
            rec.Response_Time__c = 0;
            rec.Integration_Endpoint__c = 'ApexClass';
            recordsToInsert.add(rec);
        }

        // --- 2. Apex Triggers ---
        List<ApexTrigger> triggers = [SELECT Id, Name, Status FROM ApexTrigger];
        for (ApexTrigger trg : triggers) {
            Integration_Statuses__c rec = new Integration_Statuses__c();
            rec.Integration_Name__c = trg.Name;
            rec.Status__c = trg.Status; // 'Active', 'Inactive'
            rec.Last_Success__c = System.now();
            rec.Error_Count__c = 0;
            rec.Response_Time__c = 0;
            rec.Integration_Endpoint__c = 'ApexTrigger';
            recordsToInsert.add(rec);
        }
        
        // --- 3. Flow
        List<FlowDefinitionView> flows = [
        SELECT DurableId, ApiName, IsActive, ApiVersion, ActiveVersionId , VersionNumber 
        FROM FlowDefinitionView
    ];

    for (FlowDefinitionView flw : flows) {
        Integration_Statuses__c rec = new Integration_Statuses__c();
        rec.Integration_Name__c = flw.ApiName; 
        rec.Status__c = flw.IsActive ? 'Active' : 'Inactive';
        rec.Last_Success__c = System.now();
        rec.Error_Count__c = 0;
        rec.Response_Time__c = 0;
        rec.Integration_Endpoint__c = 'Flow';
        recordsToInsert.add(rec);
    }

         if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
            System.debug('Created ' + recordsToInsert.size() + ' Integration_Statuses__c records.');
        }
    }  */
 }
