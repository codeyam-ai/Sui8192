const { eById, eByClass, addClass, removeClass } = require("./utils");

module.exports = {
  close: (fromCloseButton) => {
    const modal = eById("modal-overlay");
    const mandatory = modal.dataset.mandatory;

    if (mandatory && fromCloseButton) return;
    addClass(modal, 'hidden');
  },

  open: (messageId, mandatory=false) => {
    const messages = eByClass('message');
    for (const message of messages) {
      addClass(message, 'hidden');
    }
    
    const modal = eById("modal-overlay");
    modal.dataset.mandatory = mandatory;

    const closeButton = eById('close-modal');
    if (mandatory) {
      addClass(closeButton, 'hidden');
    } else {
      removeClass(closeButton, 'hidden');
    }
    
    const message = eById(messageId + '-message');
    removeClass(message, 'hidden');
    removeClass(modal, 'hidden');
  }
}