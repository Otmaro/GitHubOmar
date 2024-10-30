import { ShowToastEvent } from 'lightning/platformShowToastEvent'

/**
 *
 * @param {String} str - String to capitalize the first character
 * @returns {String} String with first character capitalized
 */
export function capitalize(str){
    return str.charAt(0).toUpperCase() + str.slice(1)
}


export function showSuccessToast(message) {
    return this.showToast('SUCCESS', message, 'success', 'dismissible');
}

export function showErrorToast(message) {
    return this.showToast('ERROR', message, 'error', 'dismissible');
}

export function showToast(title, message, variantMode, mode) {
    const event = new ShowToastEvent({
        title: capitalize(title),
        message: message,
        variant: variantMode,
        mode: mode
    });
    return(event);
}


/**
 * @param {String} msg message to display to user
 * @param {String} type variant to use; Acceptables are: success, error, info or warning (Defaults to info)
 * @returns {ShowToastEvent} Event ready to dispatch using this.dispatchEvent(event)
 */
export function toast(msg, type = 'info'){

    const event = new ShowToastEvent({
        title: capitalize(type),
        message: msg,
        variant: type,
    });

    return event
}