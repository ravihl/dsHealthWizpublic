/* orgHealthDashboard.js */

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrgHealthDashboard extends LightningElement {
    @track activeTab = 'overview';
    @track refreshInterval = 300000; // 300 seconds
    @track isDarkMode = false;
    @track isLoading = false;

    ltabs = [

        
        { label: 'Governor Limits', name: 'limits', icon: 'utility:resource_capacity' },
        { label: 'API Usage', name: 'api', icon: 'utility:connected_apps' },
        { label: 'Storage', name: 'storage', icon: 'utility:database' },
        { label: 'Performance', name: 'performance', icon: 'utility:chart' },
        { label: 'Integrations', name: 'integrations', icon: 'utility:integration' },
        { label: 'Data Quality', name: 'quality', icon: 'utility:check' },
        { label: 'Alerts', name: 'alerts', icon: 'utility:notification' },
        { label: 'Overview', name: 'overview', icon: 'utility:page' }
    ];


    connectedCallback() {
        this.startAutoRefresh();
        this.loadUserPreferences();
    }

    disconnectedCallback() {
        this.stopAutoRefresh();
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.refreshData();
    }

    toggleDarkMode() {
        this.isDarkMode = !this.isDarkMode;
        this.applyTheme();
    }

    startAutoRefresh() {
        this.refreshIntervalId = setInterval(() => {
            this.refreshData();
        }, this.refreshInterval);
    }

    stopAutoRefresh() {
        if (this.refreshIntervalId) {
            clearInterval(this.refreshIntervalId);
        }
    }

    refreshData() {
        this.isLoading = true;
        const event = new CustomEvent('refreshdata', {
            detail: { tab: this.activeTab }
        });
        this.dispatchEvent(event);

        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }

    handleExport() {
        this.showToast('Export Started', 'Your data is being exported...', 'info');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    applyTheme() {
        const container = this.template.querySelector('.dashboard-container');
        if (container) {
            container.classList.toggle('dark-mode', this.isDarkMode);
        }
    }

    loadUserPreferences() {
        // Load user preferences from custom settings or metadata
    }

    isOverviewTab() {   
        this.activeTab = 'overview';
        return this.activeTab === 'overview';
    }
}