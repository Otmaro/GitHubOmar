/**
 * @description       : 
 * @author            : Clarcat
 * @group             : 
 * @last modified on  : 02-24-2022
 * @last modified by  : Clarcat
**/
import { LightningElement, api, wire, track } from "lwc";
import getinitData from "@salesforce/apex/Enhanced_Related_ListController.initData";
import getdownLoadAttachment from "@salesforce/apex/Enhanced_Related_ListController.downLoadAttachment";
import getDeleteRecord from "@salesforce/apex/Enhanced_Related_ListController.deleteRecord";
import getdeleteAttachment from "@salesforce/apex/Enhanced_Related_ListController.deleteAttachment";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from '@salesforce/apex';
import formFactor from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class enhanced_related_list extends NavigationMixin(LightningElement) {

    @api recordId;
    @api metadataConfig;
    @api title;
    @api showSpinner;
    @api refresh;
    @api iconName;
    @api jsonConfig;
    @api attach;
    @api showAllLinks;
    @api seeAll;
    @track seeAllRecords;
    @api limit;
    @api _datatableType;
    @api records;
    @track render_ = true;
    @api allRecords;
    @track seeAllLabel;
    recordsCopy;

    /**
     * Llamada inicial del componente en la que se inicializan todos los datos recibidos del metadato
     */
    @wire(getinitData, {recordId: "$recordId" , metadataConfig: "$metadataConfig", num: "$limit", seeAll: "$seeAll"})
    wiredData(value) {
        this.wiredData = value;
        const {data, error} = value;
        if(data){
            var jsonData = JSON.parse(data);
            this.iconName = jsonData.iconName;
            this.jsonConfig = jsonData;
            this.replaceIds(this.jsonConfig.records);
			this.replaceIds(this.jsonConfig.allRecords);
            this.showAllLinks = this.jsonConfig.showAllLinks;
            this.datatableType = this.jsonConfig.datatableType;
            this.records = this.jsonConfig.records;
            this.recordsCopy = this.records;
            this.allRecords = this.jsonConfig.allRecords;
            this.seeAllLabel = this.seeAll == true ? "Mostrar menos" : "Ver todo";
            this.showSpinner = false;
            this.title = formFactor == "Small" ? this.jsonConfig.phoneTitle +' ('+ this.jsonConfig.allRecords.length + ')' : this.jsonConfig.title +' ('+ this.jsonConfig.allRecords.length + ')';
        }
    }

    /**
     * Función encargada de actualizar la lista
     */
    handleReload() {
        return refreshApex(this.wiredData);
    }

    /**
     * Función encargada de gestionar la expansión de la lista
     */
    handleCountRecords() {
		this.showSpinner = true;
        this.records = !this.seeAllRecords ?  this.allRecords : this.recordsCopy;
        this.seeAllLabel = !this.seeAllRecords ? "Mostrar menos" : "Ver todo";
        this.seeAllRecords = !this.seeAllRecords;
		this.showSpinner = false;
	}

    /**
     * Función que gestiona las acciones de las filas de la tabla
     * Es importante que cada "case" se corresponda con el atributo "name"
     * del metadato
     */
    handleRowAction(event) {
		var action = event.detail.action;
		var row = event.detail.row;
        
		switch (action.name) {
		case 'download':
			this.downloadFile(row.ContentDocumentId);
		    break;
        case 'delete record':
            this.deleteRecord(row.Id);
            break;
        case 'show details':
            var url = window.location.href;           
            const regex = /(\/lightning).*/;
            window.open(url.replace(regex, "/"+row.Id));
            break;
        case 'showDetailsInCurrentTab':
             // Navigate to View Account Page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'view'
                },
            });
            break;
		case 'delete File':
			this.deleteFile(row.ContentDocumentId);
		    break;
		}
	}

    /**
     * Función para mostrar un toast 
     */
     showToast(titulo, mensaje, variante) {
        const event = new ShowToastEvent({
            title: titulo,
            message: mensaje,
            variant: variante,
        });
        this.dispatchEvent(event);
    }

    /**
     * Función invocada unavez finalizada la subida de un fichero
     */
    handleUploadFinished(event) {
		this.showToast("", "Archivo subido al muro correctamente","success");
		this.connectedCallback();
    }

    /**
     * Función encargada de realizar la descarga de un fichero
     */
    downloadFile(fileId) {
        console.log('fileID' + fileId);
        var action = getdownLoadAttachment;

        action({
			"DownloadAttachmentID": fileId
		}).then(b => {
            console.log(b);
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",

                attributes: {
                    url: b
                }
            });
        });
    }

    /**
     * Función encargada de eliminar un fichero
     */
    deleteFile(fileId) {
        var action = getdeleteAttachment;
        action({
			attachId : fileId
		}).then(() => {
            this.refresh = false;
            this.showToast("", "Archivo eliminado correctamente","success");
            this.connectedCallback();
            this.refresh = true;
        });
    }

    /**
     * Función encargada de eliminar un registro
     */
    deleteRecord(recordId){
        var action = getDeleteRecord;
        action({
			recordId : recordId
		}).then(() => {
            this.refresh = false;
            this.showToast("", "Registro eliminado correctamente","success");
            this.refresh = true;
        });
    }

    flattenStructure(topObject, prefix, toBeFlattened) {
		for (const prop in toBeFlattened) {
			const curVal = toBeFlattened[prop];
			if (curVal && typeof curVal === 'object') {
				this.flattenStructure( topObject, prefix + prop + '_', curVal);
			} else {
				topObject[prefix + prop] = curVal;
			}
		}
	}
  
	replaceIds(records){
		records.forEach(record => {
            try{
                for (const col in record) {
                    const curCol = record[col];
                    if (curCol && typeof curCol === 'object') {
                        this.flattenStructure(record, col + '_', curCol);
                    }
                }
            } catch (Exception){
                
            }
		});
	}
}