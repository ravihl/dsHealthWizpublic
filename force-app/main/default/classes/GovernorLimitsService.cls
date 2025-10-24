/**
 * GovernorLimitsService
 * Service class for monitoring and analyzing governor limits
 */
public with sharing class GovernorLimitsService {

    /**
     * Get historical governor limits trends
     * @param days Number of days to retrieve
     * @return List of historical metrics
     */
    public static List<Org_Health_Metric__c> getHistoricalTrends(Integer ndays) {
        
        Date startDate = Date.today().addDays(-ndays);
        List<Org_Health_Metric__c> metrics = new List<Org_Health_Metric__c>();
        metrics =  [SELECT Metric_Type__c, Metric_Value__c, Threshold__c, 
                   Status__c, Recorded_Date__c
            FROM Org_Health_Metric__c
            WHERE Metric_Type__c LIKE '%Governor%'
            AND Recorded_Date__c >= :startDate
            ORDER BY Recorded_Date__c DESC];
        return metrics;
    } 

    /**
     * Check if any governor limits exceed thresholds
     * @param limitsData Current limits data
     * @return List of alerts
     */
    public static List<Alert_Configuration__c> checkThresholds(Map<String, Object> limitsData) {
        List<Alert_Configuration__c> triggeredAlerts = new List<Alert_Configuration__c>();

        // Query active alert configurations
        List<Alert_Configuration__c> configs = [
            SELECT Alert_Type__c, Threshold_Value__c, Severity__c, 
                   Notification_Recipients__c
            FROM Alert_Configuration__c
            WHERE Active__c = true
            AND Alert_Type__c LIKE '%Governor%'
        ];

        for (Alert_Configuration__c config : configs) {
            Decimal currentValue = (Decimal)limitsData.get(config.Alert_Type__c);
            if (currentValue >= config.Threshold_Value__c) {
                triggeredAlerts.add(config);
            }
        }

        return triggeredAlerts;
    }

    /**
     * Send alerts for threshold violations
     * @param alerts List of triggered alerts
     */
    public static void sendAlerts(List<Alert_Configuration__c> alerts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Alert_Configuration__c alert : alerts) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(alert.Notification_Recipients__c.split(','));
            email.setSubject('Salesforce Org Health Alert: ' + alert.Alert_Type__c);
            email.setHtmlBody(buildAlertEmailBody(alert));
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
     * Build email body for alert
     */
    private static String buildAlertEmailBody(Alert_Configuration__c alert) {
        String body = '<html><body>';
        body += '<h2>Salesforce Org Health Alert</h2>';
        body += '<p><strong>Alert Type:</strong> ' + alert.Alert_Type__c + '</p>';
        body += '<p><strong>Severity:</strong> ' + alert.Severity__c + '</p>';
        body += '<p><strong>Threshold:</strong> ' + alert.Threshold_Value__c + '</p>';
        body += '<p>Please review your org health dashboard for more details.</p>';
        body += '</body></html>';
        return body;
    }

    /**
     * Analyze governor limit patterns
     * @return Analysis results
     */
    public static Map<String, Object> analyzeLimitPatterns() {
        Map<String, Object> analysis = new Map<String, Object>();

        // Get historical data
        List<Org_Health_Metric__c> metrics = getHistoricalTrends(30);

        // Group by metric type
        Map<String, List<Decimal>> metricsByType = new Map<String, List<Decimal>>();
        for (Org_Health_Metric__c metric : metrics) {
            if (!metricsByType.containsKey(metric.Metric_Type__c)) {
                metricsByType.put(metric.Metric_Type__c, new List<Decimal>());
            }
            metricsByType.get(metric.Metric_Type__c).add(metric.Metric_Value__c);
        }

        // Calculate statistics
        for (String metricType : metricsByType.keySet()) {
            List<Decimal> values = metricsByType.get(metricType);
            Map<String, Decimal> stats = calculateStatistics(values);
            analysis.put(metricType, stats);
        }

        return analysis;
    }

    /**
     * Calculate statistics for a list of values
     */
    private static Map<String, Decimal> calculateStatistics(List<Decimal> values) {
        Map<String, Decimal> stats = new Map<String, Decimal>();

        if (values.isEmpty()) {
            return stats;
        }

        // Calculate average
        Decimal sum = 0;
        Decimal max = values[0];
        Decimal min = values[0];

        for (Decimal value : values) {
            sum += value;
            if (value > max) max = value;
            if (value < min) min = value;
        }

        stats.put('average', sum / values.size());
        stats.put('max', max);
        stats.put('min', min);
        stats.put('count', values.size());

        return stats;
    }
}