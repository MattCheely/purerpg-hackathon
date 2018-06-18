module.exports = {
  run: function() {
    console.log("Javascript is still available.");

    // check for auth token
    var tokenIndex = window.location.href.indexOf('access_token');
    var purecloudToken = null;

    if (tokenIndex !== -1) purecloudToken = window.location.href.substring(tokenIndex + 13, window.location.href.indexOf('&'));


    const redirectUri = `${window.location.origin}${window.location.pathname}`;
    const platformClient = window.require('platformClient');
    const environment = 'inindca.com';
    const clientId = '9d029f54-f3df-43b8-a6b0-0c06cced3e96';
    var client = platformClient.ApiClient.instance;
    client.setEnvironment(environment);

    if (!purecloudToken) {  // go to OAuth
      return client.loginImplicitGrant(clientId, redirectUri);
    } else {  // token exists, validate & move into Elm
      require('elm/Main.elm').Main.fullscreen(purecloudToken);
    }
    // Start Elm app in fullscreen mode
  }
};
