

import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';

import { showSuccessToast, showErrorToast } from 'c/lwcToastUtils'

import closeCases from '@salesforce/apex/LwcSegEmpWorkPannelController.closeCases';

import LABEL_CASESTATUS_CERRADO from '@salesforce/label/c.CaseStatus_Cerrado';
import LABEL_MOTIVOESTADO_ANULADANOCONTINUA from '@salesforce/label/c.MotivoEstado_AnuladaNoContinua';
import LABEL_MOTIVOESTADO_ANULADA from '@salesforce/label/c.MotivoEstado_Anulada';
import LABEL_MOTIVOESTADO_REVOCADO from '@salesforce/label/c.MotivoEstado_Revocado';
import LABEL_MOTIVOESTADO_NOPASAVERIFICACION from '@salesforce/label/c.MotivoEstado_NoPasaVerificacion';
import LABEL_SITUACION_NOPASAVERIFICACION from '@salesforce/label/c.Situacion_NoPasaVerificacion';
import LABEL_SITUACION_RENUEVACARTERA from '@salesforce/label/c.Situacion_RenuevaCartera';
import LABEL_SITUACION_RENUEVACONOTRAMEDIACION from '@salesforce/label/c.Situacion_RenuevaConOtraMediacion';
import LABEL_SITUACION_CAMBIODEMEDIACION from '@salesforce/label/c.Situacion_CambioDeMediacion';


export default class LwcSegEmpWorkPannelClosingModal extends LightningModal {

    @api caseId;
    @api opportunityId;

    statusValue = LABEL_CASESTATUS_CERRADO;
    _showSpinner = false;
    saveInProcess = false;
    motivoValue;
    situacionValue;
    ciaValue;
    mediacionValue;
    commentValue;


    get isValid() {
        let items = this.template.querySelectorAll('lightning-input');
        items = [...items, ...this.template.querySelectorAll('lightning-textarea')];
        let allValid = true;
        items.forEach(item => {
            let dataId = item.dataset.id;
            if (!item.checkValidity()) {
                allValid = false;
                item.reportValidity();
            }

        });
        return allValid;
    }


    handleMotivoChange(event) {
        this.motivoValue = event.detail.value;
        this.situacionValue = null;
        this.ciaValue = null;
        this.mediacionValue = null;
    }

    handleSituacionChange(event) {
        this.situacionValue = event.detail.value;
        this.ciaValue = null;
        this.mediacionValue = null;
    }

    handleCIAChange(event) {
        this.ciaValue = event.detail.value;
    }

    handleMediacionChange(event) {
        this.mediacionValue = event.detail.value;
    }

    handleCommentChange(event) {
        this.commentValue = event.detail.value;
    }

    handleCancel() {
        this.closeModal('CANCELLED', null);
    }



    handleSubmit(event) {
        event.preventDefault();
        if (this.isValid) {
            this.disableClose = true;
            this.saveInProcess = true;
            const fields = event.detail.fields;
            var concatenatedComment = '';
            if (this.ciaValue) {
                concatenatedComment = concatenatedComment+'CIA: '+this.ciaValue+'\n';
            }
            if (this.mediacionValue) {
                concatenatedComment = concatenatedComment+'Mediacion: '+this.mediacionValue+'\n';
            }
            if (this.commentValue) {
                concatenatedComment = concatenatedComment+this.commentValue;
            }

            if (concatenatedComment != ''){
                fields.ABA_TX_Comentarios_Estado__c = concatenatedComment;
            }
            let jsonData = JSON.stringify(fields);
            closeCases({
                  opportunityId : this.opportunityId,
                  caseId : this.caseId,
                  jsonData : jsonData
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
    }


    handleOnSubmitSuccess() {
        this.closeModal('SUCCESS', null);
    }

    handleOnSubmitError() {
        this.saveInProcess = false;
        this._showSpinner = false;
    }

    closeModal(status, message) {
        this.disableClose = false;
        var obj = {status : status,
            message : message};
        this.close(obj);
    }

    get showCIA() {
            return (this.situacionValue == LABEL_SITUACION_NOPASAVERIFICACION
                || this.situacionValue == LABEL_SITUACION_RENUEVACARTERA
                || this.situacionValue == LABEL_SITUACION_RENUEVACONOTRAMEDIACION
                )
        }

    get showMediacion() {
        return (this.situacionValue == LABEL_SITUACION_RENUEVACONOTRAMEDIACION);
    }

    get closingCommentsRequired() {
            var requerido = (this.motivoValue == LABEL_MOTIVOESTADO_ANULADANOCONTINUA
                                        || this.motivoValue == LABEL_MOTIVOESTADO_ANULADA);
            return requerido;
        }

    get modalLabel() {
            return 'Cerrar caso';
        }

    get showSpinner() {
            return this.saveInProcess || this._showSpinner;
        }
}