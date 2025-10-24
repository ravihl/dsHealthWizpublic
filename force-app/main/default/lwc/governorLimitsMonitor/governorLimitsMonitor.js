// governorLimitsMonitor.js
import { LightningElement, track, wire } from 'lwc';
import getGovernorLimits from '@salesforce/apex/dsOrgHealthController.getGovernorLimits';
import { refreshApex } from '@salesforce/apex';

export default class GovernorLimitsMonitor extends LightningElement {
    @track limitsData = [];
    @track hasWarnings = false;
    wiredLimitsResult;

    limitTypes = [
        { name: 'SOQL Queries', key: 'soqlQueries', limit: 100, warning: 80, critical: 95 },
        { name: 'DML Statements', key: 'dmlStatements', limit: 150, warning: 120, critical: 140 },
        { name: 'CPU Time (ms)', key: 'cpuTime', limit: 10000, warning: 8000, critical: 9500 },
        { name: 'Heap Size (MB)', key: 'heapSize', limit: 6, warning: 4.8, critical: 5.7 },
        { name: 'SOSL Queries', key: 'soslQueries', limit: 20, warning: 16, critical: 19 },
        { name: 'Callouts', key: 'callouts', limit: 100, warning: 80, critical: 95 }
    ];

    @wire(getGovernorLimits)
    wiredLimits(result) {
        this.wiredLimitsResult = result;
        if (result.data) {
            this.processLimitsData(result.data);
        } else if (result.error) {
            this.handleError(result.error);
        }
    }

    processLimitsData(data) {
        this.limitsData = this.limitTypes.map(limitType => {
            const currentValue = data[limitType.key] || 0;
            const percentage = (currentValue / limitType.limit) * 100;
            const status = this.getStatus(percentage, limitType);

            return {
                ...limitType,
                current: currentValue,
                percentage: percentage.toFixed(2),
                status: status,
                statusClass: this.getStatusClass(status),
                progressBarClass: this.getProgressBarClass(status)
            };
        });

        this.hasWarnings = this.limitsData.some(item => 
            item.status === 'warning' || item.status === 'critical'
        );
    }

    getStatus(percentage, limitType) {
        const warningPercent = (limitType.warning / limitType.limit) * 100;
        const criticalPercent = (limitType.critical / limitType.limit) * 100;

        if (percentage >= criticalPercent) return 'critical';
        if (percentage >= warningPercent) return 'warning';
        return 'healthy';
    }

    getStatusClass(status) {
        const classes = {
            'healthy': 'slds-text-color_success',
            'warning': 'slds-text-color_warning',
            'critical': 'slds-text-color_error'
        };
        return classes[status] || '';
    }

    getProgressBarClass(status) {
        const classes = {
            'healthy': 'slds-progress-bar__value_success',
            'warning': 'slds-progress-bar__value_warning',
            'critical': 'slds-progress-bar__value_error'
        };
        return classes[status] || '';
    }

    handleRefresh() {
        return refreshApex(this.wiredLimitsResult);
    }

    handleError(error) {
        console.error('Error loading governor limits:', error);
    }
}