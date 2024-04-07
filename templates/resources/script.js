function eh_click() {
    webui.eh_click_hello('Message from JS')
        .then((response) => {
            console.log(response);
        });
}

function navigate_index() {
    webui.navigate_index()
        .then((response) => {
            console.log(response);
        });
}

function navigate_licenses() {
    webui.navigate_licenses()
        .then((response) => {
            console.log(response);
        });
}
