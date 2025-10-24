# AI Assistant Instructions for dsHealthWiz

## Project Overview
dsHealthWiz is a comprehensive Salesforce org monitoring solution built with Lightning Web Components (LWC) and Apex. The application provides real-time monitoring of org health metrics including API usage, governor limits, data quality, and performance metrics.

## Architecture & Component Structure

### Core Services
- `LoggingService.cls`: Centralized logging with buffered writes and context tracking
- `GovernorLimitsService.cls`: Monitors Salesforce governor limits and provides trend analysis
- `DataQualityService.cls`: Data quality scoring and monitoring 
- `dsOrgHealthController.cls`: Main controller bridging LWC components with backend services

### LWC Components
1. **Main Dashboard** (`orgHealthDashboard`)
   - Parent container with tab navigation
   - Manages component lifecycle and refresh intervals
   - Example: `force-app/main/default/lwc/orgHealthDashboard/`

2. **Feature Components**
   - `apiUsageTracker`: API limits monitoring
   - `dataQualityMonitor`: Data quality metrics
   - `governorLimitsMonitor`: Real-time governor limits tracking
   - `overviewComponent`: Executive summary and KPIs
   - `performanceMetrics`: Performance monitoring

### Custom Objects
Key monitoring data is stored in:
- `API_Usage_Log__c`: API usage tracking
- `Org_Health_Metric__c`: General health metrics
- `Data_Quality_Score__c`: Data quality measurements
- `Alert_Configuration__c`: Alert definitions and thresholds

## Development Workflows

### Local Development Setup
```bash
# Create a scratch org
sfdx force:org:create -f config/project-scratch-def.json

# Deploy metadata
sfdx force:source:push

# Run tests
sfdx force:apex:test:run --testlevel RunLocalTests
```

### Testing
- Jest tests for LWC components in `__tests__` folders
- Apex tests follow Salesforce best practices
- Use `LoggingService.cls` for consistent error tracking

### Common Patterns

1. **Service Layer Pattern**
   ```apex
   public with sharing class SomeService {
       @AuraEnabled(cacheable=true)
       public static Map<String, Object> getMetrics() {
           // Implementation
       }
   }
   ```

2. **LWC Data Binding**
   ```javascript
   @track metrics = [];
   @wire(getMetrics)
   wiredMetrics({ error, data }) {
       if (data) {
           this.metrics = data;
       }
   }
   ```

3. **Error Handling**
   - Use `LoggingService` for Apex errors
   - Handle LWC errors with proper UI feedback
   - Example in `overviewComponent.js`

### Integration Points
1. API Monitoring:
   - API usage tracked in `API_Usage_Log__c`
   - Real-time monitoring via `apiUsageTracker` component
   
2. Data Quality:
   - Metrics stored in `Data_Quality_Score__c`
   - Scheduled analysis via Apex batch jobs

## Best Practices

1. **Governor Limits**
   - Use `GovernorLimitsService` to track limits
   - Buffer operations using `LoggingService`
   - Example in `TriggerHandler.cls`

2. **Performance**
   - Cache API responses using `@AuraEnabled(cacheable=true)`
   - Batch DML operations
   - Use proper SOQL query optimization

3. **Error Handling**
   ```apex
   try {
       // Operation
   } catch (Exception e) {
       LoggingService.error('Operation failed', e);
       throw new AuraHandledException(e.getMessage());
   }
   ```

## Configuration
- Check `sfdx-project.json` for project settings
- Alert thresholds configured in `Alert_Configuration__c`
- Framework settings in `Framework_Config__c`

## Alerts and Notifications
- Alert configurations in `Alert_Configuration__c`
- Multiple notification channels supported (Email, Slack, Teams)
- Threshold-based triggering system

## Key Files Reference
- `/force-app/main/default/classes/` - Core Apex classes
- `/force-app/main/default/lwc/` - Lightning Web Components
- `/force-app/main/default/objects/` - Custom object definitions