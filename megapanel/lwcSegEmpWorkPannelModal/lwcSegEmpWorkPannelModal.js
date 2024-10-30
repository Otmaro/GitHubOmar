import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';

import { showSuccessToast, showErrorToast } from 'c/lwcToastUtils'

import ordenRevised from '@salesforce/apex/LwcSegEmpWorkPannelController.ordenRevised';
import infoAseguradoraRevised from '@salesforce/apex/LwcSegEmpWorkPannelController.infoAseguradoraRevised';
import proposalRevised from '@salesforce/apex/LwcSegEmpWorkPannelController.proposalRevised';
import generateQuote from '@salesforce/apex/LwcSegEmpWorkPannelController.generateQuote';
import notifyPlacement from '@salesforce/apex/LwcSegEmpWorkPannelController.notifyPlacement';
import getPresupuestosPresentados from '@salesforce/apex/LwcSegEmpWorkPannelController.getPresupuestosPresentados';
import getPolizaRecordTypeId from '@salesforce/apex/LwcSegEmpWorkPannelController.getPolizaRecordTypeId';
import quoteModification from '@salesforce/apex/LwcSegEmpWorkPannelController.quoteModification';
import coberturaFinished from '@salesforce/apex/LwcSegEmpWorkPannelController.coberturaFinished';

import LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE from '@salesforce/label/c.ProcessStatus_PdtRevisionInfoGEE';
import LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA from '@salesforce/label/c.ProcessStatus_PdtRevisionInfoAseguradora';
import LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA from '@salesforce/label/c.ProcessStatus_PdtRevisionPropuesta';


import LABEL_CASESTATUS_ENGESTIONCONASEGURADORA from '@salesforce/label/c.CaseStatus_EnGestionConAseguradora';
import LABEL_CASESTATUS_PRESENTADAOFERTA from '@salesforce/label/c.CaseStatus_PresentadaOferta';

const GENERACION_PRESUPUESTO = 'GeneracionPresupuesto';
const NOTIFY_PLACEMENT = 'NotifyPlacement';
const MODIFY_QUOTE = 'ModifyQuote';
const CHANGE_RISK = 'ChangeRiskStatus';
const COBERTURA_FINISHED = 'CoberturaFinished'

export { GENERACION_PRESUPUESTO, NOTIFY_PLACEMENT, MODIFY_QUOTE, CHANGE_RISK, COBERTURA_FINISHED};

export default class LwcSegEmpWorkPannelModal extends LightningModal {
    @api modalType;
    @api caseId;
    @api opportunityId;
    @api case;

    reviewResultValue;
    proposalReceivedValue = 'false';
    proposalStatusValue;
    notifyPlacementValue = 'infoRequest';
    quoteModificationTypeValue;
    coberturaFinishedDocReceivedValue;

    _presupuestosPresentadosOptions;
    presupuestoSelectedIdValue;
    polizaRecordTypeId;

    _showSpinner = true;
    saveInProcess = false;
    showFormaCobro = false;


    //quotegeneration
    today = new Date().toISOString();
    fechaEfecto;
    fechaVencimiento;
    tasa = '0';
    impuesto = '0';
    primaNeta = '0';
    importePrimaTotal = '0';
    comentario;

    connectedCallback() {
        if (this.isQuoteGeneration) {
            this.fechaEfecto = this.fechaEfectoFromCase;
            this.fechaVencimiento = this.fechaVencimientoFromCase;
        }
        this._showSpinner = false;
    }

    handleFechaEfectoChange(event) {
            this.fechaEfecto = event.detail.value;
        }

    handleFechaVencimientoChange(event) {
            this.fechaVencimiento = event.detail.value;
        }

    handleTasaChange(event) {
            this.tasa = event.detail.value;
        }

    handleImpuestoChange(event) {
            this.impuesto = event.detail.value;
        }

    handleQuoteModificationChange(event) {
            this.quoteModificationTypeValue = event.detail.value;
        }

    handleOnblur(event) {
            let dataId = event.target.dataset.id;
            this.checkGreaterThanZero(dataId);
    }

    checkGreaterThanZero(dataId) {
        let item = this.template.querySelector('[data-id="'+dataId+'"]');
        if (item.value <= 0)  {
             item.setCustomValidity('El importe debe ser superior a 0');
         } else {
             item.setCustomValidity('');
         }
         item.reportValidity();
    }

