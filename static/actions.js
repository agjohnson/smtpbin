// Actions

// Change class on object and redirect
function view_message (id, view) {
    var block_message = document.getElementById('message-' + id);
    if (block_message) {
        block_message.className = 'state-read'
    }

    var url = '/message/' + id;
    if (view) {
        if (view == 'html') {
            url += '.html';
        }
        else if (view == 'txt') {
            url += '.txt';
        }
    }
    window.location = url;
}

// Delete message from page
function delete_message (id) {
    var block_message = document.getElementById('message-' + id);
    block_message.parentNode.removeChild(block_message);

    var url = '/message/' + id + '/delete';
    window.location = url;
}
