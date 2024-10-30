import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFilteredCases from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredCases';
import getCaseCountsByRecordType from '@salesforce/apex/HomeSegurosEmpresasController.getCaseCountsByRecordType';
import getAlertCountsByName from '@salesforce/apex/HomeSegurosEmpresasController.getAlertCountsByName';
import getFilteredAlerts from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredAlerts';
import getCaseCountsByRecordTypeWithScope from '@salesforce/apex/HomeSegurosEmpresasController.getCaseCountsByRecordTypeWithScope';
import getFilteredCasesWithScope from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredCasesWithScope';
import getFormalizacionNuevoNegocioCount from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCount';
import getFormalizacionNuevoNegocioCases from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCases';
import getAllFormalizacionSegurosCount from '@salesforce/apex/HomeSegurosEmpresasController.getAllFormalizacionSegurosCount';
import getAllFormalizacionSegurosCases from '@salesforce/apex/HomeSegurosEmpresasController.getAllFormalizacionSegurosCases';
import getFormalizacionNuevoNegocioCountByRamos from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCountByRamos';
import getFormalizacionNuevoNegocioCasesByRamos from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCasesByRamos';
import getCaseCountsByProcessStatus from '@salesforce/apex/HomeSegurosEmpresasController.getCaseCountsByProcessStatus';
import getFilteredCasesByProcessStatus from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredCasesByProcessStatus';
import getCaseCountsByGEEOrStatus from '@salesforce/apex/HomeSegurosEmpresasController.getCaseCountsByGEEOrStatus';
import getFilteredCasesByGEEOrStatus from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredCasesByGEEOrStatus';
import getCaseCountsByRamosDuplicated from '@salesforce/apex/HomeSegurosEmpresasController.getCaseCountsByRamosDuplicated';
import getFilteredCasesByRamossDuplicated from '@salesforce/apex/HomeSegurosEmpresasController.getFilteredCasesByRamossDuplicated';
import hasPermission from '@salesforce/customPermission/SegEmp_Gestion';
import getFormalizacionNuevoNegocioCountAllRamos from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCountAllRamos';
import getFormalizacionNuevoNegocioCasesAllRamos from '@salesforce/apex/HomeSegurosEmpresasController.getFormalizacionNuevoNegocioCasesAllRamos';
export default class HomeSegurosEmpresa extends NavigationMixin(LightningElement) {
    @track data = [];
    @track columns = [];
    @track totalCases = 0;
    @track totalAlerts = 0;
    @track formalizacionSegurosCount = 0;
    @track allFormalizacionSegurosCount = 0;
    @track formalizacionNuevoNegocioCountByRamos = 0;
    @track formalizacionNuevoNegocioCasesByRamos = [];
    @track formalizacionNuevoNegocioCountAllRamos = 0;
    @track formalizacionNuevoNegocioCasesAllRamos = [];

    @track recordTypeCounts = {
        Orden_de_trabajo_Seguros_de_Empresa: 0,
        Gestion_de_placement: 0,
        Cartera: 0
    };

    @track alertCountsList = [];
    @track selectedType = 'cases';
    @track selectedRecordType = null;
    @track selectedAlertType = null;
    @track currentFilter = 'day';

    @track scopeRecordTypeCounts = {
        Orden_de_trabajo_Seguros_de_Empresa: 0,
        Gestion_de_placement: 0,
        Cartera: 0
    };
    
    @track totalScopeCases = 0;
    @track selectedScopeRecordType = null;
    @track isLoading = false;

    @track processStatusRecordTypeCounts = {
        Orden_de_trabajo_Seguros_de_Empresa: 0,
        Gestion_de_placement: 0,
        Cartera: 0
    };
    @track totalProcessStatusCases = 0;
    @track selectedProcessStatusRecordType = null;

    @track GEEOrStatusRecordTypeCounts = {
        Orden_de_trabajo_Seguros_de_Empresa: 0,
        Gestion_de_placement: 0,
        Cartera: 0
    };
    @track totalGEEOrStatusCases = 0;
    @track selectedGEEOrStatusRecordType = null;

    @track duplicatedRecordTypeCounts = {};

    @track totalDuplicatedCases = 0;
    @track ramoData = [];

    @track selectedDuplicatedRecordType = null;
    @track canViewMisGestiones = false;
    

    connectedCallback() {
        this.applyFilter(this.currentFilter);
        this.checkPermission();
    }

    refreshComponent() {
        this.isLoading = true;
        this.applyFilter(this.currentFilter);
        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }

