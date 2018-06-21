
module.exports = {

    run() {
        Promise.resolve()
            .then(() => {
                const app = require('elm/Main.elm').Main.fullscreen({
                    userId: "arglebarf",
                    token: "tokenBoken",
                    char: null
                });

                app.ports.toJs.subscribe(this.fromElm.bind(this));
            });
    },

    toElm(userId) {
    },

    fromElm(blob) {
        try {
            let { action } = blob;
            console.log(action);

        } catch (error) {
            console.error(`caught error in port that would stop elm ${error}`);
        }
    }
};
