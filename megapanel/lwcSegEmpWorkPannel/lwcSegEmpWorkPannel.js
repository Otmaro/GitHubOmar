

import { LightningElement, api, wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import { showSuccessToast, showErrorToast } from 'c/lwcToastUtils'
import { refreshApex } from '@salesforce/apex';
import { createMessageContext, releaseMessageContext, publish, subscribe } from 'lightning/messageService';
import childCasesCreatedMC from '@salesforce/messageChannel/ChildCasesCreated__c';
import {GENERACION_PRESUPUESTO, NOTIFY_PLACEMENT, MODIFY_QUOTE, CHANGE_RISK, COBERTURA_FINISHED} from 'c/lwcSegEmpWorkPannelModal';
import WorkPannelModal from 'c/lwcSegEmpWorkPannelModal';
import WorkPannelClosingModal from 'c/lwcSegEmpWorkPannelClosingModal';

import getDataTree from '@salesforce/apex/LwcSegEmpWorkPannelController.getDataTree';
import assignCasesToMe from '@salesforce/apex/LwcSegEmpWorkPannelController.assignCasesToMe';
import setAsVisto from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsVisto';
import setAsEstudio from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsEstudio';
import setAsPdtGEE from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsPdtGEE';
import removePdtGEE from '@salesforce/apex/LwcSegEmpWorkPannelController.removePdtGEE';
import setAsPdtCliente from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsPdtCliente';
import removePdtCliente from '@salesforce/apex/LwcSegEmpWorkPannelController.removePdtCliente';
import startWork from '@salesforce/apex/LwcSegEmpWorkPannelController.startWork';
import stopWork from '@salesforce/apex/LwcSegEmpWorkPannelController.stopWork';
import finishEstudio from '@salesforce/apex/LwcSegEmpWorkPannelController.finishEstudio';
import setAsPdtAseguradora from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsPdtAseguradora';
import removePdtAseguradora from '@salesforce/apex/LwcSegEmpWorkPannelController.removePdtAseguradora';
import reopenSolicitud from '@salesforce/apex/LwcSegEmpWorkPannelController.reopenSolicitud';
import coberturaReceivedDoc from '@salesforce/apex/LwcSegEmpWorkPannelController.coberturaReceivedDoc';
import setAsComputado from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsComputado';
import setPolizaAsRevisedByGEE from '@salesforce/apex/LwcSegEmpWorkPannelController.setPolizaAsRevisedByGEE';
import setAsFormalizado from '@salesforce/apex/LwcSegEmpWorkPannelController.setAsFormalizado';

import LABEL_NUEVONEGOCIO_ORDEN from '@salesforce/label/c.RT_DevName_Case_OrdenTrabajo_NuevoNegocio';
import LABEL_NUEVONEGOCIO_GESTION from '@salesforce/label/c.RT_DevName_Case_Gestion_NuevoNegocio';
import LABEL_NUEVONEGOCIO_SOLICITUD from '@salesforce/label/c.RT_DevName_Case_Solicitud_NuevoNegocio';
import LABEL_NUEVONEGOCIO_FORMALIZACION from '@salesforce/label/c.RT_DevName_Case_Formalizacion_NuevoNegocio';

import LABEL_PROCESSSTATUS_PDT_GEE from '@salesforce/label/c.ProcessStatus_PteGEE';
import LABEL_PROCESSSTATUS_PDT_CLIENTE from '@salesforce/label/c.ProcessStatus_PdtCliente';
import LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE from '@salesforce/label/c.ProcessStatus_PdtRevisionInfoGEE';
import LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA from '@salesforce/label/c.ProcessStatus_PdtRevisionInfoAseguradora';
import LABEL_PROCESSSTATUS_PDT_GESTIONPLACEMENT from '@salesforce/label/c.ProcessStatus_PdtGestionPlacement';
import LABEL_PROCESSSTATUS_PDT_ASEGURADORA from '@salesforce/label/c.ProcessStatus_PdtAseguradora';
import LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA from '@salesforce/label/c.ProcessStatus_PdtRevisionPropuesta';
import LABEL_PROCESSSTATUS_ENCURSO from '@salesforce/label/c.ProcessStatus_EnCurso';
import LABEL_PROCESSSTATUS_RECOTIZACION from '@salesforce/label/c.ProcessStatus_Recotizacion';
import LABEL_PROCESSSTATUS_COMPUTADO from '@salesforce/label/c.ProcessStatus_Contabilizado';

import LABEL_CASESTATUS_NUEVO from '@salesforce/label/c.CaseStatus_Nuevo';
import LABEL_CASESTATUS_VISTO from '@salesforce/label/c.CaseStatus_Visto';
import LABEL_CASESTATUS_ESTUDIO from '@salesforce/label/c.CaseStatus_Estudio';
import LABEL_CASESTATUS_SOLICITUD_MERCADO from '@salesforce/label/c.CaseStatus_SolicitudesDeMercado';
import LABEL_CASESTATUS_ENGESTIONCONASEGURADORA from '@salesforce/label/c.CaseStatus_EnGestionConAseguradora';
import LABEL_CASESTATUS_PROPUESTAHABILITADA from '@salesforce/label/c.CaseStatus_PropuestasHabilitadasAComercial';
import LABEL_CASESTATUS_PRESUPUESTOHABILITADO from '@salesforce/label/c.CaseStatus_PresupuestoHabilitado';
import LABEL_CASESTATUS_PRESENTADAOFERTA from '@salesforce/label/c.CaseStatus_PresentadaOferta';
import LABEL_CASESTATUS_ORDENEMISION from '@salesforce/label/c.CaseStatus_OrdenEmision';
import LABEL_CASESTATUS_FORMALIZANDO from '@salesforce/label/c.CaseStatus_Formalizando';
import LABEL_CASESTATUS_SOLICITUDCOBERTURA from '@salesforce/label/c.CaseStatus_SolicitudDeCobertura';
import LABEL_CASESTATUS_COBERTURAACEPTADA_PDTDOC from '@salesforce/label/c.CaseStatus_CoberturaAceptadaPdtDoc';
import LABEL_CASESTATUS_ENREVISION_DOCFORMALIZACION from '@salesforce/label/c.CaseStatus_EnRevisionDocFormalizacion';
import LABEL_CASESTATUS_ENTREGADAPOLIZA from '@salesforce/label/c.CaseStatus_EntregadaPoliza';
import LABEL_CASESTATUS_REVISADAPOLIZA from '@salesforce/label/c.CaseStatus_RevisadaPoliza';
import LABEL_CASESTATUS_FORMALIZADA from '@salesforce/label/c.CaseStatus_Formalizada';
import LABEL_CASESTATUS_INICIOGESTION from '@salesforce/label/c.CaseStatus_InicioDeGestion';

const PENDING_GEE_STATUS = [LABEL_CASESTATUS_PROPUESTAHABILITADA, LABEL_CASESTATUS_PRESUPUESTOHABILITADO, LABEL_CASESTATUS_PRESENTADAOFERTA];

const LABEL_CASERISKSTATUS_NOREQUIERE = 'No requiere';
const LABEL_CASERISKSTATUS_ACEPTADO = 'Aceptado';


import LABEL_QUOTESTATUS_PRESENTADA from '@salesforce/label/c.QuoteStatus_Presentado';

import LABEL_PROPOSALSTATUS_INVALIDA from '@salesforce/label/c.ProposalStatus_Invalida';
import LABEL_PROPOSALSTATUS_VALIDA from '@salesforce/label/c.ProposalStatus_Valida';

import CASE_RTDEVNAME_FIELD from '@salesforce/schema/Case.RecordType.DeveloperName';
import CASE_RTNAME_FIELD from '@salesforce/schema/Case.RecordType.Name';
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CASE_PROCESSSTATUS_FIELD from '@salesforce/schema/Case.ProcessStatus__c';
import CASE_PROPOSALSTATUS_FIELD from '@salesforce/schema/Case.ProposalStatus__c';
import CASE_RISKVERIFICATIONSTATUS_FIELD from '@salesforce/schema/Case.RiskVerificationStatus__c';
import CASE_CASENUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import CASE_CREATEDDATE_FIELD from '@salesforce/schema/Case.CreatedDate';
import CASE_OWNERID_FIELD from '@salesforce/schema/Case.OwnerId';
import CASE_DEADLINE_FIELD from '@salesforce/schema/Case.Deadline__c';
import CASE_OPPORTUNITYID_FIELD from '@salesforce/schema/Case.ABA_Opportunity__c';
import CASE_OPPORTUNITYOWNER_FIELD from '@salesforce/schema/Case.ABA_Opportunity__r.OwnerId';
import CASE_FECHAEFECTO_FIELD from '@salesforce/schema/Case.ABA_DATE_Fecha_de_efecto__c';
import CASE_FECHAVENCIMIENTO_FIELD from '@salesforce/schema/Case.ABA_DATE_Fecha_de_vencimiento__c';
import CASE_ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import CASE_PARENTSTATUS_FIELD from '@salesforce/schema/Case.Parent.Status';
import CASE_FECHAEFECTOOPP_FIELD from '@salesforce/schema/Case.ABA_Opportunity__r.ABA_DATE_Fecha_de_efecto__c';
import CASE_OFICINAGESTORAACCOUNT_FIELD from '@salesforce/schema/Case.Account.ABA_TX_Oficina_gestora__c';
import CASE_CARTERAACCOUNT_FIELD from '@salesforce/schema/Case.Account.ABA_TX_Cartera__c';
import CASE_ASEGURADORANAME_FIELD from '@salesforce/schema/Case.ABA_Aseguradora__r.Name';
import getNumeroAlertasActivas from '@salesforce/apex/LwcSegEmpWorkPannelController.getNumeroAlertasActivas';


const caseFields = [CASE_RTDEVNAME_FIELD,
    CASE_RTNAME_FIELD,
    CASE_STATUS_FIELD,
    CASE_SUBJECT_FIELD,
    CASE_PROCESSSTATUS_FIELD,
    CASE_PROPOSALSTATUS_FIELD,
    CASE_RISKVERIFICATIONSTATUS_FIELD,
    CASE_CASENUMBER_FIELD,
    CASE_CREATEDDATE_FIELD,
    CASE_OWNERID_FIELD,
    CASE_OPPORTUNITYID_FIELD,
    CASE_DEADLINE_FIELD,
    CASE_OPPORTUNITYOWNER_FIELD,
    CASE_FECHAEFECTO_FIELD,
    CASE_FECHAVENCIMIENTO_FIELD,
    CASE_ISCLOSED_FIELD,
    CASE_PARENTSTATUS_FIELD,
    CASE_FECHAEFECTOOPP_FIELD,
    CASE_OFICINAGESTORAACCOUNT_FIELD,
    CASE_ASEGURADORANAME_FIELD,
    CASE_CARTERAACCOUNT_FIELD];
const currentUserFields = [USER_PROFILENAME_FIELD];

import userId from "@salesforce/user/Id";
import USER_PROFILENAME_FIELD from '@salesforce/schema/User.Profile.Name';

const GENERIC_SUCCESS_MESSAGE = 'Proceso realizado con éxito';

export default class LwcSegEmpWorkPannel extends LightningElement {
    context = createMessageContext();

    @api recordId;
    dataTree;
    userId = userId;
    userProfileName;
    ampm = false
    _caseWireFinished = false;
    _userWireFinished = false;
    _genericSpinner = false;
    amITheCaseOwner = false;
    amITheOpportunityOwner = false;
    _case;
    numeroAlertasActivas = 0;
    wiredAlertasResult;
    label = {
            LABEL_PROCESSSTATUS_COMPUTADO
        }


    @wire (getRecord, {recordId: "$userId", fields: currentUserFields })
    wiredCurrentUser({ error, data }) {
        if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
             this.userWireFinished = true;

        }
        else if (error) {
             console.error('Error:', error);
             this.userWireFinished = true;

         }
    }

    @wire(getRecord, { recordId: "$recordId", fields: caseFields })
    wiredCase(wireResult) {
         const { data, error } = wireResult;
         this._wiredData = wireResult;
         if (data) {
             this._case = data;
             this.handleGetDataTree();
             this.caseWireFinished = true;

         } else if (error) {
             console.error('Error:', error);
             this.caseWireFinished = true;
         }
     };

     @wire(getNumeroAlertasActivas, { caseId: '$recordId' })
     wiredAlertas(result) {
         this.wiredAlertasResult = result;
         if (result.data > 0) {
             this.numeroAlertasActivas = result.data;
         } else {
             this.numeroAlertasActivas = 0;
         }
     }

     handleAlertRefresh() {
        refreshApex(this.wiredAlertasResult)
    }


    handleGetDataTree() {
            this._genericSpinner = true;
             getDataTree({
                 opportunityId : this.opportunityId
             }).then((result)=>{
                 this.dataTree = result;
                 this._genericSpinner = false;

             }).catch((error) =>{
                 console.error('Error:', error);
                 this._genericSpinner = false;
             });
        }

    publishMC() {
     const message = {
         recordId: this.recordId
     };
     publish(this.context, childCasesCreatedMC, message);
    }

    handleAssignToMe() {
        this._genericSpinner = true;
        assignCasesToMe({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
    }

    handleCaseRefresh() {
        this._genericSpinner = true;
        refreshApex(this._wiredData)
        .then(() => {
                this.handleGetDataTree();
                this.handleAlertRefresh();
                })
        .catch(() => {
                this._genericSpinner = false;
        });

    }

    handleSetAsVisto() {
        this._genericSpinner = true;
        setAsVisto({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });

        }

    handleStartStudio() {
        this._genericSpinner = true;
        setAsEstudio({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleFinishEstudio() {
        this._genericSpinner = true;
        finishEstudio({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetAsPdtGEE() {
        this._genericSpinner = true;
        setAsPdtGEE({
                opportunityId : this.opportunityId,
                caseId: this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleRemovePdtGEE() {
        this._genericSpinner = true;
        removePdtGEE({
                opportunityId : this.opportunityId,
                caseId: this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetAsPdtCliente() {
        this._genericSpinner = true;
        setAsPdtCliente({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleRemovePdtCliente() {
        this._genericSpinner = true;
        removePdtCliente({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleStartWork() {
        this._genericSpinner = true;
        startWork({
                opportunityId : this.opportunityId,
                caseId : this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                    this.publishMC();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleStopWork() {
        this._genericSpinner = true;
        stopWork({
                opportunityId : this.opportunityId,
                caseId : this.recordId,
                pendingState: false,
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                    this.publishMC();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleStopAndPendingWork() {
        this._genericSpinner = true;
        stopWork({
                opportunityId : this.opportunityId,
                caseId : this.recordId,
                pendingState: true,
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                    this.publishMC();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetAsPdtAseguradora() {
        this._genericSpinner = true;
        setAsPdtAseguradora({
                opportunityId : this.opportunityId,
                caseId : this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleRemovePdtAseguradora() {
        this._genericSpinner = true;
        removePdtAseguradora({
                opportunityId : this.opportunityId,
                caseId : this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleReopenSolicitud() {
        this._genericSpinner = true;
        reopenSolicitud({
                opportunityId : this.opportunityId,
                caseId : this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    async handleRevisedInfoGEE() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE,
            caseId: this.recordId,
            opportunityId: this.opportunityId

        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
            this.publishMC();
        } else if (result && result.status == 'ERROR') {
            this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
             this.publishMC();
        }
    }

    async handleRevisedInfoAseguradora() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId

        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleRevisedProposal() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId

        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleGenerateQuote() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: GENERACION_PRESUPUESTO,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId

        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleNotifyPlacement() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: NOTIFY_PLACEMENT,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId

        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleQuoteModification() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: MODIFY_QUOTE,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId
        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleChangeRisk() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: CHANGE_RISK,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId
        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
            if (this.isGestion) {
                this.publishMC();
            }

        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    async handleCoberturaFinished() {
        let result = await WorkPannelModal.open({
            size: 'small',
            modalType: COBERTURA_FINISHED,
            caseId: this.recordId,
            case: this.case,
            opportunityId: this.opportunityId
        });
        if (result && result.status == 'SUCCESS') {
            this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
            this.handleCaseRefresh();
            if (this.isGestion) {
                this.publishMC();
            }

        } else if (result && result.status == 'ERROR') {
             this.dispatchEvent(showErrorToast('Error: '+result.message));
             this.handleCaseRefresh();
         }
    }

    handleCoberturaReceivedDoc() {
        this._genericSpinner = true;
        coberturaReceivedDoc({
                opportunityId : this.opportunityId,
                caseId: this.recordId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();

                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetAsComputadoManual() {
        this._genericSpinner = true;
        setAsComputado({
                opportunityId : this.opportunityId,
                isManual: true
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetPolizaForRevision() {
        this._genericSpinner = true;
        setAsComputado({
                opportunityId : this.opportunityId,
                isManual: false
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetPolizaAsRevisedByGEE() {
        this._genericSpinner = true;
        setPolizaAsRevisedByGEE({
                opportunityId : this.opportunityId,
                isManual: false
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

    handleSetAsFormalizado() {
        this._genericSpinner = true;
        setAsFormalizado({
                opportunityId : this.opportunityId
            }).then((result) => {
                if (result.isSuccess) {
                    this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                    this.handleCaseRefresh();
                } else {
                    this.dispatchEvent(showErrorToast('Error: '+result.message));
                }
                this._genericSpinner = false;
            }).catch((error)=> {
                    this.dispatchEvent(showErrorToast('Error: '+JSON.stringify(error)));
                this._genericSpinner = false;
                });
        }

        async handleCloseCase() {
            let result = await WorkPannelClosingModal.open({
                size: 'small',
                caseId: this.recordId,
                opportunityId: this.opportunityId
            });
            if (result && result.status == 'SUCCESS') {
                this.dispatchEvent(showSuccessToast(GENERIC_SUCCESS_MESSAGE));
                this.handleCaseRefresh();
                if (this.isGestion) {
                    this.publishMC();
                }

            } else if (result && result.status == 'ERROR') {
                 this.dispatchEvent(showErrorToast('Error: '+result.message));
                 this.handleCaseRefresh();
             }
        }

   setOwners() {
            if (this._caseWireFinished && this._userWireFinished) {
                 if (this.userId == this.ownerId) {
                    this.amITheCaseOwner = true;
                 } else {
                     this.amITheCaseOwner = false;
                 }
                 if (this.userId == this.oppOwnerId) {
                    this.amITheOpportunityOwner = true;
                 } else {
                     this.amITheOpportunityOwner = false;
                 }

            } else {
                this.amITheCaseOwner = false;
                this.amITheOpportunityOwner = false;
            }
        }




//setters
    set caseWireFinished(value) {
            this._caseWireFinished = value;
            this.setOwners();
        }

    set userWireFinished(value) {
            this._userWireFinished = value;
            this.setOwners();
    }


//Getter Fields

    get case() {
            return this._case;
    }

    get caseNumber() {
        if (this._case) {
            return this._case.fields.CaseNumber.value;
        } else {
            return null;
        }
    }

    get subject() {
        if (this._case) {
            return this._case.fields.Subject.value;
        } else {
            return null;
        }
    }

    get ownerId() {
        if (this._case) {
            return this._case.fields.OwnerId.value;
        } else {
            return null;
        }
    }

    get recordTypeName() {
        if (this._case) {
            return this._case.fields.RecordType.value.fields.Name.value;
        } else {
            return null;
        }
    }

    get oppOwnerId() {
        if (this._case) {
            return this._case.fields.ABA_Opportunity__r.value.fields.OwnerId.value;
        } else {
            return null;
        }
    }

    get recordTypeDevName() {
        if (this._case) {
            return this._case.fields.RecordType.value.fields.DeveloperName.value;
        } else {
            return null;
        }
    }

    get cartera() {
        if (this._case && this._case.fields.Account) {
            return this._case.fields.Account.value.fields.ABA_TX_Cartera__c.value;
        } else {
            return null;
        }
    }

    get parentCaseStatus() {
        if (this._case && this._case.fields.Parent.value) {
            return this._case.fields.Parent.value.fields.Status.value;
        } else {
            return null;
        }
    }

    get createdDate() {
        if (this._case) {
            return this._case.fields.CreatedDate.value;
        } else {
            return null;
        }
    }

    get status() {
        if (this._case) {
            return this._case.fields.Status.value;
        } else {
            return null;
        }
    }

    get processStatus() {
        if (this._case && this._case.fields.ProcessStatus__c.value != null) {
            return this._case.fields.ProcessStatus__c.value.split(';');
        } else {
            return [];
        }
    }

    get gestionProcessStatus() {
            if (this.dataTree && this.dataTree.gestion && this.dataTree.gestion.ProcessStatus__c != null) {
                return this.dataTree.gestion.ProcessStatus__c.split(';');
            } else {
                return [];
            }
        }

    get formalizacionStatus() {
            if (this.dataTree && this.dataTree.formalizacion && this.dataTree.formalizacion.Status != null) {
                return this.dataTree.formalizacion.Status;
            } else {
                return null;
            }
        }

    get proposalStatus() {
        if (this._case) {
            return this._case.fields.ProposalStatus__c.value;
        } else {
            return [];
        }
    }

    get deadline() {
        if (this._case) {
            return this._case.fields.Deadline__c.value;
        } else {
            return [];
        }
    }

    get opportunityId() {
        if (this._case) {
            return this._case.fields.ABA_Opportunity__c.value;
        } else {
            return null;
        }
    }

    get isClosed() {
        if (this._case) {
            return this._case.fields.IsClosed.value;
        } else {
            return null;
        }
    }

    get isFormalizacionOpen() {

        if (this.dataTree && this.dataTree.formalizacion && !this.dataTree.formalizacion.IsClosed) {
            return true;
        } else {
            return false;
        }

    }

    get riskVerificationStatus() {
        if (this._case) {
          return this._case.fields.RiskVerificationStatus__c.value;
        } else {
          return null;
        }
    }

    get aseguradoraName() {
        if (this._case && this.isSolicitud) {
          return this._case.fields.ABA_Aseguradora__r.value.fields.Name.value;
        } else {
          return null;
        }
    }


//getter methods
    get isOrden() {
            return this.recordTypeDevName == LABEL_NUEVONEGOCIO_ORDEN;
        }

    get isGestion() {
            return this.recordTypeDevName == LABEL_NUEVONEGOCIO_GESTION;
        }

    get isSolicitud() {
            return this.recordTypeDevName == LABEL_NUEVONEGOCIO_SOLICITUD;
        }

    get isFormalizacion() {
            return this.recordTypeDevName == LABEL_NUEVONEGOCIO_FORMALIZACION;
        }

    get isPendingGEE() {
            return (this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GEE) || PENDING_GEE_STATUS.includes(this.status));
        }

    get isEnCurso() {
            return ((!this.isOrden && this.processStatus.includes(LABEL_PROCESSSTATUS_ENCURSO)) || (this.isOrden && this.gestionProcessStatus.includes(LABEL_PROCESSSTATUS_ENCURSO)));
        }

    get isPendingAseguradora() {
            return (this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_ASEGURADORA));
        }

    get isPendingActionFromPlacement() {
            return (this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA)
            || this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE)
            || this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA)
            || this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GESTIONPLACEMENT)
            );
        }

    get isPendingOutsidePlacement() {
            return (this.isPendingAseguradora || this.isPendingGEE);
        }

    get isRiskVerificationOK() {
            return (this.riskVerificationStatus == LABEL_CASERISKSTATUS_NOREQUIERE || this.riskVerificationStatus == LABEL_CASERISKSTATUS_ACEPTADO);
        }

    get isFormalizando() {
            return (this.status == LABEL_CASESTATUS_ORDENEMISION
                || this.status == LABEL_CASESTATUS_FORMALIZANDO)
        }

    get isContabilizado() {
            return this.processStatus.includes(LABEL_PROCESSSTATUS_COMPUTADO);
        }

    get showProposalStatusField() {
            return this.isGestion || this.isSolicitud;
        }

    get showCarteraField() {
            return (this.isGestion || this.isOrden);
        }

    get showFormalizacionStatus() {
            return (!this.isClosed && this.isOrden && this.formalizacionStatus);
        }

    get showAssignToMeButton() {
            //todo revisar para que solo se pueda con profile de backoffice
//            return !this.isClosed && !this.amITheCaseOwner ( this.isOrden || this.isGestion);
            return !this.isClosed && !this.amITheCaseOwner && !this.amITheOpportunityOwner && ( this.isOrden || this.isGestion);
    }

    get showSetAsVistoButton() {
            return (!this.isClosed && this.amITheCaseOwner && this.isGestion && this.status == LABEL_CASESTATUS_NUEVO);
    }

    get showStartStudioButton() {
            return (!this.isClosed && this.amITheCaseOwner && this.isGestion && (this.status == LABEL_CASESTATUS_NUEVO || this.status == LABEL_CASESTATUS_VISTO));
    }

    get showSetAsPdtGEEButton () {
            let boolShow = !this.isClosed && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GEE)
                && this.status != LABEL_CASESTATUS_NUEVO && this.status != LABEL_CASESTATUS_VISTO
                && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE)
                && !this.gestionProcessStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE) && this.isEnCurso
                && (!this.isFormalizando || this.isFormalizacion);
            return (this.amITheCaseOwner && boolShow);
        }

    get showRemovePdtGEEButton () {
            let boolShow = !this.isClosed && this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GEE) ;
            return (this.amITheOpportunityOwner && this.isOrden && boolShow);
        }

    get showSetAsPdtClienteButton () {
            let boolShow = !this.isClosed && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_CLIENTE) && this.isOrden;
            return (this.amITheOpportunityOwner && boolShow);
        }

    get showRemovePdtClienteButton () {
            let boolShow = !this.isClosed && this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_CLIENTE) ;
            return (this.amITheOpportunityOwner && this.isOrden && boolShow);
        }

    get showRevisedButton () {
            let boolShow = !this.isClosed && this.gestionProcessStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE) && this.isEnCurso;
            return (this.amITheCaseOwner && (this.isOrden || this.isGestion) && boolShow);
        }

    get showStartWorkButton () {
            let boolShow = !this.isClosed && (this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GESTIONPLACEMENT) || !this.isEnCurso) && this.status != LABEL_CASESTATUS_NUEVO && this.status != LABEL_CASESTATUS_VISTO && !this.showRevisedOkButton ;
            return (this.amITheCaseOwner && (this.isGestion || this.isSolicitud || this.isFormalizacion)  && boolShow);
        }

    get showStopWorkButton () {
            let boolShow = !this.isClosed && this.isEnCurso && (this.isPendingGEE || this.isPendingAseguradora || (this.isSolicitud && this.isFormalizando));
            return (this.amITheCaseOwner && (this.isGestion || this.isSolicitud || this.isFormalizacion)  && boolShow);

        }

    get showStopWorkAndPendingButton () {
            let boolShow = !this.isClosed && this.isEnCurso;
            return (this.amITheCaseOwner && (this.isGestion || this.isSolicitud || this.isFormalizacion)  && boolShow);

        }

    get showFinishEstudioButton () {
                let boolShow = !this.isClosed && this.isEnCurso && this.status == LABEL_CASESTATUS_ESTUDIO;
                return (this.amITheCaseOwner && this.isGestion && boolShow);
        }

    get showSetAsPdtAseguradoraButton () {
            let boolShow = !this.isClosed && this.isEnCurso && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_ASEGURADORA) && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA);
            return (this.amITheCaseOwner && ((this.isSolicitud  && !this.isFormalizando) || this.isFormalizacion)  && boolShow);
        }

    get showRemovePdtAseguradoraButton () {
            let boolShow = !this.isClosed && this.isPendingAseguradora;
            return (this.amITheCaseOwner && (this.isSolicitud || this.isFormalizacion) && boolShow);
        }

    get showRevisedInfoAseguradoraButton () {
            let boolShow = !this.isClosed && this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA);
            return (this.amITheCaseOwner && (this.isSolicitud || this.isFormalizacion)  && boolShow);
        }

    get showProposalRevisedButton () {
            let boolShow = !this.isClosed && this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA) && this.isEnCurso;
            return (this.amITheCaseOwner && (this.isSolicitud)  && boolShow);
        }

    get showGenerarPresupuestoButton () {
            let boolShow = !this.isClosed && (this.status == LABEL_CASESTATUS_ENGESTIONCONASEGURADORA) && this.isEnCurso && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA) && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA) && this.proposalStatus == LABEL_PROPOSALSTATUS_VALIDA;
            return (this.amITheCaseOwner && this.isSolicitud && boolShow);
        }

    get showNotificarPlacementButton () {
            let boolShow = !this.isClosed && !this.processStatus.includes(LABEL_PROCESSSTATUS_PDT_GEE);
            return (this.amITheOpportunityOwner && this.isOrden && boolShow);
        }

    get showQuoteModificationButton () {
            let boolShow = !this.isClosed && this.dataTree && this.dataTree.quote && this.isEnCurso
            && (this.status == LABEL_CASESTATUS_PRESENTADAOFERTA || this.status == LABEL_CASESTATUS_PROPUESTAHABILITADA || (this.status == LABEL_CASESTATUS_ENGESTIONCONASEGURADORA && this.proposalStatus == LABEL_PROPOSALSTATUS_VALIDA));
            return (this.amITheCaseOwner && this.isSolicitud && boolShow);
        }

    get showReopenSolicitudButton () {
            return (this.amITheCaseOwner && this.isSolicitud && this.isClosed && this.parentCaseStatus == LABEL_CASESTATUS_SOLICITUD_MERCADO);
        }

    get showChangeRiskButton () {
            let boolShow = !this.isClosed && this.isEnCurso && (this.status == LABEL_CASESTATUS_SOLICITUDCOBERTURA || this.status == LABEL_CASESTATUS_INICIOGESTION) ;
            return (this.amITheCaseOwner && this.isFormalizacion && boolShow);
        }

    get showCoberturaFinishedButton () {
            let boolShow = this.isEnCurso && this.status == LABEL_CASESTATUS_SOLICITUDCOBERTURA && !this.isPendingOutsidePlacement && !this.isPendingActionFromPlacement && this.isRiskVerificationOK;
            return (this.amITheCaseOwner && this.isFormalizacion && boolShow);
        }

    get showCoberturaReceivedDocButton () {
            let boolShow = this.isEnCurso && this.status == LABEL_CASESTATUS_COBERTURAACEPTADA_PDTDOC;
            return (this.amITheCaseOwner && this.isFormalizacion && boolShow);
        }

    get showSetAsComputadoButton () {
            let boolShow = this.isEnCurso
            && (this.status == LABEL_CASESTATUS_COBERTURAACEPTADA_PDTDOC || this.status == LABEL_CASESTATUS_ENREVISION_DOCFORMALIZACION)
            && !this.isContabilizado;
            return (this.amITheCaseOwner && this.isFormalizacion && boolShow);
        }

    get showPolizaSetForRevisionButton () {
            let boolShow = this.isEnCurso
            && (this.formalizacionStatus == LABEL_CASESTATUS_COBERTURAACEPTADA_PDTDOC || this.formalizacionStatus == LABEL_CASESTATUS_ENREVISION_DOCFORMALIZACION);
            return (this.amITheCaseOwner && this.isOrden && boolShow);
        }

    get showSetPolizaAsRevisedByGEEButton () {
            let boolShow = (this.status == LABEL_CASESTATUS_ENTREGADAPOLIZA);
            return (this.amITheOpportunityOwner && this.isOrden && boolShow);
        }


    get showSetAsFormalizadaButton () {
            let boolShow = (this.status == LABEL_CASESTATUS_REVISADAPOLIZA);
            return (this.amITheCaseOwner && (this.isOrden || this.isGestion || this.isFormalizacion) && boolShow);
        }
    get showSetAsFormalizadaButton () {
        let boolShow = (this.status == LABEL_CASESTATUS_REVISADAPOLIZA);
        return (this.amITheCaseOwner && (this.isOrden || this.isGestion || this.isFormalizacion) && boolShow);
    }

    get showCloseButton() {
        return (this.amITheCaseOwner && !this.isClosed && (!this.isFormalizacionOpen || this.isFormalizacion));
    }

    get showSpinner() {
        return !(this._caseWireFinished && this._userWireFinished && !this._genericSpinner);
    }




}