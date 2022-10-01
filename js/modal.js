const { eById, eByClass, addClass, removeClass } = require("./utils");

module.exports = {
  close: () => {
    addClass(eById("modal-overlay"), 'hidden');
  },

  open: (messageId) => {
    console.log("OPEN", messageId)
    const messages = eByClass('message');
    for (const message of messages) {
      addClass(message, 'hidden');
    }
    
    const message = eById(messageId + '-message');
    removeClass(message, 'hidden');
    removeClass(eById("modal-overlay"), 'hidden');
  }
}