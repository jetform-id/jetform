let Hooks = {}

// Hooks.TrixEditor = {
//     updated() {
//         var trixEditor = document.querySelector("trix-editor")
//         if (null != trixEditor) {
//             trixEditor.editor.loadHTML(this.el.value);
//         }
//     }
// }


Hooks.RenderCaptcha = {
    mounted() {
        turnstile.render('#cf-turnstile', {
            sitekey: document.querySelector("meta[name='captcha-sitekey']").getAttribute("content")
        });
    }
}

export default Hooks