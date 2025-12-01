import { LightningElement, track, wire, api } from 'lwc';
import getHeatmapData from '@salesforce/apex/DataQualityDashboardService.getHeatmapData';
import { refreshApex } from '@salesforce/apex';

export default class DataQualityHeatmap extends LightningElement {
    @track metrics = [];
    @track isLoading = true;
    @track error;

    wiredDataResult;

    @wire(getHeatmapData)
    wiredScores(result) {
        this.wiredDataResult = result;
        const { data, error } = result;
        this.isLoading = false;

        if(data){
            this.error = undefined;
            const thresholds = { green: 0, yellow: 1, red: 5 };

            this.metrics = data.map(row => ({
                ...row,
                missingClass: this.getClassForValue(row.missingRequired, thresholds),
                invalidEmailClass: this.getClassForValue(row.invalidEmails, thresholds),
                invalidPhoneClass: this.getClassForValue(row.invalidPhones, thresholds),
                dupEmailClass: this.getClassForValue(row.duplicateEmails, thresholds),
                dupPhoneClass: this.getClassForValue(row.duplicatePhones, thresholds)
            }));
        } else if(error){
            this.error = error;
            this.metrics = [];
        }
    }

    getClassForValue(value, thresholds){
        if(!value || value <= thresholds.yellow) return 'cell-green';
        if(value > thresholds.yellow && value < thresholds.red) return 'cell-yellow';
        return 'cell-red';
    }

    get errorMessage(){
        if(!this.error) return '';
        if(this.error.body && this.error.body.message) return this.error.body.message;
        return this.error.message || 'Unknown error';
    }

    @api
    refresh(){
        if(this.wiredDataResult){
            this.isLoading = true;
            refreshApex(this.wiredDataResult);
        }
    }
}