const firebase = require('firebase');
const localForage = require('localforage');
const platformClient = window.require('platformClient');

module.exports = {
    purecloudEnvironment: 'inindca.com',
    purecloudClientId: '9d029f54-f3df-43b8-a6b0-0c06cced3e96',
    appRedirectUri: `${window.location.origin}${window.location.pathname}`,

    accessToken: null,
    userId: null,
    userName: null,

    run() {
        Promise.resolve()
            .then(() => this.authToPurecloud())
            .then(() => this.loadPurecloudUser())
            .then(() => {
                let userId = "1234";
                localForage.getItem(`forage.character.${userId}`).then(char => {   // load character data
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
        const client = platformClient.ApiClient.instance;

        client.setEnvironment(this.purecloudEnvironment);
        client.setPersistSettings(true, 'optional_prefix');

        return client
            .loginImplicitGrant(this.purecloudClientId, this.appRedirectUri)
            .then(({accessToken}) =>
                this.accessToken = accessToken);
    },

    loadPurecloudUser() {
        return new platformClient.UsersApi().getUsersMe()
            .then(userModel => {
                this.userId = userModel.id;
                this.userName = userModel.name;
            });
    },

    toElm(userId) {
    },

    fromElm(blob) {
        if (blob.action === 'save') {
            // save to localForage
            console.log(`save my character ${blob}`);
            localForage.setItem(`forage.character.${blob.userId}`, blob.character);
        } else if (blob.action === 'load') {
            this.toElm(blob.userId);
        }
    }
};
