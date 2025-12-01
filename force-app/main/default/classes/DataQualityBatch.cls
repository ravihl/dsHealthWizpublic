public class DataQualityBatch implements Database.Batchable<SObject> {

    public String objectName;
    public List<String> reqfieldName;
    public List<String> emailFieldsName;
    public List<String> phoneFieldsName;
    public Integer limitSze;

    public DataQualityBatch(
        String objName,
        List<String> reqfield,
        List<String> emailFieldsName,
        List<String> phoneFieldsName
    ) {
        this.objectName = objName;
        this.reqfieldName = reqfield != null ? reqfield : new List<String>();
        this.emailFieldsName = emailFieldsName != null ? emailFieldsName : new List<String>();
        this.phoneFieldsName = phoneFieldsName != null ? phoneFieldsName : new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        // Combine validation fields for SELECT
        List<String> allFields = new List<String>();
        allFields.addAll(emailFieldsName);
        allFields.addAll(phoneFieldsName);

        // If no fields exist (example: Opportunity has no email/phone) → SELECT Id only
        String selectFields = allFields.isEmpty() ? 'Id' : String.join(allFields, ',');

        String soql = 'SELECT ' + selectFields + ' FROM ' + objectName;
        System.debug('🔥 FINAL SOQL → ' + soql);

        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        // Only Contact/Lead have email & phone to validate
        if (objectName == 'Lead' || objectName == 'Contact') {
            DataQualityValidator.runEmailandPhoneChecks(
                objectName,
                scope,
                emailFieldsName,
                phoneFieldsName
            );
        }
    }

    public void finish(Database.BatchableContext bc) {

        // Required Field Check for ALL objects (Account, Contact, Lead, Opp)
        DataQualityValidator.runReqFieldChecks(
            objectName,
            reqfieldName
        );
    }
}