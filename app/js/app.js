const firebase = require('firebase');
const localForage = require('localforage');
const appsSdk = require('purecloud-client-app-sdk');
const platformClient = window.require('platformClient');

module.exports = {
    purecloudEnvironment: 'inindca.com',
    purecloudClientId: '9d029f54-f3df-43b8-a6b0-0c06cced3e96',
    appRedirectUri: `${window.location.origin}${window.location.pathname}`,

    accessToken: null,
    userId: null,
    userName: null,

    database: null,
    characterModel: null,

    run() {
        Promise.resolve()
            .then(() => this.authToPurecloud())
            .then(() => this.loadPurecloudUser())
            .then(() => this.connectToFirebase())
            .then(() => this.loadGameUser())
            .then(() => {
                const app = require('elm/Main.elm').Main.fullscreen({
                    userId: this.userId,
                    token: this.accessToken,
                    char: this.characterModel,
                    seed: Date.now()
                });

                app.ports.toJs.subscribe(this.fromElm.bind(this));
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

    connectToFirebase() {
        firebase.initializeApp({
            apiKey: "AIzaSyCMWIi0QW_YPG4uVTWMlKzq_61fJs-AHT8",
            authDomain: "project-939081188532.firebaseapp.com",
            databaseURL: "https://purerpg-65258.firebaseio.com/",
            storageBucket: "bucket.appspot.com"
        });

        this.database = firebase.database();

        return Promise.resolve();
    },

    loadGameUser() {
        return this.database.ref(`/users/${this.userId}`).once('value')
            .then(snapshot => {
                this.characterModel = snapshot.val();
            });
    },

    toElm(userId) {
    },

    fromElm(blob) {
        try {
            let { action } = blob;

            if (action === 'saveCharacter') {
                let { character } = blob;
                character.userId = this.userId;

                this.database.ref(`users/${this.userId}`).set(character);
            }

            if (action === 'saveCombat') {
                let { combat, combatId } = blob;

                this.database.ref(`combat/${combatId}`).set(combat);
            }

            if (action === 'showAchievement') {
                let { message } = blob;
                let clientApp = new appsSdk({
                    pcOrigin: 'https://apps.inindca.com'
                });
                let title = 'Achievement Unlocked!';
                let options = {
                    type: 'success',
                    timeout: 30,
                    showCloseButton: true
                }
                clientApp.alerting.showToastPopup(title, message, options)
            }

            if (action == "playSound") {
                document.getElementById(`sound-${blob.sound}`).play();
            }

            console.log(action);

        } catch (error) {
            console.error(`caught error in port that would stop elm ${error}`);
        }
    }
};
