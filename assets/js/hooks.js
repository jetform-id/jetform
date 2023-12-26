let Hooks = {}

// Hooks.TrixEditor = {
//     updated() {
//         var trixEditor = document.querySelector("trix-editor")
//         if (null != trixEditor) {
//             trixEditor.editor.loadHTML(this.el.value);
//         }
//     }
// }

Hooks.CheckoutPage = {
    mounted() {
        document.body.classList.remove("bg-gray-50")
        document.body.classList.add("bg-gray-300")
    }
}

export default Hooks