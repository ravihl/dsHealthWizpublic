import { LightningElement, wire, track } from 'lwc'; 

import captureTop10DataStorageUsage from '@salesforce/apex/StorageAnalyzerController.captureTop10DataStorageUsage'; 

import getLatestDataStorageUsage from '@salesforce/apex/StorageAnalyzerController.getLatestDataStorageUsage'; 

import getOverallDataStorageUsage from '@salesforce/apex/StorageAnalyzerController.getOverallDataStorageUsage'; 

import { refreshApex } from '@salesforce/apex'; 

import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

 

const COLUMNS = [ 

    { label: 'Object Name', fieldName: 'Object_Name__c', type: 'text' }, 

    { label: 'Record Count', fieldName: 'Record_Count__c', type: 'number' }, 

    { label: 'Storage Used (KB)', fieldName: 'Data_Storage_Used__c', type: 'number' }, 

    { label: 'Percent Used', fieldName: 'Storage_Used_Percentage__c', type: 'percent' }, 

    { label: 'Date', fieldName: 'Date__c', type: 'date' } 

]; 

 

export default class DataStorageUsage extends LightningElement { 

    @track data; 

    @track error; 

    @track overallUsage = {}; 

    columns = COLUMNS; 

    wiredResult; 

 

   @wire(getLatestDataStorageUsage) 
    wiredSnapshots(result) { 

        this.wiredResult = result; 

        if (result.data) { 

            this.data = result.data; 

            this.error = undefined; 

        } else if (result.error) { 

            this.error = result.error; 

        } 

    }  

    @wire(getOverallDataStorageUsage) 
    wiredOverall(result) { 
        if (result.data) { 
            this.overallUsage = result.data; 
        } else if (result.error) { 
           console.error(result.error); 
        } 
    } 

 

    async handleCapture() { 

        try { 

            await captureTop10DataStorageUsage(); 

            this.dispatchEvent( 

                new ShowToastEvent({ 

                    title: 'Success', 

                    message: 'Top-10 Data Storage snapshot captured successfully.', 

                    variant: 'success' 

                }) 

            ); 

            await refreshApex(this.wiredResult); 

        } catch (error) { 

            this.dispatchEvent( 

                new ShowToastEvent({ 

                    title: 'Error', 

                    message: error.body ? error.body.message : error.message, 

                    variant: 'error' 

                }) 

            ); 

        } 

    } 

    get percentUsed() { 

    return this.overallUsage?.percentUsed 

        ? Math.round(this.overallUsage.percentUsed) 

        : 0; 

} 

 

get totalUsedMB() { 

        return this.overallUsage?.totalUsedMB 

            ? this.overallUsage.totalUsedMB.toFixed(2) 

            : 0; 

    } 

 

    get orgLimitMB() { 

        return this.overallUsage?.orgLimitMB 

            ? this.overallUsage.orgLimitMB 

            : 0; 

    } 

} 
