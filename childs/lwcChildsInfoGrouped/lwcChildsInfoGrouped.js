
import { LightningElement, api, track } from 'lwc';
import getInitData from '@salesforce/apex/LwcChildsInfoGroupedController.getInitData';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { createMessageContext, releaseMessageContext, publish, subscribe } from 'lightning/messageService';
import childCasesCreatedMC from '@salesforce/messageChannel/ChildCasesCreated__c';

import LABEL_NUEVONEGOCIO_SOLICITUD from '@salesforce/label/c.RT_DevName_Case_Solicitud_NuevoNegocio';
import LABEL_NUEVONEGOCIO_FORMALIZACION from '@salesforce/label/c.RT_DevName_Case_Formalizacion_NuevoNegocio';


import modal from '@salesforce/resourceUrl/CustomAccordionCSS';

export default class LwcChildsInfoGrouped extends NavigationMixin(LightningElement) {
    @api recordId;
    @api label;
    @track data = {};
    showSpinner = true;
    context = createMessageContext();
    subscription;

    connectedCallback() {
        loadStyle(this, modal);
        this.subscribeMC();

        this.getInitData();
    }

    subscribeMC() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.context, childCasesCreatedMC, (message) => {
            this.handleMessage(message);
        });
    }

    handleMessage(message) {
        if (message.recordId === this.recordId) {
            this.handleRefresh();
        }
    }

    getInitData() {
        this.showSpinner = true;
        getInitData ({
            caseId: this.recordId
        }).then((result) => {
            this.data = result.map(function(currentItem, index, actualArray){
                const title = currentItem.childCase.CaseNumber+ ' - ' +currentItem.childCase.Subject;
                const isFormalizacion = (currentItem.childCase.RecordType.DeveloperName == LABEL_NUEVONEGOCIO_FORMALIZACION);

                const updatedEmails = currentItem.lEmailMessages.map(function(currentEmail){
                                                                           return {...currentEmail, viewStatus:'View More'};
                                                       });
                const updatedCaseComments = currentItem.lCaseComments.map(function(currentCaseComment){
                                                           return {...currentCaseComment, viewStatus:'View More'};
                                                       });
                const updatedFeedItems = currentItem.lFeedItems.map(function(currentFeedItem){
                                                           return {...currentFeedItem, viewStatus:'View More'};
                                                       });
                const mergedObject = {...currentItem, lEmailMessages: updatedEmails, lCaseComments: updatedCaseComments, lFeedItems: updatedFeedItems, title: title, isFormalizacion: isFormalizacion, activeSections : [], activeHighSection : []};
                return mergedObject;
            });

                this.showSpinner = false;
        }).catch((error) => {
            console.log('****ERROR: '+JSON.stringify(error));
            this.showSpinner = false;

        });
    }




    viewMore(event) {
        const caseId = event.currentTarget.dataset.caseid;
        const objectType = event.currentTarget.dataset.objecttype;
        var newData = [];
        newData = this.data.map(function(currentItem){
                if (currentItem.Id != caseId) {
                    return currentItem;
                } else {
                    if (objectType == 'Email'){
                        let updatedRecords = this.updateViewStatus(event,  currentItem.lEmailMessages);
                        return {...currentItem, lEmailMessages: updatedRecords};
                    } else if (objectType == 'Comment'){
                        let updatedRecords = this.updateViewStatus(event, currentItem.lCaseComments);
                        return {...currentItem, lCaseComments: updatedRecords};
                    } else if (objectType == 'FeedItem'){
                        let updatedRecords = this.updateViewStatus(event, currentItem.lFeedItems);
                        return {...currentItem, lFeedItems: updatedRecords};
                    } else {
                        return currentItem;
                    }
                }
            }, this);
        this.data = newData;
    }

    updateViewStatus(event, array) {
        const recordId = event.currentTarget.dataset.auxid;
        const selectorString = '[data-clampid="'+recordId+'"]';

        let newArray = array.map(function(currentRecord){
           if (currentRecord.Id != event.currentTarget.dataset.auxid) {
               return currentRecord;
           } else {
               if (currentRecord.viewStatus == 'View More') {
                   this.template.querySelector(selectorString).classList.remove('slds-line-clamp_small');
                   return {...currentRecord, viewStatus: 'View Less'};

               } else {
                   this.template.querySelector(selectorString).classList.add('slds-line-clamp_small');
                   return {...currentRecord, viewStatus: 'View More'};
               }
           }
       }, this);
        return newArray;
    }

    handleCollapseAll() {
        var newData = [];
        newData = this.data.map(function(currentItem){
            const mergedObject = {...currentItem, activeSections : [], activeHighSection : []};
            return mergedObject;
        });
        this.data = newData;
    }

    handleExpandAll() {
        var newData = [];
        newData = this.data.map(function(currentItem){
            const mergedObject = {...currentItem, activeSections : ["Emails", "Comments", "Files", "FeedItems"], activeHighSection : ["RelatedData"]};
            return mergedObject;
        });
        this.data = newData;
    }

    handleSingleCollapse(event) {
        let recordId = event.target.dataset.id;
        var newData = [];
        newData = this.data.map(function(currentItem){
            if (currentItem.childCase.Id == event.target.dataset.id) {
                const mergedObject = {...currentItem, activeSections : [], activeHighSection : []};
                return mergedObject;
            } else {
                return currentItem;
            }
        });
        this.data = newData;
    }

    handleSingleExpand(event) {
        let recordId = event.target.dataset.id;
        var newData = [];
        newData = this.data.map(function(currentItem){
            if (currentItem.childCase.Id == event.target.dataset.id) {
                const mergedObject = {...currentItem, activeSections : ["Emails", "Comments", "Files", "FeedItems"], activeHighSection : ["RelatedData"]};
                return mergedObject;
            } else {
                return currentItem;
            }
        });
        this.data = newData;
    }

    handleOpen(event) {
        this.navigateToRecordViewPage(event.currentTarget.dataset.id);
    }

    navigateToRecordViewPage(recordId) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: recordId,
            actionName: "view",
          },
        });
    }

    handleRefresh() {
        this.getInitData();
    }

    navigateToFiles(recordId) {
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
            attributes: {
                pageName: "filePreview",
            },
            state: {
                recordIds: recordId,
                selectedRecordId: recordId,
            },
        });
    }

    get hasNotChildCases() {
            return !this.hasChildCases;
        }
    get hasChildCases() {
            return (this.data && this.data.length >0);
        }


}