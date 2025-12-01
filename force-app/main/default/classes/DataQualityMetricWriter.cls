/**
* @File Name : DataQualityMetricWriter.cls
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

/**
 * Writes aggregated Data Quality metrics into Data_Quality_Score__c
 */
public with sharing class DataQualityMetricWriter {

    public static void writeMetricsToDQScore(List<DataQualityMetricsService.DataQualityMetricDTO> metrics) {

        if (metrics == null || metrics.isEmpty()) return;

        List<Data_Quality_Score__c> toInsert = new List<Data_Quality_Score__c>();

        for (DataQualityMetricsService.DataQualityMetricDTO m : metrics) {

            // Missing Required
            toInsert.add(buildMetricRecord(
                m.objectApiName,
                'MissingRequired',
                m.missingRequired,
                m.analysisDate
            ));

            // Invalid Emails
            toInsert.add(buildMetricRecord(
                m.objectApiName,
                'InvalidEmails',
                m.invalidEmails,
                m.analysisDate
            ));

            // Invalid Phones
            toInsert.add(buildMetricRecord(
                m.objectApiName,
                'InvalidPhones',
                m.invalidPhones,
                m.analysisDate
            ));

            // Duplicate Emails
            toInsert.add(buildMetricRecord(
                m.objectApiName,
                'DuplicateEmails',
                m.duplicateEmails,
                m.analysisDate
            ));

            // Duplicate Phones
            toInsert.add(buildMetricRecord(
                m.objectApiName,
                'DuplicatePhones',
                m.duplicatePhones,
                m.analysisDate
            ));
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private static Data_Quality_Score__c buildMetricRecord(
        String objName,
        String metricName,
        Integer value,
        Date analysisDate
    ) {
        Data_Quality_Score__c rec = new Data_Quality_Score__c();

        rec.Name = objName + ' - ' + metricName + ' - ' + analysisDate.format();
        rec.Object_Name__c = objName;
        rec.Field__c = metricName;
        rec.Score__c = value == null ? 0 : value;
        rec.Analysis_Date__c = analysisDate;
        rec.Notes__c = 'Generated via nightly data-quality job';

        return rec;
    }
}