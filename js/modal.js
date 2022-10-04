const { eById, eByClass, addClass, removeClass } = require("./utils");

module.exports = {
  close: () => {
    const modal = eById("modal-overlay");
    addClass(modal, 'hidden');
  },

  open: (messageId, containerId, mandatory=false) => {
    const messages = eByClass('message');
    for (const message of messages) {
      addClass(message, 'hidden');
    }
    
    const modal = eById("modal-overlay");
    if (modal.parentNode.id !== containerId) {
      const container = eById(containerId);
      modal.parentNode.removeChild(modal);
      container.prepend(modal);
    }

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