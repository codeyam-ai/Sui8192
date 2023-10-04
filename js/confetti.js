const confetti = require('canvas-confetti');

module.exports = {
  run: () => {
    const end = Date.now() + (1 * 1000);

    // const colors = ['#bb0000', '#ffffff'];

    const frame = () => {
      confetti.default({
        particleCount: 200,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        // colors: colors
      });
      confetti.default({
        particleCount: 200,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        // colors: colors
      });

      if (Date.now() < end) {
        requestAnimationFrame(frame);
      }
    }
    
    frame();
  }
};