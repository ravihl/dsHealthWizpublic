import { LightningElement, wire, track } from 'lwc';
import getTodayApiSummary from '@salesforce/apex/APIUsageService.getTodayApiSummary';
import getHourlyApiUsage from '@salesforce/apex/APIUsageService.getHourlyApiUsage';
import getTodayApiUsageByIntegration from '@salesforce/apex/APIUsageService.getTodayApiUsageByIntegration';

export default class ApiUsageTracker extends LightningElement {
    @track summary = null;
    @track summaryError = undefined;

    @track hourly = [];
    @track hourlyError = undefined;

    @track byIntegration = [];
    @track byIntegrationError = undefined;

    columnsHourly = [
        { label: 'Hour', fieldName: 'hour', type: 'number' },
        { label: 'API Calls Used', fieldName: 'callsUsed', type: 'number' },
        { label: 'Quota (%)', fieldName: 'usagePct', type: 'percent', cellAttributes:{ alignment: 'left' } }
    ];

    columnsIntegration = [
        { label: 'Integration Client', fieldName: 'client', type: 'text' },
        { label: 'Calls Used', fieldName: 'calls', type: 'number'}
    ];

    // KPI summary (tile)
    @wire(getTodayApiSummary)
    wiredSummary({ error, data }) {
        if (data) {
            this.summary = data;
            this.summaryError = undefined;
        } else if (error) {
            this.summary = null;
            this.summaryError = error;
        }
    }

    // Hourly usage table
    @wire(getHourlyApiUsage)
    wiredHourly({ error, data }) {
        if (data) {
            this.hourly = data;
            this.hourlyError = undefined;
        } else if (error) {
            this.hourly = [];
            this.hourlyError = error;
        }
    }

    // Per integration leaderboard
    @wire(getTodayApiUsageByIntegration)
    wiredIntegration({ error, data }) {
        if (data) {
            this.byIntegration = data;
            this.byIntegrationError = undefined;
        } else if (error) {
            this.byIntegration = [];
            this.byIntegrationError = error;
        }
    }

    // Error helper for the template
    get summaryErrorMessage() {
        if (!this.summaryError) return '';
        if (this.summaryError.body && typeof this.summaryError.body.message === 'string') {
            return this.summaryError.body.message;
        }
        return this.summaryError.message || 'Unknown error in summary';
    }
    get hourlyErrorMessage() {
        if (!this.hourlyError) return '';
        if (this.hourlyError.body && typeof this.hourlyError.body.message === 'string') {
            return this.hourlyError.body.message;
        }
        return this.hourlyError.message || 'Unknown error in hourly';
    }
    get byIntegrationErrorMessage() {
        if (!this.byIntegrationError) return '';
        if (this.byIntegrationError.body && typeof this.byIntegrationError.body.message === 'string') {
            return this.byIntegrationError.body.message;
        }
        return this.byIntegrationError.message || 'Unknown error in table';
    }

    get usagePctClass() {
        if (!this.summary || !this.summary.usagePct) return 'kpi-success';
        const pct = Number(this.summary.usagePct);
        if (pct >= 90) return 'kpi-danger';
        if (pct >= 75) return 'kpi-warning';
        return 'kpi-success';
    }

}