    handlePrimaNetaChange(event) {
            this.primaNeta = event.detail.value;
            let dataId = event.target.dataset.id;
            this.checkGreaterThanZero(dataId);
        }

    handleImportePrimaTotalChange(event) {
            this.importePrimaTotal = event.detail.value;
            let dataId = event.target.dataset.id;
            this.checkGreaterThanZero(dataId);
        }

    handleCommentChange(event) {
        this.comentario = event.detail.value;
    }

    handleReviewResultChange(event) {
            this.reviewResultValue = event.detail.value;
        }

    handleProposalReceivedChange(event) {
            this.proposalReceivedValue = event.detail.value;
        }

    handleProposalStatusChange(event) {
            this.proposalStatusValue = event.detail.value;
        }

    handleNotifyPlacementChange(event) {
            this.notifyPlacementValue = event.detail.value;
            if (this.notifyPlacementValue == 'accepted') {
                this.handleGetPresentedPresupuestos();
            }
        }

    handleCoberturaFinishedChange(event) {
            this.coberturaFinishedDocReceivedValue = event.detail.value;
        }

    handlePeriodicidadChange(event) {
        if (event.detail.value == 'Renovable') {
            this.showFormaCobro = true;
        } else {
            this.showFormaCobro = false;
        }
    }

    handlePresupuestoSelectedForAcceptionValueChange(event) {
            this.presupuestoSelectedIdValue = event.detail.value;
        }

    handleRevisedGEE() {
        ordenRevised({
                opportunityId : this.opportunityId,
                isOk : this.reviewResultValue
            }).then((result) => {
                if (result.isSuccess) {
                        this.closeModal('SUCCESS', null);
                } else {
                        this.closeModal('ERROR', 'Error: '+result.message);
                }
            }).catch((error)=> {
                        this.closeModal('ERROR', ('Error: '+JSON.stringify(error)));
            });
        }

    handleRevisedAseguradora() {
        infoAseguradoraRevised({
                opportunityId : this.opportunityId,
                caseId: this.caseId,
                isOk : this.reviewResultValue,
                isProposal : this.proposalReceivedValue,
            }).then((result) => {
                if (result.isSuccess) {
                        this.closeModal('SUCCESS', null);
                } else {
                        this.closeModal('ERROR', result.message);
                }
            }).catch((error)=> {
                        this.closeModal('ERROR', JSON.stringify(error));
                });
        }

    handleRevisedProposal() {
        proposalRevised({
                opportunityId : this.opportunityId,
                caseId: this.caseId,
                isOk : this.proposalStatusValue,
            }).then((result) => {
                if (result.isSuccess) {
                        this.closeModal('SUCCESS', null);
                } else {
                        this.closeModal('ERROR', result.message);
                }
            }).catch((error)=> {
                        this.closeModal('ERROR', JSON.stringify(error));
                });
        }

    handleGenerateQuote() {
            var obj = {
                    fechaEfecto : this.fechaEfecto,
                    fechaVencimiento : this.fechaVencimiento,
                    tasa : this.tasa,
                    impuesto : this.impuesto,
                    primaNeta : this.primaNeta,
                    importePrimaTotal : this.importePrimaTotal,
                    comentario : this.comentario,
                }
            let jsonObj = JSON.stringify(obj);

        generateQuote({
                opportunityId : this.opportunityId,
                caseId: this.caseId,
                jsonPresupuesto : jsonObj
            }).then((result) => {
                if (result.isSuccess) {
                        this.closeModal('SUCCESS', null);
                } else {
                        this.closeModal('ERROR', result.message);
                }
            }).catch((error)=> {
                        this.closeModal('ERROR', JSON.stringify(error));
                });
        }

    handleGetPresentedPresupuestos() {
            this._showSpinner = true;
            if (this._presupuestosPresentadosOptions) {
                this._showSpinner = false;
            } else {
                this._presupuestosPresentadosOptions = [];
                getPresupuestosPresentados({
                    opportunityId : this.opportunityId
                }).then((result) => {
                    result.forEach(item => {
                            this._presupuestosPresentadosOptions = [...this._presupuestosPresentadosOptions, {label: item.Name, value: item.Id}];
                    });
                    if (this._presupuestosPresentadosOptions.length ==1) {
                        this.presupuestoSelectedIdValue = this._presupuestosPresentadosOptions[0].Id;
                    }
                    getPolizaRecordTypeId({
                    }).then((result) => {
                        this.polizaRecordTypeId = result;
                        this._showSpinner = false;
                    }).catch((error)=> {
                        this.closeModal('ERROR', JSON.stringify(error));
                    });
                }).catch((error)=> {
                    this.closeModal('ERROR', JSON.stringify(error));
                });
            }

        }

