const utils = {
  eById: (id) => document.getElementById(id),
  
  eByClass: (className) => document.getElementsByClassName(className),

  toArray: (itemOrItems) => {
    const itemsArray = Array.isArray(itemOrItems) || itemOrItems instanceof HTMLCollection ? 
      itemOrItems : 
      [itemOrItems];
    return itemsArray;
  },

  addClass: (elementOrElements, className) => {
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.classList.add(className)
    }
  },

  removeClass: (elementOrElements, classNameOrNames) => {
    const allClassNames = utils.toArray(classNameOrNames) 
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.classList.remove(...allClassNames)
    }
  },

  setOnClick: (elementOrElements, onClick) => {
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.onclick = onClick;
    }
  },

  directionNumberToDirection: (directionNumber) => {
    switch(directionNumber) {
      case "0": return "left";
      case "1": return "right";
      case "2": return "up";
      case "3": return "down";
    }
  },

  directionToDirectionNumber: (direction) => {
    switch(direction) {
      case "left": return "0";
      case "right": return "1";
      case "up": return "2";
      case "down": return "3";
    }
  },

  directionNumberToSymbol: (directionNumber) => {
    switch(directionNumber) {
      case "0": return "←";
      case "1": return "→";
      case "2": return "↑";
      case "3": return "↓";
    }
  },

  isVertical: (direction) => ["up", "down"].includes(direction),

  isReverse: (direction) => ["right", "down"].includes(direction),

  truncateMiddle: (s, length=6) => `${s.slice(0,length)}...${s.slice(length * -1)}`
}

module.exports = utils;
  