/**
* @File Name : DataQualityMetricsService .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 25, 2025 |   | Initial Version
**/

public with sharing class DataQualityMetricsService {

    public class DataQualityMetricDTO {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public Integer missingRequired;
        @AuraEnabled public Integer invalidEmails;
        @AuraEnabled public Integer invalidPhones;
        @AuraEnabled public Integer duplicateEmails;
        @AuraEnabled public Integer duplicatePhones;
        @AuraEnabled public Date analysisDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataQualityMetricDTO> getAggregatedMetrics() {

        List<String> objects = new List<String>{ 'Account', 'Opportunity','Lead', 'Contact' };

        List<DataQualityMetricDTO> result = new List<DataQualityMetricDTO>();

        for (String obj : objects) {
            result.add(getMetricsForObject(obj));
        }

        return result;
    }


    private static DataQualityMetricDTO getMetricsForObject(String objectApiName) {

        DataQualityMetricDTO dto = new DataQualityMetricDTO();
        dto.objectApiName = objectApiName;
        dto.analysisDate = Date.today();

        // ==== REQUIRED FIELD DEFINITIONS ====
        Map<String, List<String>> requiredFields = new Map<String, List<String>>{
            'Lead'        => new List<String>{ 'LastName' },
            'Contact'     => new List<String>{ 'LastName' },
            'Opportunity' => new List<String>{ 'Name', 'CloseDate', 'StageName' },
            'Account'     => new List<String>{ 'Name' }
        };

        // ==== EMAIL FIELDS ====
        Map<String, List<String>> emailFields = new Map<String, List<String>>{
            'Lead'    => new List<String>{ 'Email' },
            'Contact' => new List<String>{ 'Email' }
        };

        // ==== PHONE FIELDS ====
        Map<String, List<String>> phoneFields = new Map<String, List<String>>{
            'Lead'    => new List<String>{ 'Phone' },
            'Contact' => new List<String>{ 'Phone' },
            'Account' => new List<String>{ 'Phone' }
        };

        // For duplicates:
        Set<String> emailObjects = new Set<String>{ 'Lead', 'Contact' };
        Set<String> phoneObjects = new Set<String>{ 'Lead', 'Contact', 'Account' };

        dto.missingRequired  = countMissingRequired(objectApiName, requiredFields.get(objectApiName));
        dto.invalidEmails    = countInvalidFormat(objectApiName, emailFields.get(objectApiName), true);
        dto.invalidPhones    = countInvalidFormat(objectApiName, phoneFields.get(objectApiName), false);

        dto.duplicateEmails = emailObjects.contains(objectApiName)
            ? countDuplicates(objectApiName, 'Email')
            : 0;

        dto.duplicatePhones = phoneObjects.contains(objectApiName)
            ? countDuplicates(objectApiName, 'Phone')
            : 0;

        return dto;
    }


    private static Integer countMissingRequired(String obj, List<String> fields) {
        if (fields == null || fields.isEmpty()) return 0;

        List<String> conds = new List<String>();
        for (String f : fields) conds.add(f + ' = NULL');

        String soql = 'SELECT COUNT() FROM ' + obj + ' WHERE ' + String.join(conds, ' OR ');

        return (Integer)Database.countQuery(soql);
    }


    private static Integer countDuplicates(String obj, String fieldName) {

        String q =
            'SELECT ' + fieldName + ', COUNT(Id) c ' +
            'FROM ' + obj + 
            ' WHERE ' + fieldName + ' != NULL ' +
            'GROUP BY ' + fieldName + 
            ' HAVING COUNT(Id) > 1';

        List<AggregateResult> ars = Database.query(q);

        return ars.size();
    }


    private static Integer countInvalidFormat(String obj, List<String> fields, Boolean isEmail) {

        if (fields == null || fields.isEmpty()) return 0;

        String fieldStr = String.join(fields, ', ');
        String soql = 'SELECT Id, ' + fieldStr + ' FROM ' + obj;

        List<SObject> recs = Database.query(soql);

        Integer invalidCount = 0;

        Pattern emailPat = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        Pattern phonePat = Pattern.compile('^[0-9()\\-+\\s]*$');

        for (SObject s : recs) {
            for (String f : fields) {
                Object val = s.get(f);
                if (val == null) continue;

                String v = String.valueOf(val).trim();

                if (isEmail && !emailPat.matcher(v).matches()) {
                    invalidCount++;
                    break;
                }
                if (!isEmail && !phonePat.matcher(v).matches()) {
                    invalidCount++;
                    break;
                }
            }
        }
        return invalidCount;
    }

}