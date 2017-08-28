// Run this example by adding <%= javascript_pack_tag "hello_elm" %> to the head of your layout
// file, like app/views/layouts/application.html.erb. It will render "Hello Elm!" within the page.


import Elm from './Main'

let fetchCatalog = (callback) => {
    let request = new XMLHttpRequest();
    request.open('GET', '/catalog.json', true);

    request.onload = function() {
        let data = JSON.parse(request.responseText);
        if (request.status >= 200 && request.status < 400) {
            // Success!
            callback(null, data);
        } else {
            // We reached our target server, but it returned an error
            callback(data, null);
        }
    };

    request.onerror = function() {
        // There was a connection error of some sort
        callback({message: "Couldn't connect"}, null);
    };

    request.send();
}


document.addEventListener('DOMContentLoaded', () => {
    const target = document.createElement('div');

    document.body.appendChild(target);
    let elm = Elm.Main.embed(target);

    fetchCatalog((error, data) => {
        console.info(data);
        elm.ports.catalog.send(data["catalog"]["products"]);
    });
})
