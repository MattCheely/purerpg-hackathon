// import localForage from "localforage"
const firebase = require('firebase');

module.exports = {
    run() {
        this.authToPurecloud()
            .then(() => {
                let lf = require('localforage');
                let userId = "1234";
                lf.getItem(`forage.character.${userId}`).then(char => {   // load character data
                    let config = {
                        token: this.accessToken,
                        char
                    };
                    let app = require('elm/Main.elm').Main.fullscreen(config);
                    app.ports.toJs.subscribe(this.fromElm);
                });
            });
    },

    authToPurecloud() {
        return new Promise((resolve, reject) => {
            const redirectUri = `${window.location.origin}${window.location.pathname}`;
            const platformClient = window.require('platformClient');
            const environment = 'inindca.com';
            const clientId = '9d029f54-f3df-43b8-a6b0-0c06cced3e96';
            const client = platformClient.ApiClient.instance;

            client.setEnvironment(environment);
            client.setPersistSettings(true, 'optional_prefix');

            resolve(client
                .loginImplicitGrant(clientId, redirectUri)
                .then(({accessToken}) =>
                    this.accessToken = accessToken));
        });
    },

    toElm(userId) {
    },

    fromElm(blob) {
        if (blob.action === 'save') {
            // save to localForage
            let lf = require('localforage');
            console.log(`save my character ${blob}`);
            lf.setItem(`forage.character.${blob.userId}`, blob.character);
        } else if (blob.action === 'load') {
            this.toElm(blob.userId);
        }
    }
};
