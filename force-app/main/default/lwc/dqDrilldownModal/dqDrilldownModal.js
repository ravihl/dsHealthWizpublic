import { LightningElement, track } from 'lwc';
import getDrilldownIssues from '@salesforce/apex/DataQualityDashboardService.getDrilldownIssues';

const COLUMNS = [
    { label: 'Analysis Date', fieldName: 'Analysis_Date__c', type: 'date-local' },
    { label: 'Score', fieldName: 'Score__c', type: 'number' },
    { label: 'Notes', fieldName: 'Notes__c', type: 'text' },
    { label: 'Record', fieldName: 'Record_Link', type: 'url', typeAttributes: { label: { fieldName: 'Record_Name' }, target: '_blank' } }
];

export default class DqDrilldownModal extends LightningElement {
    @track isOpen = false;
    @track isLoading = false;
    @track rows = [];
    @track error;
    @track title = '';
    columns = COLUMNS;

    open(objectApiName, metricName) {
        this.title = `${objectApiName} — ${metricName}`;
        this.isOpen = true;
        this.load(objectApiName, metricName);
    }

    close() {
        this.isOpen = false;
        this.rows = [];
    }

    load(objectApiName, metricName) {
        this.isLoading = true;
        getDrilldownIssues({ objectApiName, metricName, limitRows: 200 })
            .then(result => {
                this.isLoading = false;
                this.error = undefined;
                this.rows = result.map(r => {
                    return {
                        ...r,
                        Record_Link: r.Record_Id__c ? `/lightning/r/${r.Object_Name__c}/${r.Record_Id__c}/view` : null,
                        Record_Name: r.Record_Id__c ? r.Record_Id__c : ''
                    };
                });
            })
            .catch(err => {
                this.isLoading = false;
                this.error = err;
                this.rows = [];
            });
    }
}