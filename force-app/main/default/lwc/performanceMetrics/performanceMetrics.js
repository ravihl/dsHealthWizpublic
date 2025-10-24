import { LightningElement, wire, track } from 'lwc';
import getPerformanceMetrics from '@salesforce/apex/PerformanceMetricsController.getPerformanceMetrics';

export default class PerformanceMetrics extends LightningElement {
    @track metrics = [];
    @track error = undefined;
    @track isLoading = true;

    columns = [
        { label: 'Recorded', fieldName: 'timestamp', type: 'date' },
        { label: 'EPT (ms)', fieldName: 'ept', type: 'number' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Details', fieldName: 'details', type: 'text' }
    ];

    @wire(getPerformanceMetrics)
    wiredMetrics({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.metrics = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.metrics = [];
        }
    }

    get hasResults() {
        return this.metrics && this.metrics.length > 0;
    }

    get errorMessage() {
        if (!this.error) return '';
        if (this.error.body && typeof this.error.body.message === 'string') {
            return this.error.body.message;
        }
        return this.error.message || this.error.statusText || 'Unknown error';
    }
}
