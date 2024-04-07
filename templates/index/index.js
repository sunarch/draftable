function eh_click() {
    webui.eh_click_hello('Message from JS')
        .then((response) => {
            console.log(response);
        });
}
