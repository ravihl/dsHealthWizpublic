public with sharing class APIUsageService {
	
    @future(callout=true)
    public static void logCurrentUsage() {
       try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/v61.0/limits');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> limits = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> apiLimits = (Map<String, Object>) limits.get('DailyApiRequests'); 
                
                Decimal max = (Decimal) apiLimits.get('Max');
        	    Decimal remaining = (Decimal) apiLimits.get('Remaining');
                Decimal used = max - remaining;
                Decimal pct = (max > 0) ? (used / max * 100) : 0;
				
                
                insert new API_Usage_Log__c(
                    Date__c = Date.today(),
                    Hour__c = String.valueOf(Datetime.now().hour()),
                    Total_Calls_Used__c = used,
                    Total_Org_Limit__c = max,
                    Percentage_Used__c = pct.setScale(2)
                );
            } else {
                System.debug('Tooling API call failed: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in Tooling API usage logger: ' + e.getMessage());
        }
    }
                      
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getHourlyApiUsage() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<API_Usage_Log__c> logs = [
            SELECT Id, Date__c, Hour__c, Total_Calls_Used__c, Total_Org_Limit__c, Percentage_Used__c
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            ORDER BY Hour__c ASC LIMIT 10
        ];
        for (API_Usage_Log__c log : logs) {
            result.add(new Map<String, Object>{
                'id' => log.Id,
                'date' => log.Date__c,
                'hour' => log.Hour__c,
                'callsUsed' => log.Total_Calls_Used__c,
                'orgLimit' => log.Total_Org_Limit__c,
                'usagePct' => log.Percentage_Used__c
            });
        }
        return result;
    }

    /**
     * Get hourly API usage for each integration/client for today.
     * Produces a list suitable for line/bar charts (grouped by client).
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getHourlyApiUsageByIntegration() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<AggregateResult> aggs = [
            SELECT API_Client_Name__c client, Hour__c hour, SUM(Calls_Used__c) calls
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            GROUP BY API_Client_Name__c, Hour__c
            ORDER BY API_Client_Name__c ASC, Hour__c ASC
        ];
        for (AggregateResult ar : aggs) {
            result.add(new Map<String, Object>{
                'client' => (String)ar.get('client'),
                'hour' => (Integer)ar.get('hour'),
                'calls' => (Decimal)ar.get('calls')
            });
        }
        return result;
    }

    /**
     * Get today's total API usage summary per integration/client.
     * For pie charts, leaderboards, tables.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTodayApiUsageByIntegration() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<AggregateResult> grouped = [
            SELECT API_Client_Name__c client, SUM(Calls_Used__c) calls
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
            GROUP BY API_Client_Name__c
            ORDER BY SUM(Calls_Used__c) DESC
        ];
        for (AggregateResult ag : grouped) {
            result.add(new Map<String, Object>{
                'client' => (String)ag.get('client'),
                'calls' => (Decimal)ag.get('calls')
            });
        }
        return result;
    }
    
   		 @AuraEnabled(cacheable=true)
    //MOnthly limit from UsageEntitlement - API Request per month
public static Decimal getMonthlyApiLimit() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v61.0/limits/usage');
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        List<Object> items = (List<Object>) JSON.deserializeUntyped(res.getBody());

        for (Object o : items) {
            Map<String, Object> item = (Map<String, Object>) o;

            // Look for Monthly API Entitlement
            if (
                item.get('name') == 'ApiRequests' &&
                item.get('periodType') == 'Monthly'
            ) {
                return (Decimal) item.get('max');
            }
        }
    }

    return 0;
} 
    
    
    @AuraEnabled(cacheable=true)
    public static List<MonthlyUsageWrapper> getMonthlyUsageHistory() {

        Date startDate = Date.today().addDays(-30);

        List<AggregateResult> results = [
            SELECT Date__c d, SUM(Total_Calls_Used__c) total
            FROM API_Usage_Log__c
            WHERE Date__c >= :startDate
            GROUP BY Date__c
            ORDER BY Date__c
        ];

        Decimal monthlyLimit = getMonthlyApiLimit();
        List<MonthlyUsageWrapper> response = new List<MonthlyUsageWrapper>();

        for (AggregateResult ar : results) {
            MonthlyUsageWrapper w = new MonthlyUsageWrapper();
            w.month = ((Date) ar.get('d')).format();
            w.used = (Decimal) ar.get('total');
            w.monthlyLimit = monthlyLimit;
            w.usagePct = (monthlyLimit > 0) ? (w.used / monthlyLimit * 100) : 0;

            response.add(w);
        }
        return response;
    }


    public class MonthlyUsageWrapper {
        @AuraEnabled public String month;
        @AuraEnabled public Decimal used;
        @AuraEnabled public Decimal monthlyLimit;
        @AuraEnabled public Decimal usagePct;
    }



    /**
     * Get today's summary for dashboard KPI display.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTodayApiSummary() {
        AggregateResult ar = [
            SELECT SUM(Total_Calls_Used__c) used,
                   SUM(Total_Org_Limit__c) vlimit
            FROM API_Usage_Log__c
            WHERE Date__c = TODAY
        ];
        Decimal used = (Decimal) ar.get('used');
        Decimal vlimit = (Decimal) ar.get('vlimit');
        Decimal pct = (vlimit > 0 ? used / vlimit * 100 : 0);
      //  Decimal monthlyLimit = getMonthlyApiLimit();
      //  Decimal monthlyLimit = getMonthlyApiLimit() * 30;


        Map<String, Object> summary = new Map<String, Object>();
        summary.put('callsUsed', used);
        summary.put('orgLimit', vlimit);
        summary.put('usagePct', pct.setScale(2));
        summary.put('monthlyLimit', getMonthlyApiLimit());  
        return summary;
    }

    }
