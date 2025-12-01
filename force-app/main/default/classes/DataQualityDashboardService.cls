/**
* @File Name : DataQualityDashboardService.cls
* @Description : Provides KPI, drilldown, and trend data for Data Quality Dashboard LWC
* @Author :
* @Last Modified On : November 25, 2025
*/

public with sharing class DataQualityDashboardService {

    // ----------------------------------------------------------
    //  KPI SUMMARY (invalidEmails, missingRequired, perObject map)
    // ----------------------------------------------------------
  @AuraEnabled(cacheable=true)
public static Map<String, Object> getKpis() {
    Date today = Date.today();

    // 1. Check if today's metrics exist
    AggregateResult[] anyToday = [
        SELECT COUNT(Id) c
        FROM Data_Quality_Score__c
        WHERE Analysis_Date__c = :today
    ];

    // 2. Get latest analysis date (returned as Datetime internally)
    AggregateResult[] latest = [
        SELECT MAX(Analysis_Date__c) maxD
        FROM Data_Quality_Score__c
    ];

    // SAFE FIX APPLIED HERE
    Date latestDate;
    if (latest != null && latest.size() > 0 && latest[0].get('maxD') != null) {
        Datetime dt = (Datetime) latest[0].get('maxD');
        latestDate = dt.date();
    } else {
        latestDate = today;
    }

    // 3. Determine which date to use
    Boolean hasToday =
        anyToday != null &&
        anyToday.size() > 0 &&
        ((Integer)anyToday[0].get('c')) > 0;

    Date targetDate = hasToday ? today : latestDate;

    // 4. Load all metric rows for that date
    List<Data_Quality_Score__c> rows = [
        SELECT Id, Object_Name__c, Field__c, Score__c,
               Analysis_Date__c, Notes__c, Record_Id__c
        FROM Data_Quality_Score__c
        WHERE Analysis_Date__c = :targetDate
    ];

    // 5. Build object+metric map
    Map<String, Integer> kv = new Map<String, Integer>();
    for (Data_Quality_Score__c r : rows) {
        String key = r.Object_Name__c + '#' + r.Field__c;
        kv.put(key, r.Score__c == null ? 0 : Integer.valueOf(r.Score__c));
    }

    Integer invalidEmails = 0;
    Integer missingRequired = 0;

    for (String key : kv.keySet()) {
        if (key.endsWith('#InvalidEmails'))
            invalidEmails += kv.get(key);

        if (key.endsWith('#MissingRequired'))
            missingRequired += kv.get(key);
    }

    Map<String, Object> response = new Map<String, Object>();
    response.put('analysisDate', targetDate);
    response.put('invalidEmails', invalidEmails);
    response.put('missingRequired', missingRequired);
    response.put('perObject', kv);

    return response;
}


    // ----------------------------------------------------------
    //  DRILLDOWN (click heatmap → get list of bad records)
    // ----------------------------------------------------------
    @AuraEnabled(cacheable=true)
public static List<Data_Quality_Score__c> getDrilldownIssues(
    String objectApiName,
    String metricName,
    Integer limitRows
) {
    if (limitRows == null) limitRows = 400;

    String soql = 
        'SELECT Id, Object_Name__c, Field__c, Record_Count__c, ' +
        'Analysis_Date__c, Notes__c, Record_Id__c ' +
        'FROM Data_Quality_Score__c WHERE Analysis_Date__c != NULL ';

    if (!String.isBlank(objectApiName)) {
        soql += ' AND Object_Name__c = :objectApiName ';
    }
    if (!String.isBlank(metricName)) {
        soql += ' AND Field__c = :metricName ';
    }

    soql += ' ORDER BY Analysis_Date__c DESC LIMIT :limitRows';

    return Database.query(soql);
}

	 // ----------------------------------------------------------
    //  Heat Map
    // ----------------------------------------------------------
    @AuraEnabled(cacheable=true)
public static List<Map<String,Object>> getHeatmapData() {
    AggregateResult ar = [SELECT MAX(Analysis_Date__c) maxDate FROM Data_Quality_Score__c];
    Datetime latestDt = (Datetime) ar.get('maxDate');
    Date latestDate = latestDt != null ? latestDt.date() : Date.today();

    List<Data_Quality_Score__c> scores = [
        SELECT Object_Name__c, Field__c, Score__c
        FROM Data_Quality_Score__c
        WHERE Analysis_Date__c = :latestDate
    ];

    Map<String, Map<String,Integer>> aggMap = new Map<String, Map<String,Integer>>();

    for(Data_Quality_Score__c s : scores){
        String obj = s.Object_Name__c;
        String metric = s.Field__c;
        Integer val = s.Score__c != null ? Integer.valueOf(s.Score__c) : 0;

        if(!aggMap.containsKey(obj)){
            aggMap.put(obj, new Map<String,Integer>{
                'missingRequired' => 0,
                'invalidEmails'   => 0,
                'invalidPhones'   => 0,
                'duplicateEmails' => 0,
                'duplicatePhones' => 0
            });
        }

        Map<String,Integer> m = aggMap.get(obj);

        if(metric == 'MissingRequired') m.put('missingRequired', m.get('missingRequired') + val);
        else if(metric == 'InvalidEmails') m.put('invalidEmails', m.get('invalidEmails') + val);
        else if(metric == 'InvalidPhones') m.put('invalidPhones', m.get('invalidPhones') + val);
        else if(metric == 'DuplicateEmails') m.put('duplicateEmails', m.get('duplicateEmails') + val);
        else if(metric == 'DuplicatePhones') m.put('duplicatePhones', m.get('duplicatePhones') + val);
    }

    List<Map<String,Object>> out = new List<Map<String,Object>>();
    for(String obj : aggMap.keySet()){
        Map<String,Integer> m = aggMap.get(obj);
        out.add(new Map<String,Object>{
            'objectApiName'   => obj,
            'missingRequired' => m.get('missingRequired'),
            'invalidEmails'   => m.get('invalidEmails'),
            'invalidPhones'   => m.get('invalidPhones'),
            'duplicateEmails' => m.get('duplicateEmails'),
            'duplicatePhones' => m.get('duplicatePhones')
        });
    }

    return out;
}

    // ----------------------------------------------------------
    //  TREND CHART (last N days → line chart)
    // ----------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTrendData(
        Integer daysBack,
        String objectApiName,
        String metricName
    ) {
        if (daysBack == null || daysBack <= 0) daysBack = 30;
        Date startDate = Date.today().addDays(-daysBack + 1);

        // dynamic query construction
       String soql =
    'SELECT DAY_ONLY(Analysis_Date__c) d, Field__c f, SUM(Score__c) s ' +
    'FROM Data_Quality_Score__c ' +
    'WHERE Analysis_Date__c >= :startDate ';

if (!String.isBlank(objectApiName)) {
    soql += 'AND Object_Name__c = :objectApiName ';
}
if (!String.isBlank(metricName)) {
    soql += 'AND Field__c = :metricName ';
}

soql += 'GROUP BY DAY_ONLY(Analysis_Date__c), Field__c ' +
        'ORDER BY DAY_ONLY(Analysis_Date__c) ASC';


        if (!String.isBlank(objectApiName)) {
            soql += 'AND Object_Name__c = :objectApiName ';
        }
        if (!String.isBlank(metricName)) {
            soql += 'AND Field__c = :metricName ';
        }

        soql += 'GROUP BY Analysis_Date__c, Field__c ' +
                'ORDER BY Analysis_Date__c ASC';

        List<AggregateResult> ars = Database.query(soql);

        List<Map<String, Object>> out = new List<Map<String, Object>>();
        for (AggregateResult ar : ars) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('date', (Date) ar.get('d'));
            row.put('metric', (String) ar.get('f'));
            row.put('total', ((Decimal) ar.get('s')).intValue());
            out.add(row);
        }

        return out;
    }
}