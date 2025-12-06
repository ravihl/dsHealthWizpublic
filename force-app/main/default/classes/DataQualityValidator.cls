public class DataQualityValidator {

    // ----------------------------------------------------------
    // REQUIRED FIELD VALIDATION
    // ----------------------------------------------------------
    public static List<Data_Quality_Score__c> runReqFieldChecks(
        String objectApiName,
        List<String> requiredFieldsApiName
    ) {
        Map<String, Integer> mapCount = new Map<String, Integer>();
        List<Data_Quality_Score__c> dataQualityScore = new List<Data_Quality_Score__c>();

        if (requiredFieldsApiName == null || requiredFieldsApiName.isEmpty()) {
            return new List<Data_Quality_Score__c>();
        }

        String fields = 'Id,' + String.join(requiredFieldsApiName, ',');
        String query = 'SELECT ' + fields + ' FROM ' + objectApiName;
        List<SObject> records = Database.query(query);

        for (SObject r : records) {
            for (String f : requiredFieldsApiName) {
                if (r.get(f) == null) {
                    mapCount.put(f, mapCount.containsKey(f) ? mapCount.get(f) + 1 : 1);
                }
            }
        }

        for (String fieldApiName : mapCount.keySet()) {
            dataQualityScore.add(
                createDataScore(
                    objectApiName,
                    fieldApiName,
                    'Required field ' + fieldApiName + ' Missing',
                    mapCount.get(fieldApiName)
                )
            );
        }

        return dataQualityScore;
    }

    // ----------------------------------------------------------
    // EMAIL + PHONE VALIDATION
    // ----------------------------------------------------------
    public static List<Data_Quality_Score__c> runEmailandPhoneChecks(
        String objectApiName,
        List<String> emailFieldsApiName,
        List<String> phoneFieldsApiName
    ) {
        List<Data_Quality_Score__c> results = new List<Data_Quality_Score__c>();

        if ((emailFieldsApiName == null || emailFieldsApiName.isEmpty()) &&
            (phoneFieldsApiName == null || phoneFieldsApiName.isEmpty())) {
            return results;
        }

        Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        Pattern phonePattern = Pattern.compile('^[0-9()+\\-\\s]*$');

        List<String> allFields = new List<String>();
        allFields.addAll(emailFieldsApiName);
        allFields.addAll(phoneFieldsApiName);

        String soql = 'SELECT Id';
        if (!allFields.isEmpty()) {
            soql += ',' + String.join(allFields, ',');
        }
        soql += ' FROM ' + objectApiName;

        List<SObject> records = Database.query(soql);

        Map<String, Integer> mapEmailCount = new Map<String, Integer>();
        Map<String, Integer> mapPhoneCount = new Map<String, Integer>();

        for (SObject rec : records) {

            // Email checks
            for (String email : emailFieldsApiName) {
                String emailVal = (String) rec.get(email);
                if (emailVal != null && !emailPattern.matcher(emailVal).matches()) {
                    mapEmailCount.put(email, mapEmailCount.containsKey(email) ? mapEmailCount.get(email) + 1 : 1);
                }
            }

            // Phone checks
            for (String phn : phoneFieldsApiName) {
                String phoneVal = (String) rec.get(phn);
                if (phoneVal != null && !phonePattern.matcher(phoneVal).matches()) {
                    mapPhoneCount.put(phn, mapPhoneCount.containsKey(phn) ? mapPhoneCount.get(phn) + 1 : 1);
                }
            }
        }

        for (String phn : mapPhoneCount.keySet()) {
            results.add(createDataScore(objectApiName, phn, 'Invalid ' + phn, mapPhoneCount.get(phn)));
        }

        for (String email : mapEmailCount.keySet()) {
            results.add(createDataScore(objectApiName, email, 'Invalid ' + email, mapEmailCount.get(email)));
        }

        return results;
    }

    // ----------------------------------------------------------
    // DUPLICATE VALIDATION
    // ----------------------------------------------------------
    public static Data_Quality_Score__c searchForDuplicate(
        String objectApiName,
        String fieldApiName
    ) {
        String dupquery = 
            'SELECT ' + fieldApiName + ', COUNT(Id) unitCount ' +
            'FROM ' + objectApiName +
            ' GROUP BY ' + fieldApiName +
            ' HAVING COUNT(Id) > 1';

        List<AggregateResult> dupesObjrecords = Database.query(dupquery);

        Integer dupCount = 0;
        for (AggregateResult ag : dupesObjrecords) {
            dupCount += (Integer) ag.get('unitCount');
        }

        if (dupCount > 0) {
            return createDataScore(
                objectApiName,
                fieldApiName,
                fieldApiName + ' has Duplicate values',
                dupCount
            );
        }

        return null;
    }

    // ----------------------------------------------------------
    // SCORE CREATION HELPER
    // ----------------------------------------------------------
    public static Data_Quality_Score__c createDataScore(
        String ObjectName,
        String FieldName,
        String Notes,
        Integer Score
    ) {
        Data_Quality_Score__c dsq = new Data_Quality_Score__c();
        dsq.Name = 'DATA QUALITY';
        dsq.Object_Name__c = ObjectName;
        dsq.Field__c = FieldName;
        dsq.Record_Count__c = Score;
        dsq.Analysis_Date__c = System.today();
        dsq.Notes__c = Notes;
        return dsq;
    }
}