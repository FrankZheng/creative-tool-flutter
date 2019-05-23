console = {};
console.log = function(s) {
    window.webkit.messageHandlers.VungleMessageHandler.postMessage('log:'+s);
}

console.error = function(s) {
    window.webkit.messageHandlers.VungleMessageHandler.postMessage('error:'+s);
}

console.trace = function() {
    try {
        var a = {};
        a.debug();
    } catch (ex) {
        window.webkit.messageHandlers.VungleMessageHandler.postMessage('trace:'+ex.stack);
    }
}

window.onerror = function(message, script, lineNumber, column, error) {
    //if CORs disabled, always 'Script error', error is null
    var msg = null;
    if(error == null) {
        msg = {msg:message};
    } else {
        msg = {errName:error.name, msg:message, stack:error.stack};
    }
    console.error(JSON.stringify(msg));
    return false;
}

window.console = console;
