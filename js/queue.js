const { 
  eById, 
  addClass, 
  removeClass,  
  directionNumberToSymbol,
  directionToDirectionNumber
} = require("./utils");

const queue = [];
let queueId = 0;

const next = () => queue[0];

const length = () => queue.length;

const add = (direction) => {
  const id = ++queueId;
  const item = { id, direction }
  queue.push(item);

  if (queue.length > 0) {
    const directionElement = document.createElement('DIV');
    directionElement.id = `queue-${id}`
    addClass(directionElement, 'queue-element')
    directionElement.innerHTML = directionNumberToSymbol(directionToDirectionNumber(direction));
    eById('queue').appendChild(directionElement);
    show();
  }

  return item;
}

const remove = (queuedMove) => {
  if (!queue[0] || queue[0].id !== queuedMove.id) return;

  queue.splice(0, 1);

  const queueElement = eById(`queue-${queuedMove.id}`)
  if (queueElement) {
    queueElement.parentNode.removeChild(queueElement)
  }
  
  if (queue.length === 0) {
    hide();
  }
}

const removeAll = () => {
  for (const queuedMove of queue) {
    queue.remove(queuedMove);
  }
}

const show = () => {
  const queueElement = eById('queue');
  removeClass(queueElement, 'hidden');
}

const hide = () => {
  const queueElement = eById('queue');
  addClass(queueElement, 'hidden');
}

module.exports = { next, length, add, remove, removeAll, show, hide };