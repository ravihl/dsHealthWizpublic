/* orgHealthDashboard.js */

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrgHealthDashboard extends LightningElement {
    @track activeTab = 'performance';
    @track tabContent = '';
    @track refreshInterval = 300000; // 300 seconds
    @track isDarkMode = false;
    @track isLoading = false;
    @track isOverviewTab = false;
    @track isLimitsTab  = false;     
    @track isApiTab = false;
    @track isStorageTab = false;

    ltabs = [
        { label: 'Overview', name: 'overview', icon: 'utility:page', component: 'c-overview-component' },
        { label: 'Governor Limits', name: 'limits', icon: 'utility:resource_capacity',  component: 'c-governor-limits-monitor' },
        { label: 'API Usage', name: 'api', icon: 'utility:connected_apps', component: 'c-api-usage-tracker' },
        { label: 'Storage', name: 'storage', icon: 'utility:database', component: 'c-storage-monitor' },
        { label: 'Performance', name: 'performance', icon: 'utility:chart', component: 'c-performance-metrics' },
        { label: 'Integrations', name: 'integrations', icon: 'utility:integration', component: 'c-integration-monitor' },
        { label: 'Data Quality', name: 'quality', icon: 'utility:check', component: 'c-data-quality-assessment' },
        { label: 'Alerts', name: 'alerts', icon: 'utility:notification', component: 'c-alert-management' },
        { label: 'Settings', name: 'settings', icon: 'utility:settings', component: 'c-dashboard-settings' }
    ];

    connectedCallback() {
        this.startAutoRefresh();
        this.loadUserPreferences();
    }

    disconnectedCallback() {
        this.stopAutoRefresh();
    }

    handleTabChange(event) {
        const tabValue = event.target.value;
        this.activeTab = tabValue;
        // Perform any logic needed when a tab is selected.
        console.log(`Tab with value "${tabValue}" was activated.`);
        this.updateTabContent();
        //this.refreshData();
    }

    toggleDarkMode() {
        this.isDarkMode = !this.isDarkMode;
        console.log('Dark mode:', this.isDarkMode);
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
        //console.log('Applying theme. Dark mode:', this.isDarkMode);
        /*const container = this.template.querySelector('.dashboard-container');
        console.log('Container element:', container);
        if (container) {
            console.log('Toggling dark mode class');
            container.classList.toggle('dark-mode', this.isDarkMode);
            console.log('Dark mode class applied:', container.classList.contains('dark-mode'));
        }
     */
        // Ensure container exists
        const container = this.template.querySelector('.dashboard-container');
        //console.log('Container element:', container);

        if (container) {
            // Explicit add/remove for clarity
            if (this.isDarkMode) {
            container.classList.add('dark-mode');
            //console.log('Dark mode class added');
            } else {
            container.classList.remove('dark-mode');
            //console.log('Dark mode class removed');
            }
        } else {
            console.warn('dashboard-container not found in template');
        }
    }

        

    loadUserPreferences() {
        // Load user preferences from custom settings or metadata
    }

    updateTabContent() {
        switch(this.activeTab) {
            case 'overview':
                console.log ('*****Overview Tab Active');
                this.isOverviewTab = true;
                this.isLimitsTab = false;
                this.isApiTab = false;
                this.isStorageTab = false;
                break;
            case 'limits':
                console.log ('*****Limits Tab Active');
                this.isOverviewTab = false;
                this.isLimitsTab = true;
                this.isApiTab = false;
                this.isStorageTab = false;
                break;
            case 'api':
                console.log ('*****API Tab Active');
                this.isOverviewTab = false;
                this.isLimitsTab = false;
                this.isApiTab = true;
                this.isStorageTab = false;
                break;
            case 'storage':
                console.log ('*****API Tab Active');
                this.isOverviewTab = false;
                this.isLimitsTab = false;
                this.isApiTab = false;
                this.isStorageTab = true;
                break;    
            default:
                this.isOverviewTab = true;
        }
    }

        get activeComponent() {
        const activeTab = this.ltabs.find(tab => tab.name === this.activeTab);
        return activeTab ? activeTab.component : null;
    }
}