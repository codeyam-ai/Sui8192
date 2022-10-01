module.exports = {
  eById: (id) => document.getElementById(id),
  eByClass: (className) => document.getElementsByClassName(className),
  addClass: (element, className) => element.classList.add(className),
  removeClass: (element, classNames) => {
    const allClassNames = Array.isArray(classNames) ? classNames : [classNames];
    element.classList.remove(...allClassNames)
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