    checkPermission() {
        if (hasPermission) {
            this.canViewMisGestiones = true;
        }
    }

    applyFilter(timeframe) {
        this.currentFilter = timeframe;
        this.loadCaseCounts(timeframe);
        this.loadAlertCounts(timeframe);
        this.loadScopeCaseCounts(timeframe);
        this.loadProcessStatusCaseCounts(timeframe);  
        this.loadGEEOrStatusCaseCounts(timeframe);

        this.loadFormalizacionSegurosCount(timeframe);
        this.loadAllFormalizacionSegurosCount(timeframe);
        this.loadFormalizacionNuevoNegocioCountByRamos(timeframe);
        this.loadDuplicatedCaseCounts(timeframe);
        this.loadFormalizacionNuevoNegocioCountAllRamos(timeframe);



        if (this.selectedType === 'cases') {
            this.fetchCases(timeframe, this.selectedRecordType);
        } else if (this.selectedType === 'alerts') {
            this.fetchAlerts(timeframe, this.selectedAlertType);
        } else if (this.selectedType === 'scopeCases') {
            this.fetchCasesWithScope(timeframe, this.selectedScopeRecordType);
        } else if (this.selectedType === 'processStatusCases') {
            this.fetchProcessStatusCases(timeframe, this.selectedProcessStatusRecordType);
        } else if (this.selectedType === 'GEEOrStatusCases') {
            this.fetchGEEOrStatusCases(timeframe, this.selectedGEEOrStatusRecordType);
        } else if (this.selectedType === 'formalizacionSeguros') {
            this.fetchFormalizacionSegurosCases(timeframe);
        } else if (this.selectedType === 'allFormalizacionSeguros') {
            this.fetchAllFormalizacionSegurosCases(timeframe);
        } else if (this.selectedType === 'formalizacionNuevoNegocioRamos') {
            this.fetchFormalizacionNuevoNegocioCasesByRamos(timeframe);
        }else if (this.selectedType === 'formalizacionNuevoNegocioAllRamos') {
            this.fetchFormalizacionNuevoNegocioCasesAllRamos(timeframe);
        } else if (this.selectedType === 'duplicatedCases') {
            this.fetchDuplicatedCases(timeframe, this.selectedDuplicatedRecordType);
        }
    }

    get duplicatedRamosKeys() {
        return Object.keys(this.duplicatedRecordTypeCounts);
    }

    processRamoData() {
        this.ramoData = Object.keys(this.duplicatedRecordTypeCounts).map(ramo => {
            return {
                name: ramo,
                count: this.duplicatedRecordTypeCounts[ramo]
            };
        });
    
        const subcountersElement = this.template.querySelector('.subcounters-ramo');
        if (this.ramoData.length > 3) {
            subcountersElement.classList.add('scrollable');
        } else {
            subcountersElement.classList.remove('scrollable');
        }
    }

    loadFormalizacionNuevoNegocioCountAllRamos(timeframe) {
        getFormalizacionNuevoNegocioCountAllRamos({ timeframe: timeframe })
            .then(data => {
                this.formalizacionNuevoNegocioCountAllRamos = data || 0;
            })
            .catch(error => {
                console.error('Error fetching formalizacion nuevo negocio count all ramos:', error);
            });
    }
    loadCaseCounts(timeframe) {
        getCaseCountsByRecordType({ timeframe: timeframe })
            .then(data => {
                this.recordTypeCounts = {
                    Orden_de_trabajo_Seguros_de_Empresa: data.Orden_de_trabajo_Seguros_de_Empresa || 0,
                    Gestion_de_placement: data.Gestion_de_placement || 0,
                    Cartera: data.Cartera || 0
                };
                this.totalCases = Object.values(this.recordTypeCounts).reduce((a, b) => a + b, 0);
            })
            .catch(error => {
                console.error('Error fetching case counts:', error);
            });
    }

    loadAlertCounts(timeframe) {
        getAlertCountsByName({ timeframe: timeframe })
            .then(data => {
                this.alertCountsList = Object.keys(data).map(key => {
                    return { name: key, count: data[key] };
                });
                this.totalAlerts = this.alertCountsList.reduce((total, alert) => total + alert.count, 0);
            })
            .catch(error => {
                console.error('Error fetching alert counts:', error);
            });
    }

