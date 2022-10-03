const { eById, eByClass, addClass, removeClass } = require("./utils");

module.exports = {
  close: () => {
    const modal = eById("modal-overlay");
    addClass(modal, 'hidden');
  },

  open: (messageId, mandatory=false) => {
    const messages = eByClass('message');
    for (const message of messages) {
      addClass(message, 'hidden');
    }
    
    const modal = eById("modal-overlay");
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