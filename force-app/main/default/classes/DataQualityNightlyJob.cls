/**
* @File Name : DataQualityNightlyJob.cls
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
 * Scheduled job that runs nightly to refresh Data Quality Metrics
 */
public with sharing class DataQualityNightlyJob implements Schedulable {

    public void execute(SchedulableContext sc) {

        // Step 1: Generate Metrics
        List<DataQualityMetricsService.DataQualityMetricDTO> metrics =
            DataQualityMetricsService.getAggregatedMetrics();

        // Step 2: Write to Data_Quality_Score__c
        DataQualityMetricWriter.writeMetricsToDQScore(metrics);

        System.debug('Nightly Data Quality Job complete. Metrics processed: ' + metrics.size());
    }
}