    loadScopeCaseCounts(timeframe) {
        getCaseCountsByRecordTypeWithScope({ timeframe: timeframe })
            .then(data => {
                this.scopeRecordTypeCounts = {
                    Orden_de_trabajo_Seguros_de_Empresa: data.Orden_de_trabajo_Seguros_de_Empresa || 0,
                    Gestion_de_placement: data.Gestion_de_placement || 0,
                    Cartera: data.Cartera || 0
                };
                this.totalScopeCases = Object.values(this.scopeRecordTypeCounts).reduce((a, b) => a + b, 0);
            })
            .catch(error => {
                console.error('Error fetching scope case counts:', error);
            });
    }

    loadProcessStatusCaseCounts(timeframe) {
        getCaseCountsByProcessStatus({ timeframe: timeframe })
            .then(data => {
                this.processStatusRecordTypeCounts = {
                    Orden_de_trabajo_Seguros_de_Empresa: data.Orden_de_trabajo_Seguros_de_Empresa || 0,
                    Gestion_de_placement: data.Gestion_de_placement || 0,
                    Cartera: data.Cartera || 0
                };
                this.totalProcessStatusCases = Object.values(this.processStatusRecordTypeCounts).reduce((a, b) => a + b, 0);
            })
            .catch(error => {
                console.error('Error fetching process status case counts:', error);
            });
    }

    loadGEEOrStatusCaseCounts(timeframe) {
        getCaseCountsByGEEOrStatus({ timeframe: timeframe })
            .then(data => {
                this.GEEOrStatusRecordTypeCounts = {
                    Orden_de_trabajo_Seguros_de_Empresa: data.Orden_de_trabajo_Seguros_de_Empresa || 0,
                    Gestion_de_placement: data.Gestion_de_placement || 0,
                    Cartera: data.Cartera || 0
                };
                this.totalGEEOrStatusCases = Object.values(this.GEEOrStatusRecordTypeCounts).reduce((a, b) => a + b, 0);
            })
            .catch(error => {
                console.error('Error fetching GEE or Status case counts:', error);
            });
    }

    loadFormalizacionSegurosCount(timeframe) {
        getFormalizacionNuevoNegocioCount({ timeframe: timeframe })
            .then(data => {
                this.formalizacionSegurosCount = data || 0;
            })
            .catch(error => {
                console.error('Error fetching formalizacion seguros count:', error);
            });
    }

    loadAllFormalizacionSegurosCount(timeframe) {
        getAllFormalizacionSegurosCount({ timeframe: timeframe })
            .then(data => {
                this.allFormalizacionSegurosCount = data || 0;
            })
            .catch(error => {
                console.error('Error fetching all formalizacion seguros count:', error);
            });
    }

    loadFormalizacionNuevoNegocioCountByRamos(timeframe) {
        getFormalizacionNuevoNegocioCountByRamos({ timeframe: timeframe })
            .then(data => {
                this.formalizacionNuevoNegocioCountByRamos = data || 0;
            })
            .catch(error => {
                console.error('Error fetching formalizacion nuevo negocio count by ramos:', error);
            });
    }

