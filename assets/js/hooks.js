
let Hooks = {}

Hooks.Math = {
  mounted() {
    window.renderMathInElement(this.el);
  },

  updated() {
    window.renderMathInElement(this.el);
  }
}

export default Hooks;
