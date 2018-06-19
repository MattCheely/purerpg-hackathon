// import localForage from "localforage"

module.exports = {
    run() {
        console.log("Javascript is still available.");

        // check for auth token
        let tokenIndex = window.location.href.indexOf('access_token');
        let purecloudToken = null;

        if (tokenIndex !== -1) {
            purecloudToken = window.location.href.substring(tokenIndex + 13, window.location.href.indexOf('&'));
        }


        const redirectUri = `${window.location.origin}${window.location.pathname}`;
        const platformClient = window.require('platformClient');
        const environment = 'inindca.com';
        const clientId = '9d029f54-f3df-43b8-a6b0-0c06cced3e96';
        let client = platformClient.ApiClient.instance;
        client.setEnvironment(environment);

        if (!purecloudToken) {  // go to OAuth
            return client.loginImplicitGrant(clientId, redirectUri);
        } else {  // token exists, validate & move into Elm
            let lf = require('localforage');
            let userId = "1234";
            lf.getItem(`forage.character.${userId}`).then(char => {   // load character data
                let config = {
                    token: purecloudToken,
                    char
                };
                let app = require('elm/Main.elm').Main.fullscreen(config);
                app.ports.toJs.subscribe(this.fromElm);
            });
        }
    },

    toElm(userId) {
    },

    fromElm(blob) {
        if (blob.action === 'save') {
            // save to localForage
            let lf = require('localforage');
            console.log(`save my character ${blob}`);
            lf.setItem(`forage.character.${blob.userId}`, blob.character)
        } else if (blob.action === 'load') {
            this.toElm(blob.userId)
        }
    }
};
