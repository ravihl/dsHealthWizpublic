import { LightningElement, wire, track } from 'lwc';
import getDataQualityScores from '@salesforce/apex/DataQualityService.getDataQualityScores';

export default class DataQualityMonitor extends LightningElement {
    @track metrics = [];
    @track error = undefined;
    @track isLoading = true;

    columns = [
        { label: 'Object', fieldName: 'objectApiName', type: 'text' },
        { label: 'Field', fieldName: 'fieldApiName', type: 'text' },
        { label: 'Completeness (%)', fieldName: 'completeness', type: 'percent', cellAttributes: { alignment: 'left' } },
        { label: 'Analysis Date', fieldName: 'analysisDate', type: 'date-local' },
        { label: 'Notes', fieldName: 'notes', type: 'text' }
    ];

    @wire(getDataQualityScores)
    wiredQuality({ error, data }) {
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
    // If Apex error format
    if (this.error.body && typeof this.error.body.message === 'string') {
        return this.error.body.message;
    }
    // JS error or other format
    return this.error.message || this.error.statusText || 'Unknown error';
}

}