    loadDuplicatedCaseCounts(timeframe) {
        getCaseCountsByRamosDuplicated({ timeframe: timeframe })
            .then(data => {
                this.duplicatedRecordTypeCounts = data;
                this.totalDuplicatedCases = Object.values(this.duplicatedRecordTypeCounts).reduce((a, b) => a + b, 0);
                this.processRamoData();
            })
            .catch(error => {
                console.error('Error fetching duplicated case counts:', error);
            });
    }
    fetchFormalizacionNuevoNegocioCasesAllRamos(timeframe) {
        getFormalizacionNuevoNegocioCasesAllRamos({ timeframe: timeframe })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Ramo', fieldName: 'ABA_LIS_Ramo__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching formalizacion nuevo negocio cases all ramos:', error);
                this.data = [];
            });
    }

    fetchFormalizacionNuevoNegocioCasesByRamos(timeframe) {
        getFormalizacionNuevoNegocioCasesByRamos({ timeframe: timeframe })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Ramo', fieldName: 'ABA_LIS_Ramo__c', type: 'text' }
                ]; 
            })
            .catch(error => {
                console.error('Error fetching formalizacion nuevo negocio cases by ramos:', error);
                this.data = [];
            });
    }
    

    fetchCases(timeframe, recordTypeName) {
        getFilteredCases({ timeframe: timeframe, recordTypeName: recordTypeName })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso', 
                        fieldName: 'CaseNumber', 
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Estado del Proceso', fieldName: 'ProcessStatus__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching cases:', error);
                this.data = [];
            });
    }

    fetchDuplicatedCases(timeframe, ramoName) {
        getFilteredCasesByRamossDuplicated({ ramo: ramoName, timeframe: timeframe })
            .then(data => {
                this.data = data.map(record => ({
                    ...record,
                    RecordTypeName: record.RecordType ? record.RecordType.Name : 'N/A'
                }));
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Ramo', fieldName: 'ABA_LIS_Ramo__c', type: 'text' },
                    { label: 'Tipo de Registro', fieldName: 'RecordTypeName', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching duplicated cases:', error);
                this.data = [];
            });
    }
    handleFormalizacionNuevoNegocioAllRamosClick() {
        this.selectedType = 'formalizacionNuevoNegocioAllRamos';
        this.fetchFormalizacionNuevoNegocioCasesAllRamos(this.currentFilter);
    }
    
    handleTotalDuplicatedCasesClick() {
        this.selectedType = 'duplicatedCases';
        this.selectedDuplicatedRecordType = null;
    
        getFilteredCasesByRamossDuplicated({ ramo: '', timeframe: this.currentFilter })
            .then(result => {
                this.data = result;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Ramo', fieldName: 'ABA_LIS_Ramo__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching all cases:', error);
                this.data = [];
            });
    }
    
    

    handleRowAction(event) {
        const recordId = event.detail.row.Id;
        
        if (event.detail.action.name === 'view_alert') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Alert__c',
                    actionName: 'view'
                },
                state: {
                    nooverride: '1'
                }
            });
        } else if (event.detail.action.name === 'view_case') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Case',
                    actionName: 'view'
                },
                state: {
                    nooverride: '1'
                }
            });
        }
    }

    fetchAlerts(timeframe, alertTypeName) {
        getFilteredAlerts({ timeframe: timeframe })
            .then(data => {
                let alerts = data.map(alert => {
                    return {
                        ...alert,
                        formattedDate: new Date(alert.Fecha_Alerta__c).toLocaleDateString('es-ES')
                    };
                });

                if (alertTypeName) {
                    alerts = alerts.filter(alert => alert.ABA_LIS_Nombre__c === alertTypeName);
                }

                this.data = alerts;
                this.columns = [
                    {
                        label: 'Nombre de Alerta',
                        fieldName: 'ABA_LIS_Nombre__c',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'ABA_LIS_Nombre__c' },
                            name: 'view_alert',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Fecha de Alerta', fieldName: 'formattedDate', type: 'date' }
                ];
            })
            .catch(error => {
                console.error('Error fetching alerts:', error);
                this.data = [];
            });
    }

    fetchCasesWithScope(timeframe, recordTypeName) {
        getFilteredCasesWithScope({ timeframe: timeframe, recordTypeName: recordTypeName })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Estado del Proceso', fieldName: 'ProcessStatus__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching cases with scope:', error);
                this.data = [];
            });
    }

    fetchProcessStatusCases(timeframe, recordTypeName) {
        getFilteredCasesByProcessStatus({ timeframe: timeframe, recordTypeName: recordTypeName })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Estado del Proceso', fieldName: 'ProcessStatus__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching process status cases:', error);
                this.data = [];
            });
    }

    fetchGEEOrStatusCases(timeframe, recordTypeName) {
        getFilteredCasesByGEEOrStatus({ timeframe: timeframe, recordTypeName: recordTypeName })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' },
                    { label: 'Estado del Proceso', fieldName: 'ProcessStatus__c', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching GEE or Status cases:', error);
                this.data = [];
            });
    }

    fetchFormalizacionSegurosCases(timeframe) {
        getFormalizacionNuevoNegocioCases({ timeframe: timeframe })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching formalizacion seguros cases:', error);
                this.data = [];
            });
    }

    fetchAllFormalizacionSegurosCases(timeframe) {
        getAllFormalizacionSegurosCases({ timeframe: timeframe })
            .then(data => {
                this.data = data;
                this.columns = [
                    {
                        label: 'Número de Caso',
                        fieldName: 'CaseNumber',
                        type: 'button',
                        typeAttributes: {
                            label: { fieldName: 'CaseNumber' },
                            name: 'view_case',
                            variant: 'base',
                            value: { fieldName: 'Id' }
                        }
                    },
                    { label: 'Asunto', fieldName: 'Subject', type: 'text' },
                    { label: 'Fecha Límite', fieldName: 'Deadline__c', type: 'date' },
                    { label: 'Estado', fieldName: 'Status', type: 'text' }
                ];
            })
            .catch(error => {
                console.error('Error fetching all formalizacion seguros cases:', error);
                this.data = [];
            });
    }

    filterByDay() {
        this.applyFilter('day');
    }

    filterByCurrentWeek() {
        this.applyFilter('week');
    }

    filterByCurrentMonth() {
        this.applyFilter('month');
    }

    handleTotalCasesClick() {
        this.selectedType = 'cases';
        this.selectedRecordType = null;
        this.selectedScopeRecordType = null;
        this.fetchCases(this.currentFilter, null);
    }

    handleTotalAlertsClick() {
        this.selectedType = 'alerts';
        this.selectedAlertType = null;
        this.selectedScopeRecordType = null;
        this.selectedRecordType = null;
        this.fetchAlerts(this.currentFilter, null);
    }

    handleTotalScopeCasesClick() {
        this.selectedType = 'scopeCases';
        this.selectedScopeRecordType = null;
        this.selectedRecordType = null;
        this.fetchCasesWithScope(this.currentFilter, null);
    }

    handleFormalizacionNuevoNegocioClick() {
        this.selectedType = 'formalizacionSeguros';
        this.fetchFormalizacionSegurosCases(this.currentFilter);
    }

    handleAllFormalizacionSegurosClick() {
        this.selectedType = 'allFormalizacionSeguros';
        this.fetchAllFormalizacionSegurosCases(this.currentFilter);
    }

    handleFormalizacionNuevoNegocioByRamosClick() {
        this.selectedType = 'formalizacionNuevoNegocioRamos';
        this.fetchFormalizacionNuevoNegocioCasesByRamos(this.currentFilter);
    }

    handleRecordTypeFilter(event) {
        const recordTypeName = event.currentTarget.dataset.recordType;

        if (this.selectedType === 'scopeCases') {
            this.selectedScopeRecordType = recordTypeName || null;
            this.fetchCasesWithScope(this.currentFilter, this.selectedScopeRecordType);
        } else {
            this.selectedType = 'cases';
            this.selectedRecordType = recordTypeName || null;
            this.fetchCases(this.currentFilter, this.selectedRecordType);
        }
    }

    handleAlertTypeFilter(event) {
        const alertTypeName = event.currentTarget.dataset.alertType;
        this.selectedType = 'alerts';
        this.selectedAlertType = alertTypeName || null;
        this.fetchAlerts(this.currentFilter, this.selectedAlertType);
    }

    handleTotalProcessStatusCasesClick() {
        this.selectedType = 'processStatusCases';
        this.selectedProcessStatusRecordType = null;
        this.fetchProcessStatusCases(this.currentFilter, null);
    }

    handleProcessStatusRecordTypeFilter(event) {
        const recordTypeName = event.currentTarget.dataset.recordType;
        this.selectedType = 'processStatusCases';
        this.selectedProcessStatusRecordType = recordTypeName || null;
        this.fetchProcessStatusCases(this.currentFilter, this.selectedProcessStatusRecordType);
    }

    handleTotalGEEOrStatusCasesClick() {
        this.selectedType = 'GEEOrStatusCases';
        this.selectedGEEOrStatusRecordType = null;
        this.fetchGEEOrStatusCases(this.currentFilter, null);
    }

    handleTotalDuplicatedCasesClick() {
        this.selectedType = 'duplicatedCases';
        this.selectedDuplicatedRecordType = null;
        this.fetchDuplicatedCases(this.currentFilter, null);
    }

    handleGEEOrStatusRecordTypeFilter(event) {
        const recordTypeName = event.currentTarget.dataset.recordType;
        this.selectedType = 'GEEOrStatusCases';
        this.selectedGEEOrStatusRecordType = recordTypeName || null;
        this.fetchGEEOrStatusCases(this.currentFilter, this.selectedGEEOrStatusRecordType);
    }

    handleDuplicatedRecordTypeFilter(event) {
        const ramo = event.currentTarget.dataset.recordType;
        const timeframe = this.currentFilter;

        getFilteredCasesByRamossDuplicated({ ramo: ramo, timeframe: timeframe })
            .then(result => {
                this.data = result;
            })
            .catch(error => {
                console.error('Error fetching cases by ramo:', error);
            });
    }
    
    

    handleTestClick() {
        console.log('Prueba Mi Grupo: Haz clic en la tarjeta');
    }

    get dayButtonClass() {
        return this.currentFilter === 'day' ? 'selected-filter' : '';
    }

    get weekButtonClass() {
        return this.currentFilter === 'week' ? 'selected-filter' : '';
    }

    get monthButtonClass() {
        return this.currentFilter === 'month' ? 'selected-filter' : '';
    }
}