const { eById, eByClass, addClass, removeClass } = require("./utils");

module.exports = {
  close: () => {
    addClass(eById("modal"), 'hidden');
  },

  open: (messageId) => {
    const messages = eByClass('message');
    for (const message of messages) {
      addClass(message, 'hidden');
    }
    
    const message = eById(messageId);
    removeClass(message, 'hidden');
    removeClass(eById("modal"), 'hidden');
  }
}