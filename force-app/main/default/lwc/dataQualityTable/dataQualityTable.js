import { LightningElement, wire, track } from 'lwc';
import getDrilldownIssues from '@salesforce/apex/DataQualityDashboardService.getDrilldownIssues';

export default class DataQualityTable extends LightningElement {

    @track data = [];
    @track rowCount = 0;
    @track objectCounts = [];

    maxRows = 400; // 🔥 Change this dynamically anytime (e.g., user input)

    columns = [
        { label: 'Object', fieldName: 'Object_Name__c', type: 'text' },
        { label: 'Field', fieldName: 'Field__c', type: 'text' },
        { label: 'Score', fieldName: 'Record_Count__c', type: 'number' },

        {
            label: 'Record Id',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'RecordId' },
                target: '_blank'
            },
            wrapText: false,
            cellAttributes: { class: 'no-wrap' }
        },

        { label: 'Notes', fieldName: 'Notes__c', type: 'text', wrapText: true }
    ];

@wire(getDrilldownIssues)
wiredIssues({ data, error }) {
    if (data) {
        // limit rows
        let trimmed = data.slice(0, this.maxRows);

        // sort by Object (groups them visually)
        trimmed.sort((a, b) => a.Object_Name__c.localeCompare(b.Object_Name__c));

        // Fix undefined Record Id issue
        trimmed = trimmed.map(row => ({
            ...row,
            recordUrl: row.Record_Id__c ? '/' + row.Record_Id__c : '',
            RecordId: row.Record_Id__c ? row.Record_Id__c : 'N/A'
        }));

        this.data = trimmed;
        this.rowCount = trimmed.length;

        // Count per object
        const counts = {};
        trimmed.forEach(r => {
            counts[r.Object_Name__c] = (counts[r.Object_Name__c] || 0) + 1;
        });

        this.objectCounts = Object.keys(counts).map(key => ({
            object: key,
            count: counts[key]
        }));
    }

    if (error) {
        console.error(error);
    }
}

}