    handleNotifyPlacement() {
        if (this.showCreatePoliza) {
            let obj = {};
            let fields = this.template.querySelectorAll('lightning-input-field');

            fields.forEach(item => {
                    item.reportValidity();
                    obj[item.dataset.id] = item.value;
                    });
            var jsonObj = JSON.stringify(obj);
        }
        notifyPlacement({
                opportunityId : this.opportunityId,
                notificationType : this.notifyPlacementValue,
                acceptedPresupuestoId: this.presupuestoSelectedIdValue,
                jsonPoliza : jsonObj
        }).then((result) => {
            if (result.isSuccess) {
                    this.closeModal('SUCCESS', null);
            } else {
                    this.closeModal('ERROR', result.message);
            }
        }).catch((error)=> {
                    this.closeModal('ERROR', JSON.stringify(error));
            });
        }

    handleQuoteModification() {
        quoteModification({
                opportunityId : this.opportunityId,
                caseId : this.caseId,
                modificationType : this.quoteModificationTypeValue
            }).then((result) => {
                if (result.isSuccess) {
                        this.closeModal('SUCCESS', null);
                } else {
                        this.closeModal('ERROR', result.message);
                }
            }).catch((error)=> {
                        this.closeModal('ERROR', JSON.stringify(error));
                });
        }

    handleCoberturaFinished() {
            let docReceived = (this.coberturaFinishedDocReceivedValue == 'true' ? true : false);
        coberturaFinished({
            opportunityId : this.opportunityId,
            docReceived: docReceived
        }).then((result) => {
            if (result.isSuccess) {
                    this.closeModal('SUCCESS', null);
            } else {
                    this.closeModal('ERROR', result.message);
            }
        }).catch((error)=> {
                    this.closeModal('ERROR', JSON.stringify(error));
            });
    }

    handleChangeRisk() {
        this.template.querySelector('[data-id="changeriskform"]').submit();
    }

    handleOnSubmitSuccess() {
        this.closeModal('SUCCESS', null);
    }

    handleOnSubmitError() {
        this.saveInProcess = false;
        this._showSpinner = false;
    }

    handleCancel() {
        this.closeModal('CANCELLED', null);
    }

    handleSave() {
        if (this.isValid) {
            this.disableClose = true;
            this.saveInProcess = true;
            if (this.isRevisedInfoGEE) {
                this.handleRevisedGEE();
            } else if (this.isRevisedInfoAseguradora) {
                this.handleRevisedAseguradora();
            } else if (this.isRevisedProposal) {
                this.handleRevisedProposal();
            } else if (this.isQuoteGeneration) {
                this.handleGenerateQuote();
            } else if (this.isNotifyPlacement) {
                this.handleNotifyPlacement();
            } else if (this.isQuoteModification) {
                this.handleQuoteModification();
            } else if (this.isChangeRisk) {
                this.handleChangeRisk();
            } else if (this.isCoberturaFinished) {
                this.handleCoberturaFinished();
            }
        }
    }

    closeModal(status, message) {
        this.disableClose = false;
        var obj = {status : status,
            message : message};
        this.close(obj);
    }

    get isValid() {
        let items = this.template.querySelectorAll('lightning-radio-group');
        items = [...items, ...this.template.querySelectorAll('lightning-input')];
        items = [...items, ...this.template.querySelectorAll('lightning-combobox')];
//        items = [...items, ...this.template.querySelectorAll('lightning-input-field')];
        let allValid = true;
        items.forEach(item => {
            let dataId = item.dataset.id;
            if ((dataId == 'primaneta' || dataId == 'importeprimatotal')){
                this.checkGreaterThanZero(dataId);
            }
            if (!item.checkValidity()) {
                allValid = false;
                item.reportValidity();
            }

        });
        return allValid;
    }

    get reviewOptions() {
            return [    {label: 'Revisado info OK', value: 'true'},
                        {label:'Revisado info NO OK', value: 'false'}
                   ];
        }

    get yesOrNoOptions() {
            return [    {label: 'Si', value: 'true'},
                        {label:'No', value: 'false'}
                   ];
    }

