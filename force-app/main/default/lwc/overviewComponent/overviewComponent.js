import { LightningElement, wire, track } from 'lwc';
import getOverviewStats from '@salesforce/apex/OverviewController.getOverviewStats';

export default class OverviewComponent extends LightningElement {
    @track stats = null;
    @track error = undefined;
    @track isLoading = true;

    @wire(getOverviewStats)
    wiredStats({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.stats = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.stats = null;
        }
    }

    get hasStats() {
        return this.stats !== null && this.stats !== undefined;
    }

    get errorMessage() {
        if (!this.error) return '';
        if (this.error.body && typeof this.error.body.message === 'string') {
            return this.error.body.message;
        }
        return this.error.message || this.error.statusText || 'Unknown error';
    }

    get apiUsageClass() {
        if (!this.stats) return '';
        const usage = this.stats.apiUsagePct;
        if (usage >= 90) return 'metric-critical';
        if (usage >= 75) return 'metric-warning';
        return 'metric-healthy';
    }

    get storageUsageClass() {
        if (!this.stats) return '';
        const usage = this.stats.storageUsedPct;
        if (usage >= 90) return 'metric-critical';
        if (usage >= 75) return 'metric-warning';
        return 'metric-healthy';
    }

    get healthScoreClass() {
        if (!this.stats) return '';
        const score = this.stats.healthScore;
        if (score >= 80) return 'metric-healthy';
        if (score >= 60) return 'metric-warning';
        return 'metric-critical';
    }

    get integrationHealthClass() {
        if (!this.stats) return '';
        const total = this.stats.totalIntegrations || 1;
        const healthy = this.stats.healthyIntegrations || 0;
        const percentage = (healthy / total) * 100;
        
        if (percentage >= 80) return 'metric-healthy';
        if (percentage >= 60) return 'metric-warning';
        return 'metric-critical';
    }

    get integrationHealthPercentage() {
        if (!this.stats) return 0;
        const total = this.stats.totalIntegrations || 1;
        const healthy = this.stats.healthyIntegrations || 0;
        return Math.round((healthy / total) * 100);
    }
}
