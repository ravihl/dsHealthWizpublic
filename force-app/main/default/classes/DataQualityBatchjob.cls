public class DataQualityBatchjob implements Database.Batchable<SObject>, Database.Stateful {

// Inputs
private String objectName;
private List<String> requiredFields;
private List<String> emailFields;
private List<String> phoneFields;

// Constructor
public DataQualityBatchjob(
    String objectName,
    List<String> requiredFields,
    List<String> emailFields,
    List<String> phoneFields
) {
    this.objectName     = objectName;
    this.requiredFields = (requiredFields != null ? requiredFields : new List<String>());
    this.emailFields    = (emailFields != null ? emailFields : new List<String>());
    this.phoneFields    = (phoneFields != null ? phoneFields : new List<String>());
}

// -------------------------------
// START — Build SOQL dynamically
// -------------------------------
public Database.QueryLocator start(Database.BatchableContext bc) {
    List<String> selectFields = new List<String>{ 'Id' };
    selectFields.addAll(requiredFields);
    selectFields.addAll(emailFields);
    selectFields.addAll(phoneFields);

    Set<String> cleanFields = new Set<String>(selectFields);
    String soql = 'SELECT ' + String.join(new List<String>(cleanFields), ',') +
                  ' FROM ' + objectName;

    System.debug('FINAL SOQL: ' + soql);
    return Database.getQueryLocator(soql);
}

// -------------------------------
// EXECUTE — Run validations and duplicate scoring
// -------------------------------
public void execute(Database.BatchableContext bc, List<SObject> scope) {

    List<Data_Quality_Score__c> logs = new List<Data_Quality_Score__c>();

    for (SObject rec : scope) {
        Id recordId = (Id) rec.get('Id');

        // Required Field Validation
        for (String f : requiredFields) {
            Object val = rec.get(f);
            if (val == null || String.valueOf(val).trim() == '') {
                logs.add(new Data_Quality_Score__c(
                    Object_Name__c = objectName,
                    Field__c       = f,
                    Score__c       = 1,
                    Record_Id__c   = recordId,
                    Notes__c       = 'Missing Required Field'
                ));
            }
        }

        // Email Validation
        for (String f : emailFields) {
            String emailVal = (String) rec.get(f);
            if (!isValidEmail(emailVal)) {
                logs.add(new Data_Quality_Score__c(
                    Object_Name__c = objectName,
                    Field__c       = f,
                    Score__c       = 1,
                    Record_Id__c   = recordId,
                    Notes__c       = 'Invalid Email'
                ));
            }
        }

        // Phone Validation
        for (String f : phoneFields) {
            String phoneVal = (String) rec.get(f);
            if (!isValidPhone(phoneVal)) {
                logs.add(new Data_Quality_Score__c(
                    Object_Name__c = objectName,
                    Field__c       = f,
                    Score__c       = 1,
                    Record_Id__c   = recordId,
                    Notes__c       = 'Invalid Phone'
                ));
            }
        }

        // Duplicate Scoring — Contact
        if (objectName == 'Contact') {
            Integer dupScore = getContactDuplicateScore(recordId, (String) rec.get('Email'), (String) rec.get('Phone'));
            if (dupScore > 0) {
                logs.add(new Data_Quality_Score__c(
                    Object_Name__c = 'Contact',
                    Field__c       = 'Duplicate Check',
                    Score__c       = dupScore,
                    Record_Id__c   = recordId,
                    Notes__c       = 'Possible duplicate Contact'
                ));
            }
        }

        // Duplicate Scoring — Opportunity
        if (objectName == 'Opportunity') {
            Integer dupScore = getOpportunityDuplicateScore(
                recordId,
                (Id) rec.get('AccountId'),
                (Decimal) rec.get('Amount'),
                (Date) rec.get('CloseDate')
            );
            if (dupScore > 0) {
                logs.add(new Data_Quality_Score__c(
                    Object_Name__c = 'Opportunity',
                    Field__c       = 'Duplicate Check',
                    Score__c       = dupScore,
                    Record_Id__c   = recordId,
                    Notes__c       = 'Possible duplicate Opportunity'
                ));
            }
        }
    }

    if (!logs.isEmpty()) {
        insert logs;
    }
}

// -------------------------------
// FINISH — Summary
// -------------------------------
public void finish(Database.BatchableContext bc) {
    System.debug('Data Quality Batch Completed for ' + objectName);
}

// -------------------------------
// Helper — Email validation
// -------------------------------
private Boolean isValidEmail(String email) {
    if (String.isBlank(email)) return true;
    Pattern p = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
    return p.matcher(email).matches();
}

// -------------------------------
// Helper — Phone validation
// -------------------------------
private Boolean isValidPhone(String phone) {
    if (String.isBlank(phone)) return true;
    Pattern p = Pattern.compile('^[0-9()+\\-\\s]{6,20}$');
    return p.matcher(phone).matches();
}

// -------------------------------
// Helper — Contact Duplicate Score
// -------------------------------
private Integer getContactDuplicateScore(Id recordId, String email, String phone) {
    Integer score = 0;
    List<Contact> dups = [
        SELECT Id 
        FROM Contact 
        WHERE Id != :recordId 
          AND (Email = :email OR Phone = :phone) 
        LIMIT 1
    ];
    if (!dups.isEmpty()) score = 5;
    return score;
}

// -------------------------------
// Helper — Opportunity Duplicate Score
// -------------------------------
private Integer getOpportunityDuplicateScore(Id recordId, Id accountId, Decimal amount, Date closeDate) {
    Integer score = 0;
    List<Opportunity> dups = [
        SELECT Id 
        FROM Opportunity 
        WHERE Id != :recordId
          AND AccountId = :accountId
          AND Amount = :amount
          AND CloseDate = :closeDate 
        LIMIT 1
    ];
    if (!dups.isEmpty()) score = 5;
    return score;
}
}