    get quoteModificationOptions() {
            return [    {label: 'Ajustar detalles', value: 'ajustar'},
                        {label:'Recotizar', value: 'recotizar'}
                   ];
    }

    get notifyPlacementOptions() {
            var options = [{label: 'Notificar nueva info añadida/requerida', value: 'infoRequest'}];
                if (this.statusFromCase == LABEL_CASESTATUS_PRESENTADAOFERTA) {
                    let ofertaOptions = [
//                        {label: 'Cotización necesita cambios', value: 'changeRequest'},
                        {label:'Cotización aceptada', value: 'accepted'},
//                        {label:'Cotización rechazada', value: 'rejected'}
                    ];
                    options = [...options, ...ofertaOptions];
                }
            return options;
    }

    get presupuestosPresentadosOptions() {
            return this._presupuestosPresentadosOptions;
        }

    get isRevisedInfoAseguradora () {
            return this.modalType == LABEL_PROCESSSTATUS_PDT_REVISIONINFOASEGURADORA;
    }

    get isRevisedInfoGEE() {
            return this.modalType == LABEL_PROCESSSTATUS_PDT_REVISIONINFOGEE;
        }

    get isRevisedProposal() {
            return this.modalType == LABEL_PROCESSSTATUS_PDT_REVISIONPROPUESTA;
        }

    get isQuoteGeneration() {
            return this.modalType == GENERACION_PRESUPUESTO;
        }

    get isNotifyPlacement() {
            return this.modalType == NOTIFY_PLACEMENT;
        }

    get isQuoteModification() {
            return this.modalType == MODIFY_QUOTE;
        }

    get isChangeRisk() {
            return this.modalType == CHANGE_RISK;
        }

    get isCoberturaFinished() {
            return this.modalType == COBERTURA_FINISHED;
        }

    get showCheckIfProposalMade() {
            return this.reviewResultValue == 'true' && this.isRevisedInfoAseguradora && this.statusFromCase == LABEL_CASESTATUS_ENGESTIONCONASEGURADORA;
        }

    get showIsInfoOkQuestion() {
            return this.isRevisedInfoGEE || this.isRevisedInfoAseguradora;
        }

    get showPresupuestosList() {
            return (this.notifyPlacementValue == 'accepted');
        }

    get showCreatePoliza() {
            return (this.notifyPlacementValue == 'accepted' && this.presupuestoSelectedIdValue);
        }

    get modalLabel() {
            if (this.isRevisedInfoGEE) {
                    return 'Resultado revisión info GEE';
            } else if (this.isRevisedInfoAseguradora) {
                    return 'Resultado revisión info aseguradora';
            } else if(this.isRevisedProposal) {
                    return 'Resultado revisión propuesta';
            } else if(this.isQuoteGeneration) {
                    return 'Generación de presupuesto';
            }  else if(this.isNotifyPlacement) {
                    return 'Notificar a placement';
            } else if (this.isQuoteModification) {
                    return 'Determinar tipo de cambio';
            } else if (this.isChangeRisk) {
                    return 'Cambiar estado verificación riesgo';
            } else if (this.isCoberturaFinished) {
                    return 'Solicitud de cobertura finalizada';
            } else return null;
        }

    get showSpinner() {
            return this.saveInProcess || this._showSpinner;
        }


    //field getters
    get fechaEfectoFromCase() {
        if (this.case) {
            return this.case.fields.ABA_DATE_Fecha_de_efecto__c.value;
        } else {
            return null;
        }
    }
    get fechaEfectoFromOpportunity() {
        if (this.case && this.case.fields.ABA_Opportunity__r && this.case.fields.ABA_Opportunity__r.value.fields.ABA_DATE_Fecha_de_efecto__c) {
            return this.case.fields.ABA_Opportunity__r.value.fields.ABA_DATE_Fecha_de_efecto__c.value;
        } else {
            return null;
        }
    }

    get fechaVencimientoFromCase() {
        if (this.case) {
            return this.case.fields.ABA_DATE_Fecha_de_vencimiento__c.value;
        } else {
            return null;
        }
    }

    get statusFromCase() {
        if (this.case) {
            return this.case.fields.Status.value;
        } else {
            return null;
        }
    }

    get oficinaGestora() {
        if (this.case && this.case.fields.Account && this.case.fields.Account.value.fields.ABA_TX_Oficina_gestora__c) {
            return this.case.fields.Account.value.fields.ABA_TX_Oficina_gestora__c.value;
        } else {
            return null;
        }
    }


}